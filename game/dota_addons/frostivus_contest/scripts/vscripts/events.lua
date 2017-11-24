function GameMode:OnDisconnect(keys)

	-- GetConnectionState values:
	-- 0 - no connection
	-- 1 - bot connected
	-- 2 - player connected
	-- 3 - bot/player disconnected.

	-- Typical keys:
	-- PlayerID: 2
	-- name: Zimberzimber
	-- networkid: [U:1:95496383]
	-- reason: 2
	-- splitscreenplayer: -1
	-- userid: 7
	-- xuid: 76561198055762111

	-- If the game hasn't started, or has already ended, do nothing
	if (GameRules:State_Get() >= DOTA_GAMERULES_STATE_POST_GAME) or (GameRules:State_Get() < DOTA_GAMERULES_STATE_PRE_GAME) then
		return nil
	-- Else, start tracking player's reconnect/abandon state
	else
		-- Fetch player's player and hero information
		local player_id = keys.PlayerID
		local player_name = keys.name
		local hero = PlayerResource:GetPickedHero(player_id)
		local hero_name = PlayerResource:GetPickedHeroName(player_id)
		local line_duration = 7

		-- Start tracking
		print("started keeping track of player "..player_id.."'s connection state")
		local disconnect_time = 0
		Timers:CreateTimer(1, function()
			
			-- Keep track of time disconnected
			disconnect_time = disconnect_time + 1

			-- If the player has abandoned the game, set his gold to zero and distribute passive gold towards its allies
			if hero:HasOwnerAbandoned() or disconnect_time >= ABANDON_TIME then

				-- Abandon message
				Notifications:BottomToAll({hero = hero_name, duration = line_duration})
				Notifications:BottomToAll({text = player_name.." ", duration = line_duration, continue = true})
				Notifications:BottomToAll({text = "#imba_player_abandon_message", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
				PlayerResource:SetHasAbandonedDueToLongDisconnect(player_id, true)
				print("player "..player_id.." has abandoned the game.")

				-- Decrease the player's team's player count
				PlayerResource:DecrementTeamPlayerCount(player_id)

				-- Start redistributing this player's gold to its allies
				PlayerResource:StartAbandonGoldRedistribution(player_id)

				-- If this was the last player to abandon on his team, wait 15 seconds and end the game if no one came back.
				if REMAINING_GOODGUYS <= 0 then
					Notifications:BottomToAll({text = "#imba_team_good_abandon_message", duration = line_duration, style = {color = "DodgerBlue"} })
					Timers:CreateTimer(FULL_ABANDON_TIME, function()
						if REMAINING_GOODGUYS <= 0 then
							GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
							GAME_WINNER_TEAM = "Dire"
						end
					end)
				elseif REMAINING_BADGUYS <= 0 then
					Notifications:BottomToAll({text = "#imba_team_bad_abandon_message", duration = line_duration, style = {color = "DodgerBlue"} })
					Timers:CreateTimer(FULL_ABANDON_TIME, function()
						if REMAINING_BADGUYS <= 0 then
							GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
							GAME_WINNER_TEAM = "Radiant"
						end
					end)
				end
			-- If the player has reconnected, stop tracking connection state every second
			elseif PlayerResource:GetConnectionState(player_id) == 2 then

			-- Else, keep tracking connection state
			else
				print("tracking player "..player_id.."'s connection state, disconnected for "..disconnect_time.." seconds.")
				return 1
			end
		end)
	end
end

-- The overall game state has changed
function GameMode:OnGameRulesStateChange(keys)
	GameMode:_OnGameRulesStateChange(keys)

	local new_state = GameRules:State_Get()
	CustomNetTables:SetTableValue("game_options", "game_state", {state = new_state})

	if new_state == DOTA_GAMERULES_STATE_HERO_SELECTION then
		HeroSelection:HeroListPreLoad()
	end

	if new_state == DOTA_GAMERULES_STATE_PRE_GAME then

		for i = 1, 7 do
			local altar = Entities:FindByName(nil, "altar_"..i)
			if i == 5 then
				altar:SetModel("models/altar_01/altar_01_center.vmdl")
				altar:SetOriginalModel("models/altar_01/altar_01_center.vmdl")
				altar:SetMaterialGroup("materialGroup_01")
			end
			altar:AddNewModifier(altar, nil, "modifier_altar", {})
		end

		Timers:CreateTimer(function() -- OnThink
			if CHEAT_ENABLED == false then
				if Convars:GetBool("sv_cheats") == true or GameRules:IsCheatMode() then
					if not IsInToolsMode() then
						print("Cheats have been enabled, game don't count.")
						CHEAT_ENABLED = true
					end
				end
			end
			return 1.0
		end)
	end

	if new_state == DOTA_GAMERULES_STATE_GAME_IN_PROGRESS then
		if GetMapName() == "frostivus" then
			Frostivus()
		end
	end

	if new_state == DOTA_GAMERULES_STATE_POST_GAME then
		CustomGameEventManager:Send_ServerToAllClients("end_game", {})
	end
end

dummy_created_count = 0

function GameMode:OnNPCSpawned(keys)
GameMode:_OnNPCSpawned(keys)
local npc = EntIndexToHScript(keys.entindex)

	if npc then
		if npc:GetUnitName() == "npc_dota_hero_monkey_king" then
			if TRUE_MK_HAS_SPAWNED then
				return nil
			else
				TRUE_MK_HAS_SPAWNED = true
			end
		end
		
		if npc:IsRealHero() then
			if not npc.first_spawn then
				npc.first_spawn = true
				-- Disabled boss respawning since they are tagged as heroes
				if npc:GetPlayerOwnerID() == -1 then
					npc:SetRespawnsDisabled(true)
				end
			end

			if not npc.altar then
				if npc:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
					npc.altar = 1
				else
					npc.altar = 7
				end
			end

			FrostivusAltarRespawn(npc)
		end
	end
end

function GameMode:OnEntityHurt(keys)
	--local damagebits = keys.damagebits -- This might always be 0 and therefore useless
	--if keys.entindex_attacker ~= nil and keys.entindex_killed ~= nil then
	--local entCause = EntIndexToHScript(keys.entindex_attacker)
	--local entVictim = EntIndexToHScript(keys.entindex_killed)
	--end
end

function GameMode:OnItemPickedUp(keys)
	--local heroEntity = EntIndexToHScript(keys.HeroEntityIndex)
	--local itemEntity = EntIndexToHScript(keys.ItemEntityIndex)
	--local player = PlayerResource:GetPlayer(keys.PlayerID)
	--local itemname = keys.itemname
end

function GameMode:OnPlayerReconnect(keys)
	PrintTable(keys)
end

function GameMode:OnItemPurchased( keys )
	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

function GameMode:OnAbilityUsed(keys)
local player = keys.PlayerID
local abilityname = keys.abilityname
if not abilityname then return end

local hero = PlayerResource:GetSelectedHeroEntity(player)
if not hero then return end

--	local abilityUsed = hero:FindAbilityByName(abilityname)
--	if not abilityUsed then return end
end

function GameMode:OnNonPlayerUsedAbility(keys)
	local abilityname = keys.abilityname
end

function GameMode:OnPlayerChangedName(keys)
	local newName = keys.newname
	local oldName = keys.oldName
end

-- A player leveled up an ability
function GameMode:OnPlayerLearnedAbility(keys)
	local player = EntIndexToHScript(keys.player)
	local abilityname = keys.abilityname
end

function GameMode:OnAbilityChannelFinished(keys)
	local abilityname = keys.abilityname
	local interrupted = keys.interrupted == 1
end

function GameMode:OnPlayerLevelUp(keys)
	local player = EntIndexToHScript(keys.player)
	local hero = player:GetAssignedHero()
	local hero_level = hero:GetLevel()
end

function GameMode:OnLastHit(keys)
	local isFirstBlood = keys.FirstBlood == 1
	local isHeroKill = keys.HeroKill == 1
	local isTowerKill = keys.TowerKill == 1
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local killedEnt = EntIndexToHScript(keys.EntKilled)
end

function GameMode:OnTreeCut(keys)
	local treeX = keys.tree_x
	local treeY = keys.tree_y
end

-- A rune was activated by a player
function GameMode:OnRuneActivated(keys)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local rune = keys.rune

	PrintTable(rune)

	--[[ Rune Can be one of the following types
	DOTA_RUNE_DOUBLEDAMAGE
	DOTA_RUNE_HASTE
	DOTA_RUNE_HAUNTED
	DOTA_RUNE_ILLUSION
	DOTA_RUNE_INVISIBILITY
	DOTA_RUNE_BOUNTY
	DOTA_RUNE_MYSTERY
	DOTA_RUNE_RAPIER
	DOTA_RUNE_REGENERATION
	DOTA_RUNE_SPOOKY
	DOTA_RUNE_TURBO
	]]
end

-- A player took damage from a tower
function GameMode:OnPlayerTakeTowerDamage(keys)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local damage = keys.damage
end

-- A player picked a hero
function GameMode:OnPlayerPickHero(keys)
	local hero_entity = EntIndexToHScript(keys.heroindex)
	local player_id = hero_entity:GetPlayerID()
end

-- A player killed another player in a multi-team context
function GameMode:OnTeamKillCredit(keys)
	-- Typical keys:
	-- herokills: 6
	-- killer_userid: 0
	-- splitscreenplayer: -1
	-- teamnumber: 2
	-- victim_userid: 7
	-- killer id will be -1 in case of a non-player owned killer (e.g. neutrals, towers, etc.)

	local killer_id = keys.killer_userid
	local victim_id = keys.victim_userid
	local killer_team = keys.teamnumber
end

function GameMode:OnEntityKilled( keys )
	GameMode:_OnEntityKilled( keys )

	local killed_unit = EntIndexToHScript( keys.entindex_killed )
	local killer = nil
	if keys.entindex_attacker then killer = EntIndexToHScript( keys.entindex_attacker ) end

	if killed_unit then
		if killed_unit:IsRealHero() then
			FrostivusHeroKilled(killer, killed_unit)
		end
	end
end

function GameMode:PlayerConnect(keys)

end

function GameMode:OnConnectFull(keys)
	GameMode:_OnConnectFull(keys)
	
	local entIndex = keys.index+1
	local ply = EntIndexToHScript(entIndex)
	local player_id = ply:GetPlayerID()

	print("Player has fully connected:", player_id)

--	if player.is_dev then
--		CustomGameEventManager:Send_ServerToPlayer(player:GetPlayerOwner(), "show_netgraph", {})
--	end

	ReconnectPlayer(player_id)
	PlayerResource:InitPlayerData(player_id)
end

function GameMode:OnIllusionsCreated(keys)
	local originalEntity = EntIndexToHScript(keys.original_entindex)
end

function GameMode:OnItemCombined(keys)
	-- The playerID of the hero who is buying something
	local plyID = keys.PlayerID
	if not plyID then return end
	local player = PlayerResource:GetPlayer(plyID)

	-- The name of the item purchased
	local itemName = keys.itemname 
	
	-- The cost of the item purchased
	local itemcost = keys.itemcost
end

function GameMode:OnAbilityCastBegins(keys)
	local player = PlayerResource:GetPlayer(keys.PlayerID)
	local abilityName = keys.abilityname
end

function GameMode:OnTowerKill(keys)
	local gold = keys.gold
	local killerPlayer = PlayerResource:GetPlayer(keys.killer_userid)
	local tower_team = keys.teamnumber	
end

-- This function is called whenever a player changes there custom team selection during Game Setup 
function GameMode:OnPlayerSelectedCustomTeam(keys)
	local player = PlayerResource:GetPlayer(keys.player_id)
	local success = (keys.success == 1)
	local team = keys.team_id
end

-- This function is called whenever an NPC reaches its goal position/target
function GameMode:OnNPCGoalReached(keys)
	local goalEntity = EntIndexToHScript(keys.goal_entindex)
	local nextGoalEntity = EntIndexToHScript(keys.next_goal_entindex)
	local npc = EntIndexToHScript(keys.npc_entindex)
end
