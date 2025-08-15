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
