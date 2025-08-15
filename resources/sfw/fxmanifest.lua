fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'SFW Team'
description 'SurvivalFW consolidated refactor v1.3.1'
version '1.3.1'

provide 'SurvivalFW'

ui_page 'nui/sfw_shell/index.html'
files { 'nui/sfw_shell/*.*' }

shared_scripts {
  'shared/10_config.lua',
  'shared/20_utils.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/00_core_boot.lua',
  'server/00_db_collation.lua',
  'server/00_db_wrappers.lua',
  'server/00_acl.lua',
  'server/00_shims.lua',
  'server/00_fw_db_boot.lua',
  'server/01_db_players.lua',
  'server/10_spawn.lua',
  'server/11_identity.lua',
  'server/20_med.lua',
  'server/30_inventory.lua',
  'server/40_trader.lua',
  'server/50_stash.lua',
  'server/60_environment.lua',
  'server/70_player_state.lua',
  'server/80_admin.lua',
  'server/90_metrics.lua',
  'server/99_db_guard.lua'
}

client_scripts {
  '@spawnmanager/client/spawnmanager.lua',
  'client/00_boot.lua',
  'client/01_utils.lua',
  'client/10_spawn.lua',
  'client/11_identity.lua',
  'client/12_appearance.lua',
  'client/20_inventory.lua',
  'client/30_interaction.lua',
  'client/40_ui.lua',
  'client/60_wildlife.lua',
  'client/70_env.lua',
  'client/90_admin.lua',
  'client/95_weap_debug.lua'
}
