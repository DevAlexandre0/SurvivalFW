RegisterNetEvent('fw:inv:toast', function(msg)
  SendNUIMessage({action='inv:toast', text=msg})
end)

RegisterNUICallback('inv:moveStrict', function(d, cb)
  TriggerServerEvent('fw:inv:moveStrict', d)
  cb({ ok = true })
end)
RegisterNUICallback('inv:move', function(data, cb) -- passthrough to server (already registered there)
  cb({ ok=true })
end)
RegisterNetEvent('fw:player:register_mode', function(enabled)
  local ped = PlayerPedId()
  if enabled then
    SetEntityVisible(ped, false, false)
    FreezeEntityPosition(ped, true)
  else
    FreezeEntityPosition(ped, false)
    SetEntityVisible(ped, true, false)
  end
end)

RegisterCommand('fw_unhide', function()
  local ped = PlayerPedId()
  FreezeEntityPosition(ped, false)
  SetEntityVisible(ped, true, false)
end, false)
local state = { weapon = 'DEMO', mag = 0, chamber = 0, jam = false }

local function push()
  TriggerEvent('fw:weap:state', state)
end

RegisterCommand('magfill', function()
  state.mag = 30
  state.chamber = 1
  state.jam = false
  push()
end, false)

RegisterCommand('magunload', function()
  state.mag = 0
  state.chamber = 0
  push()
end, false)

RegisterCommand('swapmag', function()
  state.mag = math.random(5, 30)
  push()
end, false)

RegisterCommand('weapjam', function()
  state.jam = not state.jam
  push()
end, false)

-- Example hooks: In your weapon handling, trigger these appropriately.
-- Here we simulate for testing with simple commands.

RegisterCommand('weap_state', function(_, args)
  local wtype = args[1] or 'AR'
  local cap = tonumber(args[2] or '30')
  local rounds = tonumber(args[3] or '30')
  local chamber = tonumber(args[4] or '1')
  SendNUIMessage({ type='update', wtype=wtype, wmagMax=cap, wmagRounds=rounds, wchamber=chamber })
  TriggerServerEvent('fw:weap:update', { wtype=wtype, magMax=cap, magRounds=rounds, chamber=chamber, cond=100.0, heat=0.0, jam=false })
end, false)

RegisterCommand('weap_shot', function(_, args)
  local q = (args[1] or 'normal') -- ammo quality
  TriggerServerEvent('fw:weap:shot', q)
end, false)

RegisterCommand('weap_clear', function() TriggerServerEvent('fw:weap:clearjam') end, false)
RegisterCommand('weap_swap', function(_, args) TriggerServerEvent('fw:weap:swapmag', tonumber(args[1] or '30'), tonumber(args[2] or '30')) end, false)
local function hash(name) return GetHashKey(name) end
local map = (FW and FW.WeapCompat and FW.WeapCompat.weapons) or {}

local lastClass = nil
CreateThread(function()
  while true do
    Wait(1000)
    map = (FW and FW.WeapCfg and FW.WeapCfg.weapons) or map
    local ped = PlayerPedId()
    local w = GetSelectedPedWeapon(ped)
    local found = nil
    for cls,def in pairs(map or {}) do
      for _,n in ipairs(def.hashes or {}) do
        if w == hash(n) then found = cls break end
      end
      if found then break end
    end
    if found ~= lastClass then
      lastClass = found
      if LocalPlayer and LocalPlayer.state then LocalPlayer.state:set('fw_wclass', found, true) end
      TriggerServerEvent('fw:weap:update', { wtype = found or '-' })
    end
  end
end)


RegisterNetEvent('fw:weap:compat:update', function(mat)
  FW = FW or {}
  FW.WeapCompat = mat or {}
end)
local function play(dict, name, time)
  if not dict or not name then return end
  RequestAnimDict(dict); local t=0
  while not HasAnimDictLoaded(dict) and t<2000 do Wait(10); t=t+10 end
  TaskPlayAnim(PlayerPedId(), dict, name, 4.0, 4.0, math.ceil((time or 1500)), 49, 0, false, false, false)
end

RegisterNetEvent('fw:weap:anim', function(action, ms)
  local cfg = (FW and FW.WeapCfg and FW.WeapCfg.weapons) or {}
  local wclass = LocalPlayer and LocalPlayer.state and LocalPlayer.state.fw_wclass
  local anim = nil
  if wclass and cfg[wclass] and cfg[wclass].anims then anim = cfg[wclass].anims[action] end
  if not anim then
    -- fallback generic anims
    if action=='swap' then play('anim@mp_player_intmenu@key_fob@', 'fob_click', ms)
    elseif action=='fill' then play('amb@world_human_cop_idles@male@idle_b', 'idle_d', ms)
    elseif action=='unload' then play('amb@world_human_hang_out_street@male_c@base', 'base', ms)
    else play('amb@world_human_cop_idles@male@idle_b', 'idle_d', ms) end
  else
    play(anim.dict, anim.name, ms)
  end
end)
