-- SurvivalFW consolidated schema
-- Create all necessary tables for players, inventory, trading, crafting,
-- medical, environment and related systems.

-- Players and identity
CREATE TABLE IF NOT EXISTS players (
  identifier      VARCHAR(64) PRIMARY KEY,
  display_name    VARCHAR(64) NOT NULL,
  role            VARCHAR(32) NOT NULL DEFAULT 'user',
  health          INT NOT NULL DEFAULT 100,
  stamina         INT NOT NULL DEFAULT 100,
  hunger          INT NOT NULL DEFAULT 0,
  thirst          INT NOT NULL DEFAULT 0,
  temperature_c   DECIMAL(5,2) NOT NULL DEFAULT 37.00,
  pos_x           DECIMAL(10,4) NULL,
  pos_y           DECIMAL(10,4) NULL,
  pos_z           DECIMAL(10,4) NULL,
  pos_h           DECIMAL(6,2)  NULL,
  appearance_set  TINYINT(1) NOT NULL DEFAULT 0,
  citizen_id      VARCHAR(32) UNIQUE,
  first_name      VARCHAR(64),
  last_name       VARCHAR(64),
  dob             DATE,
  sex             CHAR(1),
  height_cm       INT,
  blood_type      VARCHAR(16),
  nationality     VARCHAR(32),
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS player_appearance (
  identifier  VARCHAR(64) PRIMARY KEY,
  model       VARCHAR(64) NOT NULL,
  components  TEXT NOT NULL,
  props       TEXT,
  outfit_tag  VARCHAR(64),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Item definitions
CREATE TABLE IF NOT EXISTS items (
  item_key     VARCHAR(64) PRIMARY KEY,
  label        VARCHAR(64) NOT NULL,
  stackable    TINYINT(1) NOT NULL DEFAULT 1,
  max_stack    INT NOT NULL DEFAULT 20,
  base_weight  DECIMAL(10,3) NOT NULL DEFAULT 0,
  base_dura    INT NOT NULL DEFAULT 100,
  rarity       VARCHAR(32),
  icon         VARCHAR(64),
  tags         TEXT,
  desc_long    TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Inventory containers and slots
CREATE TABLE IF NOT EXISTS containers (
  container_id INT AUTO_INCREMENT PRIMARY KEY,
  type         VARCHAR(32) NOT NULL,
  owner_ident  VARCHAR(64),
  ref          VARCHAR(64),
  slots        INT NOT NULL,
  weight_limit DECIMAL(10,2) NOT NULL DEFAULT 0,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_owner (owner_ident),
  KEY idx_ref   (ref)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS container_slots (
  container_id INT NOT NULL,
  slot_index   INT NOT NULL,
  locked       TINYINT(1) NOT NULL DEFAULT 0,
  tag          TEXT,
  PRIMARY KEY (container_id, slot_index),
  CONSTRAINT fk_slots_container FOREIGN KEY (container_id) REFERENCES containers(container_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stacks (
  stack_id      INT AUTO_INCREMENT PRIMARY KEY,
  container_id  INT NOT NULL,
  slot_index    INT NOT NULL,
  item_key      VARCHAR(64) NOT NULL,
  quantity      INT NOT NULL DEFAULT 1,
  durability    INT NOT NULL DEFAULT 100,
  metadata      TEXT,
  state_hash    VARCHAR(64) DEFAULT '',
  weight_cached DECIMAL(10,3) NOT NULL DEFAULT 0,
  created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  KEY idx_container_slot (container_id, slot_index),
  KEY idx_container_item (container_id, item_key),
  CONSTRAINT fk_stack_container FOREIGN KEY (container_id) REFERENCES containers(container_id) ON DELETE CASCADE,
  CONSTRAINT fk_stack_item FOREIGN KEY (item_key) REFERENCES items(item_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inv_tx (
  tx_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(64) NOT NULL,
  action     VARCHAR(16) NOT NULL,
  item_key   VARCHAR(64) NOT NULL,
  qty        INT NOT NULL,
  from_cont  INT,
  from_slot  INT,
  to_cont    INT,
  to_slot    INT,
  stack_id   INT,
  context    TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_invtx_ident (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Crafting
CREATE TABLE IF NOT EXISTS recipes (
  recipe_key  VARCHAR(64) PRIMARY KEY,
  label       VARCHAR(64) NOT NULL,
  bench_tier  INT NOT NULL DEFAULT 0,
  output_item VARCHAR(64) NOT NULL,
  output_qty  INT NOT NULL DEFAULT 1,
  time_ms     INT NOT NULL DEFAULT 0,
  meta        TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS recipe_ingredients (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  recipe_key VARCHAR(64) NOT NULL,
  item_key   VARCHAR(64) NOT NULL,
  qty        INT NOT NULL,
  meta       TEXT,
  KEY idx_recipe (recipe_key),
  CONSTRAINT fk_ing_recipe FOREIGN KEY (recipe_key) REFERENCES recipes(recipe_key) ON DELETE CASCADE,
  CONSTRAINT fk_ing_item FOREIGN KEY (item_key) REFERENCES items(item_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Trading
CREATE TABLE IF NOT EXISTS traders (
  trader_id INT AUTO_INCREMENT PRIMARY KEY,
  name      VARCHAR(64) NOT NULL,
  pos       TEXT,
  meta      TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS trader_prices (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  trader_id  INT NOT NULL,
  item_key   VARCHAR(64) NOT NULL,
  price_buy  INT NOT NULL,
  price_sell INT NOT NULL,
  scarcity   DECIMAL(6,2) NOT NULL DEFAULT 1.00,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uniq_trader_item (trader_id, item_key),
  KEY idx_price_item (item_key),
  CONSTRAINT fk_tp_trader FOREIGN KEY (trader_id) REFERENCES traders(trader_id) ON DELETE CASCADE,
  CONSTRAINT fk_tp_item FOREIGN KEY (item_key) REFERENCES items(item_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS trader_price_history (
  id        BIGINT AUTO_INCREMENT PRIMARY KEY,
  trader_id INT NOT NULL,
  item_key  VARCHAR(64) NOT NULL,
  price     INT NOT NULL,
  scarcity  DECIMAL(6,2) NOT NULL DEFAULT 1.00,
  ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_tph_trader (trader_id),
  KEY idx_tph_item (item_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS market_config (
  id            INT PRIMARY KEY,
  ema_alpha     DECIMAL(5,2) NOT NULL DEFAULT 0.25,
  weekly_decay  DECIMAL(5,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Medical
CREATE TABLE IF NOT EXISTS effects_active (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  identifier  VARCHAR(64) NOT NULL,
  effect_type VARCHAR(32) NOT NULL,
  severity    INT NOT NULL,
  body_part   VARCHAR(32) NOT NULL,
  meta        TEXT,
  started_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at  TIMESTAMP NULL,
  KEY idx_effect_ident (identifier),
  KEY idx_effect_type (effect_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS med_injuries (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  identifier  VARCHAR(64) NOT NULL,
  injury_type VARCHAR(32) NOT NULL,
  body_part   VARCHAR(32) NOT NULL,
  severity    INT NOT NULL,
  treated     TINYINT(1) NOT NULL DEFAULT 0,
  meta        TEXT,
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  resolved_at TIMESTAMP NULL,
  KEY idx_injury_ident (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS med_snapshots (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(64) NOT NULL,
  snapshot   TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_snapshot_ident (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Skills
CREATE TABLE IF NOT EXISTS player_skills (
  identifier VARCHAR(64) NOT NULL,
  skill_key  VARCHAR(64) NOT NULL,
  level      INT NOT NULL DEFAULT 0,
  xp         INT NOT NULL DEFAULT 0,
  PRIMARY KEY (identifier, skill_key)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS skill_events (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  identifier VARCHAR(64) NOT NULL,
  skill_key  VARCHAR(64) NOT NULL,
  delta      INT NOT NULL,
  reason     VARCHAR(64) NOT NULL,
  context    TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  KEY idx_skill_evt_ident (identifier)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Environment
CREATE TABLE IF NOT EXISTS biomes (
  biome_id   INT AUTO_INCREMENT PRIMARY KEY,
  name       VARCHAR(64) NOT NULL,
  priority   INT NOT NULL DEFAULT 0,
  weight     DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  height_min INT,
  height_max INT,
  weather    VARCHAR(64),
  meta       TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS biome_polygons (
  id        INT AUTO_INCREMENT PRIMARY KEY,
  biome_id  INT NOT NULL,
  polygon   TEXT NOT NULL,
  blacklist TINYINT(1) NOT NULL DEFAULT 0,
  KEY idx_poly_biome (biome_id),
  CONSTRAINT fk_poly_biome FOREIGN KEY (biome_id) REFERENCES biomes(biome_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS wildlife_rules (
  rule_id        INT AUTO_INCREMENT PRIMARY KEY,
  biome_id       INT NOT NULL,
  species        VARCHAR(64) NOT NULL,
  density        DECIMAL(5,2) NOT NULL DEFAULT 0.25,
  night_mult     DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  rain_mult      DECIMAL(5,2) NOT NULL DEFAULT 1.00,
  group_min      INT NOT NULL DEFAULT 1,
  group_max      INT NOT NULL DEFAULT 1,
  no_spawn_radius INT NOT NULL DEFAULT 0,
  meta           TEXT,
  KEY idx_rule_biome (biome_id),
  CONSTRAINT fk_rule_biome FOREIGN KEY (biome_id) REFERENCES biomes(biome_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Stash ownership (optional)
CREATE TABLE IF NOT EXISTS myfw_stash (
  stash_id INT PRIMARY KEY,
  owner    VARCHAR(64)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
