require('internal/util')
require('internal/funcs')
require('player_resource')
require('gamemode')
require('frostivus')
require('hero_selection')
require('boss_scripts/boss_functions')
require('boss_scripts/greevil_functions')

function Precache(context)

	-- Link lua modifiers
	LinkLuaModifier("modifier_command_restricted", "modifier/modifier_command_restricted.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("modifier_river", "modifier/modifier_river.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("modifier_passive_bounty", "boss_scripts/aura_abilities/modifier_passive_bounty.lua", LUA_MODIFIER_MOTION_NONE )

	-- Stuff
	PrecacheResource("particle_folder", "particles/hero", context)
	PrecacheResource("particle_folder", "particles/ambient", context)
	PrecacheResource("particle_folder", "particles/generic_gameplay", context)
	PrecacheResource("particle_folder", "particles/status_fx/", context)
	PrecacheResource("particle_folder", "particles/item", context)
	PrecacheResource("particle_folder", "particles/items_fx", context)
	PrecacheResource("particle_folder", "particles/items2_fx", context)
	PrecacheResource("particle_folder", "particles/items3_fx", context)
	PrecacheResource("particle_folder", "particles/creeps/lane_creeps/", context)
	PrecacheResource("particle_folder", "particles/customgames/capturepoints/", context)
	PrecacheResource("particle", "particles/range_indicator.vpcf", context)

	-- Other frostivus things to precache
	PrecacheResource("particle_folder", "particles/arena_wall", context)
	PrecacheResource("particle_folder", "particles/generic_particles", context)
	PrecacheResource("soundfile", "soundevents/frostivus_soundevents.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/soundevents_conquest.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_rattletrap.vsndevts", context)

	-- Zeus boss
	PrecacheResource("particle_folder", "particles/units/heroes/hero_zuus/", context)
	PrecacheResource("particle_folder", "particles/boss_zeus/", context)
	PrecacheResource("particle_folder", "particles/econ/items/zeus/arcana_chariot/", context)
	PrecacheResource("particle", "particles/econ/events/ti6/maelstorm_ti6.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_disruptor.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_zuus.vsndevts", context)

	-- Venomancer boss
	PrecacheResource("particle_folder", "particles/boss_veno/", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_venomancer/", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_viper.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_venomancer.vsndevts", context)

	-- Models can also be precached by folder or individually
	PrecacheResource("model_folder", "models/development", context)
	PrecacheResource("model_folder", "models/creeps", context)
	PrecacheResource("model_folder", "models/props_gameplay", context)
end

function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end
