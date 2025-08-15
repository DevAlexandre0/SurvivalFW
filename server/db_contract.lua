FW = FW or {}; FW.DB = FW.DB or {}
FW.DB.Contract = {
  players = { table="players", cols={"identifier","display_name","role","health","stamina","hunger","thirst","temperature_c","created_at","updated_at"}, pk="identifier" },
  items = { table="items", cols={"item_key","label","stackable","max_stack","base_weight","base_dura","rarity","icon","tags","desc_long"}, pk="item_key" },
  containers = { table="containers", cols={"container_id","type","owner_ident","ref","slots","weight_limit","created_at"}, pk="container_id" },
  container_slots = { table="container_slots", cols={"container_id","slot_index","locked","tag"}, pk={"container_id","slot_index"} },
  stacks = { table="stacks", cols={"stack_id","container_id","slot_index","item_key","quantity","durability","metadata","state_hash","weight_cached","created_at","updated_at"}, pk="stack_id" },
  inv_tx = { table="inv_tx", cols={"tx_id","identifier","action","item_key","qty","from_cont","from_slot","to_cont","to_slot","stack_id","context","created_at"}, pk="tx_id" },
  recipes = { table="recipes", cols={"recipe_key","label","bench_tier","output_item","output_qty","time_ms","meta"}, pk="recipe_key" },
  recipe_ingredients = { table="recipe_ingredients", cols={"id","recipe_key","item_key","qty","meta"}, pk="id" },
  traders = { table="traders", cols={"trader_id","name","pos","meta"}, pk="trader_id" },
  trader_prices = { table="trader_prices", cols={"id","trader_id","item_key","price_buy","price_sell","scarcity","updated_at"}, pk="id" },
  trader_price_history = { table="trader_price_history", cols={"id","trader_id","item_key","price","scarcity","ts"}, pk="id" },
  effects_active = { table="effects_active", cols={"id","identifier","effect_type","severity","body_part","meta","started_at","expires_at"}, pk="id" },
  med_injuries = { table="med_injuries", cols={"id","identifier","injury_type","body_part","severity","treated","meta","created_at","resolved_at"}, pk="id" },
  med_snapshots = { table="med_snapshots", cols={"id","identifier","snapshot","created_at"}, pk="id" },
  player_skills = { table="player_skills", cols={"identifier","skill_key","level","xp"}, pk={"identifier","skill_key"} },
  skill_events = { table="skill_events", cols={"id","identifier","skill_key","delta","reason","context","created_at"}, pk="id" },
  biomes = { table="biomes", cols={"biome_id","name","priority","weight","height_min","height_max","weather","meta"}, pk="biome_id" },
  biome_polygons = { table="biome_polygons", cols={"id","biome_id","polygon","blacklist"}, pk="id" },
  wildlife_rules = { table="wildlife_rules", cols={"rule_id","biome_id","species","density","night_mult","rain_mult","group_min","group_max","no_spawn_radius","meta"}, pk="rule_id" },
}
return FW.DB.Contract
