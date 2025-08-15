CreateThread(function()
  Wait(500)
  if exports and exports.spawnmanager and exports.spawnmanager.setAutoSpawn then
    exports.spawnmanager:setAutoSpawn(false)
  end
end)

AddEventHandler('playerSpawned', function()
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, false)
  SetEntityVisible(ped, true, false)
  TriggerServerEvent('fw:id:check')
  TriggerServerEvent('fw:spawn:request')
end)

RegisterNetEvent('fw:spawn:at', function(p)
  local ped = PlayerPedId()
  local x,y,z,h = p.x or 0.0, p.y or 0.0, p.z or 0.0, p.h or 0.0

  local model = (p.gender == 'F') and `mp_f_freemode_01` or `mp_m_freemode_01`
  if not IsPedModel(ped, model) then
    RequestModel(model); while not HasModelLoaded(model) do Wait(0) end
    SetPlayerModel(PlayerId(), model); SetModelAsNoLongerNeeded(model)
    ped = PlayerPedId()
  end

  SetEntityCoordsNoOffset(ped, x, y, z, false, false, false)
  SetEntityHeading(ped, h or 0.0)
  NetworkResurrectLocalPlayer(x, y, z, h or 0.0, true, true, false)
  ClearPedTasksImmediately(ped)
  RemoveAllPedWeapons(ped, true)

  -- Only open hair UI if identity already completed
  if p.hasIdentity and not p.hasAppearance then
    TriggerEvent('fw:outfit:prison:apply', p.gender=='F' and 'F' or 'M')
    TriggerEvent('fw:appearance:open')
  end
end)

-- periodic save last position
CreateThread(function()
  while true do
    local ped = PlayerPedId()
    local x,y,z = table.unpack(GetEntityCoords(ped))
    local h = GetEntityHeading(ped)
    TriggerServerEvent('fw:spawn:save', { x=x, y=y, z=z, h=h })
    Wait(30000)
  end
end)
