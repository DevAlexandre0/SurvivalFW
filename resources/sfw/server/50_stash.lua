FW = FW or {}

local function ensureStash(ref, slots)
  local row = MySQL.single.await("SELECT container_id FROM containers WHERE type='STASH' AND ref=? LIMIT 1", { ref })
  if not row then
    MySQL.query.await("INSERT INTO containers(type, ref, slots, weight_limit) VALUES ('STASH', ?, ?, 200.0)", { ref, slots or 30 })
    row = MySQL.single.await("SELECT LAST_INSERT_ID() AS id", {})
    local cid = row.id
    for i=1,(slots or 30) do
      MySQL.insert.await("INSERT INTO container_slots(container_id,slot_index,locked,tag) VALUES (?,?,0,NULL)", { cid, i })
    end
    return cid
  end
  return row.container_id
end

exports('SFW_StashPayload', function(ref, ident)
  local cid = ensureStash(ref, 42)
  local pcid = exports['survivalfw']:SFW_PlayerContainerId(ident)
  local payload = {
    player = exports['survivalfw']:SFW_FetchStacks(pcid),
    stash = exports['survivalfw']:SFW_FetchStacks(cid),
    stash_id = cid,
    player_id = pcid
  }
  return payload
end)
FW = FW or {}
FW.ACL = FW.ACL or {}

local function pidOf(src)
  return (FW.DB and FW.DB.ResolveId and FW.DB.ResolveId(src)) or tostring(src)
end
local function ownerOf(stashId)
  local row = MySQL.single.await("SELECT owner FROM myfw_stash WHERE stash_id = ?", { stashId })
  return row and row.owner or nil
end

function FW.ACL.RoleOf(src) return FW.DB.GetRole(pidOf(src)) end
function FW.ACL.StashCanRead(stashId, src)
  local pid = pidOf(src)
  if FW.DB.StashPerm(stashId, pid) then return true end
  if ownerOf(stashId) == pid then return true end
  local role = FW.DB.GetRole(pid); return (role == 'admin' or role == 'mod')
end
function FW.ACL.StashCanWrite(stashId, src)
  local pid = pidOf(src)
  local perm = FW.DB.StashPerm(stashId, pid)
  if perm == 'rw' then return true end
  if ownerOf(stashId) == pid then return true end
  local role = FW.DB.GetRole(pid); return (role == 'admin')
end

RegisterNetEvent('fw:stash:grant', function(srcReq, stashId, ident, perm)
  local src = srcReq or source
  if not FW.ACL.StashCanWrite(stashId, src) then return end
  FW.DB.StashGrant(stashId, ident, perm or 'rw')
  TriggerClientEvent('chat:addMessage', src, { args={'^2Stash','Granted '..ident..' '..(perm or 'rw')} })
end)
RegisterNetEvent('fw:stash:revoke', function(srcReq, stashId, ident)
  local src = srcReq or source
  if not FW.ACL.StashCanWrite(stashId, src) then return end
  FW.DB.StashRevoke(stashId, ident)
  TriggerClientEvent('chat:addMessage', src, { args={'^2Stash','Revoked '..ident} })
end)

RegisterCommand('aclrole', function(src, args)
  local role = (args[1] or 'user'):lower()
  if role ~= 'admin' and role ~= 'mod' and role ~= 'user' then return end
  local my = FW.DB.GetRole((FW.DB.ResolveId and FW.DB.ResolveId(src)) or tostring(src))
  if my ~= 'admin' then TriggerClientEvent('chat:addMessage', src, { args={'^1ACL','Only admin can set roles.'} }); return end
  local target = args[2]; if not target then return end
  FW.DB.SetRole(target, role)
  TriggerClientEvent('chat:addMessage', src, { args={'^2ACL','Set '..target..' -> '..role} })
end, false)
FW = FW or {}
FW.SafeGate = {}
local keys = {
  ["evt:weap_shot"] = { rate=10, burst=15 },
  ["evt:veh_impact"] = { rate=2, burst=5 },
  ["stash:open"] = { rate=1, burst=2 },
  ["stash:move"] = { rate=2, burst=5 },
  ["craft:do"] = { rate=1, burst=2 },
  ["forage:do"] = { rate=0.5, burst=1 },
  ["wildlife:harvest"] = { rate=1, burst=2 },
  ["env:weather"] = { rate=1, burst=5 },
  ["med:splint"] = { rate=0.5, burst=1 },
  ["med:morphine"] = { rate=0.5, burst=1 },
  ["med:painkiller"] = { rate=0.5, burst=1 },
  ["med:bandage"] = { rate=0.5, burst=1 },
  ["med:tourniquet"] = { rate=0.5, burst=1 },
  ["veh:*"] = { rate=1, burst=3 },
}
local buckets = {}
function FW.SafeGate.Allowed(src, key)
  local now = GetGameTimer()
  local k = keys[key] or keys[key:match("^[^:]+:%*")] or {rate=1, burst=2}
  local b = buckets[src..':'..key] or {ts=now, tokens=k.burst}
  local elapsed = (now - b.ts)/1000.0
  b.tokens = math.min(k.burst, b.tokens + elapsed * k.rate)
  b.ts = now
  local ok = b.tokens >= 1.0
  if ok then b.tokens = b.tokens - 1.0 end
  buckets[src..':'..key] = b
  return ok
end
