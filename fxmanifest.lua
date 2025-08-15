fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'SFW Team'
description 'SurvivalFW consolidated refactor v1.3.1'
version '1.3.1'

ui_page 'nui/sfw_shell/index.html'
files { 'nui/sfw_shell/*.*' }

shared_scripts {
  'shared/00_init.lua',
  'shared/*.lua'
}

server_scripts {
  '@oxmysql/lib/MySQL.lua',
  'server/00_core_boot.lua',
  'server/01_db_players.lua',
  'server/10_spawn.lua',
  'server/11_identity.lua',
  'server/20_med.lua',
  'server/*.lua'
}

client_scripts {
  '@spawnmanager/client/spawnmanager.lua',
  'client/00_boot.lua',
  'client/10_spawn.lua',
  'client/11_identity.lua',
  'client/12_appearance.lua',
  'client/*.lua'
}
