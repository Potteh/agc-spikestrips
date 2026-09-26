fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'AGC'
description 'QBCore police spike strip deployment system'
version '1.0.0'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}

dependency 'qb-core'
