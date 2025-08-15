FW = FW or {}

local function playerPayload(ident)
  local c = exports['survivalfw']:SFW_PlayerContainerId(ident)
  local inv = exports['survivalfw']:SFW_FetchStacks(c)
  return inv or {}
end

exports('SFW_TraderPayload', function(trader_id, ident)
  local prices = MySQL.query.await([[
    SELECT tp.item_key, tp.price_buy, tp.price_sell, tp.scarcity, i.label
    FROM trader_prices tp LEFT JOIN items i ON i.item_key=tp.item_key
    WHERE tp.trader_id=?
    ORDER BY i.label ASC
  ]], { trader_id })
  return { trader_id=trader_id, prices=prices or {}, inv=playerPayload(ident) }
end)

RegisterNetEvent('fw:trader:buy', function(data)
  local src = source; local ident = FW.GetIdentifier and FW.GetIdentifier(src); if not ident then return end
  local item = data and data.item_key; local qty = tonumber(data and data.qty) or 1; local trader_id = tonumber(data and data.trader_id) or 0
  if not item or qty<=0 then return end
  local c = exports['survivalfw']:SFW_PlayerContainerId(ident)
  local row = MySQL.single.await("SELECT slot_index FROM container_slots WHERE container_id=? AND slot_index NOT IN (SELECT slot_index FROM stacks WHERE container_id=?) ORDER BY slot_index LIMIT 1", { c, c })
  if row then
    MySQL.insert.await("INSERT INTO stacks(container_id,slot_index,item_key,quantity,durability,metadata,state_hash,weight_cached) VALUES (?,?,?,?,100,'{}','',0)", { c, row.slot_index, item, qty })
  end
end)

RegisterNetEvent('fw:trader:sell', function(data)
  local src = source; local ident = FW.GetIdentifier and FW.GetIdentifier(src); if not ident then return end
  local item = data and data.item_key; local qty = tonumber(data and data.qty) or 1
  if not item or qty<=0 then return end
  local c = exports['survivalfw']:SFW_PlayerContainerId(ident)
  local st = MySQL.single.await("SELECT * FROM stacks WHERE container_id=? AND item_key=? LIMIT 1", { c, item })
  if not st or st.quantity < qty then return end
  if st.quantity == qty then MySQL.update.await("DELETE FROM stacks WHERE stack_id=?", { st.stack_id })
  else MySQL.update.await("UPDATE stacks SET quantity=quantity-? WHERE stack_id=?", { qty, st.stack_id }) end
end)
FW = FW or {}
local function cfg() local r=MySQL.single.await("SELECT ema_alpha,weekly_decay FROM market_config WHERE id=1"); return {alpha=(r and tonumber(r.ema_alpha)) or 0.25, decay=(r and tonumber(r.weekly_decay)) or 1} end
local function ema(prev, price, a) return (prev==nil) and price or (a*price + (1-a)*prev) end
local function reprice(trader_id, item_key)
  local a=cfg().alpha
  local rows = MySQL.query.await("SELECT price FROM trader_price_history WHERE trader_id=? AND item_key=? ORDER BY ts DESC LIMIT 12", { trader_id, item_key }) or {}
  if #rows==0 then return end
  local e=nil; for i=#rows,1,-1 do e=ema(e, tonumber(rows[i].price), a) end
  if e then local buy=math.max(1, math.floor(e*1.05)); local sell=math.max(1, math.floor(e*0.80)); exports.oxmysql:update("UPDATE trader_prices SET price_buy=?, price_sell=? WHERE trader_id=? AND item_key=?", { buy, sell, trader_id, item_key }) end
end
AddEventHandler('fw:trader:buy', function(trader_id, item_key, qty) reprice(trader_id, item_key) end)
AddEventHandler('fw:trader:sell', function(trader_id, item_key, qty) reprice(trader_id, item_key) end)
FW = FW or {}

exports('SFW_CraftPayload', function(bench_tier, ident)
  local recs = MySQL.query.await([[
    SELECT r.recipe_key, r.label, r.bench_tier, r.output_item, r.output_qty, r.time_ms
    FROM recipes r WHERE r.bench_tier <= ? ORDER BY r.bench_tier, r.label
  ]], { bench_tier or 0 }) or {}
  for _, r in ipairs(recs) do
    local ing = MySQL.query.await("SELECT item_key, qty FROM recipe_ingredients WHERE recipe_key=?", { r.recipe_key }) or {}
    r.ingredients = ing
  end
  return { recipes = recs }
end)

RegisterNetEvent('fw:craft:queue', function(data)
  local src = source; local ident = FW.GetIdentifier and FW.GetIdentifier(src); if not ident then return end
  local key = data and data.recipe_key; if not key then return end
  local r = MySQL.single.await("SELECT * FROM recipes WHERE recipe_key=?", { key }); if not r then return end
  local ings = MySQL.query.await("SELECT item_key, qty FROM recipe_ingredients WHERE recipe_key=?", { key }) or {}
  local c = exports['survivalfw']:SFW_PlayerContainerId(ident)

  -- Check ingredients
  for _, i in ipairs(ings) do
    local row = MySQL.single.await("SELECT COALESCE(SUM(quantity),0) as q FROM stacks WHERE container_id=? AND item_key=?", { c, i.item_key })
    if (tonumber(row and row.q) or 0) < (tonumber(i.qty) or 0) then return end
  end

  -- Consume
  for _, i in ipairs(ings) do
    local remain = i.qty
    local rows = MySQL.query.await("SELECT * FROM stacks WHERE container_id=? AND item_key=? ORDER BY quantity DESC", { c, i.item_key }) or {}
    for _, s in ipairs(rows) do
      if remain <= 0 then break end
      local take = math.min(remain, s.quantity)
      if take == s.quantity then MySQL.update.await("DELETE FROM stacks WHERE stack_id=?", { s.stack_id })
      else MySQL.update.await("UPDATE stacks SET quantity=quantity-? WHERE stack_id=?", { take, s.stack_id }) end
      remain = remain - take
    end
  end

  -- Output
  local slot = MySQL.single.await("SELECT slot_index FROM container_slots WHERE container_id=? AND slot_index NOT IN (SELECT slot_index FROM stacks WHERE container_id=?) ORDER BY slot_index LIMIT 1", { c, c })
  if slot then
    MySQL.insert.await("INSERT INTO stacks(container_id,slot_index,item_key,quantity,durability,metadata,state_hash,weight_cached) VALUES (?,?,?,?,100,'{}','',0)", { c, slot.slot_index, r.output_item, r.output_qty })
  end
end)
FW = FW or {}; FW.DB = FW.DB or {}

local function getIdentifier(src)
  if FW.GetIdentifier then return FW.GetIdentifier(src) end
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:sub(1,8) == "license:" then return id end
  end
  return nil
end

local DEFAULT_MODEL = 'mp_m_freemode_01'

local function getAppearance(ident)
  return MySQL.single.await("SELECT model, components, props, outfit_tag FROM player_appearance WHERE identifier=?", { ident })
end

local function setAppearance(ident, model, comps, props, tag)
  local row = getAppearance(ident)
  if row then
    MySQL.update.await("UPDATE player_appearance SET model=?, components=?, props=?, outfit_tag=? WHERE identifier=?",
      { model, comps, props, tag, ident })
  else
    MySQL.insert.await("INSERT INTO player_appearance(identifier,model,components,props,outfit_tag) VALUES (?,?,?,?,?)",
      { ident, model, comps, props, tag })
  end
end

RegisterNetEvent('fw:wardrobe:save', function(payload)
  local src = source
  local ident = getIdentifier(src); if not ident then return end
  if type(payload) ~= 'table' then return end
  local model = payload.model or DEFAULT_MODEL
  local comps = payload.components or {}
  local props = payload.props or {}
  local tag   = payload.outfit_tag or nil
  setAppearance(ident, model, json.encode(comps), (next(props) and json.encode(props) or nil), tag)
  TriggerClientEvent('fw:wardrobe:saved', src, true)
end)

RegisterNetEvent('fw:wardrobe:pull', function()
  local src = source
  local ident = getIdentifier(src); if not ident then return end
  local ap = getAppearance(ident)
  if ap then
    TriggerClientEvent('fw:wardrobe:applySaved', src, ap)
  end
end)
FW = FW or {}
FW.Econ = { mult = 1.0, scarcity = {} }

local function weeklySeed()
  local year, week = tonumber(os.date("!%Y")), tonumber(os.date("!%W"))
  return (year*100 + week)
end

local function rollScarcity()
  math.randomseed(weeklySeed())
  local scarce = {}
  local pool = {'ammo_556','ammo_762','ammo_9','ammo_45','med_bandage','med_charcoal','fuel_can','car_battery'}
  for i=1,3 do
    local idx = math.random(1, #pool)
    scarce[pool[idx]] = (math.random() < 0.5) and 1.25 or 0.75
    table.remove(pool, idx)
  end
  return scarce
end

CreateThread(function()
  while true do
    Wait(30000)
    FW.Econ.scarcity = rollScarcity()
  end
end)

function FW.Econ.PriceMult(item) return FW.Econ.scarcity[item] or 1.0 end


function FW.Econ.PreviewWeek(basePrices, stock)
  local out = {}
  local seedBase = (tonumber(os.date("!%Y")) or 2025) * 100 + (tonumber(os.date("!%W")) or 1)
  for item, basePrice in pairs(basePrices or {}) do
    local arr = {}
    local p = (stock[item] and stock[item].price) or basePrice
    local scarceMul = FW.Econ.PriceMult(item) or 1.0
    for d=1,7 do
      local seed = seedBase*1000 + d*37 + string.byte(item, 1) -- deterministic-ish
      math.randomseed(seed)
      local vol = (FW.Trader and FW.Trader.priceVolatility) or 0.25
      local jitter = 1.0 + (math.random()*2*vol - vol)
      p = math.max(1, math.floor(p * jitter))
      table.insert(arr, { day=d, price=math.floor(p * scarceMul) })
    end
    out[item] = arr
  end
  return out
end
FW = FW or {}; FW.DB = FW.DB or {}
FW.DB.Contract = {
  players = { table="players", cols={"identifier","display_name","role","health","stamina","hunger","thirst","temperature_c","created_at","updated_at"}, pk="identifier" },
  items = { table="items", cols={"item_key","label","stackable","max_stack","base_weight","base_dura","rarity","icon","tags","desc_long"}, pk="item_key" },
  containers = { table="containers", cols={"container_id","type","owner_ident","ref","slots","weight_limit","created_at"}, pk="container_id" },
  container_slots = { table="container_slots", cols={"container_id","slot_index","locked","tag"}, pk={"container_id","slot_index"} },
  stacks = { table="stacks", cols={"stack_id","container_id","slot_index","item_key","quantity","durability","metadata","state_hash","weight_cached","created_at","updated_at"}, pk="stack_id" },
  inv_tx = { table="inv_tx", cols={"tx_id","identifier","action","item_key","qty","from_cont","from_slot","to_cont","to_slot","stack_id","context","created_at"}, pk="tx_id" },
  recipes = { table="recipes", cols={"recipe_key","label","bench_tier","output_item","output_qty","time_ms","meta"}, pk="recipe_key" },
  recipe_ingredients = { table="recipe_ingredients", cols={"id","recipe_key","item_key","qty","meta"}, pk="id" },
  traders = { table="traders", cols={"trader_id","name","pos","meta"}, pk="trader_id" },
  trader_prices = { table="trader_prices", cols={"id","trader_id","item_key","price_buy","price_sell","scarcity","updated_at"}, pk="id" },
  trader_price_history = { table="trader_price_history", cols={"id","trader_id","item_key","price","scarcity","ts"}, pk="id" },
  effects_active = { table="effects_active", cols={"id","identifier","effect_type","severity","body_part","meta","started_at","expires_at"}, pk="id" },
  med_injuries = { table="med_injuries", cols={"id","identifier","injury_type","body_part","severity","treated","meta","created_at","resolved_at"}, pk="id" },
  med_snapshots = { table="med_snapshots", cols={"id","identifier","snapshot","created_at"}, pk="id" },
  player_skills = { table="player_skills", cols={"identifier","skill_key","level","xp"}, pk={"identifier","skill_key"} },
  skill_events = { table="skill_events", cols={"id","identifier","skill_key","delta","reason","context","created_at"}, pk="id" },
  biomes = { table="biomes", cols={"biome_id","name","priority","weight","height_min","height_max","weather","meta"}, pk="biome_id" },
  biome_polygons = { table="biome_polygons", cols={"id","biome_id","polygon","blacklist"}, pk="id" },
  wildlife_rules = { table="wildlife_rules", cols={"rule_id","biome_id","species","density","night_mult","rain_mult","group_min","group_max","no_spawn_radius","meta"}, pk="rule_id" },
}

-- Hardening: guard every DB call and avoid iterating nil
local function q(sql, params)
  local ok, res = pcall(function() return MySQL.query.await(sql, params or {}) end)
  if not ok or type(res) ~= 'table' then return {} end
  return res
end

local function single(sql, params)
  local ok, res = pcall(function() return MySQL.single.await(sql, params or {}) end)
  if not ok then return nil end
  return res
end

CreateThread(function()
  Wait(800)
  -- Example checks (adjust/extend as needed to your schema)
  local need = { 'players','containers','container_slots','stacks','items','recipes','recipe_ingredients','traders','trader_prices','biomes','biome_polygons','wildlife_rules' }
  for _, t in ipairs(need) do
    local rows = q("SHOW TABLES LIKE ?", { t })
    if #rows == 0 then
      print(("^1[SFW:DB] Missing table: %s^7"):format(t))
    end
  end

  -- Collation check for players.display_name (warn only)
  local info = q([[
    SELECT TABLE_NAME, COLUMN_NAME, COLLATION_NAME
    FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME='players' AND COLUMN_NAME='display_name'
  ]])
  local col = info[1]
  if col and col.COLLATION_NAME and not col.COLLATION_NAME:match('utf8mb4_unicode_ci') then
    print(("^3[SFW:DB] Warning: players.display_name collation is %s (recommended utf8mb4_unicode_ci)^7"):format(col.COLLATION_NAME))
  end
end)
FW = FW or {}; FW.ACL = FW.ACL or {}; FW.DB = FW.DB or {}

local function identOf(src)
  return (FW.GetIdentifier and FW.GetIdentifier(src)) or tostring(src)
end

function FW.DB.GetRole(ident)
  local row = MySQL.single.await("SELECT role FROM players WHERE identifier = ?", { ident })
  return (row and row.role) or 'user'
end

function FW.ACL.RoleOf(src)
  return FW.DB.GetRole(identOf(src))
end

local function stashOwner(stashId)
  local row = MySQL.single.await("SELECT owner_ident, container_id FROM containers WHERE type='STASH' AND ref = ? LIMIT 1", { stashId })
  return row and row.owner_ident, row and row.container_id
end

-- Basic policy: owner has RW; admin has RW; mod has R; others none (until you add a stash_acl table)
function FW.ACL.StashCanRead(stashId, src)
  local pid = identOf(src)
  local owner = select(1, stashOwner(stashId))
  if owner and owner == pid then return true end
  local role = FW.DB.GetRole(pid)
  return (role == 'admin' or role == 'mod')
end

function FW.ACL.StashCanWrite(stashId, src)
  local pid = identOf(src)
  local owner = select(1, stashOwner(stashId))
  if owner and owner == pid then return true end
  local role = FW.DB.GetRole(pid)
  return (role == 'admin')
end

return FW.DB.Contract
