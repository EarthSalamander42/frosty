-- This function initializes the game mode and is called before anyone loads into the game
-- It can be used to pre-initialize any values/tables that will be needed later

function GameMode:_InitGameMode()

	-- Register a listener for the game mode configuration
	CustomGameEventManager:RegisterListener("set_game_mode", OnSetGameMode)

	--InitLogFile( "log/barebones.txt","")

	-- Event Hooks
	-- All of these events can potentially be fired by the game, though only the uncommented ones have had
	-- Functions supplied for them.  If you are interested in the other events, you can uncomment the
	-- ListenToGameEvent line and add a function to handle the event
	ListenToGameEvent('dota_player_gained_level', Dynamic_Wrap(GameMode, 'OnPlayerLevelUp'), self)
	ListenToGameEvent('dota_ability_channel_finished', Dynamic_Wrap(GameMode, 'OnAbilityChannelFinished'), self)
	ListenToGameEvent('dota_player_learned_ability', Dynamic_Wrap(GameMode, 'OnPlayerLearnedAbility'), self)
	ListenToGameEvent('entity_killed', Dynamic_Wrap(GameMode, 'OnEntityKilled'), self)
	ListenToGameEvent('player_connect_full', Dynamic_Wrap(GameMode, 'OnConnectFull'), self)
	ListenToGameEvent('player_disconnect', Dynamic_Wrap(GameMode, 'OnDisconnect'), self)
	ListenToGameEvent('dota_item_purchased', Dynamic_Wrap(GameMode, 'OnItemPurchased'), self)
	ListenToGameEvent('dota_item_picked_up', Dynamic_Wrap(GameMode, 'OnItemPickedUp'), self)
	ListenToGameEvent('last_hit', Dynamic_Wrap(GameMode, 'OnLastHit'), self)
	ListenToGameEvent('dota_non_player_used_ability', Dynamic_Wrap(GameMode, 'OnNonPlayerUsedAbility'), self)
	ListenToGameEvent('player_changename', Dynamic_Wrap(GameMode, 'OnPlayerChangedName'), self)
	ListenToGameEvent('dota_rune_activated_server', Dynamic_Wrap(GameMode, 'OnRuneActivated'), self)
	ListenToGameEvent('dota_player_take_tower_damage', Dynamic_Wrap(GameMode, 'OnPlayerTakeTowerDamage'), self)
	ListenToGameEvent('tree_cut', Dynamic_Wrap(GameMode, 'OnTreeCut'), self)
	ListenToGameEvent('entity_hurt', Dynamic_Wrap(GameMode, 'OnEntityHurt'), self)
	ListenToGameEvent('player_connect', Dynamic_Wrap(GameMode, 'PlayerConnect'), self)
	ListenToGameEvent('dota_player_used_ability', Dynamic_Wrap(GameMode, 'OnAbilityUsed'), self)
	ListenToGameEvent('game_rules_state_change', Dynamic_Wrap(GameMode, 'OnGameRulesStateChange'), self)
	ListenToGameEvent('npc_spawned', Dynamic_Wrap(GameMode, 'OnNPCSpawned'), self)
	ListenToGameEvent('dota_player_pick_hero', Dynamic_Wrap(GameMode, 'OnPlayerPickHero'), self)
	ListenToGameEvent('dota_team_kill_credit', Dynamic_Wrap(GameMode, 'OnTeamKillCredit'), self)
	ListenToGameEvent("player_reconnected", Dynamic_Wrap(GameMode, 'OnPlayerReconnect'), self)
	ListenToGameEvent("player_chat", Dynamic_Wrap(GameMode, 'OnPlayerChat'), self)

	ListenToGameEvent("dota_illusions_created", Dynamic_Wrap(GameMode, 'OnIllusionsCreated'), self)
	ListenToGameEvent("dota_item_combined", Dynamic_Wrap(GameMode, 'OnItemCombined'), self)
	ListenToGameEvent("dota_player_begin_cast", Dynamic_Wrap(GameMode, 'OnAbilityCastBegins'), self)
	ListenToGameEvent("dota_tower_kill", Dynamic_Wrap(GameMode, 'OnTowerKill'), self)
	ListenToGameEvent("dota_player_selected_custom_team", Dynamic_Wrap(GameMode, 'OnPlayerSelectedCustomTeam'), self)
	ListenToGameEvent("dota_npc_goal_reached", Dynamic_Wrap(GameMode, 'OnNPCGoalReached'), self)
	
	--ListenToGameEvent("dota_tutorial_shop_toggled", Dynamic_Wrap(GameMode, 'OnShopToggled'), self)

	--ListenToGameEvent('player_spawn', Dynamic_Wrap(GameMode, 'OnPlayerSpawn'), self)
	--ListenToGameEvent('dota_unit_event', Dynamic_Wrap(GameMode, 'OnDotaUnitEvent'), self)
	--ListenToGameEvent('nommed_tree', Dynamic_Wrap(GameMode, 'OnPlayerAteTree'), self)
	--ListenToGameEvent('player_completed_game', Dynamic_Wrap(GameMode, 'OnPlayerCompletedGame'), self)
	--ListenToGameEvent('dota_match_done', Dynamic_Wrap(GameMode, 'OnDotaMatchDone'), self)
	--ListenToGameEvent('dota_combatlog', Dynamic_Wrap(GameMode, 'OnCombatLogEvent'), self)
	--ListenToGameEvent('dota_player_killed', Dynamic_Wrap(GameMode, 'OnPlayerKilled'), self)
	--ListenToGameEvent('player_team', Dynamic_Wrap(GameMode, 'OnPlayerTeam'), self)

	--[[This block is only used for testing events handling in the event that Valve adds more in the future
	Convars:RegisterCommand('events_test', function()
			GameMode:StartEventTest()
		end, "events test", 0)]]

	-- Change random seed
	local timeTxt = string.gsub(string.gsub(GetSystemTime(), ':', ''), '0','')
	math.randomseed(tonumber(timeTxt))

	-- Initialized tables for tracking state
	self.bSeenWaitForPlayers = false
end

mode = nil

-- This function is called as the first player loads and sets up the GameMode parameters
function GameMode:_CaptureGameMode()
	self:OnFirstPlayerLoaded()
end

-- This function captures the game mode options when they are set
function OnSetGameMode( eventSourceIndex, args )
	
	local player_id = args.PlayerID
	local player = PlayerResource:GetPlayer(player_id)
	local is_host = GameRules:PlayerHasCustomGameHostPrivileges(player)
	local mode_info = args.modes
	local game_mode_imba = GameRules:GetGameModeEntity()  
	local map_name = GetMapName()

	-- If the player who sent the game options is not the host, do nothing
	if not is_host then
		return nil
	end

	-- If nothing was captured from the game options, do nothing
	if not mode_info then
		return nil
	end

	-- If the game options were already chosen, do nothing
	if GAME_OPTIONS_SET then
		return nil
	end

	-- Set the game options as being chosen
	GAME_OPTIONS_SET = true

	-------------------------------------------------------------------------------------------------
	-- IMBA: Stat tracking stuff
	-------------------------------------------------------------------------------------------------

	-- Tracks if game options were customized or just left as default
	-- statCollection:setFlags({game_options_set = GAME_OPTIONS_SET and 1 or 0})

	-- -- Tracks the game mode
	-- if IMBA_ABILITY_MODE_RANDOM_OMG then
	-- 	statCollection:setFlags({game_mode = "Random_OMG"})
	-- 	if IMBA_RANDOM_OMG_RANDOMIZE_SKILLS_ON_DEATH then
	-- 		statCollection:setFlags({romg_mode = "ROMG_random_skills"})
	-- 	else
	-- 		statCollection:setFlags({romg_mode = "ROMG_fixed_skills"})
	-- 	end
	-- elseif IMBA_PICK_MODE_ALL_RANDOM then
	-- 	statCollection:setFlags({game_mode = "All_Random"})
	-- else
	-- 	statCollection:setFlags({game_mode = "All_Pick"})
	-- end

	-- -- Tracks same-hero selection
	-- statCollection:setFlags({same_hero = ALLOW_SAME_HERO_SELECTION and 1 or 0})

	-- -- Tracks game objective
	-- if END_GAME_ON_KILLS then
	-- 	statCollection:setFlags({kills_to_end = KILLS_TO_END_GAME_FOR_TEAM})
	-- else
	-- 	statCollection:setFlags({kills_to_end = 0})
	-- end

	-- -- Tracks gold/experience options
	-- statCollection:setFlags({gold_bonus = CUSTOM_GOLD_BONUS})
	-- statCollection:setFlags({exp_bonus = CUSTOM_XP_BONUS})

	-- -- Tracks respawn and buyback
	-- statCollection:setFlags({respawn_mult = HERO_RESPAWN_TIME_MULTIPLIER})
	-- statCollection:setFlags({buyback_mult = 100})

	-- -- Track starting gold and levels
	-- statCollection:setFlags({starting_gold = HERO_INITIAL_GOLD})
	-- statCollection:setFlags({starting_exp = HERO_STARTING_LEVEL})

	-- -- Tracks creep and tower power settings
	-- statCollection:setFlags({creep_power = CREEP_POWER_FACTOR})
	-- statCollection:setFlags({tower_power = TOWER_POWER_FACTOR})

	-- -- Tracks structure abilities and upgrades
	-- statCollection:setFlags({tower_abilities = TOWER_ABILITY_MODE and 1 or 0})
	-- statCollection:setFlags({tower_upgrades = TOWER_UPGRADE_MODE and 1 or 0})
end