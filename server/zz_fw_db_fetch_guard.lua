CreateThread(function()
  Wait(1500)
  FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
  if type(FW.DB.players.fetchPlayer) ~= 'function' then
    print("^3[SFW] Restoring FW.DB.players.fetchPlayer alias (late guard)^7")
    if type(FW.DB.players.get) == 'function' then
      FW.DB.players.fetchPlayer = FW.DB.players.get
    else
      FW.DB.players.fetchPlayer = function(identifier)
        return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
      end
    end
  end
end)
