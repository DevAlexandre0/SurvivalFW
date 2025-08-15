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
