FW = FW or {}
FW.Surv = FW.Surv or {}
FW.Surv.Inventory = FW.Surv.Inventory or {}

-- Existing aliases
if not FW.Inventory then
  FW.Inventory = FW.Surv.Inventory
end
if not FW.GetStatus and FW.Surv and FW.Surv.GetStatus then
  FW.GetStatus = FW.Surv.GetStatus
end

-- DB namespace safety
FW.DB = FW.DB or {}
FW.DB.players = FW.DB.players or {}

-- Alias fetchPlayer -> get (or fallback query), for old scripts like med_bleed.lua
if type(FW.DB.players.fetchPlayer) ~= 'function' then
  if type(FW.DB.players.get) == 'function' then
    FW.DB.players.fetchPlayer = FW.DB.players.get
  else
    FW.DB.players.fetchPlayer = function(identifier)
      return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
    end
  end
end
