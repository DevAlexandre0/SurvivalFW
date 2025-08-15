FW = FW or {}

-- Example: publish weapon state to HUD
RegisterNetEvent('fw:weap:update', function(state)
  local src = source
  if type(state) ~= 'table' then return end
  local weapon  = state.weapon or '—'
  local mag     = tonumber(state.mag) or 0
  local chamber = tonumber(state.chamber) or 0
  local jam     = state.jam and true or false
  TriggerClientEvent('fw:ui:ammo', src, weapon, mag, chamber, jam)
end)
