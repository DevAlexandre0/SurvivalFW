RegisterNetEvent('fw:player:register_mode', function(enabled)
  local ped = PlayerPedId()
  if enabled then SetEntityVisible(ped,false,false); FreezeEntityPosition(ped,true)
  else FreezeEntityPosition(ped,false); SetEntityVisible(ped,true,false) end
end)
RegisterNetEvent('fw:nui:open', function(packet)
  if not packet or not packet.type then return end
  SendNUIMessage(packet)
  if packet.type:find(':open',1,true) then SetNuiFocus(true,true) end
  if packet.type:find(':close',1,true) then SetNuiFocus(false,false) end
end)
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
