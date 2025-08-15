-- SFW — UI Bindings (syntax-correct)
local function nui(type_, payload)
  SendNUIMessage(payload or { type = type_ })
end

RegisterCommand('ui-close', function()
  nui('ui:close', { type = 'ui:close' })
  SetNuiFocus(false, false)
end, false)

RegisterCommand('ui-open', function()
  nui('ui:open', { type = 'ui:open' })
  SetNuiFocus(true, true)
end, false)

-- Optional keymaps (uncomment if needed)
-- RegisterKeyMapping('ui-open', 'Open SFW UI', 'keyboard', 'F2')
-- RegisterKeyMapping('ui-close', 'Close SFW UI', 'keyboard', 'ESC')
