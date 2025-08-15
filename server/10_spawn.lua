FW = FW or {}; FW.DB = FW.DB or {}

local PRISON = vec4(1690.0, 2605.0, 45.0, 90.0)

RegisterNetEvent('fw:spawn:request', function()
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src); if not ident then return end
  local r = MySQL.single.await([[
    SELECT pos_x,pos_y,pos_z,pos_h,appearance_set,sex FROM players WHERE BINARY identifier=BINARY ? LIMIT 1
  ]], { ident }) or {}

  local hasId = (FW.NeedsIdentity and not FW.NeedsIdentity(ident)) or false
  local x = tonumber(r.pos_x) or PRISON.x
  local y = tonumber(r.pos_y) or PRISON.y
  local z = tonumber(r.pos_z) or PRISON.z
  local h = tonumber(r.pos_h or PRISON.w)

  TriggerClientEvent('fw:spawn:at', src, {
    x=x, y=y, z=z, h=h,
    hasAppearance = (r.appearance_set == 1),
    hasIdentity   = hasId,
    gender        = r.sex or 'M'
  })
end)

RegisterNetEvent('fw:spawn:save', function(p)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src); if not ident then return end
  if type(p) ~= 'table' then return end
  local x,y,z,h = tonumber(p.x), tonumber(p.y), tonumber(p.z), tonumber(p.h or 0.0)
  if not x or not y or not z then return end
  MySQL.update.await([[
    UPDATE players SET pos_x=?, pos_y=?, pos_z=?, pos_h=?, updated_at=NOW() WHERE BINARY identifier=BINARY ?
  ]], { x,y,z,h, ident })
end)

RegisterNetEvent('fw:appearance:set_flag', function(val)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src); if not ident then return end
  MySQL.update.await("UPDATE players SET appearance_set=?, updated_at=NOW() WHERE BINARY identifier=BINARY ?",
    { (val and 1 or 0), ident })
end)
