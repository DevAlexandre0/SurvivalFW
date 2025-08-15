-- Legacy shims for SurvivalFW

-- Ensure FW.DB.players.fetchPlayer exists before any legacy script uses it
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}

if type(FW.DB.players.fetchPlayer) ~= 'function' then
  if type(FW.DB.players.get) == 'function' then
    FW.DB.players.fetchPlayer = FW.DB.players.get
  else
    function FW.DB.players.fetchPlayer(identifier)
      if not identifier then return nil end
      return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
    end
  end
  print("^2[SFW] Installed fetchPlayer shim (00_shims.lua)^7")
end

-- Robust FW.GetIdentifier fallback (license: preferred, then fivem, discord, steam)
if type(FW.GetIdentifier) ~= 'function' then
  function FW.GetIdentifier(src)
    if not src then return nil end
    local ids = GetPlayerIdentifiers(src) or {}
    local best = nil
    for _,id in ipairs(ids) do
      if id:find("^license:") then best = id break end
    end
    if not best then
      for _,id in ipairs(ids) do
        if id:find("^fivem:") or id:find("^discord:") or id:find("^steam:") then best = id break end
      end
    end
    return best or ids[1]
  end
end

-- Late guard to ensure fetchPlayer alias remains available
CreateThread(function()
  Wait(1500)
  FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
  if type(FW.DB.players.fetchPlayer) ~= 'function' then
    print("^3[SFW] Restoring FW.DB.players.fetchPlayer alias (late guard)^7")
    if type(FW.DB.players.get) == 'function' then
      FW.DB.players.fetchPlayer = FW.DB.players.get
    else
      FW.DB.players.fetchPlayer = function(identifier)
        if not identifier then return nil end
        return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
      end
    end
  end
end)
