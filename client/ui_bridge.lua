-- Simple NUI bridge for SFW
RegisterNUICallback('inv:moveStrict', function(data, cb)
  TriggerServerEvent('fw:inv:moveStrict', data)
  cb({ ok = true })
end)

RegisterNUICallback('admin:trader:setPriceBatch', function(data, cb)
  TriggerServerEvent('fw:admin:trader:setPriceBatch', data.trader_id, data.rows or {})
  cb({ ok = true })
end)

RegisterNUICallback('admin:setRole', function(data, cb)
  TriggerServerEvent('fw:admin:setRole', data.identifier, data.role)
  cb({ ok = true })
end)
