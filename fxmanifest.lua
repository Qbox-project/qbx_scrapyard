fx_version 'cerulean'
game 'gta5'

description 'QBX_Scrapyard'
repository 'https://github.com/Qbox-project/qbx_scrapyard'
version '1.0.0'

ox_lib 'locale'

shared_script {
    '@ox_lib/init.lua',
    '@qbx_core/modules/lib.lua',
}

client_script 'client/main.lua'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

files {
    'config/client.lua',
    'locales/*.json',
}

provide 'qb-scrapyard'
lua54 'yes'
use_experimental_fxv2_oal 'yes'