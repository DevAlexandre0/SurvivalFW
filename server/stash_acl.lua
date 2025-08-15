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
