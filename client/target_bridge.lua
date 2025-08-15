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
