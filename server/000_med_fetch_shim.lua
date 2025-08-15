-- SFW shim: ensure FW.DB.players.fetchPlayer exists *before* legacy med_bleed.lua runs
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}

if type(FW.GetIdentifier) ~= 'function' then
  function FW.GetIdentifier(src)
    local ids = GetPlayerIdentifiers(src) or {}
    for _,id in ipairs(ids) do if id:find("^license:") then return id end end
    return ids[1]
  end
end

if type(FW.DB.players.fetchPlayer) ~= 'function' then
  function FW.DB.players.fetchPlayer(identifier)
    if not identifier then return nil end
    -- Return full row so legacy code can use any column
    return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
  end
  print("^2[SFW] Installed fetchPlayer shim (000_med_fetch_shim.lua)^7")
end
