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
