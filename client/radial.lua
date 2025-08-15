RegisterNetEvent('fw:nui:open', function(packet)
  if not packet or not packet.type then return end
  SendNUIMessage({ type = packet.type, payload = packet.payload })
  if packet.type == 'radial:open' or packet.type == 'id:open' or packet.type == 'ward:open' or packet.type == 'trader:open' or packet.type == 'stash:open' or packet.type == 'craft:open' then
    SetNuiFocus(true, true)
  end
  if packet.type == 'radial:close' or packet.type == 'id:close' or packet.type == 'ward:close' or packet.type == 'trader:close' or packet.type == 'stash:close' or packet.type == 'craft:close' then
    SetNuiFocus(false, false)
  end
end)
