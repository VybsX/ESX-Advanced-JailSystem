fx_version 'cerulean'
game 'gta5'

author 'Luca'
description 'Jail system with ox_lib integration'
version '1.0.1'
lua54 'yes'

shared_script '@ox_lib/init.lua'

client_script 'client.lua'
server_script 'server.lua'

dependencies {
    'ox_lib', 
    'es_extended'
}
