-- SFW 00_core_boot (generated minimal)
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}

-- Determine a player's primary identifier, preferring `license:`
if type(FW.GetIdentifier) ~= 'function' then
  function FW.GetIdentifier(src)
    local ids = GetPlayerIdentifiers(src) or {}
    for _,id in ipairs(ids) do if id:find("^license:") then return id end end
    return ids[1]
  end
end

-- Alias fetchPlayer -> get() or fallback query for legacy scripts
if type(FW.DB.players.fetchPlayer) ~= 'function' then
  if type(FW.DB.players.get) == 'function' then
    FW.DB.players.fetchPlayer = FW.DB.players.get -- alias to existing get()
  else
    function FW.DB.players.fetchPlayer(identifier)
      if not identifier then return nil end
      return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
    end
  end
end

if type(FW.DB.players.updatePlayer) ~= 'function' then
  function FW.DB.players.updatePlayer(identifier, patch)
    if not identifier or type(patch) ~= 'table' then return 0 end
    local allow = {
      display_name=true, role=true,
      health=true, stamina=true, hunger=true, thirst=true, temperature_c=true,
      citizen_id=true, first_name=true, last_name=true, dob=true, sex=true,
      height_cm=true, blood_type=true, nationality=true,
      pos_x=true, pos_y=true, pos_z=true, pos_h=true,
      appearance_set=true
    }
    local cols, vals = {}, {}
    for k,v in pairs(patch) do
      if allow[k] then cols[#cols+1] = ("`%s`=?"):format(k); vals[#vals+1] = v end
    end
    if #cols == 0 then return 0 end
    vals[#vals+1] = identifier
    local sql = ("UPDATE players SET %s, updated_at=NOW() WHERE BINARY identifier=BINARY ?")
      :format(table.concat(cols, ","))
    return MySQL.update.await(sql, vals) or 0
  end
end
print("^2[SFW] 00_core_boot (generated) loaded^7")
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
