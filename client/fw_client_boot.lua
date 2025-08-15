local function setFreemode(model)
  local m = model or 'mp_m_freemode_01'
  local hash = GetHashKey(m)
  if not IsModelInCdimage(hash) or not IsModelValid(hash) then return end
  RequestModel(hash); while not HasModelLoaded(hash) do Wait(0) end
  SetPlayerModel(PlayerId(), hash)
  SetModelAsNoLongerNeeded(hash)
end

local function ping()
  TriggerServerEvent('fw:id:ready')
  TriggerServerEvent('fw:wardrobe:pull')
end

AddEventHandler('onClientResourceStart', function(res)
  if res == GetCurrentResourceName() then
    SetNuiFocus(false, false)
    Wait(800)
    setFreemode('mp_m_freemode_01')
    Wait(400)
    ping()
  end
end)

AddEventHandler('playerSpawned', function()
  Wait(500)
  setFreemode('mp_m_freemode_01')
  Wait(300)
  ping()
end)
