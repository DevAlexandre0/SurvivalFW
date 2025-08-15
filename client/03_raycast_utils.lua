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
