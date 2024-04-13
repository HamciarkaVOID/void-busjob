fx_version 'cerulean'
games {'gta5'}
lua54 'yes'

author 'Hamciarka'
description 'Simple bus job for roleplay servers by -- https://voiddevelopments.tebex.io'
version '1.0'

client_scripts {
    'client/*.lua'
}

files {
	'locales/*.json'
}

shared_scripts {
	'@ox_lib/init.lua',
	'config.lua',
	'@es_extended/imports.lua'
}

server_scripts {
	'@oxmysql/lib/MySQL.lua',
	'config.lua',
	'server/*.lua'
}

dependencies {
    '/server:6116',
    '/onesync',
    'oxmysql',
    'ox_lib',
	'es_extended',
}