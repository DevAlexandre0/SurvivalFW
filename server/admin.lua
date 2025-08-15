FW = FW or {}; FW.DB = FW.DB or {}; FW.ACL = FW.ACL or {}

local function isAdmin(src)
  return (FW.ACL and FW.ACL.RoleOf and (FW.ACL.RoleOf(src) == 'admin'))
end

-- Minimal admin endpoints
RegisterNetEvent('fw:admin:setRole', function(targetIdent, newRole)
  local src = source
  if not isAdmin(src) then return end
  if not targetIdent or not newRole then return end
  MySQL.update.await("UPDATE players SET role=? WHERE identifier=?", { tostring(newRole), tostring(targetIdent) })
end)

RegisterNetEvent('fw:admin:swapStacks', function(c1,s1,c2,s2)
  local src = source
  if not isAdmin(src) then return end
  MySQL.transaction.await({
    { query = "UPDATE stacks SET container_id=?, slot_index=? WHERE container_id=? AND slot_index=?", values = { c2, s2, c1, s1 } },
    { query = "UPDATE stacks SET container_id=?, slot_index=? WHERE container_id=? AND slot_index=?", values = { c1, s1, c2, s2 } },
  })
end)

RegisterNetEvent('fw:admin:trader:setPriceBatch', function(trader_id, rows)
  local src = source
  if not isAdmin(src) then return end
  trader_id = tonumber(trader_id); if not trader_id then return end
  for _, r in ipairs(rows or {}) do
    local buy  = tonumber(r.buy or r.price_buy)
    local sell = tonumber(r.sell or r.price_sell)
    local sc   = tonumber(r.scarcity or 1)
    local item = r.item_key
    if buy and sell and item then
      MySQL.update.await("UPDATE trader_prices SET price_buy=?, price_sell=?, scarcity=? WHERE trader_id=? AND item_key=?", { buy, sell, sc, trader_id, item })
      MySQL.insert.await("INSERT INTO trader_price_history(trader_id,item_key,price,scarcity) VALUES (?,?,?,?)", { trader_id, item, math.floor((buy+sell)/2), sc })
    end
  end
end)
