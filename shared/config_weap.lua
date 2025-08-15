-- SurvivalFW — Weapons Config (mag/weapon compatibility)
FW = FW or {}; FW.Weap = FW.Weap or {}

local C = {
  mags = {
    mag_pistol_std = { caliber = "9mm", capacity = 15, fill_time_ms = 900, unload_time_ms = 600 },
    mag_rifle_30   = { caliber = "556", capacity = 30, fill_time_ms = 1400, unload_time_ms = 1000 },
    mag_rifle_60   = { caliber = "556", capacity = 60, fill_time_ms = 2200, unload_time_ms = 1500 }
  },
  weapons = {
    WEAPON_PISTOL        = { caliber = "9mm", chamber_size = 1, compatible_mags = { "mag_pistol_std" }, reload_time_ms = 1600 },
    WEAPON_CARBINERIFLE  = { caliber = "556", chamber_size = 1, compatible_mags = { "mag_rifle_30", "mag_rifle_60" }, reload_time_ms = 2200 }
  },
  jams = {
    base_jam_chance = 0.004,   -- 0.4% baseline
    dura_threshold  = 20       -- durability under this increases jam chance
  }
}

FW.Weap.Config = C
return C
