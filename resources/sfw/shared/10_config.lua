FW = FW or {}; FW.DB = FW.DB or {}; FW.DB.players = FW.DB.players or {}
FW = FW or {}
FW.Clothing = {
  insulation = {
    jacket_warm = 0.35, coat_wool = 0.45, sweater = 0.2, raincoat = 0.1,
    boots_leather = 0.05, hat_wool = 0.08, gloves = 0.03
  },
  wetPenalty = 0.6
}
FW = FW or {}
FW.Durability = {
  weaponPerShot = 0.15,
  weaponHeatFactor = 0.005,
  clothingWetWear = 0.02,
  toolUseWear = 0.5,
  minCondToJamMul = 0.6,
}
FW = FW or {}
FW.Env = {
  baseTempC = 22.0, diurnal = { day=6.0, night=-4.0 }, altitudeLapse = -0.0065,
  indoorBonus = 2.0, rainWetRate = 6.0, rainTempDrop = -4.0,
  windChillAt = 6.0, windChillMul = -0.25,
  dryRateIdle = 1.2, dryRateWindMul = 0.4, wetFromWater = 15.0,
  staminaDrainSprint = 3.0, staminaRegenIdle = 2.0, overweightPenaltyMul = 2.0,
  hypoThresh = 8.0, hyperThresh = 33.0, tempHpTick = 0.5,
}
FW = FW or {}
FW.Trader = {
  currency = 'caps',
  basePrices = {
    ammo_556=120, ammo_762=140, ammo_9=60, ammo_45=70,
    med_bandage=30, med_charcoal=45, fuel_can=250, car_battery=600,
    cloth=6, stick=2, wood=12, scrap=8
  },
  minStock = 2, maxStock = 20, restockPerHour = 0.15, priceVolatility = 0.25
}
FW = FW or {}
FW.Crafting = {
  benches = {
    work = { label='Workbench', radius=3.0, points = { {x=2329.4,y=2571.2,z=46.6} } },
    chem  = { label='ChemBench', radius=3.0, points = { {x=2332.0,y=2570.0,z=46.6} } },
    garage= { label='Garage',    radius=5.0, points = { {x=2335.0,y=2572.5,z=46.6} } },
  },
  recipes = {
    bandage = { bench='work', in_={ cloth=2 }, out_={ med_bandage=1 }, time=4 },
    splint  = { bench='work', in_={ stick=2, cloth=1 }, out_={ splint=1 }, time=6 },
    charcoal= { bench='chem', in_={ wood=3 }, out_={ med_charcoal=1 }, time=8 },
    kitrepair  = { bench='work', in_={ scrap=12, cloth=1 }, out_={ repair_kit=1 }, time=8 },
  }
}
FW = FW or {}
FW.Items = {
  cloth = { label='Cloth', weight=0.2, desc='Torn cloth for bandage/crafting' },
  stick = { label='Stick', weight=0.5, desc='Primitive crafting material' },
  wood = { label='Wood', weight=1.0, desc='Fuel and crafting' },
  scrap = { label='Scrap', weight=0.6, desc='Random metal parts' },
  med_bandage = { label='Bandage', weight=0.1, desc='Stop bleeding' },
  med_charcoal = { label='Charcoal tablets', weight=0.05, desc='Treat poisoning' },
  ammo_556 = { label='5.56mm', weight=0.012, desc='Rifle ammo' },
  ammo_762 = { label='7.62mm', weight=0.015, desc='Rifle ammo' },
  ammo_9   = { label='9mm', weight=0.009, desc='Pistol ammo' },
  ammo_45  = { label='.45 ACP', weight=0.011, desc='Pistol ammo' },
  fuel_can = { label='Fuel Can', weight=8.0, desc='Portable fuel' },
  car_battery = { label='Car Battery', weight=12.0, desc='Vehicle power' },
  caps = { label='Caps', weight=0.0, desc='Currency' },
}
FW = FW or {}
FW.MedDepth = {
  fractureChance = 0.2,
  morphinePainRelief = 40,
  painkillerRelief = 20,
  fractureMovePenalty = 0.3,
  splintDuration = 1800,
  infectionTick = 0.15,
}
FW.MedBleed = {
  bandageReduce = 1,
  tourniquetReduce = 2,
  tourniquetTime = 120,
  hpLossPerTick = {0,1,2,4},
  fatiguePerTick = {0,1,2,3},
  infectionPerTick = {0,0.3,0.6,1.0},
}
FW = FW or {}
FW.Interact = {
  trader = {
    -- Add as many stations as you want
    { x=2331.6, y=2568.9, z=46.7, radius=1.6, label='Trader Terminal' },
  },
  stash = {
    { x=2328.9, y=2570.8, z=46.7, radius=1.4, label='Stash Locker' },
  },
  craft = function()
    -- Use benches from Crafting config as interactive points
    local pts = {}
    for id,b in pairs((FW.Crafting and FW.Crafting.benches) or {}) do
      for _,p in ipairs(b.points or {}) do table.insert(pts, { x=p.x, y=p.y, z=p.z, radius=1.6, label='Craft: '..(b.label or id), bench=id }) end
    end
    return pts
  end
}
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
FW = FW or {}
FW.WildlifeCfg = {
  maxGlobal = 22,
  perPlayer = 5,
  despawnRange = 220.0,
  spawnRadius = { min=45.0, max=140.0 },

  species = {
    deer    = { model='a_c_deer',      day=1.0, night=0.6, rain=0.8, tempMin=5,  tempMax=35 },
    boar    = { model='a_c_boar',      day=0.8, night=1.0, rain=0.7, tempMin=0,  tempMax=40 },
    coyote  = { model='a_c_coyote',    day=0.7, night=1.2, rain=0.9, tempMin=-5, tempMax=40 },
    rabbit  = { model='a_c_rabbit_01', day=1.2, night=0.8, rain=1.0, tempMin=0,  tempMax=45 },
  },

  -- Biomes with polygon + altitude band (height 'minZ'..'maxZ'). Coordinates are example placeholders.
  poiNoSpawn = { -- points of interest radius (no-spawn)
    -- {x=2000,y=3000,r=120},
  },
  blacklist = {
    -- example: water or safe zone
    -- { {x1,y1}, {x2,y2}, {x3,y3} }
  },
  biomes = {
    forest = { priority=10, w=3,
      polys = { { {1200,2100},{2800,2100},{3000,3500},{1500,4000},{1100,3200} }, { {1800,2200},{2000,2400},{1900,2600} } },
      poly = { {1200,2100},{2800,2100},{3000,3500},{1500,4000},{1100,3200} },
      minZ = 20.0, maxZ = 2000.0,
      weights = { deer=3, rabbit=2, coyote=1 }
    },
    scrub = { priority=5, w=2,
      polys = { { {-1400,1200},{400,1200},{400,3200},{-1400,3200} } },
      poly = { {-1400,1200},{400,1200},{400,3200},{-1400,3200} },
      minZ = 10.0, maxZ = 2000.0,
      weights = { boar=2, coyote=2, rabbit=1 }
    },
    urban = { priority=8, w=1,
      polys = { { {-1800,-1800},{400,-1800},{400,400},{-1800,400} } },
      poly = { {-1800,-1800},{400,-1800},{400,400},{-1800,400} },
      minZ = 0.0, maxZ = 400.0,
      weights = { coyote=1, rabbit=1 }
    },
    highlands = { priority=9, w=2,
      polys = { { {2000,4000},{3800,4200},{4200,5200},{2600,5400} } },
      poly = { {2000,4000},{3800,4200},{4200,5200},{2600,5400} },
      minZ = 600.0, maxZ = 3000.0,
      weights = { deer=2, coyote=1, rabbit=1 }
    }
  },
}
FW = FW or {}
FW.InteractCfg = {
  enabled = true,
  keyOpen = 38,          -- E
  keyBack = 177,         -- BACKSPACE
  keyUp   = 172,         -- ARROW UP
  keyDown = 173,         -- ARROW DOWN
  keyLeft = 174,         -- ARROW LEFT
  keyRight= 175,         -- ARROW RIGHT,
  scan = {
    entityRadius = 3.2,
    zoneRadius   = 2.0,
    raycast      = true,
    pollMs       = 200
  },
  ui = { layout = 'list', -- 'list' | 'radial'
    tooltip = true, progress = true,
    theme = 'neon-green',
    showHints = true
  },
  -- Default zones (augment from config_interact + crafting benches at runtime)
  zones = {
    trader = { { x=2331.6, y=2568.9, z=46.7, r=1.6, label='Trader Terminal' } },
    stash  = { { x=2328.9, y=2570.8, z=46.7, r=1.4, label='Stash Locker' } }
  },
  -- Quick keybinds per action id (optional; press key when in context to trigger)
  actionKeys = {
    veh_repair = 311,   -- K
    veh_trunk  = 182,   -- L
    veh_siphon = 170    -- F3
  },

  -- Entity scanning details
  entities = { vehicle=true, ped=true, prop=true },
  raycast = { enabled=true, maxDist=4.0 },

  -- Relationship filtering (example; can be extended)
  filter = { friendlyOnly=false, hostileOnly=false, ownedOnly=false }
}
return C
