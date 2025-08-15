-- Push HUD vitals to clients when they change

local lastVitals = {}

CreateThread(function()
  while true do
    for _, src in ipairs(GetPlayers()) do
      local ped = GetPlayerPed(src)
      local hp = GetEntityHealth(ped)
      local armor = GetPedArmour(ped)
      local snapshot = { hp = hp, armor = armor }
      local prev = lastVitals[src]
      if not prev or prev.hp ~= hp or prev.armor ~= armor then
        lastVitals[src] = snapshot
        TriggerClientEvent('fw:hud:push', src, snapshot)
      end
    end
    Wait(1000)
  end
end)

AddEventHandler('playerDropped', function()
  lastVitals[source] = nil
end)

