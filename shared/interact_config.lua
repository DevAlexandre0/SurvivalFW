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
