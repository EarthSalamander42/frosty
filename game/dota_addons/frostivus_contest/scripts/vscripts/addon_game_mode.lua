require('internal/util')
require('internal/funcs')
require('player_resource')
require('imba')
require('hero_selection')

function Precache(context)
DebugPrint("[IMBA] Performing pre-load precache")

	LinkLuaModifier("modifier_command_restricted", "modifier/modifier_command_restricted.lua", LUA_MODIFIER_MOTION_NONE )	
	LinkLuaModifier("modifier_npc_dialog", "modifier/modifier_npc_dialog.lua", LUA_MODIFIER_MOTION_NONE )	

	-- Items
	if GetMapName() == "imba_diretide" then
		print("Precaching Diretide particles...")
		PrecacheResource("particle", "particles/hw_fx/hw_candy_drop.vpcf", context)
		PrecacheResource("particle", "particles/hw_fx/candy_carrying_overhead.vpcf", context)
	end

	PrecacheResource("particle", "particles/econ/items/effigies/status_fx_effigies/gold_effigy_ambient_dire_lvl2.vpcf", context)

	-- Ghost Revenant
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_pugna.vsndevts", context)
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_warlock.vsndevts", context)

	-- Storegga
	PrecacheResource("soundfile", "soundevents/game_sounds_heroes/game_sounds_tiny.vsndevts", context)

	-- Roshan
	PrecacheResource("particle", "particles/units/heroes/hero_invoker/invoker_deafening_blast.vpcf", context)
	PrecacheResource("particle", "particles/neutral_fx/roshan_slam.vpcf", context)

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

	-- Models can also be precached by folder or individually
	PrecacheResource("model_folder", "models/development", context)
	PrecacheResource("model_folder", "models/creeps", context)
	PrecacheResource("model_folder", "models/props_gameplay", context)

	PrecacheUnitByNameSync("npc_dota_hero_wisp", context) --Precaching dummy wisp
end

function Activate()
	GameRules.GameMode = GameMode()
	GameRules.GameMode:InitGameMode()
end
