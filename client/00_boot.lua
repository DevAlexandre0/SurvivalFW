RegisterNetEvent('fw:player:register_mode', function(enabled)
  local ped = PlayerPedId()
  if enabled then SetEntityVisible(ped,false,false); FreezeEntityPosition(ped,true)
  else FreezeEntityPosition(ped,false); SetEntityVisible(ped,true,false) end
end)
RegisterNetEvent('fw:nui:open', function(packet)
  if not packet or not packet.type then return end
  SendNUIMessage(packet)
  if packet.type:find(':open',1,true) then SetNuiFocus(true,true) end
  if packet.type:find(':close',1,true) then SetNuiFocus(false,false) end
end)
