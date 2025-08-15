FW = FW or {}; FW.Surv = FW.Surv or {}
local function clamp(v,a,b) if v<a then return a elseif v>b then return b else return v end end
FW.Surv.Inventory = FW.Surv.Inventory or {}

function FW.Surv.Inventory.WeightOf(ident)
  if not ident then return 0.0 end
  local row = MySQL.single.await([[
    SELECT COALESCE(SUM(CASE WHEN s.weight_cached>0 THEN s.weight_cached ELSE s.quantity*COALESCE(i.base_weight,0) END),0) AS w
    FROM stacks s JOIN containers c ON c.container_id=s.container_id
    LEFT JOIN items i ON i.item_key=s.item_key
    WHERE c.owner_ident = ? AND c.type='PLAYER'
  ]], { ident })
  return (row and tonumber(row.w)) or 0.0
end

function FW.Surv.Inventory.InsulationOf(ident)
  if not ident then return 0.10 end
  local ap = MySQL.single.await("SELECT components FROM player_appearance WHERE BINARY identifier=BINARY ?", { ident })
  local score = 0.10
  if ap and ap.components then
    local ok, comps = pcall(json.decode, ap.components)
    if ok and type(comps)=='table' then
      local map = { [3]=0.20,[4]=0.15,[11]=0.20,[6]=0.05,[9]=0.10 }
      for k,add in pairs(map) do
        local c = comps[k]
        if c and type(c)=='table' and (c.drawable or 0) > 0 then score = score + add end
      end
    end
  end
  return clamp(score, 0.0, 1.0)
end
