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
