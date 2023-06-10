fx_version 'cerulean'
game 'gta5'

description 'QBX-Scrapyard'
version '1.0.0'

shared_script {
    '@ox_lib/init.lua',
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/ComboZone.lua',
    'config.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua', -- Change to the language you want
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

client_script 'client/main.lua'

provide 'qb-scrapyard'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
