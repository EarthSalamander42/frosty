if GameMode == nil then _G.GameMode = class({}) end

require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/projectiles_new')
require('libraries/notifications')
require('libraries/animations')
--	require('libraries/attachments')
require('libraries/astar')
require('libraries/illusionmanager')

require('internal/gamemode')
require('internal/events')
require('server/server')
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

--	CustomNetTables:SetTableValue("arena_capture", "radiant_score", {0})
--	CustomNetTables:SetTableValue("arena_capture", "dire_score", {0})
end

function GameMode:ModifierFilter( keys )
-- entindex_parent_const	215
-- entindex_ability_const	610
-- duration					-1
-- entindex_caster_const	215
-- name_const				modifier_imba_roshan_rage_stack

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
			
			-- Ignore stuns
			if modifier_name == "modifier_stunned" then
				return false
			end
		end

		-------------------------------------------------------------------------------------------------
		-- Fight intervention prevention
		-------------------------------------------------------------------------------------------------
		if modifier_owner:HasModifier("modifier_fighting_boss") and modifier_owner:GetTeam() ~= modifier_caster:GetTeam() and not modifier_caster:HasModifier("modifier_frostivus_boss") then
			return false
		end

		if modifier_owner:HasModifier("modifier_frostivus_boss") and not modifier_caster:HasModifier("modifier_fighting_boss") and not modifier_caster:HasModifier("modifier_frostivus_boss") then
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

	-- Do special handlings if shift-casted only here! The event gets fired another time if the caster
	-- is actually doing this order
	if keys.queue == 1 then
		return true
	end

	------------------------------------------------------------------------------------
	-- Prevent Buyback
	------------------------------------------------------------------------------------
	if keys.order_type == DOTA_UNIT_ORDER_BUYBACK then
		return false
	end

	if keys.order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
		local ability = EntIndexToHScript(keys.entindex_ability)
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

		if victim:HasModifier("modifier_frostivus_boss") and not attacker:HasModifier("modifier_fighting_boss") and not attacker:HasModifier("modifier_frostivus_boss") then
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
	-- IMBA: Game filters setup
	-------------------------------------------------------------------------------------------------

	GameRules:GetGameModeEntity():SetBountyRunePickupFilter( Dynamic_Wrap(GameMode, "BountyRuneFilter"), self )
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
					if not hero:HasModifier("modifier_imba_prevent_actions_game_start") then
						hero:AddNewModifier(hero, nil, "modifier_imba_prevent_actions_game_start", {})
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
	if GetMapName() == "imba_arena" then
		-- Define the bonus gold positions
		local bonus_gold_positions = {}
		bonus_gold_positions.fountain_radiant = {
			stacks = 20,
			center = Vector(-3776, -3776, 384),
			radius = 1300
		}
		bonus_gold_positions.fountain_dire = {
			stacks = 20,
			center = Vector(3712, 3712, 384),
			radius = 1300
		}
		bonus_gold_positions.center_arena = {
			stacks = 40,
			center = Vector(0, 0, 256),
			radius = 900
		}

		-- Continuously update the amount of gold/exp to gain
		Timers:CreateTimer(0, function()
			-- Apply the modifier
			local nearby_heroes = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, 6000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
			for _, hero in pairs(nearby_heroes) do
				if not hero:HasModifier("modifier_imba_arena_passive_gold_thinker") then
					hero:AddNewModifier(hero, nil, "modifier_imba_arena_passive_gold_thinker", {})
				end
				hero:FindModifierByName("modifier_imba_arena_passive_gold_thinker"):SetStackCount(12)
			end

			-- Update stack amount, when relevant
			for _, position in pairs(bonus_gold_positions) do
				nearby_heroes = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, position.center, nil, position.radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
				for _, hero in pairs(nearby_heroes) do
					hero:FindModifierByName("modifier_imba_arena_passive_gold_thinker"):SetStackCount(position.stacks)
				end
			end
			return 0.1
		end)

		-- Set up control points
		local radiant_control_point_loc = Entities:FindByName(nil, "radiant_capture_point"):GetAbsOrigin()
		local dire_control_point_loc = Entities:FindByName(nil, "dire_capture_point"):GetAbsOrigin()
		RADIANT_CONTROL_POINT_DUMMY = CreateUnitByName("npc_dummy_unit_perma", radiant_control_point_loc, false, nil, nil, DOTA_TEAM_NOTEAM)
		DIRE_CONTROL_POINT_DUMMY = CreateUnitByName("npc_dummy_unit_perma", dire_control_point_loc, false, nil, nil, DOTA_TEAM_NOTEAM)
		RADIANT_CONTROL_POINT_DUMMY.score = 20
		DIRE_CONTROL_POINT_DUMMY.score = 20
		ArenaControlPointThinkRadiant(RADIANT_CONTROL_POINT_DUMMY)
		ArenaControlPointThinkDire(DIRE_CONTROL_POINT_DUMMY)
		Timers:CreateTimer(10, function()
			ArenaControlPointScoreThink(RADIANT_CONTROL_POINT_DUMMY, DIRE_CONTROL_POINT_DUMMY)
		end)
		CustomGameEventManager:Send_ServerToAllClients("contest_started", {})
	end
end

function GameMode:InitGameMode()
	GameMode = self

	GameMode:_InitGameMode()

	GameRules.HeroKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")

	HERO_SELECTION_TIME = 45.0 + 10.0 -- Add 10 additional seconds because there's a delay between entering game and hero applied
	if IsInToolsMode() then HERO_SELECTION_TIME = 5.0 end
	GameRules:SetUseUniversalShopMode(true)
	GameRules:SetHeroSelectionTime(0.0)
	GameRules:SetPreGameTime(90.0 + HERO_SELECTION_TIME)
	GameRules:SetPostGameTime(60.0)
	GameRules:SetShowcaseTime(0.0)
	GameRules:SetStrategyTime(0.0)
	GameRules:SetCustomGameSetupAutoLaunchDelay(10.0)
--	GameRules:SetTreeRegrowTime( 180.0 )
--	GameRules:SetGoldPerTick(1.0)
--	GameRules:SetGoldTickTime(0.6)
--	GameRules:SetRuneSpawnTime(120.0)
--	GameRules:SetHeroMinimapIconScale(1.0)
--	GameRules:SetCreepMinimapIconScale(1.0)
--	GameRules:SetRuneMinimapIconScale(1.0)
--	GameRules:EnableCustomGameSetupAutoLaunch(true)
--	GameRules:SetFirstBloodActive(true)
--	GameRules:SetHideKillMessageHeaders(false)

	if mode == nil then
		mode = GameRules:GetGameModeEntity()
		mode:SetRecommendedItemsDisabled( false )
		mode:SetCameraDistanceOverride( 1134 )
		mode:SetCustomGameForceHero("npc_dota_hero_wisp")
		mode:SetLoseGoldOnDeath(true)
		mode:SetMaximumAttackSpeed(600.0)
		mode:SetMinimumAttackSpeed(20.0)

--		mode:SetTowerBackdoorProtectionEnabled( false )
--		mode:SetFountainConstantManaRegen(10.0)
--		mode:SetFountainPercentageHealthRegen(5.0)
--		mode:SetFountainPercentageManaRegen(5.0)

--		for rune, spawn in pairs(ENABLED_RUNES) do
--			mode:SetRuneEnabled(rune, spawn)
--		end

		self:OnFirstPlayerLoaded()
	end 

	-- IMBA testbed command
	Convars:RegisterCommand("imba_test", Dynamic_Wrap(GameMode, 'StartImbaTest'), "Spawns several units to help with testing", FCVAR_CHEAT)

	CustomGameEventManager:RegisterListener("remove_units", Dynamic_Wrap(GameMode, "RemoveUnits"))

	-- Panorama event stuff
	initScoreBoardEvents()
end

-- Starts the testbed if in tools mode
function GameMode:StartImbaTest()

	-- If not in tools mode, do nothing
	if not IsInToolsMode() then
		print("IMBA testbed is only available in tools mode.")
		return nil
	end

	-- If the testbed was already initialized, do nothing
	if IMBA_TESTBED_INITIALIZED then
		print("Testbed already initialized.")
		return nil
	end

	-- Define testbed zone reference point
	local testbed_center = Vector(1500, -5000, 256)
	if GetMapName() == "imba_arena" then
		testbed_center = Vector(0, 0, 128)
	end

	-- Move any existing heroes to the testbed area, and grant them useful testing items
	local player_heroes = HeroList:GetAllHeroes()
	for _, hero in pairs(player_heroes) do
		hero:SetAbsOrigin(testbed_center + Vector(-250, 0, 0))
		hero:AddItemByName("item_imba_diffusal_blade_3")
		hero:AddItemByName("item_imba_manta")
		hero:AddItemByName("item_imba_blink")
		hero:AddItemByName("item_imba_silver_edge")
		hero:AddItemByName("item_black_king_bar")
		hero:AddItemByName("item_imba_heart")
		hero:AddItemByName("item_imba_siege_cuirass")
		hero:AddItemByName("item_imba_butterfly")
		hero:AddItemByName("item_ultimate_scepter")
		hero:AddExperience(100000, DOTA_ModifyXP_Unspecified, false, true)
		PlayerResource:SetCameraTarget(0, hero)
	end
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(0, nil)
	end)
	ResolveNPCPositions(testbed_center + Vector(-300, 0, 0), 128)

	-- Spawn some high health allies for benefic spell testing
	local dummy_hero
	local dummy_ability
	for i = 1, 3 do
		dummy_hero = CreateUnitByName("npc_dota_hero_axe", testbed_center + Vector(-500, (i-2) * 300, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_GOODGUYS)
		dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
		dummy_hero:SetControllableByPlayer(0, true)
		dummy_hero:AddItemByName("item_imba_heart")
		dummy_hero:AddItemByName("item_imba_heart")

		-- Add specific items to each dummy hero
		if i == 1 then
			dummy_hero:AddItemByName("item_imba_manta")
			dummy_hero:AddItemByName("item_imba_diffusal_blade_3")
		elseif i == 2 then
			dummy_hero:AddItemByName("item_imba_silver_edge")
			dummy_hero:AddItemByName("item_imba_necronomicon_5")
		elseif i == 3 then
			dummy_hero:AddItemByName("item_sphere")
			dummy_hero:AddItemByName("item_black_king_bar")
		end
	end

	-- Spawn some high health enemies to attack/spam abilities on
	for i = 1, 3 do
		dummy_hero = CreateUnitByName("npc_dota_hero_axe", testbed_center + Vector(300, (i-2) * 300, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
		dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
		dummy_hero:SetControllableByPlayer(0, true)
		dummy_hero:AddItemByName("item_imba_heart")
		dummy_hero:AddItemByName("item_imba_heart")

		-- Add specific items to each dummy hero
		if i == 1 then
			dummy_hero:AddItemByName("item_imba_manta")
			dummy_hero:AddItemByName("item_imba_diffusal_blade_3")
		elseif i == 2 then
			dummy_hero:AddItemByName("item_imba_silver_edge")
			dummy_hero:AddItemByName("item_imba_necronomicon_5")
		elseif i == 3 then
			dummy_hero:AddItemByName("item_sphere")
			dummy_hero:AddItemByName("item_black_king_bar")
		end
	end

	-- Spawn a rubick with spell steal leveled up
	dummy_hero = CreateUnitByName("npc_dota_hero_rubick", testbed_center + Vector(600, 200, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
	dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
	dummy_hero:SetControllableByPlayer(0, true)
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_ability = dummy_hero:FindAbilityByName("rubick_spell_steal")
	if dummy_ability then
		dummy_ability:SetLevel(6)
	end

	-- Spawn a pugna with nether ward leveled up and some CDR
	dummy_hero = CreateUnitByName("npc_dota_hero_pugna", testbed_center + Vector(600, 0, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
	dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
	dummy_hero:SetControllableByPlayer(0, true)
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_triumvirate")
	dummy_hero:AddItemByName("item_imba_octarine_core")
	dummy_ability = dummy_hero:FindAbilityByName("imba_pugna_nether_ward")
	if dummy_ability then
		dummy_ability:SetLevel(7)
	end

	-- Spawn an antimage with a scepter and leveled up spell shield
	dummy_hero = CreateUnitByName("npc_dota_hero_antimage", testbed_center + Vector(600, -200, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
	dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
	dummy_hero:SetControllableByPlayer(0, true)
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_ultimate_scepter")
	dummy_ability = dummy_hero:FindAbilityByName("imba_antimage_spell_shield")
	if dummy_ability then
		dummy_ability:SetLevel(7)
	end

	-- Spawn some assorted neutrals for reasons
	neutrals_table = {}
	neutrals_table[1] = {}
	neutrals_table[2] = {}
	neutrals_table[3] = {}
	neutrals_table[4] = {}
	neutrals_table[5] = {}
	neutrals_table[6] = {}
	neutrals_table[7] = {}
	neutrals_table[8] = {}
	neutrals_table[1].name = "npc_dota_neutral_big_thunder_lizard"
	neutrals_table[1].position = Vector(-450, 800, 0)
	neutrals_table[2].name = "npc_dota_neutral_granite_golem"
	neutrals_table[2].position = Vector(-150, 800, 0)
	neutrals_table[3].name = "npc_dota_neutral_black_dragon"
	neutrals_table[3].position = Vector(150, 800, 0)
	neutrals_table[4].name = "npc_dota_neutral_prowler_shaman"
	neutrals_table[4].position = Vector(450, 800, 0)
	neutrals_table[5].name = "npc_dota_neutral_satyr_hellcaller"
	neutrals_table[5].position = Vector(-450, 600, 0)
	neutrals_table[6].name = "npc_dota_neutral_mud_golem"
	neutrals_table[6].position = Vector(-150, 600, 0)
	neutrals_table[7].name = "npc_dota_neutral_enraged_wildkin"
	neutrals_table[7].position = Vector(150, 600, 0)
	neutrals_table[8].name = "npc_dota_neutral_centaur_khan"
	neutrals_table[8].position = Vector(450, 600, 0)

	for _, neutral in pairs(neutrals_table) do
		dummy_hero = CreateUnitByName(neutral.name, testbed_center + neutral.position, true, player_heroes[1], player_heroes[1], DOTA_TEAM_NEUTRALS)
		dummy_hero:SetControllableByPlayer(0, true)
		dummy_hero:Hold()
	end

	-- Flag testbed as having been initialized
	IMBA_TESTBED_INITIALIZED = true
end

--	function GameMode:RemoveUnits(good, bad, neutral)
function GameMode:RemoveUnits()
local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local units3 = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local count = 0

--	if good == true then
		for _,v in pairs(units) do
			if v:HasMovementCapability() and not v:GetUnitName() == "npc_dota_creep_goodguys_melee" then
				count = count +1
				v:RemoveSelf()
			end
		end
--	end

--	if bad == true then
		for _,v in pairs(units2) do
			if v:HasMovementCapability() and not v:GetUnitName() == "npc_dota_creep_badguys_melee" then
				count = count +1
				v:RemoveSelf()
			end
		end
--	end

--	if neutral == true then
		for _,v in pairs(units3) do
			if v:HasMovementCapability() then
				count = count +1
				v:RemoveSelf()
			end
		end
--	end
end
