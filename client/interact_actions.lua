-- SFW — Interact Actions (syntax-correct)
function FW_DoRepair(entity)
  TriggerEvent('chat:addMessage', { args = { '^2SFW', 'Repair started on entity '..tostring(entity) } })
end

function FW_DoSiphon(entity)
  TriggerEvent('chat:addMessage', { args = { '^2SFW', 'Siphon started on entity '..tostring(entity) } })
end

-- keep file terminated with a newline
