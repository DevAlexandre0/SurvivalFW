RegisterNUICallback('inv:moveStrict', function(d, cb)
  TriggerServerEvent('fw:inv:moveStrict', d)
  cb({ ok = true })
end)
