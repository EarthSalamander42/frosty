if GameMode == nil then _G.GameMode = class({}) end

require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/projectiles_new')
require('libraries/notifications')
require('libraries/animations')
require('libraries/astar')
require('libraries/keyvalues')

require('internal/gamemode')
require('internal/events')
require('libraries/json')
require('internal/constants')
require('internal/scoreboard_events')

require('settings')
require('events')

-- storage API
--require('libraries/json')
--require('libraries/storage')

--Storage:SetApiKey("35c56d290cbd168b6a58aabc43c87aff8d6b39cb")

function GameMode:OnItemPickedUp(event) 
	if event.HeroEntityIndex then
		local owner = EntIndexToHScript(event.HeroEntityIndex)
		if owner:IsHero() and event.itemname == "item_bag_of_gold" then
			GoldPickup(event)
		end
	end
end

function GameMode:PostLoadPrecache()

end

function GameMode:OnFirstPlayerLoaded()
	if GetMapName() == "frostivus" then
		GoodCamera = Entities:FindByName(nil, "altar_1")
		BadCamera = Entities:FindByName(nil, "altar_7")
	end

	-- Altar particle attach points
	local nature_particle_points = Entities:FindAllByName("nature_rock_particle")
	local fire_particle_points = Entities:FindAllByName("fire_rock_particle")
	local ice_particle_points = Entities:FindAllByName("ice_rock_particle")
	local lightning_particle_points = Entities:FindAllByName("lightning_rock_particle")

	-- Draw altar particles
	for _, particle_point in pairs(nature_particle_points) do
		local nature_pfx = ParticleManager:CreateParticle("particles/generic_particles/ambient_nature_altar.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(nature_pfx, 0, particle_point:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(nature_pfx)
	end

	for _, particle_point in pairs(fire_particle_points) do
		local fire_pfx = ParticleManager:CreateParticle("particles/generic_particles/ambient_fire_altar.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(fire_pfx, 0, particle_point:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(fire_pfx)
	end

	for _, particle_point in pairs(ice_particle_points) do
		local ice_pfx = ParticleManager:CreateParticle("particles/generic_particles/ambient_ice_altar.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(ice_pfx, 0, particle_point:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(ice_pfx)
	end

	for _, particle_point in pairs(lightning_particle_points) do
		local lightning_pfx = ParticleManager:CreateParticle("particles/generic_particles/ambient_lightning_altar.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(lightning_pfx, 0, particle_point:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(lightning_pfx)
	end

	-- Icewrack lanterns attach points
	local icewrack_lantern_spawn_points = Entities:FindAllByName("icewrack_lantern")
	for _, point in pairs(icewrack_lantern_spawn_points) do
		local spawn_point = point:GetAbsOrigin()
		local lantern = CreateUnitByName("npc_dota_dungeon_checkpoint", spawn_point, false, nil, nil, DOTA_TEAM_NEUTRALS)
		lantern:AddNewModifier(nil, nil, "modifier_frostivus_lantern", {})
		AddFOWViewer(DOTA_TEAM_GOODGUYS, spawn_point, 1600, 1800, false)
		AddFOWViewer(DOTA_TEAM_BADGUYS, spawn_point, 1600, 1800, false)
	end

--	local developer_statues = {
--		"npc_dota_developer_cookies",
--		"npc_dota_developer_firetoad",
--		"npc_dota_developer_zimber",
--		"npc_dota_developer_starboxx",
--		"npc_dota_developer_plexus",
--		"npc_dota_developer_mc",
--	}

--	local current_location
--	local current_statue
--	local statue_entity
--	for i = 1, 4 do
--		current_location = Entities:FindByName(nil, "developer_location_0"..i):GetAbsOrigin()
--		current_statue = table.remove(developer_statues, RandomInt(1, #developer_statues))
--		if i <= 2 then
--			statue_entity = CreateUnitByName(current_statue, current_location, true, nil, nil, DOTA_TEAM_GOODGUYS)
--			statue_entity:SetForwardVector(Vector(1, 1, 0):Normalized())
--		else
--			statue_entity = CreateUnitByName(current_statue, current_location, true, nil, nil, DOTA_TEAM_BADGUYS)
--			statue_entity:SetForwardVector(Vector(-1, -1, 0):Normalized())
--		end
--		statue_entity:AddNewModifier(statue_entity, nil, "modifier_imba_contributor_statue", {})
--	end
end

function GameMode:ModifierFilter( keys )
	if IsServer() then
		local modifier_owner = EntIndexToHScript(keys.entindex_parent_const)
		local modifier_name = keys.name_const
		local modifier_caster
		if keys.entindex_caster_const then
			modifier_caster = EntIndexToHScript(keys.entindex_caster_const)
		else
			return true
		end

		-------------------------------------------------------------------------------------------------
		-- Special boss modifier rules
		-------------------------------------------------------------------------------------------------
		if modifier_owner:HasModifier("modifier_frostivus_boss") then

			-- Ignore stuns and knockbacks
			if modifier_name == "modifier_stunned" or modifier_name == "modifier_knockback" or modifier_name == "modifier_rooted" or modifier_name == "modifier_item_forcestaff_active" or modifier_name == "modifier_item_hurricane_pike_active_alternate" then
				return false
			end
		end

		-------------------------------------------------------------------------------------------------
		-- Fight intervention prevention
		-------------------------------------------------------------------------------------------------
		if modifier_owner:HasModifier("modifier_fighting_boss") and modifier_owner:GetTeam() ~= modifier_caster:GetTeam() and not modifier_caster:HasModifier("modifier_frostivus_boss") then
			return false
		end

		if (modifier_owner:HasModifier("modifier_frostivus_boss") or modifier_owner:HasModifier("modifier_frostivus_boss_add")) and not (modifier_caster:HasModifier("modifier_fighting_boss") or modifier_caster:HasModifier("modifier_frostivus_boss") or modifier_caster:HasModifier("modifier_frostivus_boss_add")) then
			return false
		end

		return true
	end
end

function GameMode:ItemAddedFilter( keys )

	-- Typical keys:
	-- inventory_parent_entindex_const: 852
	-- item_entindex_const: 1519
	-- item_parent_entindex_const: -1
	-- suggested_slot: -1
	local unit = EntIndexToHScript(keys.inventory_parent_entindex_const)
	local item = EntIndexToHScript(keys.item_entindex_const)
	local item_name = 0
	if item:GetName() then
		item_name = item:GetName()
	end

	return true
end

function GameMode:OrderFilter(keys)
--entindex_ability	 ==> 	0
--sequence_number_const	 ==> 	20
--queue	 ==> 	0
--units	 ==> 	table: 0x031d5fd0
--entindex_target	 ==> 	0
--position_z	 ==> 	384
--position_x	 ==> 	-5694.3334960938
--order_type	 ==> 	1
--position_y	 ==> 	-6381.1127929688
--issuer_player_id_const	 ==> 	0

	local units = keys["units"]
	local unit
	if units["0"] then
		unit = EntIndexToHScript(units["0"])
	else
		return nil
	end

	-- Prevent Monkey King from jumping outside boss arenas
	if keys.order_type == DOTA_UNIT_ORDER_CAST_TARGET_TREE and unit:HasModifier("modifier_fighting_boss") and EntIndexToHScript(keys.entindex_ability):GetAbilityName() == "monkey_king_tree_dance" then
		return false
	end

	-- Prevent Vengeful Spirit using Nether Swap on bosses
	if keys.order_type == DOTA_UNIT_ORDER_CAST_TARGET and (not unit:HasModifier("modifier_fighting_boss")) and EntIndexToHScript(keys.entindex_ability):GetAbilityName() == "vengefulspirit_nether_swap" then
		return false
	end

	-- Do special handlings if shift-casted only here! The event gets fired another time if the caster
	-- is actually doing this order
	if keys.queue == 1 then
		return true
	end

	return true
end

function GameMode:DamageFilter( keys )
	if IsServer() then
		--damagetype_const
		--damage
		--entindex_attacker_const
		--entindex_victim_const
		local attacker
		local victim

		if keys.entindex_attacker_const and keys.entindex_victim_const then
			attacker = EntIndexToHScript(keys.entindex_attacker_const)
			victim = EntIndexToHScript(keys.entindex_victim_const)
		else
			return false
		end

		local damage_type = keys.damagetype_const		

		-- Lack of entities handling
		if not attacker or not victim then
			return false
		end

		-- Fight interference prevention
		if victim:HasModifier("modifier_fighting_boss") and not attacker:HasModifier("modifier_frostivus_boss") then
			return false
		end

		if (victim:HasModifier("modifier_frostivus_boss") or victim:HasModifier("modifier_frostivus_boss_add")) and not (attacker:HasModifier("modifier_fighting_boss") or attacker:HasModifier("modifier_frostivus_boss") or attacker:HasModifier("modifier_frostivus_boss_add") or attacker:GetUnitName() == "npc_dota_witch_doctor_death_ward") then
			return false
		end
	end
	return true
end

--[[
	This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
	It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]
function GameMode:OnAllPlayersLoaded()
	-------------------------------------------------------------------------------------------------
	-- Game filters setup
	-------------------------------------------------------------------------------------------------

--	GameRules:GetGameModeEntity():SetBountyRunePickupFilter( Dynamic_Wrap(GameMode, "BountyRuneFilter"), self )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap(GameMode, "OrderFilter"), self )
	GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap(GameMode, "DamageFilter"), self )
--	GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap(GameMode, "GoldFilter"), self )
--	GameRules:GetGameModeEntity():SetModifyExperienceFilter( Dynamic_Wrap(GameMode, "ExperienceFilter"), self )
	GameRules:GetGameModeEntity():SetModifierGainedFilter( Dynamic_Wrap(GameMode, "ModifierFilter"), self )
	GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter( Dynamic_Wrap(GameMode, "ItemAddedFilter"), self )

	-- CHAT
	self.chat = Chat(self.Players, self.Users, TEAM_COLORS)
	--	Chat:constructor(players, users, teamColors)
--	print("Constructing Chat!")
end

random_time = 1.0
function GameMode:OnHeroInGame(hero)	
local time_elapsed = 0

	-- Disabling announcer for the player who picked a hero
	Timers:CreateTimer(0.1, function()
		if hero:GetUnitName() ~= "npc_dota_hero_wisp" then
			hero.picked = true
		elseif hero.is_real_wisp then
			print("REAL WISP")
			hero.picked = true
		end
	end)

	Timers:CreateTimer(0.1, function()
		if hero.is_real_wisp then
			hero.picked = true
			return
		elseif hero:GetUnitName() ~= "npc_dota_hero_wisp" then
			hero.picked = true
			return
		elseif not hero.is_real_wisp then
			if hero:GetUnitName() == "npc_dota_hero_wisp" then
				Timers:CreateTimer(function()
					if not hero:HasModifier("modifier_command_restricted") then
						hero:AddNewModifier(hero, nil, "modifier_command_restricted", {})
						hero:AddEffects(EF_NODRAW)
						hero:SetDayTimeVisionRange(475)
						hero:SetNightTimeVisionRange(475)				
						if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), GoodCamera)
							FindClearSpaceForUnit(hero, GoodCamera:GetAbsOrigin(), false)
						else
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), BadCamera)					
							FindClearSpaceForUnit(hero, BadCamera:GetAbsOrigin(), false)
						end
					end
					if time_elapsed < 0.9 then
						time_elapsed = time_elapsed + 0.1
					else			
						return nil
					end
					return 0.1
				end)
			end
			return
		end
	end)
end

function GameMode:OnGameInProgress()

	-- Apply the gold/experience thinker to the central altar
	local central_altar = Entities:FindByName(nil, "altar_4")
	central_altar:AddNewModifier(nil, nil, "modifier_passive_bounty", {})
end

function GameMode:InitGameMode()
	GameMode = self

	GameMode:_InitGameMode()

	GameRules.HeroKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")

	-------------------------------------------------------------------------------------------------
	-- Game rules setup
	-------------------------------------------------------------------------------------------------

	HERO_SELECTION_TIME = 45.0 + 10.0 -- Add 10 additional seconds because there's a delay between entering game and hero applied
	if IsInToolsMode() then HERO_SELECTION_TIME = 5.0 end
	GameRules:SetUseUniversalShopMode(true)
	GameRules:SetHeroSelectionTime(0.0)
	GameRules:SetPreGameTime(40.0 + HERO_SELECTION_TIME)
	GameRules:SetPostGameTime(60.0)
	GameRules:SetShowcaseTime(0.0)
	GameRules:SetStrategyTime(0.0)
	GameRules:SetCustomGameSetupAutoLaunchDelay(10.0)
--	GameRules:SetTreeRegrowTime( 180.0 )
	GameRules:SetGoldPerTick(0)
--	GameRules:SetGoldTickTime(0.6)
--	GameRules:SetRuneSpawnTime(120.0)
--	GameRules:SetHeroMinimapIconScale(1.0)
--	GameRules:SetCreepMinimapIconScale(1.0)
--	GameRules:SetRuneMinimapIconScale(1.0)
--	GameRules:EnableCustomGameSetupAutoLaunch(true)
--	GameRules:SetFirstBloodActive(true)
--	GameRules:SetHideKillMessageHeaders(false)
	GameRules:SetCustomVictoryMessage("Frostivus is saved!")

	if mode == nil then
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( false )
		mode:SetCameraDistanceOverride( 1134 )
		mode:SetCustomGameForceHero("npc_dota_hero_wisp")
		mode:SetLoseGoldOnDeath(true)
		mode:SetMaximumAttackSpeed(600.0)
		mode:SetMinimumAttackSpeed(20.0)
		mode:SetCustomAttributeDerivedStatValue(DOTA_ATTRIBUTE_STRENGTH_STATUS_RESISTANCE_PERCENT, 0)
		mode:SetFixedRespawnTime(26.0)
		mode:SetTopBarTeamValuesOverride(true)

--		mode:SetTowerBackdoorProtectionEnabled( false )
--		mode:SetFountainConstantManaRegen(10.0)
--		mode:SetFountainPercentageHealthRegen(5.0)
--		mode:SetFountainPercentageManaRegen(5.0)

--		for rune, spawn in pairs(ENABLED_RUNES) do
--			mode:SetRuneEnabled(rune, spawn)
--		end

		self:OnFirstPlayerLoaded()
	end 

	CustomGameEventManager:RegisterListener("spawn_point", AltarRespawn)

	-- Panorama event stuff
	initScoreBoardEvents()
end

function AltarRespawn(eventSourceIndex, args)
	local hero = PlayerResource:GetPlayer(args["player"]):GetAssignedHero()
	local spawn_point = args["altar"]
	hero.altar = spawn_point
end
