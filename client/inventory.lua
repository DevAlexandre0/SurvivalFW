RegisterNetEvent('fw:inv:toast', function(msg)
  SendNUIMessage({action='inv:toast', text=msg})
end)

