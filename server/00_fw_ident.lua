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
