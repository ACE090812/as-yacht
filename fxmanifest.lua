fx_version 'cerulean'

game 'gta5'

description 'as-yacht'

version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua'
}

server_scripts {
	
	'@oxmysql/lib/MySQL.lua', 
	'config.lua',
	'language/main.lua',
	'language/translations.lua',
	'server/main.lua',
	'server/other.lua',
	'server/commands.lua',
	'server/upgrades.lua',
	'server/economy.lua',
	'server/extras.lua'
}

client_scripts {
	'config.lua',
	'language/main.lua',
	'language/translations.lua',
	'client/main.lua',
	'client/other.lua'
}

files {
	'html/ui.html',
	'html/styles.css',
	'html/scripts.js',
	'html/gizmoapi.js',
	'html/debounce.min.js',
	'html/img/*.png',
	'html/img/*.webp',
	'html/img/objects/*.webp',
	'html/img/yachtcolors/*.png',
	'html/img/yachtcolors/*.jpg'
}

ui_page 'html/ui.html'

lua54 'yes'

dependencies {
    '/assetpacks',
    'as-yachtmodels',
}

