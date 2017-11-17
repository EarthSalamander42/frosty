function PrintAll(t)
	for k,v in pairs(t) do
		print(k,v)
	end
end

function MergeTables( t1, t2 )
	for name,info in pairs(t2) do
		t1[name] = info
	end
end

function AddTableToTable( t1, t2)
	for k,v in pairs(t2) do
		table.insert(t1, v)
	end
end

function PrintTable(t, indent, done)
	--print ( string.format ('PrintTable type %s', type(keys)) )
	if type(t) ~= "table" then return end

	done = done or {}
	done[t] = true
	indent = indent or 0

	local l = {}
	for k, v in pairs(t) do
	table.insert(l, k)
	end

	table.sort(l)
	for k, v in ipairs(l) do
	-- Ignore FDesc
	if v ~= 'FDesc' then
		local value = t[v]

		if type(value) == "table" and not done[value] then
		done [value] = true
		print(string.rep ("\t", indent)..tostring(v)..":")
		PrintTable (value, indent + 2, done)
		elseif type(value) == "userdata" and not done[value] then
		done [value] = true
		print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
		PrintTable ((getmetatable(value) and getmetatable(value).__index) or getmetatable(value), indent + 2, done)
		else
		if t.FDesc and t.FDesc[v] then
			print(string.rep ("\t", indent)..tostring(t.FDesc[v]))
		else
			print(string.rep ("\t", indent)..tostring(v)..": "..tostring(value))
		end
		end
	end
	end
end

-- Colors
COLOR_NONE = '\x06'
COLOR_GRAY = '\x06'
COLOR_GREY = '\x06'
COLOR_GREEN = '\x0C'
COLOR_DPURPLE = '\x0D'
COLOR_SPINK = '\x0E'
COLOR_DYELLOW = '\x10'
COLOR_PINK = '\x11'
COLOR_RED = '\x12'
COLOR_LGREEN = '\x15'
COLOR_BLUE = '\x16'
COLOR_DGREEN = '\x18'
COLOR_SBLUE = '\x19'
COLOR_PURPLE = '\x1A'
COLOR_ORANGE = '\x1B'
COLOR_LRED = '\x1C'
COLOR_GOLD = '\x1D'

-- Returns a random value from a non-array table
function RandomFromTable(table)
	local array = {}
	local n = 0
	for _,v in pairs(table) do
		array[#array+1] = v
		n = n + 1
	end

	if n == 0 then return nil end

	return array[RandomInt(1,n)]
end

-- Picks a random tower ability of level in the interval [level - 1, level]
function GetRandomTowerAbility(tier, ability_table)

	local ability = RandomFromTable(ability_table[tier])	

	return ability
end

-- Precaches an unit, or, if something else is being precached, enters it into the precache queue
function PrecacheUnitWithQueue( unit_name )
	
	Timers:CreateTimer(0, function()

		-- If something else is being precached, wait two seconds
		if UNIT_BEING_PRECACHED then
			return 2

		-- Otherwise, start precaching and block other calls from doing so
		else
			UNIT_BEING_PRECACHED = true
			PrecacheUnitByNameAsync(unit_name, function(...) end)

			-- Release the queue after one second
			Timers:CreateTimer(2, function()
				UNIT_BEING_PRECACHED = false
			end)
		end
	end)
end

-- Initializes heroes' innate abilities
function InitializeInnateAbilities( hero )	

	-- Cycle through all of the heroes' abilities, and upgrade the innates ones
	for i = 0, 15 do		
		local current_ability = hero:GetAbilityByIndex(i)		
		if current_ability and current_ability.IsInnateAbility then
			if current_ability:IsInnateAbility() then
				current_ability:SetLevel(1)
			end
		end
	end
end

function IndexAllTowerAbilities()
	local ability_table = {}
	local tier_one_abilities = {}
	local tier_two_abilities = {}
	local tier_three_abilities = {}
	local tier_active_abilities = {}

	for _,tier in pairs(TOWER_ABILITIES) do		

		for _,ability in pairs(tier) do
			if tier == TOWER_ABILITIES.tier_one then
				table.insert(tier_one_abilities, ability.ability_name)
			elseif tier == TOWER_ABILITIES.tier_two then
				table.insert(tier_two_abilities, ability.ability_name)
			elseif tier == TOWER_ABILITIES.tier_three then
				table.insert(tier_three_abilities, ability.ability_name)
			else
				table.insert(tier_active_abilities, ability.ability_name)
			end			
		end
	end

	table.insert(ability_table, tier_one_abilities)
	table.insert(ability_table, tier_two_abilities)
	table.insert(ability_table, tier_three_abilities)
	table.insert(ability_table, tier_active_abilities)

	return ability_table
end

-- Upgrades a tower's abilities
function UpgradeTower(tower)
	for i = 0, tower:GetAbilityCount()-1 do
		local ability = tower:GetAbilityByIndex(i)
		if ability and ability:GetLevel() < ability:GetMaxLevel() then			
			ability:SetLevel(ability:GetLevel() + 1)
			break
		end
	end
end

-- Randoms an ability of a certain tier for the Ancient
function GetAncientAbility( tier )

	-- Tier 1 abilities
	if tier == 1 then
		local ability_list = {
			"venomancer_poison_nova",
			"juggernaut_blade_fury"			
		}

		return ability_list[RandomInt(1, #ability_list)]

	-- Tier 2 abilities
	elseif tier == 2 then
		local ability_list = {
			"abaddon_borrowed_time",
			"nyx_assassin_spiked_carapace",
			"axe_berserkers_call"
		}

		return ability_list[RandomInt(1, #ability_list)]

	-- Tier 3 abilities
	elseif tier == 3 then
		local ability_list = {
			"tidehunter_ravage",
			"magnataur_reverse_polarity",
--			"phoenix_supernova",
		}

		return ability_list[RandomInt(1, #ability_list)]
	end
	
	return nil
end

-- Gold bag pickup event function
function GoldPickup(event)
	if IsServer() then
		local item = EntIndexToHScript( event.ItemEntityIndex )
		local owner = EntIndexToHScript( event.HeroEntityIndex )
		local gold_per_bag = item:GetCurrentCharges()
		PlayerResource:ModifyGold( owner:GetPlayerID(), gold_per_bag, true, 0 )
		SendOverheadEventMessage( owner, OVERHEAD_ALERT_GOLD, owner, gold_per_bag, nil )
		UTIL_Remove( item ) -- otherwise it pollutes the player inventory
	end
end

function getkvValues(tEntity, ...) -- KV Values look hideous in finished code, so this function will parse through all sent KV's for tEntity (typically self)
	local values = {...}
	local data = {}
	for i,v in ipairs(values) do
		table.insert(data,tEntity:GetSpecialValueFor(v))
	end
	return unpack(data)
end

-- COOKIES: PreGame Chat System, created by Mahou Shoujo
Chat = Chat or class({})

function Chat:constructor(players, users, teamColors)
	self.players = players
	self.teamColors = TEAM_COLORS
	self.users = users

	CustomGameEventManager:RegisterListener("custom_chat_say", function(id, ...) Dynamic_Wrap(self, "OnSay")(self, ...) end)
	print("CHAT: constructing...")
end

function Chat:OnSay(args)
	local id = args.PlayerID
	local message = args.message
	local player = PlayerResource:GetPlayer(id)

	message = message:gsub("^%s*(.-)%s*$", "%1") -- Whitespace trim
	message = message:gsub("^(.{0,256})", "%1") -- Limit string length

	if message:len() == 0 then
		return
	end

	local arguments = {
		hero = player,
		color = TEAM_COLORS[player:GetPlayerID()],
		player = id,
		message = args.message,
		team = args.team,
--		IsFiretoad = player:IsFireToad() -- COOKIES: Define this function later, can also be used for all devs
	}

	if args.team then
		CustomGameEventManager:Send_ServerToTeam(player:GetTeamNumber(), "custom_chat_say", arguments)
--	else -- i leave this here if someday we want to create a whole new chat, and not only a pregame chat
--		CustomGameEventManager:Send_ServerToAllClients("custom_chat_say", arguments)
	end
end

function Chat:PlayerRandomed(id, hero, teamLocal, name)
	local hero = PlayerResource:GetPlayer(id)
	local shared = {
		color = TEAM_COLORS[hero:GetPlayerID()],
		player = id,
--		IsFiretoad = player:IsFireToad()
	}

	local localArgs = vlua.clone(shared)
	localArgs.hero = hero
	localArgs.team = teamLocal
	localArgs.name = name

	CustomGameEventManager:Send_ServerToAllClients("custom_randomed_message", localArgs)
end

function SystemMessage(token, vars)
	CustomGameEventManager:Send_ServerToAllClients("custom_system_message", { token = token or "", vars = vars or {}})
end

function ReconnectPlayer(player_id)
	print("Player is reconnecting:", player_id)
	-- Reinitialize the player's pick screen panorama, if necessary
	if HeroSelection.HorriblyImplementedReconnectDetection then
		HeroSelection.HorriblyImplementedReconnectDetection[player_id] = false
		Timers:CreateTimer(2.0, function()
			if HeroSelection.HorriblyImplementedReconnectDetection[player_id] then
				local pick_state = HeroSelection.playerPickState[player_id].pick_state
				local repick_state = HeroSelection.playerPickState[player_id].repick_state

				local data = {
					PlayerID = player_id,
					PickedHeroes = HeroSelection.picked_heroes,
					pickState = pick_state,
					repickState = repick_state
				}

				print("HERO SELECTION ARGS:")
				print("Player ID:", player_id)
				print("Pick State:", pick_state)
				print("Re-Pick State:", repick_state)

				print("Sending picked heroes...")
				PrintTable(HeroSelection.picked_heroes)
				CustomGameEventManager:Send_ServerToAllClients("player_reconnected", {PlayerID = player_id, PickedHeroes = HeroSelection.picked_heroes, pickState = pick_state, repickState = repick_state})
			else
				print("Not fully reconnected yet:", player_id)
				return 0.1
			end
		end)

		-- If this is a reconnect from abandonment due to a long disconnect, remove the abandon state
		if PlayerResource:GetHasAbandonedDueToLongDisconnect(player_id) then
			local player_name = keys.name
			local hero = PlayerResource:GetPickedHero(player_id)
			local hero_name = PlayerResource:GetPickedHeroName(player_id)
			local line_duration = 7
			Notifications:BottomToAll({hero = hero_name, duration = line_duration})
			Notifications:BottomToAll({text = player_name.." ", duration = line_duration, continue = true})
			Notifications:BottomToAll({text = "#imba_player_reconnect_message", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})
			PlayerResource:IncrementTeamPlayerCount(player_id)

			-- Stop redistributing gold to allies, if applicable
			PlayerResource:StopAbandonGoldRedistribution(player_id)
		end
	else
		print("Player "..player_id.." has not fully connected before this time")
	end
end

function UpdateBossBar(boss, team)
	CustomNetTables:SetTableValue("game_options", "boss", {
		level = boss:GetLevel(),
		HP = boss:GetHealth(),
		HP_alt = boss:GetHealthPercent(),
		maxHP = boss:GetMaxHealth(),
		label = boss:GetUnitName(),
		short_label = string.gsub(boss:GetUnitName(), "npc_frostivus_boss_", ""),
		team_contest = team
	})
end
