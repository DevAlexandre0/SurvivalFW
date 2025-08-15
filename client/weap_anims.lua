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
