fx_version 'cerulean'
game 'gta5'

author 'FT Development'
description 'Advanced Queue System for FiveM'
version '1.0.0'

shared_scripts {
    'config.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/database.lua',
    'server/server.lua'
}

dependencies {
    'oxmysql'
}
