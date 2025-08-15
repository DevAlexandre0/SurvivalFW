-- SFW — Medical Advanced (await API)
FW = FW or {}; FW.DB = FW.DB or {}
local C = (FW and FW.DB and FW.DB.Contract) or { effects_active={table='effects_active'}, med_injuries={table='med_injuries'} }

local function identOf(src)
  if FW.GetIdentifier then return FW.GetIdentifier(src) end
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:sub(1,8) == "license:" then return id end
  end
  return nil
end

RegisterNetEvent('fw:med:addEffect', function(effect_type, severity, body_part, ttl, meta)
  local src = source; local ident = identOf(src); if not ident then return end
  body_part = body_part or 'GENERIC'
  local exp = (ttl and ttl>0) and os.date('%Y-%m-%d %H:%M:%S', os.time()+ttl) or nil
  MySQL.insert.await(("INSERT INTO %s(identifier,effect_type,severity,body_part,meta,expires_at) VALUES (?,?,?,?,?,?)"):format(C.effects_active.table),
    { ident, effect_type, tonumber(severity) or 1, body_part, meta or json.encode({}), exp })
end)

RegisterNetEvent('fw:med:addInjury', function(type_, body, sev, meta)
  local src = source; local ident = identOf(src); if not ident then return end
  MySQL.insert.await(("INSERT INTO %s(identifier,injury_type,body_part,severity,treated,meta) VALUES (?,?,?,?,0,?)"):format(C.med_injuries.table),
    { ident, type_ or 'CUT', body or 'GENERIC', tonumber(sev) or 1, meta or json.encode({}) })
end)
