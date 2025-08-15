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

