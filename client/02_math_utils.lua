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
