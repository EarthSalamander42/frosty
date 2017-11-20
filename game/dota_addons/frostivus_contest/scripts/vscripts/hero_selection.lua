--[[
 Hero selection module for D2E.
 This file basically just separates the functions related to hero selection from
 the other functions present in D2E.
]]

--Class definition
if HeroSelection == nil then
	HeroSelection = {}
	HeroSelection.__index = HeroSelection
end

function HeroSelection:HeroListPreLoad()
	-- Retrieve heroes info
	NPC_HEROES_CUSTOM = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")

	HeroSelection.tank_heroes = {}
	HeroSelection.dps_heroes = {}
	HeroSelection.support_heroes = {}

	HeroSelection.vanilla_heroes = {}
--	HeroSelection.new_heroes = {}
	HeroSelection.random_heroes = {}
	HeroSelection.picked_heroes = {}

	for hero, attributes in pairs(NPC_HEROES_CUSTOM) do
		if string.find(hero, "npc_dota_hero_") then

			table.insert(HeroSelection.vanilla_heroes, hero)
			HeroSelection:AddVanillaHeroToList(hero)

			-- Add a specific label (not using it right now)
--			if GetKeyValueByHeroName(hero, "IsNew") == 1 then
--				table.insert(HeroSelection.new_heroes, hero)
--			end
		end
	end

	HeroSelection:HeroList()
end

function HeroSelection:AddVanillaHeroToList(hero_name)
	if GetKeyValueByHeroName(hero_name, "FrostivusType") == "DOTA_ATTRIBUTE_TANK" then
		table.insert(HeroSelection.tank_heroes, hero_name)
	elseif GetKeyValueByHeroName(hero_name, "FrostivusType") == "DOTA_ATTRIBUTE_DPS" then
		table.insert(HeroSelection.dps_heroes, hero_name)
	elseif GetKeyValueByHeroName(hero_name, "FrostivusType") == "DOTA_ATTRIBUTE_SUPPORT" then
		table.insert(HeroSelection.support_heroes, hero_name)
	end

	a = {}
	for k, n in pairs(HeroSelection.tank_heroes) do
		table.insert(a, n)
		HeroSelection.tank_heroes = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.tank_heroes, n)
	end

	a = {}
	for k, n in pairs(HeroSelection.dps_heroes) do
		table.insert(a, n)
		HeroSelection.dps_heroes = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.dps_heroes, n)
	end

	a = {}
	for k, n in pairs(HeroSelection.support_heroes) do
		table.insert(a, n)
		HeroSelection.support_heroes = {}
	end
	table.sort(a)
	for i,n in ipairs(a) do
		table.insert(HeroSelection.support_heroes, n)
	end
end

local only_once_alt = false
function HeroSelection:HeroList()
	CustomNetTables:SetTableValue("game_options", "hero_list", {
		Tank = HeroSelection.tank_heroes,
		Dps = HeroSelection.dps_heroes,
		Support = HeroSelection.support_heroes,
--		New = HeroSelection.new_heroes,
		Picked = HeroSelection.picked_heroes
	})

	if only_once_alt == false then
		only_once_alt = true
		HeroSelection:Start()
	end
end

--[[
	Start
	Call this function from your gamemode once the gamestate changes
	to pre-game to start the hero selection.
]]
function HeroSelection:Start()
	HeroSelection.HorriblyImplementedReconnectDetection = {}
	HeroSelection.radiantPicks = {}
	HeroSelection.direPicks = {}
	HeroSelection.playerPicks = {}
	HeroSelection.playerPickState = {}
	HeroSelection.numPickers = 0

	HeroSelection.pick_sound_dummy_good = CreateUnitByName("npc_dummy_unit", Entities:FindByName(nil, "altar_1"):GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
	HeroSelection.pick_sound_dummy_good:EmitSound("Imba.PickPhaseDrums")
	HeroSelection.pick_sound_dummy_bad = CreateUnitByName("npc_dummy_unit", Entities:FindByName(nil, "altar_7"):GetAbsOrigin(), false, nil, nil, DOTA_TEAM_GOODGUYS)
	HeroSelection.pick_sound_dummy_bad:EmitSound("Imba.PickPhaseDrums")

	-- Figure out which players have to pick
	for pID = 0, DOTA_MAX_PLAYERS -1 do
		if PlayerResource:IsValidPlayer( pID ) then
			HeroSelection.numPickers = self.numPickers + 1
			HeroSelection.playerPickState[pID] = {}
			HeroSelection.playerPickState[pID].pick_state = "selecting_hero"
			HeroSelection.playerPickState[pID].repick_state = false
			HeroSelection.HorriblyImplementedReconnectDetection[pID] = true			
		end
	end

	-- Start the pick timer
	HeroSelection.TimeLeft = HERO_SELECTION_TIME
	Timers:CreateTimer( 0.04, HeroSelection.Tick )

	-- Keep track of the number of players that have picked
	HeroSelection.playersPicked = 0

	-- Listen for pick and repick events
	HeroSelection.listener_select = CustomGameEventManager:RegisterListener("hero_selected", HeroSelection.HeroSelect )
	HeroSelection.listener_random = CustomGameEventManager:RegisterListener("hero_randomed", HeroSelection.RandomHero )
	HeroSelection.listener_imba_random = CustomGameEventManager:RegisterListener("hero_imba_randomed", HeroSelection.RandomImbaHero )
	HeroSelection.listener_repick = CustomGameEventManager:RegisterListener("hero_repicked", HeroSelection.HeroRepicked )
	HeroSelection.listener_ui_initialize = CustomGameEventManager:RegisterListener("ui_initialized", HeroSelection.UiInitialized )
	HeroSelection.listener_abilities_requested = CustomGameEventManager:RegisterListener("pick_abilities_requested", HeroSelection.PickAbilitiesRequested )

	-- Play relevant pick lines
	EmitGlobalSound("announcer_announcer_type_all_pick")
end

-- Horribly implemented reconnection detection
function HeroSelection:UiInitialized(event)
	Timers:CreateTimer(0.04, function()
		HeroSelection.HorriblyImplementedReconnectDetection[event.PlayerID] = true
	end)
end 

--[[
	Tick
	A tick of the pick timer.
	Params:
		- event {table} - A table containing PlayerID and HeroID.
]]
function HeroSelection:Tick() 
	-- Send a time update to all clients
	if HeroSelection.TimeLeft >= 0 then
		CustomGameEventManager:Send_ServerToAllClients( "picking_time_update", {time = HeroSelection.TimeLeft} )
	end

	-- Tick away a second of time
	HeroSelection.TimeLeft = HeroSelection.TimeLeft - 1
	if HeroSelection.TimeLeft < 0 then
		-- End picking phase
		HeroSelection:EndPicking()
		return nil
	elseif HeroSelection.TimeLeft >= 0 then
		return 1
	end
end

function HeroSelection:RandomHero(event)
local id = event.PlayerID
if PlayerResource:GetConnectionState(id) == 1 then
	print("Bot, ignoring..")
else
	if HeroSelection.playerPickState[id].pick_state ~= "selecting_hero" then
		return nil
	end
end

	-- Roll a random hero
	local random_hero = HeroSelection.random_heroes[RandomInt(1, #HeroSelection.random_heroes)]

	for _, picked_hero in pairs(HeroSelection.picked_heroes) do
		if random_hero == picked_hero then
			print("Hero picked, random again...")
			HeroSelection:RandomHero({PlayerID = id})
			break
		end
	end

	-- Flag the player as having randomed
	PlayerResource:SetHasRandomed(id)

	-- If it's a valid hero, allow the player to select it
	HeroSelection:HeroSelect({PlayerID = id, HeroName = random_hero, HasRandomed = true})

	-- The person has randomed (separate from Set/HasRandomed, because those cannot be unset)
	HeroSelection.playerPickState[id].random_state = true

	-- Send a Custom Message in PreGame Chat to tell other players this player has randomed
	Chat:PlayerRandomed(id, PlayerResource:GetPlayer(id), PlayerResource:GetTeam(id), random_hero)
end

--[[
	HeroSelect
	A player has selected a hero. This function is caled by the CustomGameEventManager
	once a 'hero_selected' event was seen.
	Params:
		- event {table} - A table containing PlayerID and HeroID.
]]
function HeroSelection:HeroSelect(event)

	-- If this player has not picked yet give him the hero
	if PlayerResource:GetConnectionState(event.PlayerID) == 1 then
		HeroSelection:AssignHero( event.PlayerID, event.HeroName )
	else
		if not HeroSelection.playerPicks[ event.PlayerID ] then
			HeroSelection.playersPicked = HeroSelection.playersPicked + 1
			HeroSelection.playerPicks[ event.PlayerID ] = event.HeroName

			-- Add the picked hero to the list of picks of the relevant team
			if PlayerResource:GetTeam(event.PlayerID) == DOTA_TEAM_GOODGUYS then
				HeroSelection.radiantPicks[#HeroSelection.radiantPicks + 1] = event.HeroName
			else
				HeroSelection.direPicks[#HeroSelection.direPicks + 1] = event.HeroName
			end

			table.insert(HeroSelection.picked_heroes, event.HeroName)

			-- Send a pick event to all clients
			local has_randomed = false
			if event.HasRandomed then has_randomed = true end
			CustomGameEventManager:Send_ServerToAllClients("hero_picked", {PlayerID = event.PlayerID, HeroName = event.HeroName, Team = PlayerResource:GetTeam(event.PlayerID), HasRandomed = has_randomed})
			if PlayerResource:GetConnectionState(event.PlayerID) ~= 1 then
				HeroSelection.playerPickState[event.PlayerID].pick_state = "selected_hero"
			end

			-- Assign the hero if picking is over
			if HeroSelection.TimeLeft <= 0 and HeroSelection.playerPickState[event.PlayerID].pick_state ~= "in_game" then
				HeroSelection:AssignHero( event.PlayerID, event.HeroName )
				HeroSelection.playerPickState[event.PlayerID].pick_state = "in_game"
				CustomGameEventManager:Send_ServerToAllClients("hero_loading_done", {} )
			end

			-- Play pick sound to the player
			EmitSoundOnClient("HeroPicker.Selected", PlayerResource:GetPlayer(event.PlayerID))
		end
	end

	-- If this is All Random and the player picked a hero manually, refuse it
	if IMBA_PICK_MODE_ALL_RANDOM or IMBA_PICK_MODE_ALL_RANDOM_SAME_HERO and (not event.HasRandomed) then
		return nil
	end

    for _, picked_hero in pairs(HeroSelection.radiantPicks) do
        if event.HeroName == picked_hero then
            return nil
        end
    end
        
	for _, picked_hero in pairs(HeroSelection.direPicks) do
        if event.HeroName == picked_hero then
            return nil
        end
    end

	--Check if all heroes have been picked
--	if HeroSelection.playersPicked >= HeroSelection.numPickers then

		--End picking
--		HeroSelection.TimeLeft = 0
--	end
end

-- Handles player repick
function HeroSelection:HeroRepicked( event )
	local player_id = event.PlayerID
	local hero_name = HeroSelection.playerPicks[player_id]

	-- Fire repick event to all players
	CustomGameEventManager:Send_ServerToAllClients("hero_unpicked", {PlayerID = player_id, HeroName = hero_name, Team = PlayerResource:GetTeam(player_id)})

	-- Remove the player's currently picked hero
	HeroSelection.playerPicks[ player_id ] = nil

	-- Remove the picked hero to the list of picks of the relevant team
	if PlayerResource:GetTeam(player_id) == DOTA_TEAM_GOODGUYS then
		for pick_index, team_pick in pairs(HeroSelection.radiantPicks) do
			if team_pick == hero_name then
				table.remove(HeroSelection.radiantPicks, pick_index)
			end
		end
	else
		for pick_index, team_pick in pairs(HeroSelection.direPicks) do
			if team_pick == hero_name then
				table.remove(HeroSelection.direPicks, pick_index)
			end
		end
	end

	-- Decrement player pick count
	HeroSelection.playersPicked = HeroSelection.playersPicked - 1

	-- Flag the player as having repicked
	PlayerResource:CustomSetHasRepicked(player_id, true)
	HeroSelection.playerPickState[player_id].pick_state = "selecting_hero"
	HeroSelection.playerPickState[player_id].repick_state = true
	HeroSelection.playerPickState[player_id].random_state = false

	-- Play pick sound to the player
	EmitSoundOnClient("ui.pick_repick", PlayerResource:GetPlayer(player_id))
end

--[[
	EndPicking
	The final function of hero selection which is called once the selection is done.
	This function spawns the heroes for the players and signals the picking screen
	to disappear.
]]
function HeroSelection:EndPicking()
local time = 0.0

	--Stop listening to events (except picks)
	CustomGameEventManager:UnregisterListener( self.listener_repick )

	-- Let all clients know the picking phase has ended
	CustomGameEventManager:Send_ServerToAllClients("picking_done", {} )

	-- Assign the picked heroes to all players that have picked
	for player_id = 0, HeroSelection.numPickers do
		if HeroSelection.playerPicks[player_id] and HeroSelection.playerPickState[player_id].pick_state ~= "in_game" then
			HeroSelection:AssignHero(player_id, HeroSelection.playerPicks[player_id])
			HeroSelection.playerPickState[player_id].pick_state = "in_game"
		end
	end

	-- Let all clients know hero loading has ended
	CustomGameEventManager:Send_ServerToAllClients("hero_loading_done", {} )

	-- Stop picking phase music
	StopSoundOn("Imba.PickPhaseDrums", HeroSelection.pick_sound_dummy_good)
	StopSoundOn("Imba.PickPhaseDrums", HeroSelection.pick_sound_dummy_bad)

	-- Destroy dummy!
	UTIL_Remove(HeroSelection.pick_sound_dummy_good) 
	UTIL_Remove(HeroSelection.pick_sound_dummy_bad) 
end

--[[
	AssignHero
	Assign a hero to the player. Replaces the current hero of the player
	with the selected hero, after it has finished precaching.
	Params:
		- player_id {integer} - The playerID of the player to assign to.
		- hero_name {string} - The unit name of the hero to assign (e.g. 'npc_dota_hero_rubick')
]]
function HeroSelection:AssignHero(player_id, hero_name)
	PrecacheUnitByNameAsync(hero_name, function()
		-- Dummy invisible wisp
		local wisp = PlayerResource:GetPlayer(player_id):GetAssignedHero()
		local hero = PlayerResource:ReplaceHeroWith(player_id, hero_name, 0, 0 )
		hero.pID = player_id
--		print(hero.pID)
--		print(hero_name)

		-- If this is a "real" wisp, tag it
		if hero:GetUnitName() == "npc_dota_hero_wisp" then
			hero.is_real_wisp = true
		end

		-------------------------------------------------------------------------------------------------
		-- IMBA: First hero spawn initialization
		-------------------------------------------------------------------------------------------------
		
		hero:RespawnHero(false, false)
		PlayerResource:SetCameraTarget(player_id, hero)
		Timers:CreateTimer(FrameTime(), function()
			PlayerResource:SetCameraTarget(player_id, nil)
		end)

		-- Set the picked hero for this player
		PlayerResource:SetPickedHero(player_id, hero)

		-- Initializes player data if this is a bot
		if PlayerResource:GetConnectionState(player_id) == 1 then
			PlayerResource:InitPlayerData(player_id)
		end

		-- Make heroes briefly visible on spawn (to prevent bad fog interactions)
		Timers:CreateTimer(0.5, function()
			hero:MakeVisibleToTeam(DOTA_TEAM_GOODGUYS, 0.5)
			hero:MakeVisibleToTeam(DOTA_TEAM_BADGUYS, 0.5)
		end)

		-- Set up initial gold
		-- local has_randomed = PlayerResource:HasRandomed(player_id)
		-- This randomed variable gets reset when the player chooses to Repick, so you can detect a rerandom
		local has_randomed = HeroSelection.playerPickState[player_id].random_state
		local has_repicked = PlayerResource:CustomGetHasRepicked(player_id)

		if has_repicked and has_randomed then
			PlayerResource:SetGold(player_id, HERO_INITIAL_GOLD +100, false)
		elseif has_repicked then
			PlayerResource:SetGold(player_id, HERO_INITIAL_GOLD -100, false)
		elseif has_randomed or IMBA_PICK_MODE_ALL_RANDOM or IMBA_PICK_MODE_ALL_RANDOM_SAME_HERO then
			PlayerResource:SetGold(player_id, HERO_INITIAL_GOLD +200, false)
		else
			PlayerResource:SetGold(player_id, HERO_INITIAL_GOLD, false)
		end

		-- fail-safe, check it really needed else remove it
		Timers:CreateTimer(3.0, function()
			if not hero:HasModifier("modifier_command_restricted") then
				PlayerResource:SetCameraTarget(player_id, nil)
			end
			UTIL_Remove(wisp)
		end)

		-- Set initial spawn setup as having been done
		PlayerResource:IncrementTeamPlayerCount(player_id)
		CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(player_id), "picking_done", {})
	end, player_id)
end

-- Sends this hero's nonhidden abilities to the client
function HeroSelection:PickAbilitiesRequested(event)
	CustomGameEventManager:Send_ServerToPlayer(PlayerResource:GetPlayer(event.PlayerID), "pick_abilities", { heroAbilities = HeroSelection:GetPickScreenAbilities(event.HeroName) })
end

-- Returns an array with the hero's non-hidden abilities
function HeroSelection:GetPickScreenAbilities(hero_name)
local hero_abilities = {}

	for i = 1, 9 do
		if GetKeyValueByHeroName(hero_name, "Ability"..i) ~= nil then
			hero_abilities[i] = GetKeyValueByHeroName(hero_name, "Ability"..i)
		end
	end
	return hero_abilities
end
