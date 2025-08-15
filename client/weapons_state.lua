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

