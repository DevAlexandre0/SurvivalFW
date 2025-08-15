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
