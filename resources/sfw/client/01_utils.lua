-- SFW Math Utils — define RotAnglesToVec and helpers globally (load before interact_*)
FW = FW or {}

if not RotAnglesToVec then
  ---Convert GTA rotation (deg) to direction vector.
  ---@param rot vector3
  ---@return vector3
  function RotAnglesToVec(rot)
    local radX = math.rad(rot.x)
    local radZ = math.rad(rot.z)
    local cosX = math.cos(radX)
    -- FiveM forward: X to the right, Y forward; signs tuned for gameplay cam
    return vector3(-math.sin(radZ) * cosX, math.cos(radZ) * cosX, math.sin(radX))
  end
end

if not FW.RotationToDirection then
  function FW.RotationToDirection(rot) return RotAnglesToVec(rot) end
end

if not FW.ForwardFromCam then
  function FW.ForwardFromCam()
    local camRot = GetGameplayCamRot(2)
    return RotAnglesToVec(camRot)
  end
end
-- SFW Raycast Utils — safe camera raycast with timeout (prevents freeze)
FW = FW or {}; FW.Raycast = FW.Raycast or {}

---Raycast forward from gameplay cam with a safe timeout.
---@param dist number|nil
---@param flags number|nil
---@param ignoreEntity number|nil
---@return boolean hit, vector3 endCoords, number entity, vector3 normal
function FW.Raycast.FromCamera(dist, flags, ignoreEntity)
  dist = dist or 5.0
  flags = flags or 511 -- everything
  local from = GetGameplayCamCoord()
  local dir  = RotAnglesToVec(GetGameplayCamRot(2))
  local to   = vector3(from.x + dir.x*dist, from.y + dir.y*dist, from.z + dir.z*dist)

  local ped = PlayerPedId()
  local ray = StartShapeTestRay(from.x, from.y, from.z, to.x, to.y, to.z, flags, ignoreEntity or ped, 7)
  local t0 = GetGameTimer()
  while true do
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(ray)
    if retval ~= 1 then
      return hit == 1, endCoords, entityHit or 0, surfaceNormal or vector3(0.0,0.0,1.0)
    end
    if (GetGameTimer() - t0) > 250 then
      -- Timeout fallback to avoid infinite wait
      return false, to, 0, vector3(0.0,0.0,1.0)
    end
    Wait(0)
  end
end
