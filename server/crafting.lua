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
