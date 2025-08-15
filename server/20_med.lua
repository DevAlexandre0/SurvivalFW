-- SFW 20_med — self-contained bleeding tick (no fetchPlayer usage)
FW = FW or {}

local function getIdent(src)
  if FW.GetIdentifier then return FW.GetIdentifier(src) end
  local ids = GetPlayerIdentifiers(src) or {}
  for _,id in ipairs(ids) do if id:find("^license:") then return id end end
  return ids[1]
end

local function db_bleed_sum(identifier)
  local val = MySQL.scalar.await([[
    SELECT COALESCE(SUM(severity),0) FROM effects_active
    WHERE identifier=? AND effect_type='BLEEDING' AND (expires_at IS NULL OR expires_at > NOW())
  ]], { identifier })
  return tonumber(val) or 0
end

local function db_fetch_hp(identifier)
  local row = MySQL.single.await("SELECT health FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
  return row and tonumber(row.health) or 100
end

local function db_update_hp(identifier, hp)
  MySQL.update.await("UPDATE players SET health=?, updated_at=NOW() WHERE BINARY identifier=BINARY ?", { hp, identifier })
end

local function tick_one(src)
  local ident = getIdent(src); if not ident then return end
  local sev = db_bleed_sum(ident); if sev <= 0 then return end
  local hp = db_fetch_hp(ident)
  local dmg = math.max(1, math.floor(sev * 0.05))
  local newHp = math.max(0, hp - dmg)
  db_update_hp(ident, newHp)
  TriggerClientEvent('fw:hud:effects', src, { { type='BLEEDING', severity=sev } })
end

CreateThread(function()
  while true do
    for _, sid in ipairs(GetPlayers()) do tick_one(tonumber(sid) or sid) end
    Wait(2000)
  end
end)

RegisterNetEvent('fw:med:bleed:tickOne', function(target) tick_one(target or source) end)
