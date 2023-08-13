fx_version 'cerulean'
game 'gta5'

description 'QBX-Scrapyard'
version '1.0.0'

shared_script {
    '@ox_lib/init.lua',
    '@qbx-core/shared/locale.lua',
    '@qbx-core/import.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua',
}

modules {
    'qbx-core:core',
    'qbx-core:utils'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_script 'client/main.lua'

provide 'qb-scrapyard'
lua54 'yes'
use_experimental_fxv2_oal 'yes'