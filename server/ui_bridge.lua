-- Generic server->client UI opening helpers
RegisterNetEvent('fw:open:trader', function(trader_id)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local payload = exports['survivalfw']:SFW_TraderPayload(trader_id, ident) or {}
  TriggerClientEvent('fw:nui:open', src, { type='trader:open', payload=payload })
end)

RegisterNetEvent('fw:open:stash', function(stash_ref)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local payload = exports['survivalfw']:SFW_StashPayload(stash_ref, ident) or {}
  TriggerClientEvent('fw:nui:open', src, { type='stash:open', payload=payload })
end)

RegisterNetEvent('fw:open:craft', function(bench_tier)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  local payload = exports['survivalfw']:SFW_CraftPayload(bench_tier or 0, ident) or {}
  TriggerClientEvent('fw:nui:open', src, { type='craft:open', payload=payload })
end)
