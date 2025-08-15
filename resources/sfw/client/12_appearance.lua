-- Prison uniform sets for freemode
local function applyPrisonOutfit(gender)
  local ped = PlayerPedId()
  if gender == 'F' then
    -- Female orange jumpsuit style (approximate)
    SetPedComponentVariation(ped, 3, 3, 0, 0)   -- Torso
    SetPedComponentVariation(ped, 8, 14, 0, 0)  -- Undershirt
    SetPedComponentVariation(ped, 11, 3, 0, 0)  -- Top (jumpsuit)
    SetPedComponentVariation(ped, 4, 3, 0, 0)   -- Pants
    SetPedComponentVariation(ped, 6, 3, 0, 0)   -- Shoes
  else
    -- Male orange jumpsuit style (approximate)
    SetPedComponentVariation(ped, 3, 0, 0, 0)   -- Torso
    SetPedComponentVariation(ped, 8, 15, 0, 0)  -- Undershirt
    SetPedComponentVariation(ped, 11, 0, 0, 0)  -- Top (jumpsuit)
    SetPedComponentVariation(ped, 4, 0, 0, 0)   -- Pants
    SetPedComponentVariation(ped, 6, 1, 0, 0)   -- Shoes
  end
end

RegisterNetEvent('fw:outfit:prison:apply', function(gender)
  applyPrisonOutfit(gender or 'M')
end)

-- BASIC face & hair appearance (locked clothing)
RegisterNUICallback('app:apply', function(data, cb)
  local ped = PlayerPedId()
  local head = tonumber(data and data.head or 0) or 0
  local skin = tonumber(data and data.skin or 0) or 0
  local hair = tonumber(data and data.hair or 0) or 0
  local col1 = tonumber(data and data.color1 or 0) or 0
  local col2 = tonumber(data and data.color2 or 0) or 0
  SetPedComponentVariation(ped, 0, head, skin, 0) -- face/skin
  SetPedComponentVariation(ped, 2, hair, 0, 0)  -- hair style
  SetPedHairColor(ped, col1, col2)
  if cb then cb({ ok = true }) end
end)

RegisterNUICallback('app:done', function(data, cb)
  SetNuiFocus(false, false)
  SendNUIMessage({ type='app:close' })
  TriggerServerEvent('fw:appearance:set_flag', true)
  if cb then cb({ ok = true }) end
end)

RegisterNetEvent('fw:appearance:open', function()
  SendNUIMessage({ type='app:open' })
  SetNuiFocus(true, true)
end)
