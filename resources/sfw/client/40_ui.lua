local function nui(payload) SendNUIMessage(payload) end

RegisterNetEvent('fw:hud:vitals', function(v)
  nui({ type='hud:vitals', payload=v })
end)
RegisterNetEvent('fw:hud:effects', function(eff)
  nui({ type='hud:effects', payload=eff })
end)
RegisterNetEvent('fw:hud:ammo', function(ammo)
  nui({ type='hud:ammo', payload=ammo })
end)
RegisterNetEvent('fw:hud:progress', function(p)
  nui({ type='hud:progress', payload=p })
end)
local show = true
RegisterCommand('hud', function()
  show = not show
  SendNUIMessage({ type='vis', show = show })
end, false)

CreateThread(function()
  SetNuiFocus(false, false)
  SendNUIMessage({ type = 'vis', show = show })
end)

RegisterNetEvent('fw:hud:push', function(data)
  data.type = 'update'
  SendNUIMessage(data)
end)
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
local function applyPreset(gender, preset)
  local ped = PlayerPedId()
  if gender == 'M' then
    SetPedComponentVariation(ped, 3, 0, 0, 0)  -- Torso
    SetPedComponentVariation(ped, 8, 15, 0, 0) -- Undershirt
    SetPedComponentVariation(ped, 11, 0, 0, 0) -- Top
    SetPedComponentVariation(ped, 4, 0, 0, 0)  -- Pants
    SetPedComponentVariation(ped, 6, 1, 0, 0)  -- Shoes
  else
    SetPedComponentVariation(ped, 3, 14, 0, 0)
    SetPedComponentVariation(ped, 8, 14, 0, 0)
    SetPedComponentVariation(ped, 11, 3, 0, 0)
    SetPedComponentVariation(ped, 4, 3, 0, 0)
    SetPedComponentVariation(ped, 6, 3, 0, 0)
  end
end

RegisterNUICallback('ward:apply', function(data, cb)
  local gender = (data and data.gender) or 'M'
  local preset = (data and data.preset) or 1
  applyPreset(gender, preset)
  if cb then cb({ ok = true }) end
end)

RegisterNUICallback('ward:done', function(data, cb)
  SetNuiFocus(false, false)
  SendNUIMessage({ type='ward:close' })
  if cb then cb({ ok = true }) end
end)
