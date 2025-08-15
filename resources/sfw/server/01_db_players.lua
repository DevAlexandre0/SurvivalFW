FW = FW or {}; FW.DB = FW.DB or {}
FW.DB.players = FW.DB.players or {}

local function table_shallow_copy(t)
  local o = {}
  if type(t) ~= 'table' then return o end
  for k,v in pairs(t) do o[k]=v end
  return o
end

-- GET one player row
function FW.DB.players.get(identifier)
  return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier = BINARY ? LIMIT 1", { identifier })
end

-- ENSURE player exists
function FW.DB.players.ensure(identifier, display)
  local row = FW.DB.players.get(identifier)
  if row then return row end
  MySQL.insert.await([[
    INSERT INTO players(identifier, display_name, role, health, stamina, hunger, thirst, temperature_c)
    VALUES (?, ?, 'user', 100, 100, 0, 0, 37.00)
  ]], { identifier, display or identifier })
  return FW.DB.players.get(identifier)
end

-- UPDATE with whitelist columns (prevents SQL injection, dynamic set safely)
local whitelist = {
  display_name=true, role=true,
  health=true, stamina=true, hunger=true, thirst=true, temperature_c=true,
  citizen_id=true, first_name=true, last_name=true, dob=true, sex=true,
  height_cm=true, blood_type=true, nationality=true
}

local function build_update_set(patch)
  local cols, vals = {}, {}
  for k,v in pairs(patch or {}) do
    if whitelist[k] then
      cols[#cols+1] = ("`%s`=?"):format(k)
      vals[#vals+1] = v
    end
  end
  return cols, vals
end

function FW.DB.players.update(identifier, patch)
  local cols, vals = build_update_set(patch)
  if #cols == 0 then return 0 end
  vals[#vals+1] = identifier
  local sql = ("UPDATE players SET %s, updated_at=NOW() WHERE BINARY identifier = BINARY ?"):format(table.concat(cols, ","))
  return MySQL.update.await(sql, vals)
end

-- Backwards-compat alias to satisfy older scripts
FW.DB.players.updatePlayer = FW.DB.players.update

-- Convenience: set vitals
function FW.DB.players.setVitals(identifier, hp, st, hu, th, tc)
  return FW.DB.players.update(identifier, {
    health = hp, stamina = st, hunger = hu, thirst = th, temperature_c = tc
  })
end

-- Convenience: set name/role
function FW.DB.players.setName(identifier, display)
  return FW.DB.players.update(identifier, { display_name = display })
end
function FW.DB.players.setRole(identifier, role)
  return FW.DB.players.update(identifier, { role = role })
end
