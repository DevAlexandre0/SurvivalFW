-- SFW 11_identity — strict identity gate + autogen citizen_id + wardrobe bridge
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}

local ID_LOCK = {}

local function str_ok(s, min, max)
  if type(s) ~= 'string' then return false end
  s = s:gsub("^%s+",""):gsub("%s+$","")
  return #s >= (min or 1) and #s <= (max or 64)
end

local function cid_exists(cid)
  local ok, res = pcall(function() return MySQL.scalar.await("SELECT 1 FROM players WHERE citizen_id=? LIMIT 1", { cid }) end)
  if ok and res then return true end
  local row = MySQL.single.await("SELECT citizen_id FROM players WHERE citizen_id=? LIMIT 1", { cid })
  return row ~= nil
end

local __seeded = false
local function gen_citizen_id()
  if not __seeded then math.randomseed((GetGameTimer and GetGameTimer() or 0) + os.time()); __seeded = true end
  for _=1,50 do
    local d={}; d[1]=math.random(1,9); for i=2,12 do d[i]=math.random(0,9) end
    local sum=0; for i=1,12 do sum = sum + (d[i]*(13-i)) end
    d[13]=(11-(sum%11))%10
    local cid = table.concat(d, "")
    if cid ~= "0000000000000" and not cid_exists(cid) then return cid end
  end
  return string.format("%013d", math.random(10*12, 10*13-1))
end

-- strict identity checker (exported)
function FW.NeedsIdentity(identifier)
  local r = MySQL.single.await([[
    SELECT citizen_id, first_name, last_name, dob, sex, height_cm, blood_type, nationality
    FROM players WHERE BINARY identifier=BINARY ? LIMIT 1
  ]], { identifier })
  if not r then return true end
  local function empty(v) return (v == nil) or (type(v)=='string' and v=='') end
  if empty(r.citizen_id) then return true end
  if empty(r.first_name)  then return true end
  if empty(r.last_name)   then return true end
  if empty(r.dob)         then return true end
  if empty(r.sex)         then return true end
  if r.height_cm == nil   then return true end
  if empty(r.blood_type)  then return true end
  if empty(r.nationality) then return true end
  return false
end

AddEventHandler('playerJoining', function()
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  if not ident then return end
  if FW.NeedsIdentity(ident) then
    TriggerClientEvent('fw:nui:open', src, { type='id:open' })
    TriggerClientEvent('fw:player:register_mode', src, true)
  else
    TriggerClientEvent('fw:player:register_mode', src, false)
  end
end)

RegisterNetEvent('fw:id:check', function()
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  if not ident then return end
  if FW.NeedsIdentity(ident) then
    TriggerClientEvent('fw:nui:open', src, { type='id:open' })
    TriggerClientEvent('fw:player:register_mode', src, true)
  else
    TriggerClientEvent('fw:player:register_mode', src, false)
  end
end)

RegisterNetEvent('fw:id:submit', function(data)
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src); if not ident then return end
  if type(data) ~= 'table' then data = {} end
  if ID_LOCK[ident] then return end
  ID_LOCK[ident] = true

  local fn = data.first_name or ''
  local ln = data.last_name or ''
  if not str_ok(fn, 2, 64) or not str_ok(ln, 2, 64) then
    TriggerClientEvent('fw:nui:open', src, { type='id:error', payload={ message='Invalid name' } })
    ID_LOCK[ident] = nil
    return
  end

  local display = fn .. ' ' .. ln
  local cid = gen_citizen_id()

  MySQL.insert.await([[
    INSERT IGNORE INTO players(identifier, display_name, role, health, stamina, hunger, thirst, temperature_c)
    VALUES (?, ?, 'user', 100, 100, 0, 0, 37.00)
  ]], { ident, display })

  MySQL.update.await([[
    UPDATE players SET
      display_name=?, citizen_id=?, first_name=?, last_name=?, dob=?, sex=?, height_cm=?, blood_type=?, nationality=?, updated_at=NOW()
    WHERE BINARY identifier=BINARY ?
  ]], {
    display, cid, fn, ln, data.dob or '1990-01-01', data.sex or 'M',
    tonumber(data.height_cm) or 175, data.blood_type or 'UNKNOWN', data.nationality or 'TH', ident
  })

  TriggerClientEvent('fw:nui:open', src, { type='id:close' })
  TriggerClientEvent('fw:player:register_mode', src, false)
  TriggerClientEvent('fw:nui:open', src, { type='app:open' }) -- open hair UI next
  ID_LOCK[ident] = nil
end)

-- optional external wardrobe bridge can still be added later
