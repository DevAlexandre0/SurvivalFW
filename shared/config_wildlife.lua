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
