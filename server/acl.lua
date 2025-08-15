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
