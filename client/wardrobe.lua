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
