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
