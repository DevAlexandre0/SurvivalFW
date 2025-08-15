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
