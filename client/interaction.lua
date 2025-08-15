CreateThread(function()
  while not FW or not FW.Target do Wait(100) end
  -- Trader spots
  for _,p in ipairs((FW.Interact and FW.Interact.trader) or {}) do
    FW.Target.addCircle('fw_trader_'..tostring(p.x)..'_'..tostring(p.y), p.x,p.y,p.z, p.radius or 1.5, {
      { label=p.label or 'Trader', icon='fa-solid fa-store', onSelect=function() SendNUIMessage({type='ui-open', tab='trader'}) end }
    })
  end
  -- Stash spots
  for _,p in ipairs((FW.Interact and FW.Interact.stash) or {}) do
    FW.Target.addCircle('fw_stash_'..tostring(p.x)..'_'..tostring(p.y), p.x,p.y,p.z, p.radius or 1.4, {
      { label=p.label or 'Stash', icon='fa-solid fa-box', onSelect=function() SendNUIMessage({type='ui-open', tab='stash'}) end }
    })
  end
  -- Craft spots from benches
  local getCraft = FW.Interact and FW.Interact.craft
  local pts = type(getCraft)=='function' and getCraft() or {}
  for _,p in ipairs(pts) do
    FW.Target.addCircle('fw_craft_'..tostring(p.x)..'_'..tostring(p.y), p.x,p.y,p.z, p.radius or 1.6, {
      { label=p.label or 'Craft', icon='fa-solid fa-hammer', onSelect=function() SendNUIMessage({type='ui-open', tab='craft'}) end }
    })
  end
end)


local function quickCraft(recipeId)
  -- send server callback to craft 1x
  TriggerServerEvent('fw:cb:req', tostring(math.random(100000,999999)), 'ui:craft:do', { recipe=recipeId, amt=1 })
  -- simple notify
  TriggerEvent('chat:addMessage', { args={'craft', 'Queued: '..recipeId} })
end

-- add dynamic options for craft spots: top featured recipes
CreateThread(function()
  while not FW or not FW.Target do Wait(200) end
  local getCraft = FW.Interact and FW.Interact.craft
  local pts = type(getCraft)=='function' and getCraft() or {}
  for _,p in ipairs(pts) do
    local opts = {
      { label=p.label or 'Craft (open)', icon='fa-solid fa-hammer', onSelect=function() SendNUIMessage({type='ui-open', tab='craft'}) end }
    }
    -- gather featured recipes for that bench
    local R = (FW and FW.Crafting and FW.Crafting.recipes) or {}
    local added=0
    for rid,rec in pairs(R) do
      if rec.bench == p.bench and rec.featured then
        table.insert(opts, { label='Craft: '..rid, icon='fa-solid fa-wrench', onSelect=function() quickCraft(rid) end })
        added=added+1; if added>=6 then break end
      end
    end
    FW.Target.addCircle('fw_craft_quick_'..tostring(p.x)..'_'..tostring(p.y), p.x,p.y,p.z, p.radius or 1.6, opts)
  end
end)


-- Vehicle context provider
CreateThread(function()
  while not FW or not FW.Target or not FW.Target.setVehicleProvider do Wait(200) end

  local function actionOpenTrunk(ctx)
    local id = 'veh:'..(ctx.plate or tostring(NetworkGetNetworkIdFromEntity(ctx.veh)))
    ExecuteCommand(('stash open %s'):format(id))
    SendNUIMessage({ type='ui-open', tab='stash' })
  end

  local function actionRepair(ctx)
    local ped = PlayerPedId()
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_VEHICLE_MECHANIC', 0, true)
    Wait(7000)
    ClearPedTasksImmediately(ped)
    SetVehicleEngineHealth(ctx.veh, 1000.0)
    SetVehicleBodyHealth(ctx.veh, 1000.0)
    SetVehicleFixed(ctx.veh)
    TriggerEvent('chat:addMessage', { args={'veh','Repaired'} })
  end

  local function actionSiphon(ctx)
    local fuel = GetVehicleFuelLevel and GetVehicleFuelLevel(ctx.veh) or 30.0
    local take = math.min(10.0, fuel)
    TaskStartScenarioInPlace(PlayerPedId(), 'WORLD_HUMAN_GARDENER_PLANT', 0, true)
    Wait(5000)
    ClearPedTasksImmediately(PlayerPedId())
    if GetVehicleFuelLevel then SetVehicleFuelLevel(ctx.veh, fuel - take) end
    -- optionally give item; fallback to message
    TriggerEvent('chat:addMessage', { args={'veh', ('Siphoned %.1fL'):format(take)} })
  end

  FW.Target.setVehicleProvider(function(ctx)
    return {
      { label='Trunk Stash', onSelect=actionOpenTrunk },
      { label='Repair Vehicle', onSelect=actionRepair },
      { label='Siphon Fuel', onSelect=actionSiphon },
    }
  end)
end)
