FW = FW or {}; FW.Surv = FW.Surv or {}; FW.Surv.Inventory = FW.Surv.Inventory or {}
if not FW.Inventory then FW.Inventory = FW.Surv.Inventory end

local function insulationOf(ident)
  if FW.Surv and FW.Surv.Inventory and FW.Surv.Inventory.InsulationOf then
    return tonumber(FW.Surv.Inventory.InsulationOf(ident)) or 0.10
  end
  return 0.10
end

RegisterNetEvent('fw:env:tick', function()
  local src = source
  local ident = FW.GetIdentifier and FW.GetIdentifier(src)
  if not ident then return end
  local ins = insulationOf(ident)
  -- Example env tick: you can expand with wetness/wind
  TriggerClientEvent('fw:hud:vitals', src, { insulation = ins })
end)
