local spawned = {}
local function reqModel(name)
  local m = GetHashKey(name); RequestModel(m); local t=0
  while not HasModelLoaded(m) and t < 2000 do Wait(10); t=t+10 end
  return m
end
RegisterNetEvent('fw:wildlife:spawn', function(netId, model, x, y, z)
  local hash = reqModel(model); if not hash then return end
  local ped = CreatePed(28, hash, x, y, z, 0.0, true, true)
  SetEntityAsMissionEntity(ped, true, true)
  table.insert(spawned, ped)
end)
CreateThread(function()
  while true do
    Wait(15000)
    for i=#spawned,1,-1 do
      local a = spawned[i]
      if not DoesEntityExist(a) or IsEntityDead(a) then table.remove(spawned,i) end
    end
  end
end)
