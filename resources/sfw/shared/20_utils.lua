FW = FW or {}
FW.RL = FW.RL or {}
local buckets = {}
function FW.RL.Check(src, key, interval)
	local now = GetGameTimer()
	local b = buckets[src] or {}
	buckets[src] = b
	local last = b[key]
	if last and now - last < interval then
		return false
	end
	b[key] = now
	return true
end
-- Returns compatibility matrix to be loaded server+client
-- Structure:
-- { weapons = { CLASS = { hashes={...}, mags={...}, anims={...} } }, magDefs = { TYPE = { cap, label, caliber } } }
return {
  weapons = {
    CARBINE = {
      hashes = { 'WEAPON_CARBINERIFLE', 'WEAPON_CARBINERIFLE_MK2' },
      mags   = { 'STANAG30','STANAG60','STANAG100' },
      anims  = { swap={dict='anim@mp_player_intmenu@key_fob@',name='fob_click'}, fill={dict='amb@world_human_security_shine_torch@male@base',name='base'}, unload={dict='amb@world_human_stand_fishing@idle_a',name='idle_c'} }
    },
    PISTOL9 = {
      hashes = { 'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL' },
      mags   = { '9MM15','9MM33' },
      anims  = { swap={dict='anim@mp_player_intmenu@key_fob@',name='fob_click'}, fill={dict='amb@world_human_cop_idles@male@idle_b',name='idle_d'}, unload={dict='amb@world_human_hang_out_street@male_c@base',name='base'} }
    }
  },
  magDefs = {
    STANAG30  = { cap=30, label='STANAG 30', caliber='556' },
    STANAG60  = { cap=60, label='STANAG 60', caliber='556' },
    STANAG100 = { cap=100, label='C-Mag 100', caliber='556' },
    ['9MM15'] = { cap=15, label='9mm 15', caliber='9' },
    ['9MM33'] = { cap=33, label='9mm 33', caliber='9' },
  }
}
