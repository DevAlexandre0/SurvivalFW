FW = FW or {}; FW.ACL = FW.ACL or {}

RegisterNetEvent('fw:interact:build', function(ctx)
  local src = source; local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local actions = {}
  if ctx and ctx.type == 'vehicle' then
    actions[#actions+1] = { key='veh:trunk', label='Open Trunk' }
    actions[#actions+1] = { key='veh:hood', label='Open Hood' }
    actions[#actions+1] = { key='veh:repair', label='Repair', disabled = false }
    actions[#actions+1] = { key='veh:siphon', label='Siphon Fuel' }
  end
  if ctx and ctx.type == 'stash' then
    actions[#actions+1] = { key='stash:open', label='Open Stash', disabled = false }
  end
  TriggerClientEvent('fw:nui:open', src, { type='radial:open', payload={ actions=actions, ctx=ctx or {} } })
end)

RegisterNetEvent('fw:radial:select', function(data)
  local src = source; local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local key = data and data.key or ''
  if key == 'stash:open' then
    local ref = (data.ctx and data.ctx.ref) or 'world:stash:1'
    local payload = exports['survivalfw']:SFW_StashPayload(ref, ident)
    TriggerClientEvent('fw:nui:open', src, { type='stash:open', payload=payload })
  end
end)
