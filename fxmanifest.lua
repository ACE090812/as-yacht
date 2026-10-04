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
	'language/features.lua',
	'language/translations.lua',
	'server/main.lua',
	'server/other.lua',
	'server/commands.lua',
	'server/upgrades.lua',
	'server/economy.lua',
	'server/extras.lua',
	'server/marina.lua',
	'server/upkeep.lua',
	'server/condition.lua',
	'server/layouts.lua',
	'server/api.lua'
}

client_scripts {
	'config.lua',
	'language/main.lua',
	'language/features.lua',
	'language/translations.lua',
	'client/core.lua',
	'client/appearance.lua',
	'client/buypreview.lua',
	'client/blips.lua',
	'client/init.lua',
	'client/events.lua',
	'client/buymenu.lua',
	'client/sailing.lua',
	'client/threads.lua',
	'client/nui.lua',
	'client/actions.lua',
	'client/manage.lua',
	'client/furniture.lua',
	'client/comfort.lua',
	'client/marina.lua',
	'client/seastate.lua',
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

