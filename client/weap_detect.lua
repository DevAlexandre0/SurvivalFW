local function hash(name) return GetHashKey(name) end
local map = (FW and FW.WeapCompat and FW.WeapCompat.weapons) or {}

local lastClass = nil
CreateThread(function()
  while true do
    Wait(1000)
    map = (FW and FW.WeapCfg and FW.WeapCfg.weapons) or map
    local ped = PlayerPedId()
    local w = GetSelectedPedWeapon(ped)
    local found = nil
    for cls,def in pairs(map or {}) do
      for _,n in ipairs(def.hashes or {}) do
        if w == hash(n) then found = cls break end
      end
      if found then break end
    end
    if found ~= lastClass then
      lastClass = found
      if LocalPlayer and LocalPlayer.state then LocalPlayer.state:set('fw_wclass', found, true) end
      TriggerServerEvent('fw:weap:update', { wtype = found or '-' })
    end
  end
end)


RegisterNetEvent('fw:weap:compat:update', function(mat)
  FW = FW or {}
  FW.WeapCompat = mat or {}
end)
