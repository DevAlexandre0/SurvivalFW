-- Simple keybinds to demo opening panels via server
RegisterCommand('fw_trader', function() TriggerServerEvent('fw:open:trader', 1) end)
RegisterCommand('fw_stash', function() TriggerServerEvent('fw:open:stash', 'world:stash:1') end)
RegisterCommand('fw_craft', function() TriggerServerEvent('fw:open:craft', 0) end)

-- Radial toggle
local radialOpen = false
RegisterKeyMapping('fw_radial','Open FW Radial','keyboard','E')
RegisterCommand('fw_radial', function()
  if radialOpen then
    SendNUIMessage({ type='radial:close' }); radialOpen=false
  else
    -- Example ctx; in a real build you collect entity under crosshair
    TriggerServerEvent('fw:interact:build', { type='stash', ref='world:stash:1' })
    radialOpen=true
  end
end)
