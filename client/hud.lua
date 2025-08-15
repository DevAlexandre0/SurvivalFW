local show = true
RegisterCommand('hud', function() show = not show; SendNUIMessage({ type='vis', show=show }) end, false)
CreateThread(function() SetNuiFocus(false,false); SendNUIMessage({ type='vis', show=show }); while true do Wait(750) TriggerServerEvent('fw:hud:pull') end end)
RegisterNetEvent('fw:hud:snapshot', function(data) data.type='update'; SendNUIMessage(data) end)
