FW = FW or {}; FW.DB = FW.DB or {}
local function getHour()
  if GlobalState and GlobalState.sfw_worldHour then return tonumber(GlobalState.sfw_worldHour) or 12 end
  return tonumber(os.date("!%H")) or 12
end
local function isNight() local h=getHour(); return (h>=20 or h<6) end

-- track DB queries to measure queries/min
local qcount = 0
local qstart = GetGameTimer()

local function fetch_rules()
  qcount = qcount + 1
  local q = [[
    SELECT r.rule_id, b.name biome, r.species, r.density, r.night_mult, r.rain_mult, r.group_min, r.group_max
    FROM wildlife_rules r JOIN biomes b ON b.biome_id=r.biome_id
  ]]
  return MySQL.query.await(q, {}) or {}
end

local rules_cache = {}
local rules_expire = 0
local function refresh_rules()
  rules_cache = fetch_rules()
  rules_expire = GetGameTimer() + math.random(300000, 600000) -- 5-10 min TTL
end

-- expose manual refresh for admins
RegisterCommand('wildrules', function(src)
  if src ~= 0 then
    local role = (FW.ACL and FW.ACL.RoleOf and FW.ACL.RoleOf(src)) or 'user'
    if role ~= 'admin' then return end
  end
  refresh_rules()
  if src ~= 0 then TriggerClientEvent('chat:addMessage', src, { args={'^2Wildlife','Rules refreshed'} }) end
end, false)

CreateThread(function()
  refresh_rules()
  while true do
    Wait(15000)
    if GetGameTimer() > rules_expire then refresh_rules() end
    local rs = rules_cache
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

-- update metrics once per minute
CreateThread(function()
  while true do
    Wait(60000)
    local mins = (GetGameTimer() - qstart) / 60000
    local qpm = qcount / (mins > 0 and mins or 1)
    if FW.Metrics and FW.Metrics.SetG then FW.Metrics.SetG('wildlife_rules_db_qpm', qpm) end
  end
end)
