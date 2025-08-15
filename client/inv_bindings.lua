RegisterNUICallback('inv:move', function(data, cb) -- passthrough to server (already registered there)
  cb({ ok=true })
end)
