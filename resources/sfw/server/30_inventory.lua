FW = FW or {}
FW.DB = FW.DB or {}
local C = FW.DB.Contract
local function tx(ident, action, item_key, qty, fromc, froms, toc, tos, stack_id, ctx)
  local q = "INSERT INTO %s(identifier,action,item_key,qty,from_cont,from_slot,to_cont,to_slot," .. "stack_id,context) VALUES (?,?,?,?,?,?,?,?,?,?)"
	return MySQL.insert.await(q:format(C.inv_tx.table), {ident, action, item_key, qty, fromc, froms, toc, tos, stack_id, ctx and json.encode(ctx) or nil, })
end
RegisterNetEvent("fw:inv:moveStrict", function(payload)
	local src = source
	if not (FW.RL and FW.RL.Check(src, "inv_move", 500)) then
		return
	end
	if type(payload) ~= "table" then
		return
	end
	local ident = FW.GetIdentifier and FW.GetIdentifier(src)
	if not ident then
		return
	end
	local fromc, froms = tonumber(payload.from_container), tonumber(payload.from_slot)
	local toc, tos = tonumber(payload.to_container), tonumber(payload.to_slot)
	local amount = tonumber(payload.amount or 0)
	if not fromc or not froms or not toc or not tos then
		return
	end
	local from = MySQL.single.await(
		("SELECT * FROM %s WHERE container_id=? AND slot_index=?"):format(C.stacks.table),
		{ fromc, froms }
	)
	if not from then
		TriggerClientEvent("fw:inv:error", src, "no_source_stack")
		return
	end
	local to = MySQL.single.await(
		("SELECT * FROM %s WHERE container_id=? AND slot_index=?"):format(C.stacks.table),
		{ toc, tos }
	)
	local toTag = MySQL.single.await(
		("SELECT tag FROM %s WHERE container_id=? AND slot_index=?"):format(C.container_slots.table),
		{ toc, tos }
	)
	if toTag and toTag.tag then
		local ok = true
		local t = json.decode(toTag.tag)
		if t and t.only then
			ok = false
			local tagsRow =
				MySQL.single.await(("SELECT tags FROM %s WHERE item_key=?"):format(C.items.table), { from.item_key })
			local ittags = (tagsRow and tagsRow.tags) and json.decode(tagsRow.tags) or {}
			for _, g in ipairs(ittags) do
				for _, need in ipairs(t.only) do
					if g == need then
						ok = true
					end
				end
			end
		end
		if not ok then
			TriggerClientEvent("fw:inv:error", src, "slot_forbidden")
			return
		end
	end
	if to and to.item_key == from.item_key then
		local newQty = (tonumber(to.quantity) or 0) + (amount > 0 and amount or from.quantity)
		MySQL.update.await(
			("UPDATE %s SET quantity=? WHERE stack_id=?"):format(C.stacks.table),
			{ newQty, to.stack_id }
		)
		if amount > 0 and amount < from.quantity then
			MySQL.update.await(
				("UPDATE %s SET quantity=quantity-? WHERE stack_id=?"):format(C.stacks.table),
				{ amount, from.stack_id }
			)
		else
			MySQL.query.await(("DELETE FROM %s WHERE stack_id=?"):format(C.stacks.table), { from.stack_id })
		end
		tx(
			ident,
			"MERGE",
			from.item_key,
			amount > 0 and amount or from.quantity,
			fromc,
			froms,
			toc,
			tos,
			to.stack_id,
			{}
		)
	else
		MySQL.update.await(
			("UPDATE %s SET container_id=?, slot_index=? WHERE stack_id=?"):format(C.stacks.table),
			{ toc, tos, from.stack_id }
		)
		tx(
			ident,
			"MOVE",
			from.item_key,
			amount > 0 and amount or from.quantity,
			fromc,
			froms,
			toc,
			tos,
			from.stack_id,
			{}
		)
	end
	TriggerClientEvent("fw:inv:refresh", src)
end)
FW = FW or {}; FW.Surv = FW.Surv or {}
local function clamp(v,a,b) if v<a then return a elseif v>b then return b else return v end end
FW.Surv.Inventory = FW.Surv.Inventory or {}

function FW.Surv.Inventory.WeightOf(ident)
  if not ident then return 0.0 end
  local row = MySQL.single.await([[
    SELECT COALESCE(SUM(CASE WHEN s.weight_cached>0 THEN s.weight_cached ELSE s.quantity*COALESCE(i.base_weight,0) END),0) AS w
    FROM stacks s JOIN containers c ON c.container_id=s.container_id
    LEFT JOIN items i ON i.item_key=s.item_key
    WHERE c.owner_ident = ? AND c.type='PLAYER'
  ]], { ident })
  return (row and tonumber(row.w)) or 0.0
end

function FW.Surv.Inventory.InsulationOf(ident)
  if not ident then return 0.10 end
  local ap = MySQL.single.await("SELECT components FROM player_appearance WHERE BINARY identifier=BINARY ?", { ident })
  local score = 0.10
  if ap and ap.components then
    local ok, comps = pcall(json.decode, ap.components)
    if ok and type(comps)=='table' then
      local map = { [3]=0.20,[4]=0.15,[11]=0.20,[6]=0.05,[9]=0.10 }
      for k,add in pairs(map) do
        local c = comps[k]
        if c and type(c)=='table' and (c.drawable or 0) > 0 then score = score + add end
      end
    end
  end
  return clamp(score, 0.0, 1.0)
end
FW = FW or {}; local json=json

-- Helpers
local function getItemTags(item_key)
  local row = MySQL.single.await("SELECT tags FROM items WHERE item_key=?", { item_key })
  if row and row.tags then
    local ok, t = pcall(json.decode, row.tags); if ok and t then return t end
  end
  return {}
end

local function slotAllows(container_id, slot_index, item_key)
  local row = MySQL.single.await("SELECT tag FROM container_slots WHERE container_id=? AND slot_index=?", { container_id, slot_index })
  if not row or not row.tag then return true end
  local ok, tag = pcall(json.decode, row.tag); if not ok or not tag then return true end
  local tags = getItemTags(item_key)
  local set = {}; for _,x in ipairs(tags) do set[x]=true end

  if tag.only and #tag.only>0 then
    for _,x in ipairs(tag.only) do if set[x] then return true end end
    return false
  end
  if tag.forbid and #tag.forbid>0 then
    for _,x in ipairs(tag.forbid) do if set[x] then return false end end
  end
  return true
end

-- Strict move that validates constraints, then performs transactional move (merge/split/swap)
RegisterNetEvent('fw:inv:moveStrict', function(p)
  local src=source
  p = type(p)=='table' and p or {}
  local fromC,fromS,toC,toS = tonumber(p.from_container),tonumber(p.from_slot),tonumber(p.to_container),tonumber(p.to_slot)
  local amount = tonumber(p.amount or 0)
  local expectUpdated = p.updated_at

  if not (fromC and fromS and toC and toS) then return end

  local st = MySQL.single.await("SELECT * FROM stacks WHERE container_id=? AND slot_index=?", { fromC, fromS }); if not st then return end
  if amount<=0 or amount>tonumber(st.quantity) then amount = tonumber(st.quantity) end

  -- Constraint check on destination slot
  if not slotAllows(toC, toS, st.item_key) then
    TriggerClientEvent('fw:inv:error', src, 'slot_forbidden')
    if FW.Metrics then FW.Metrics.IncL('sfw_inv_error_total', {code='slot_forbidden'}) end
    return
  end

  -- Do a simple transactional move (reuse db ops pattern)
  local target = MySQL.single.await("SELECT * FROM stacks WHERE container_id=? AND slot_index=?", { toC, toS })
  local ops = {}

  if target and target.state_hash == st.state_hash then
    local def = MySQL.single.await("SELECT max_stack,base_weight FROM items WHERE item_key=?", { st.item_key })
    local maxs = (def and tonumber(def.max_stack)) or 20
    local can = math.max(0, maxs - tonumber(target.quantity))
    local add = math.min(can, amount)
    if add<=0 then return end
    local newT = tonumber(target.quantity)+add
    ops[#ops+1] = { query="UPDATE stacks SET quantity=?, weight_cached=?, updated_at=NOW() WHERE stack_id=?", values={ newT, newT*(tonumber(def and def.base_weight or 0.1)), target.stack_id } }
    local left = tonumber(st.quantity)-add
    if left<=0 then ops[#ops+1] = { query="DELETE FROM stacks WHERE stack_id=?", values={ st.stack_id } }
    else ops[#ops+1] = { query="UPDATE stacks SET quantity=?, weight_cached=?, updated_at=NOW() WHERE stack_id=?", values={ left, left*(tonumber(def and def.base_weight or 0.1)), st.stack_id } } end
  elseif target then
    ops[#ops+1] = { query="UPDATE stacks SET container_id=?, slot_index=? WHERE stack_id=?", values={ fromC, fromS, target.stack_id } }
    ops[#ops+1] = { query="UPDATE stacks SET container_id=?, slot_index=? WHERE stack_id=?", values={ toC, toS, st.stack_id } }
  else
    local def = MySQL.single.await("SELECT base_weight FROM items WHERE item_key=?", { st.item_key })
    if amount < tonumber(st.quantity) then
      local left = tonumber(st.quantity)-amount
      ops[#ops+1] = { query="UPDATE stacks SET quantity=?, weight_cached=?, updated_at=NOW() WHERE stack_id=?", values={ left, left*(tonumber(def and def.base_weight or 0.1)), st.stack_id } }
      ops[#ops+1] = { query="INSERT INTO stacks(container_id,slot_index,item_key,quantity,durability,metadata,state_hash,weight_cached) VALUES(?,?,?,?,?,?,?,?)",
                      values={ toC, toS, st.item_key, amount, st.durability, st.metadata, st.state_hash, amount*(tonumber(def and def.base_weight or 0.1)) } }
    else
      ops[#ops+1] = { query="UPDATE stacks SET container_id=?, slot_index=? WHERE stack_id=?", values={ toC, toS, st.stack_id } }
    end
  end

  local ok = exports.oxmysql:transaction(ops)
  if not ok then
    TriggerClientEvent('fw:inv:error', src, 'txn_failed')
    if FW.Metrics then FW.Metrics.IncL('sfw_inv_error_total', {code='txn_failed'}) end
    return
  end
  if FW.Metrics then FW.Metrics.Inc('sfw_inv_move_total') end
  TriggerClientEvent('fw:inv:update', src, { from={container=fromC}, to={container=toC} })
end)

-- Item-use router
FW.Inv = FW.Inv or {}
FW.Inv.Use = function(ident, item_key, qty, meta)
  qty = math.max(1, tonumber(qty or 1))
  -- consume stack(s)
  local ok = exports.oxmysql:update("UPDATE stacks SET quantity=quantity-? WHERE stack_id IN (SELECT stack_id FROM stacks WHERE item_key=? AND container_id IN (SELECT container_id FROM containers WHERE owner_ident=? AND type='PLAYER') ORDER BY quantity DESC LIMIT 1)", { qty, item_key, ident })
  if not ok then return false end
  TriggerEvent(('fw:item:use:%s'):format(item_key), ident, qty, meta or {})
  return true
end
FW = FW or {}
FW.Inv = FW.Inv or {}

local function decode(jsonStr)
  local ok, res = pcall(json.decode, jsonStr or '{}')
  if ok and type(res) == 'table' then return res else return {} end
end

local function hasTag(tags, tag)
  for _, t in ipairs(tags or {}) do if t == tag then return true end end
  return false

end

local function slotAllowed(slotId, item)
  local row = MySQL.single.await('SELECT tag FROM container_slots WHERE id=?', {slotId})
  if not row then return true end
  local cfg = decode(row.tag)
  if not next(cfg) then return true end
  local itemDef = FW.Items and FW.Items[item] or {}
  local itTags = itemDef.tags or {}
  for _, f in ipairs(cfg.forbid or {}) do
    if hasTag(itTags, f) then return false end
  end
  if cfg.only and #cfg.only > 0 then
    for _, o in ipairs(cfg.only) do
      if hasTag(itTags, o) then return true end
    end
    return false
  end
  return true
end

function FW.Inv.CheckSlot(slotId, item)
  local ok = slotAllowed(slotId, item)
  if not ok and FW.Metrics then
    FW.Metrics.Inc('sfw_inv_error_total', {code = 'slot_constraint'})
  end
  return ok
end

function FW.Inv.Use(ident, item_key, qty, meta)
  qty = qty or 1
  meta = meta or {}
  TriggerEvent('fw:item:use:' .. item_key, ident, qty, meta)
  local item = FW.Items and FW.Items[item_key]
  if item and item.tags then
    for _, tag in ipairs(item.tags) do
      TriggerEvent('fw:item:use:' .. tag .. '/*', ident, item_key, qty, meta)
    end
  end
  if meta.stack_id then
    local row = MySQL.single.await('SELECT durability FROM stacks WHERE id=?', {meta.stack_id}) or {}
    local cur = tonumber(row.durability or 100) - qty
    MySQL.update.await('UPDATE stacks SET durability=? WHERE id=?', {cur, meta.stack_id})
    if cur <= 0 then
      MySQL.update.await('DELETE FROM stacks WHERE id=?', {meta.stack_id})
      TriggerClientEvent('fw:item:broken', ident, item_key)
    end
  end
  if FW.Metrics then FW.Metrics.Inc('sfw_inv_move_total', {action='use'}) end
end

exports('Use', function(...) FW.Inv.Use(...) end)

FW = FW or {}; FW.Surv = FW.Surv or {}; FW.Surv.Inventory = FW.Surv.Inventory or {}

local function contForPlayer(ident)
  local row = MySQL.single.await("SELECT container_id, slots FROM containers WHERE owner_ident=? AND type='PLAYER' LIMIT 1", { ident })
  if not row then
    MySQL.query.await("CALL sp_ensure_player_container(?)", { ident })
    row = MySQL.single.await("SELECT container_id, slots FROM containers WHERE owner_ident=? AND type='PLAYER' LIMIT 1", { ident })
  end
  return row and row.container_id or nil
end

exports('SFW_PlayerContainerId', contForPlayer)

local function fetchStacks(container_id)
  local rows = MySQL.query.await([[
    SELECT s.stack_id, s.container_id, s.slot_index, s.item_key, s.quantity, s.durability, s.metadata, s.weight_cached,
           i.label, cs.locked
    FROM container_slots cs
    LEFT JOIN stacks s ON s.container_id=cs.container_id AND s.slot_index=cs.slot_index
    LEFT JOIN items i ON i.item_key=s.item_key
    WHERE cs.container_id=?
    ORDER BY cs.slot_index ASC
  ]], { container_id })
  return rows or {}
end

exports('SFW_FetchStacks', fetchStacks)

local function moveStack(from_c, from_s, to_c, to_s, qty)
  qty = tonumber(qty) or 0
  if qty <= 0 then return false, "BAD_QTY" end
  local from = MySQL.single.await("SELECT * FROM stacks WHERE container_id=? AND slot_index=?", { from_c, from_s })
  if not from or from.quantity < qty then return false, "NO_STOCK" end
  local to = MySQL.single.await("SELECT * FROM stacks WHERE container_id=? AND slot_index=?", { to_c, to_s })
  if to then
    if to.item_key ~= from.item_key then return false, "DIFF_ITEM" end
    MySQL.update.await("UPDATE stacks SET quantity=quantity+? , updated_at=NOW() WHERE stack_id=?", { qty, to.stack_id })
    if qty == from.quantity then
      MySQL.update.await("DELETE FROM stacks WHERE stack_id=?", { from.stack_id })
    else
      MySQL.update.await("UPDATE stacks SET quantity=quantity-? , updated_at=NOW() WHERE stack_id=?", { qty, from.stack_id })
    end
  else
    if qty == from.quantity then
      MySQL.update.await("UPDATE stacks SET container_id=?, slot_index=?, updated_at=NOW() WHERE stack_id=?", { to_c, to_s, from.stack_id })
    else
      MySQL.insert.await([[
        INSERT INTO stacks(container_id, slot_index, item_key, quantity, durability, metadata, state_hash, weight_cached)
        VALUES (?,?,?,?,100,'{}','',0)
      ]], { to_c, to_s, from.item_key, qty })
      MySQL.update.await("UPDATE stacks SET quantity=quantity-? , updated_at=NOW() WHERE stack_id=?", { qty, from.stack_id })
    end
  end
  return true
end

RegisterNetEvent('fw:inv:move', function(data)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  if not ident then return end
  if type(data) ~= 'table' then return end
  moveStack(data.from_container, data.from_slot, data.to_container, data.to_slot, data.qty)
end)

exports('SFW_InvPayloadFor', function(ident)
  local c = contForPlayer(ident)
  if not c then return { inv = {} } end
  return { inv = fetchStacks(c) }
end)
FW = FW or {}
local D = FW.Durability
AddEventHandler('fw:weap:shot', function(payload)
  local src = source
  local pid = (FW.DB.ResolveId and FW.DB.ResolveId(src)) or tostring(src)
  local st = FW.DB.GetWeapState(pid) or {}; st.current = st.current or {}
  local cond = tonumber(st.current.cond or 100)
  local loss = (D.weaponPerShot or 0.15) + ((st.current.heat or 0)/10.0) * (D.weaponHeatFactor or 0.005)
  st.current.cond = math.max(0, cond - loss)
  FW.DB.SaveWeapState(pid, st)
end)
-- clothing wet wear tick
CreateThread(function()
  while true do
    Wait(60000)
    for _, sid in ipairs(GetPlayers()) do
      local src = tonumber(sid)
      local s = FW.Surv.GetStatus(src)
      local wet = (s.wet or 0) / 100.0
      if wet > 0.2 then
        local pid = (FW.DB.ResolveId and FW.DB.ResolveId(src)) or tostring(src)
        local wear = wet * (D.clothingWetWear or 0.02)
        local item = 'jacket_warm'
        local cur = 100.0
        FW.DB.AddItem(pid, "__dura_"..item, -wear) -- simplified marker; swap to dedicated table if needed
      end
    end
  end
end)
FW = FW or {}

-- Example: publish weapon state to HUD
RegisterNetEvent('fw:weap:update', function(state)
  local src = source
  if type(state) ~= 'table' then return end
  local weapon  = state.weapon or '—'
  local mag     = tonumber(state.mag) or 0
  local chamber = tonumber(state.chamber) or 0
  local jam     = state.jam and true or false
  TriggerClientEvent('fw:ui:ammo', src, weapon, mag, chamber, jam)
end)
