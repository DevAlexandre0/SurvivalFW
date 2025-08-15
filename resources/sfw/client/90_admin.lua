-- SFW — Admin Client Bridge (syntax-safe)
local function nui(type_, payload)
  SendNUIMessage(payload or { type = type_ })
end

local function openAdmin()
  SetNuiFocus(true, true)
  nui('admin:open', { type='admin:open' })
end

RegisterNetEvent('fw:admin:open', function()
  openAdmin()
end)

RegisterCommand('admin', function()
  openAdmin()
end, false)

RegisterNUICallback('admin:close', function(_, cb)
  SetNuiFocus(false, false)
  nui('admin:close', { type='admin:close' })
  cb({ ok = true })
end)

-- Example: request server action (you can expand later)
RegisterNUICallback('admin:setRole', function(data, cb)
  TriggerServerEvent('fw:admin:setRole', data and data.identifier, data and data.role)
  cb({ ok = true })
end)
