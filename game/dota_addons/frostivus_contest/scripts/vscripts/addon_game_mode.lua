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
	LinkLuaModifier("modifier_frostivus_lantern", "boss_scripts/icewrack_lantern.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_frostivus_greevil", "boss_scripts/greevil_innate.lua", LUA_MODIFIER_MOTION_NONE)
	LinkLuaModifier("modifier_greevil_capture_aura", "boss_scripts/greevil_innate.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("modifier_greevil_captured_owner", "boss_scripts/greevil_innate.lua", LUA_MODIFIER_MOTION_NONE )
	LinkLuaModifier("modifier_greevil_captured_greevil", "boss_scripts/greevil_innate.lua", LUA_MODIFIER_MOTION_NONE )

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
	PrecacheResource("particle", "particles/units/heroes/hero_tusk/tusk_walruspunch_txt_ult.vpcf", context)
	PrecacheResource("soundfile", "soundevents/frostivus_soundevents.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/soundevents_conquest.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_rattletrap.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tusk.vsndevts", context)
	PrecacheResource("model", "models/heroes/zeus/zeus.vmdl", context)
	PrecacheResource("model", "models/heroes/venomancer/venomancer.vmdl", context)
	PrecacheResource("model", "models/heroes/treant_protector/treant_protector.vmdl", context)
	PrecacheResource("model", "models/heroes/shadow_fiend/shadow_fiend_arcana.vmdl", context)
	PrecacheResource("model", "models/heroes/tuskarr/tuskarr.vmdl", context)
	PrecacheResource("model", "models/courier/greevil/greevil.vmdl", context)
	PrecacheResource("model", "models/courier/greevil/gold_greevil.vmdl", context)
	PrecacheResource("model", "models/creeps/mega_greevil/mega_greevil.vmdl", context)

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

	-- Treant boss
	PrecacheResource("particle_folder", "particles/boss_treant/", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_treant/", context)
	PrecacheResource("particle", "particles/units/heroes/hero_tiny/tiny_toss_impact.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_furion.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tiny.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_treant.vsndevts", context)

	-- Nevermore boss
	PrecacheResource("particle_folder", "particles/boss_nevermore/", context)
	PrecacheResource("particle_folder", "particles/units/heroes/hero_nevermore/", context)
	PrecacheResource("particle_folder", "particles/econ/items/shadow_fiend/sf_fire_arcana", context)
	PrecacheResource("particle", "particles/econ/items/shadow_fiend/sf_desolation/sf_base_attack_desolation_fire_arcana.vpcf", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_invoker.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_lina.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_nevermore.vsndevts", context)

	-- Models can also be precached by folder or individually
	PrecacheResource("model", "models/props_winter/present.vmdl", context)
	PrecacheResource("model_folder", "models/development", context)
	PrecacheResource("model_folder", "models/creeps", context)
	PrecacheResource("model_folder", "models/props_gameplay", context)
end

function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end
