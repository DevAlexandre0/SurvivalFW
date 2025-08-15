FW = FW or {}
local D = FW.Durability
AddEventHandler('fw:weap:shot', function(payload)
  local src = source
  local pid = (FW.DB.ResolveId and FW.DB.ResolveId(src)) or tostring(src)
  local st = FW.DB.GetWeapState(pid) or {}; st.current = st.current or {}
  local cond = tonumber(st.current.cond or 100)
  local loss = (D.weaponPerShot or 0.15) + ((st.current.heat or 0)/10.0) * (D.weaponHeatFactor or 0.005)
  st.current.cond = math.max(0, cond - loss)
  FW.DB.SaveWeapState(pid, st)
end)
-- clothing wet wear tick
CreateThread(function()
  while true do
    Wait(60000)
    for _, sid in ipairs(GetPlayers()) do
      local src = tonumber(sid)
      local s = FW.Surv.GetStatus(src)
      local wet = (s.wet or 0) / 100.0
      if wet > 0.2 then
        local pid = (FW.DB.ResolveId and FW.DB.ResolveId(src)) or tostring(src)
        local wear = wet * (D.clothingWetWear or 0.02)
        local item = 'jacket_warm'
        local cur = 100.0
        FW.DB.AddItem(pid, "__dura_"..item, -wear) -- simplified marker; swap to dedicated table if needed
      end
    end
  end
end)
