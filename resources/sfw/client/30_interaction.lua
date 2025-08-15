-- Placeholder for hit test/raycast; can be replaced by advanced targeting
-- Expose an event to open radial with arbitrary context received from server
RegisterNetEvent('fw:target:open', function(ctx)
  TriggerServerEvent('fw:interact:build', ctx or {})
end)
-- SFW — Target Bridge (syntax-correct)
local function RotationToDirection(rot)
  local z = math.rad(rot.z); local x = math.rad(rot.x)
  local num = math.abs(math.cos(x))
  return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function RaycastFromCamera(dist)
  local ped = PlayerPedId()
  local camRot = GetGameplayCamRot(2)
  local camPos = GetGameplayCamCoord()
  local dir = RotationToDirection(camRot)
  local to = vector3(camPos.x + dir.x*dist, camPos.y + dir.y*dist, camPos.z + dir.z*dist)
  local handle = StartShapeTestRay(camPos.x, camPos.y, camPos.z, to.x, to.y, to.z, -1, ped, 7)
  local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(handle)
  return hit == 1, endCoords, entityHit
end

RegisterCommand('sfw-target', function()
  local hit, pos, ent = RaycastFromCamera(5.0)
  if hit then
    print(('[SFW] Hit entity %s at x=%.2f y=%.2f z=%.2f'):format(ent, pos.x, pos.y, pos.z))
  else
    print('[SFW] No hit')
  end
end, false)
-- SFW — Interact Actions (syntax-correct)
function FW_DoRepair(entity)
  TriggerEvent('chat:addMessage', { args = { '^2SFW', 'Repair started on entity '..tostring(entity) } })
end

function FW_DoSiphon(entity)
  TriggerEvent('chat:addMessage', { args = { '^2SFW', 'Siphon started on entity '..tostring(entity) } })
end

-- keep file terminated with a newline
-- Simple keybinds to demo opening panels via server
RegisterCommand('fw_trader', function() TriggerServerEvent('fw:open:trader', 1) end)
RegisterCommand('fw_stash', function() TriggerServerEvent('fw:open:stash', 'world:stash:1') end)
RegisterCommand('fw_craft', function() TriggerServerEvent('fw:open:craft', 0) end)

-- Radial toggle
local radialOpen = false
RegisterKeyMapping('fw_radial','Open FW Radial','keyboard','E')
RegisterCommand('fw_radial', function()
  if radialOpen then
    SendNUIMessage({ type='radial:close' }); radialOpen=false
  else
    -- Example ctx; in a real build you collect entity under crosshair
    TriggerServerEvent('fw:interact:build', { type='stash', ref='world:stash:1' })
    radialOpen=true
  end
end)
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
FW = FW or {}
FW.Interact = FW.Interact or {}

local C = FW.InteractCfg or { scan = {} }
local SRC = { zones = {}, providers = {} }

-- ===== Zones API =====
function FW.Interact.registerZone(z)
  -- z: { id, type='circle'|'poly'|'box', x,y,z,r, poly={{x,y},...}, minZ,maxZ, label, meta={} }
  z.id = z.id or ('zone_'..tostring(#SRC.zones+1))
  table.insert(SRC.zones, z)
end

-- Register default zones from config + benches
CreateThread(function()
  Wait(500)
  local cfg = FW.InteractCfg or {}
  for _,p in ipairs((cfg.zones and cfg.zones.trader) or {}) do FW.Interact.registerZone({ id='trader_'..p.x, type='circle', x=p.x,y=p.y,z=p.z,r=p.r or 1.6, label=p.label, meta={kind='trader'} }) end
  for _,p in ipairs((cfg.zones and cfg.zones.stash ) or {}) do FW.Interact.registerZone({ id='stash_'..p.x,  type='circle', x=p.x,y=p.y,z=p.z,r=p.r or 1.4, label=p.label, meta={kind='stash'} }) end
  -- benches from crafting
  if FW and FW.Crafting and FW.Crafting.benches then
    for id,b in pairs(FW.Crafting.benches) do
      for _,pt in ipairs(b.points or {}) do
        FW.Interact.registerZone({ id='bench_'..id..'_'..tostring(pt.x), type='circle', x=pt.x,y=pt.y,z=pt.z, r=pt.r or 1.6, label='Craft: '..(b.label or id), meta={ kind='bench', bench=id } })
      end
    end
  end
end)

-- ===== Providers for dynamic menu items =====
-- a provider receives (ctx) and returns array of action objects
-- ctx: { hit='zone'|'entity', zone=?, entity=?, coords=?, class=?, kind=?, bench=?, vehicle=? }
function FW.Interact.registerProvider(fn) table.insert(SRC.providers, fn) end

-- ===== Geometry helpers =====
local function pointInPoly(px,py, poly)
  local inside = false
  local j = #poly
  for i=1,#poly do
    local xi, yi = poly[i][1], poly[i][2]
    local xj, yj = poly[j][1], poly[j][2]
    local intersect = ((yi>py) ~= (yj>py)) and (px < (xj - xi) * (py - yi) / ((yj - yi) + 1e-9) + xi)
    if intersect then inside = not inside end
    j = i
  end
  return inside
end

local function near2(x1,y1,x2,y2,r) local dx=x1-x2 local dy=y1-y2 return dx*dx+dy*dy <= r*r end

-- ===== Zone detection =====
local function detectZone(px,py,pz)
  for _,z in ipairs(SRC.zones) do
    if z.type=='circle' then
      if near2(px,py, z.x,z.y, z.r or (C.scan and C.scan.zoneRadius or 2.0)) then
        local minZ,maxZ = z.minZ or -10000, z.maxZ or 10000
        if pz>=minZ and pz<=maxZ then return { id=z.id, label=z.label, meta=z.meta, type='circle', x=z.x,y=z.y,z=z.z } end
      end
    elseif z.type=='poly' and z.poly then
      if pointInPoly(px,py,z.poly) then return { id=z.id, label=z.label, meta=z.meta, type='poly' } end
    end
  end
  return nil
end


-- ===== Entity detection with raycast + sphere fallback =====
local function classOfEntity(e)
  if IsEntityAVehicle(e) then return 'vehicle'
  elseif IsEntityAPed(e) then return 'ped'
  else return 'prop' end
end

local function isOwned(e)
  if IsEntityAVehicle(e) then
    return GetPedInVehicleSeat(e, -1) == PlayerPedId()
  end
  return false
end

local function isFriendlyPed(ped)
  -- Simple heuristic: players are friendly; animals hostile; others neutral
  if IsPedAPlayer(ped) then return true end
  if IsPedHuman(ped) then return false end
  return false
end

local function detectEntity(px,py,pz)
  local ped = PlayerPedId()
  local Cfg = FW.InteractCfg or {}
  if Cfg.raycast and Cfg.raycast.enabled then
    local cam = GetGameplayCamCoord()
    local dir = RotAnglesToVec(GetGameplayCamRot(2))
    local dist = (Cfg.raycast.maxDist or 4.0)
    local to = vector3(cam.x + dir.x*dist, cam.y + dir.y*dist, cam.z + dir.z*dist)
    local ray = StartShapeTestRay(cam.x, cam.y, cam.z, to.x, to.y, to.z, 10, ped, 0)
    local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if hit==1 and entityHit and entityHit ~= 0 and DoesEntityExist(entityHit) then
      local cls = classOfEntity(entityHit)
      if (cls=='vehicle' and C.entities.vehicle) or (cls=='ped' and C.entities.ped) or (cls=='prop' and C.entities.prop) then
        return { entity=entityHit, etype=cls, coords=GetEntityCoords(entityHit), owned=isOwned(entityHit), friendly=(cls=='ped' and isFriendlyPed(entityHit)) or nil }
      end
    end
  end
  -- fallback: closest vehicle
  local veh = GetClosestVehicle(px,py,pz, (C.scan and C.scan.entityRadius or 3.0), 0, 70)
  if veh ~= 0 and DoesEntityExist(veh) then
    return { entity=veh, etype='vehicle', coords=GetEntityCoords(veh), owned=isOwned(veh) }
  end
  return nil
end


-- ===== Poll loop exposing current context =====
FW.Interact._ctx = { hit=nil }

CreateThread(function()
  while true do
    local ped = PlayerPedId()
    local px,py,pz = table.unpack(GetEntityCoords(ped))
    local ctx = { hit=nil }
    local z = detectZone(px,py,pz)
    if z then
      ctx.hit='zone'; ctx.zone=z; ctx.kind = z.meta and z.meta.kind or nil; ctx.bench = z.meta and z.meta.bench or nil
    else
      local e = detectEntity(px,py,pz)
      if e then ctx.hit='entity'; ctx.entity=e.entity; ctx.etype=e.etype; ctx.coords=e.coords end
    end
    FW.Interact._ctx = ctx
    Wait((C.scan and C.scan.pollMs) or 200)
  end
end)

RegisterNetEvent('fw:nui:open', function(packet)
  if not packet or not packet.type then return end
  SendNUIMessage({ type = packet.type, payload = packet.payload })
  if packet.type == 'radial:open' or packet.type == 'id:open' or packet.type == 'ward:open' or packet.type == 'trader:open' or packet.type == 'stash:open' or packet.type == 'craft:open' then
    SetNuiFocus(true, true)
  end
  if packet.type == 'radial:close' or packet.type == 'id:close' or packet.type == 'ward:close' or packet.type == 'trader:close' or packet.type == 'stash:close' or packet.type == 'craft:close' then
    SetNuiFocus(false, false)
  end
end)

return SRC
