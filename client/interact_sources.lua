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

return SRC
