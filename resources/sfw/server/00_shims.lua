-- Ensure fetchPlayer exists before any legacy script uses it
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
if type(FW.DB.players.fetchPlayer) ~= 'function' then
  if type(FW.DB.players.get) == 'function' then
    FW.DB.players.fetchPlayer = FW.DB.players.get
  else
    FW.DB.players.fetchPlayer = function(identifier)
      return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
    end
  end
end
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
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
if type(FW.DB.players.fetchPlayer) ~= 'function' then
  if type(FW.DB.players.get) == 'function' then
    FW.DB.players.fetchPlayer = FW.DB.players.get
  else
    FW.DB.players.fetchPlayer = function(identifier)
      return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
    end
  end
end
-- Ensure FW.DB.players.fetchPlayer exists for legacy scripts (e.g., med_bleed.lua)
FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
if type(FW.DB.players.fetchPlayer) ~= 'function' then
  if type(FW.DB.players.get) == 'function' then
    FW.DB.players.fetchPlayer = FW.DB.players.get
  else
    FW.DB.players.fetchPlayer = function(identifier)
      return MySQL.single.await("SELECT * FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { identifier })
    end
  end
end
CreateThread(function()
  Wait(500)
  pcall(function() MySQL.query.await("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci") end)
  pcall(function() MySQL.query.await("SET collation_connection = 'utf8mb4_unicode_ci'") end)
  print("^2[SFW:DB] Session collation set to utf8mb4_unicode_ci^7")
end)
FW = FW or {}; FW.DB = FW.DB or {}
local buckets = {5,10,20,50,100,200,500,1000}
local function bucket(ms) for _,b in ipairs(buckets) do if ms<=b then return b end end return 2000 end
local function now() return GetGameTimer() end
local function inc(k) if FW.Metrics and FW.Metrics.Inc then FW.Metrics.Inc(k,1) end end
local function logLatency(ms, tag) inc(("db_latency_%sms{%s}"):format(bucket(ms), tag or "gen")) end
function FW.DB.single(q,a,t) local s=now(); local r=MySQL.single.await(q,a); logLatency(now()-s,t or 'single'); return r end
function FW.DB.query(q,a,t) local s=now(); local r=MySQL.query.await(q,a) or {}; logLatency(now()-s,t or 'query'); return r end
function FW.DB.update(q,a,t) local s=now(); local r=exports.oxmysql:update(q,a); logLatency(now()-s,t or 'update'); return r end
function FW.DB.insert(q,a,t) local s=now(); local r=exports.oxmysql:insert(q,a); logLatency(now()-s,t or 'insert'); return r end
function FW.DB.txn(ops,t) local s=now(); local r=exports.oxmysql:transaction(ops); logLatency(now()-s,t or 'txn'); return r end
FW = FW or {}
RegisterNetEvent('fw:acl:reqRole', function()
  local src = source
  local role = (FW.ACL and FW.ACL.RoleOf and FW.ACL.RoleOf(src)) or 'user'
  TriggerClientEvent('fw:acl:role', src, role)
end)
FW = FW or {}; FW.ACL = FW.ACL or {}

function FW.ACL.RoleOf(ident)
  local r = MySQL.single.await("SELECT role FROM players WHERE BINARY identifier=BINARY ? LIMIT 1", { ident })
  return r and r.role or 'user'
end

function FW.ACL.Can(ident, action, ctx)
  local role = FW.ACL.RoleOf(ident)
  if role == 'admin' then return true end
  -- Basic policy examples
  if action == 'stash.manage' then return role ~= 'user' end
  if action == 'trader.admin' then return role ~= 'user' end
  -- default allow
  return true
end
-- Robust FW.GetIdentifier fallback (license: preferred, then fivem, discord, steam)
FW = FW or {}
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
