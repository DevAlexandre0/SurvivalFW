FW = FW or {}
local M = FW.MedDepth
RegisterCommand('splint', function(src)
  if not FW.SafeGate or not FW.SafeGate.Allowed(src,'med:splint') then return end
  local s = FW.Surv.GetStatus(src); s.fracture=false; s.splinted_until=os.time()+(M.splintDuration or 1800)
  FW.Surv.SetStatus(src, s); TriggerClientEvent('chat:addMessage', src, { args={'^2med','Splint applied.'} })
end, false)
RegisterCommand('morphine', function(src)
  if not FW.SafeGate or not FW.SafeGate.Allowed(src,'med:morphine') then return end
  local s = FW.Surv.GetStatus(src); s.pain=math.max(0, (s.pain or 0)-(M.morphinePainRelief or 40))
  FW.Surv.SetStatus(src, s); TriggerClientEvent('chat:addMessage', src, { args={'^2med','Morphine used.'} })
end, false)
RegisterCommand('painkiller', function(src)
  if not FW.SafeGate or not FW.SafeGate.Allowed(src,'med:painkiller') then return end
  local s = FW.Surv.GetStatus(src); s.pain=math.max(0, (s.pain or 0)-(M.painkillerRelief or 20))
  FW.Surv.SetStatus(src, s); TriggerClientEvent('chat:addMessage', src, { args={'^2med','Painkiller taken.'} })
end, false)
