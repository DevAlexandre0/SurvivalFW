FW = FW or {}; FW.DB = FW.DB or {}
local function getHour()
  if GlobalState and GlobalState.sfw_worldHour then return tonumber(GlobalState.sfw_worldHour) or 12 end
  return tonumber(os.date("!%H")) or 12
end
local function isNight() local h=getHour(); return (h>=20 or h<6) end

local function rules()
  local q = [[
    SELECT r.rule_id, b.name biome, r.species, r.density, r.night_mult, r.rain_mult, r.group_min, r.group_max
    FROM wildlife_rules r JOIN biomes b ON b.biome_id=r.biome_id
  ]]
  return MySQL.query.await(q, {}) or {}
end

CreateThread(function()
  while true do
    Wait(15000)
    local rs = rules()
    local night = isNight()
    for _, r in ipairs(rs) do
      local dens = tonumber(r.density) or 0.2
      local mult = night and (tonumber(r.night_mult) or 1.0) or 1.0
      local chance = dens * mult * 0.5
      if math.random() < chance then
        local gmin = tonumber(r.group_min) or 1
        local gmax = tonumber(r.group_max) or 2
        local group = math.random(gmin, gmax)
        TriggerEvent('fw:wildlife:spawn', { species = r.species, group = group, biome = r.biome, isNight = night })
      end
    end
  end
end)
