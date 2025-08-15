-- All NUI callbacks live on CLIENT. We forward to server via TriggerServerEvent.
local RES = GetCurrentResourceName()

local function cbOK(cb, ok, err) if cb then cb({ ok = ok ~= false, err = err }) end end

RegisterNUICallback('inv:move', function(data, cb)
  TriggerServerEvent('fw:inv:move', data)
  cbOK(cb, true)
end)

RegisterNUICallback('trader:buy', function(data, cb)
  TriggerServerEvent('fw:trader:buy', data)
  cbOK(cb, true)
end)

RegisterNUICallback('trader:sell', function(data, cb)
  TriggerServerEvent('fw:trader:sell', data)
  cbOK(cb, true)
end)

RegisterNUICallback('craft:queue', function(data, cb)
  TriggerServerEvent('fw:craft:queue', data)
  cbOK(cb, true)
end)

RegisterNUICallback('radial:select', function(data, cb)
  TriggerServerEvent('fw:radial:select', data)
  SetNuiFocus(false, false)
  cbOK(cb, true)
end)
