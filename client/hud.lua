local show = true
RegisterCommand('hud', function()
  show = not show
  SendNUIMessage({ type='vis', show = show })
end, false)

CreateThread(function()
  SetNuiFocus(false, false)
  SendNUIMessage({ type = 'vis', show = show })
end)

RegisterNetEvent('fw:hud:push', function(data)
  data.type = 'update'
  SendNUIMessage(data)
end)
