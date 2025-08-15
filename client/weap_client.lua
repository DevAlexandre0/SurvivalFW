-- Example hooks: In your weapon handling, trigger these appropriately.
-- Here we simulate for testing with simple commands.

RegisterCommand('weap_state', function(_, args)
  local wtype = args[1] or 'AR'
  local cap = tonumber(args[2] or '30')
  local rounds = tonumber(args[3] or '30')
  local chamber = tonumber(args[4] or '1')
  SendNUIMessage({ type='update', wtype=wtype, wmagMax=cap, wmagRounds=rounds, wchamber=chamber })
  TriggerServerEvent('fw:weap:update', { wtype=wtype, magMax=cap, magRounds=rounds, chamber=chamber, cond=100.0, heat=0.0, jam=false })
end, false)

RegisterCommand('weap_shot', function(_, args)
  local q = (args[1] or 'normal') -- ammo quality
  TriggerServerEvent('fw:weap:shot', q)
end, false)

RegisterCommand('weap_clear', function() TriggerServerEvent('fw:weap:clearjam') end, false)
RegisterCommand('weap_swap', function(_, args) TriggerServerEvent('fw:weap:swapmag', tonumber(args[1] or '30'), tonumber(args[2] or '30')) end, false)
