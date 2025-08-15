FW = FW or {}; FW.ACL = FW.ACL or {}; FW.DB = FW.DB or {}

local function identOf(src)
  return (FW.GetIdentifier and FW.GetIdentifier(src)) or tostring(src)
end

function FW.DB.GetRole(ident)
  local row = MySQL.single.await("SELECT role FROM players WHERE identifier = ?", { ident })
  return (row and row.role) or 'user'
end

function FW.ACL.RoleOf(src)
  return FW.DB.GetRole(identOf(src))
end

local function stashOwner(stashId)
  local row = MySQL.single.await("SELECT owner_ident, container_id FROM containers WHERE type='STASH' AND ref = ? LIMIT 1", { stashId })
  return row and row.owner_ident, row and row.container_id
end

-- Basic policy: owner has RW; admin has RW; mod has R; others none (until you add a stash_acl table)
function FW.ACL.StashCanRead(stashId, src)
  local pid = identOf(src)
  local owner = select(1, stashOwner(stashId))
  if owner and owner == pid then return true end
  local role = FW.DB.GetRole(pid)
  return (role == 'admin' or role == 'mod')
end

function FW.ACL.StashCanWrite(stashId, src)
  local pid = identOf(src)
  local owner = select(1, stashOwner(stashId))
  if owner and owner == pid then return true end
  local role = FW.DB.GetRole(pid)
  return (role == 'admin')
end
