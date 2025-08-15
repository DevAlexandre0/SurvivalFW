-- SFW — Weapon Debug Commands

if GetConvar('sfw_dev', 'false') == 'true' then
  local state = { weapon = 'DEMO', mag = 0, chamber = 0, jam = false }

  local function push()
    TriggerEvent('fw:weap:state', state)
  end

  RegisterCommand('magfill', function()
    state.mag = 30
    state.chamber = 1
    state.jam = false
    push()
  end, false)

  RegisterCommand('magunload', function()
    state.mag = 0
    state.chamber = 0
    push()
  end, false)

  RegisterCommand('swapmag', function()
    state.mag = math.random(5, 30)
    push()
  end, false)

  RegisterCommand('weapjam', function()
    state.jam = not state.jam
    push()
  end, false)

  RegisterCommand('weap_state', function(_, args)
    local wtype = args[1] or 'AR'
    local cap = tonumber(args[2] or '30')
    local rounds = tonumber(args[3] or '30')
    local chamber = tonumber(args[4] or '1')
    SendNUIMessage({ type='update', wtype=wtype, wmagMax=cap, wmagRounds=rounds, wchamber=chamber })
    TriggerServerEvent('fw:weap:update', { wtype=wtype, magMax=cap, magRounds=rounds, chamber=chamber, cond=100.0, heat=0.0, jam=false })
  end, false)

  RegisterCommand('weap_shot', function(_, args)
    local q = (args[1] or 'normal')
    TriggerServerEvent('fw:weap:shot', q)
  end, false)

  RegisterCommand('weap_clear', function()
    TriggerServerEvent('fw:weap:clearjam')
  end, false)

  RegisterCommand('weap_swap', function(_, args)
    TriggerServerEvent('fw:weap:swapmag', tonumber(args[1] or '30'), tonumber(args[2] or '30'))
  end, false)
end

