FW = FW or {}
RegisterNetEvent('fw:acl:reqRole', function()
  local src = source
  local role = (FW.ACL and FW.ACL.RoleOf and FW.ACL.RoleOf(src)) or 'user'
  TriggerClientEvent('fw:acl:role', src, role)
end)
