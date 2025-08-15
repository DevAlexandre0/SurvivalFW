RegisterNetEvent('fw:nui:open', function(packet)
  if not packet or not packet.type then return end
  SendNUIMessage({ type = packet.type, payload = packet.payload })
  if packet.type == 'id:open' or packet.type == 'ward:open' then
    SetNuiFocus(true, true)
  elseif packet.type == 'id:close' or packet.type == 'ward:close' then
    SetNuiFocus(false, false)
  end
end)

RegisterNUICallback('id:submit', function(data, cb)
  TriggerServerEvent('fw:id:submit', data or {})
  if cb then cb({ ok = true }) end
end)

RegisterNUICallback('ward:apply', function(data, cb)
  TriggerEvent('fw:wardrobe:applyLocal', data or {})
  if cb then cb({ ok = true }) end
end)

RegisterNUICallback('ward:done', function(data, cb)
  SetNuiFocus(false, false)
  SendNUIMessage({ type='ward:close' })
  if cb then cb({ ok = true }) end
end)

-- local wardrobe apply (simple presets)
AddEventHandler('fw:wardrobe:applyLocal', function(data)
  local gender = (data and data.gender) or 'M'
  local preset = (data and data.preset) or 1
  local ped = PlayerPedId()
  if gender == 'M' then
    SetPedComponentVariation(ped, 3, 0, 0, 0)
    SetPedComponentVariation(ped, 8, 15, 0, 0)
    SetPedComponentVariation(ped, 11, 0, 0, 0)
    SetPedComponentVariation(ped, 4, 0, 0, 0)
    SetPedComponentVariation(ped, 6, 1, 0, 0)
  else
    SetPedComponentVariation(ped, 3, 14, 0, 0)
    SetPedComponentVariation(ped, 8, 14, 0, 0)
    SetPedComponentVariation(ped, 11, 3, 0, 0)
    SetPedComponentVariation(ped, 4, 3, 0, 0)
    SetPedComponentVariation(ped, 6, 3, 0, 0)
  end
end)
