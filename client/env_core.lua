local cfg = FW and FW.Env or {}
local last = { wet=0.0, stamina=100.0 }
local function isSprinting(ped) return IsPedRunning(ped) or IsPedSprinting(ped) end
local function ambientTempAt(coords, indoor)
  local base = (cfg.baseTempC or 22.0)
  local h = GetClockHours()
  local dayAmp = (cfg.diurnal and cfg.diurnal.day) or 6.0
  local nightAmp = (cfg.diurnal and cfg.diurnal.night) or -4.0
  local tAmp = (h >= 7 and h <= 18) and dayAmp or nightAmp
  local rain = GetRainLevel()
  local wind = GetWindSpeed()
  local alt = coords.z or 0.0
  local lapse = (cfg.altitudeLapse or -0.0065) * alt
  local rainDrop = (cfg.rainTempDrop or -4.0) * math.min(1.0, rain or 0.0)
  local windChill = 0.0
  if (wind or 0) > (cfg.windChillAt or 6.0) then windChill = (cfg.windChillMul or -0.25) * ((wind or 0) - (cfg.windChillAt or 6.0)) end
  local shelter = indoor and (cfg.indoorBonus or 2.0) or 0.0
  return base + tAmp + lapse + rainDrop + windChill + shelter
end
CreateThread(function()
  while true do
    Wait(5000)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local indoor = (GetInteriorFromEntity(ped) ~= 0)
    local rain = GetRainLevel()
    local wind = GetWindSpeed()
    local inWater = IsEntityInWater(ped)
    local wet = last.wet or 0.0
    if inWater then wet = math.min(100.0, wet + (cfg.wetFromWater or 15.0))
    elseif (rain or 0) > 0.05 and not indoor then wet = math.min(100.0, wet + (cfg.rainWetRate or 6.0) * math.min(1.0, rain or 0.0))
    else wet = math.max(0.0, wet - ((cfg.dryRateIdle or 1.2) + ((cfg.dryRateWindMul or 0.4) * ((wind or 0)/5.0)))) end
    local st = last.stamina or 100.0
    if isSprinting(ped) then st = math.max(0.0, st - (cfg.staminaDrainSprint or 3.0)) else st = math.min(100.0, st + (cfg.staminaRegenIdle or 2.0)) end
    local amb = ambientTempAt(coords, indoor)
    local feels = amb + (wet/100.0)*-2.0
    last = { wet=wet, stamina=st }
    TriggerServerEvent('fw:env:tick', { x=coords.x, y=coords.y, z=coords.z, indoor=indoor, rain=rain, wind=wind, ambient=amb, feels=feels, wet=wet, stamina=st, sprint=isSprinting(ped) })
  end
end)
