FW = FW or {}
FW.DB = FW.DB or {}

function FW.GetIdentifier(src)
  if src == 0 or src == nil then return nil end
  for _, id in ipairs(GetPlayerIdentifiers(src)) do
    if id:sub(1,8) == "license:" then return id end
  end
  return nil
end

FW.Surv = FW.Surv or {}

function FW.Surv.GetStatusByIdent(ident)
  if not ident then return { hp=100, stamina=100, hunger=0, thirst=0, temperature_c=37.0 } end
  local row = MySQL.single.await("SELECT stamina, hunger, thirst, temperature_c, health FROM players WHERE BINARY identifier=BINARY ?", { ident })
  return {
    hp = row and row.health or 100,
    stamina = row and row.stamina or 100,
    hunger = row and row.hunger or 0,
    thirst = row and row.thirst or 0,
    temperature_c = row and row.temperature_c or 37.0
  }
end

function FW.Surv.GetStatus(who)
  if type(who) == 'string' then
    return FW.Surv.GetStatusByIdent(who)
  elseif type(who) == 'number' then
    local ident = FW.GetIdentifier(who)
    return FW.Surv.GetStatusByIdent(ident)
  else
    return { hp=100, stamina=100, hunger=0, thirst=0, temperature_c=37.0 }
  end
end

FW.Surv.Log = FW.Surv.Log or function(...) print('[SFW]', ...) end
