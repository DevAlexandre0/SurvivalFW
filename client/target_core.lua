-- Placeholder for hit test/raycast; can be replaced by advanced targeting
-- Expose an event to open radial with arbitrary context received from server
RegisterNetEvent('fw:target:open', function(ctx)
  TriggerServerEvent('fw:interact:build', ctx or {})
end)
