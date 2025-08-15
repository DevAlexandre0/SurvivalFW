RegisterNetEvent('fw:player:register_mode', function(enabled)
  local ped = PlayerPedId()
  if enabled then
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
  else
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
  end
end)

RegisterCommand('fw_unhide', function()
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, false)
  SetEntityVisible(ped, true, false)
end, false)
