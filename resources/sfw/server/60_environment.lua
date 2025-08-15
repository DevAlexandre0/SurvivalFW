FW = FW or {}; FW.Surv = FW.Surv or {}; FW.Surv.Inventory = FW.Surv.Inventory or {}
if not FW.Inventory then FW.Inventory = FW.Surv.Inventory end

local function insulationOf(ident)
  if FW.Surv and FW.Surv.Inventory and FW.Surv.Inventory.InsulationOf then
    return tonumber(FW.Surv.Inventory.InsulationOf(ident)) or 0.10
  end
  return 0.10
end

RegisterNetEvent('fw:env:tick', function()
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  if not ident then return end
  local ins = insulationOf(ident)
  -- Example env tick: you can expand with wetness/wind
  TriggerClientEvent('fw:hud:vitals', src, { insulation = ins })
end)
-- SFW — Wildlife polygons (OxMySQL await API)
FW = FW or {}; FW.DB = FW.DB or {}
local C = (FW and FW.DB and FW.DB.Contract) or { biome_polygons={table='biome_polygons'}, biomes={table='biomes'} }

local cache = {}

local function loadPolys()
  local sql = ([[
    SELECT p.id, p.biome_id, b.name AS biome, p.polygon, p.blacklist, b.priority, b.weight
    FROM %s p JOIN %s b ON b.biome_id=p.biome_id
  ]]):format(C.biome_polygons.table, C.biomes.table)
  local rows = MySQL.query.await(sql, {}) or {}
  cache = rows
  print(("[SFW] wildlife_polygons loaded %d polygons"):format(#rows))
end

exports('GetBiomePolygons', function() return cache end)

CreateThread(function()
  loadPolys()
  while true do
    Wait(300000) -- refresh every 5 min
    loadPolys()
  end
end)
-- SFW — Wildlife advanced (await API)
FW = FW or {}; FW.DB = FW.DB or {}
local C = (FW and FW.DB and FW.DB.Contract) or { wildlife_rules={table='wildlife_rules'}, biomes={table='biomes'} }

local function getRules()
  local sql = ([[
    SELECT r.rule_id, r.biome_id, b.name AS biome, r.species, r.density, r.night_mult, r.rain_mult, r.group_min, r.group_max, r.no_spawn_radius
    FROM %s r JOIN %s b ON b.biome_id=r.biome_id
  ]]):format(C.wildlife_rules.table, C.biomes.table)
  return MySQL.query.await(sql, {}) or {}
end

RegisterNetEvent('fw:wildlife:tick', function(world)
  -- world: { isNight, isRaining, playerCount, ... } (optional)
  local rules = getRules()
  for _, r in ipairs(rules) do
    local dens = tonumber(r.density) or 0.25
    local mult = 1.0
    if world and world.isNight then mult = mult * (tonumber(r.night_mult) or 1.0) end
    if world and world.isRaining then mult = mult * (tonumber(r.rain_mult) or 1.0) end
    local chance = dens * mult * 0.5
    if math.random() < chance then
      local group = math.random(tonumber(r.group_min) or 1, tonumber(r.group_max) or 2)
      TriggerEvent('fw:wildlife:spawn', { species=r.species, biome=r.biome, group=group, rule_id=r.rule_id })
    end
  end
end)
FW = FW or {}; FW.DB = FW.DB or {}
local function getHour()
  if GlobalState and GlobalState.sfw_worldHour then return tonumber(GlobalState.sfw_worldHour) or 12 end
  return tonumber(os.date("!%H")) or 12
end
local function isNight() local h=getHour(); return (h>=20 or h<6) end

-- track DB queries to measure queries/min
local qcount = 0
local qstart = GetGameTimer()

local function fetch_rules()
  qcount = qcount + 1
  local q = [[
    SELECT r.rule_id, b.name biome, r.species, r.density, r.night_mult, r.rain_mult, r.group_min, r.group_max
    FROM wildlife_rules r JOIN biomes b ON b.biome_id=r.biome_id
  ]]
  return MySQL.query.await(q, {}) or {}
end

local rules_cache = {}
local rules_expire = 0
local function refresh_rules()
  rules_cache = fetch_rules()
  rules_expire = GetGameTimer() + math.random(300000, 600000) -- 5-10 min TTL
end

-- expose manual refresh for admins
RegisterCommand('wildrules', function(src)
  if src ~= 0 then
    local role = (FW.ACL and FW.ACL.RoleOf and FW.ACL.RoleOf(src)) or 'user'
    if role ~= 'admin' then return end
  end
  refresh_rules()
  if src ~= 0 then TriggerClientEvent('chat:addMessage', src, { args={'^2Wildlife','Rules refreshed'} }) end
end, false)

CreateThread(function()
  refresh_rules()
  while true do
    Wait(15000)
    if GetGameTimer() > rules_expire then refresh_rules() end
    local rs = rules_cache
    local night = isNight()
    for _, r in ipairs(rs) do
      local dens = tonumber(r.density) or 0.2
      local mult = night and (tonumber(r.night_mult) or 1.0) or 1.0
      local chance = dens * mult * 0.5
      if math.random() < chance then
        local gmin = tonumber(r.group_min) or 1
        local gmax = tonumber(r.group_max) or 2
        local group = math.random(gmin, gmax)
        TriggerEvent('fw:wildlife:spawn', { species = r.species, group = group, biome = r.biome, isNight = night })
      end
    end
  end
end)

-- update metrics once per minute
CreateThread(function()
  while true do
    Wait(60000)
    local mins = (GetGameTimer() - qstart) / 60000
    local qpm = qcount / (mins > 0 and mins or 1)
    if FW.Metrics and FW.Metrics.SetG then FW.Metrics.SetG('wildlife_rules_db_qpm', qpm) end
  end
end)
FW = FW or {}; FW.ACL = FW.ACL or {}

RegisterNetEvent('fw:interact:build', function(ctx)
  local src = source; local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local actions = {}
  if ctx and ctx.type == 'vehicle' then
    actions[#actions+1] = { key='veh:trunk', label='Open Trunk' }
    actions[#actions+1] = { key='veh:hood', label='Open Hood' }
    actions[#actions+1] = { key='veh:repair', label='Repair', disabled = false }
    actions[#actions+1] = { key='veh:siphon', label='Siphon Fuel' }
  end
  if ctx and ctx.type == 'stash' then
    actions[#actions+1] = { key='stash:open', label='Open Stash', disabled = false }
  end
  TriggerClientEvent('fw:nui:open', src, { type='radial:open', payload={ actions=actions, ctx=ctx or {} } })
end)

RegisterNetEvent('fw:radial:select', function(data)
  local src = source; local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local key = data and data.key or ''
  if key == 'stash:open' then
    local ref = (data.ctx and data.ctx.ref) or 'world:stash:1'
    local payload = exports['survivalfw']:SFW_StashPayload(ref, ident)
    TriggerClientEvent('fw:nui:open', src, { type='stash:open', payload=payload })
  end
end)
