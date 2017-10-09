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

-- This function is responsible for cleaning dummy units and wisps that may have accumulated
function StartGarbageCollector()	
--	print("started collector")

	-- Find all dummy units in the game
	local dummies = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)		

	-- Cycle each dummy. If it is alive for more than 1 minute, delete it.
	local gametime = GameRules:GetGameTime()
	for _, dummy in pairs(dummies) do
		if dummy:GetUnitName() == "npc_dummy_unit" then			
			local dummy_creation_time = dummy:GetCreationTime()
			if gametime - dummy_creation_time > 60 then
				print("NUKING A LOST DUMMY!")
				UTIL_Remove(dummy)
			else
				print("dummy is still kinda new. Not removing it!")
			end
		end
	end
end

-- This function is responsible for deciding which team is behind, if any, and store it at a nettable.
function DefineLosingTeam()
-- Losing team is defined as a team that is both behind in both the sums of networth and levels.
local radiant_networth = 0
local radiant_levels = 0
local dire_networth = 0
local dire_levels = 0

	for i = 0, DOTA_MAX_TEAM_PLAYERS-1 do
		if PlayerResource:IsValidPlayer(i) then

			-- Only count connected players or bots
			if PlayerResource:GetConnectionState(i) == 1 or PlayerResource:GetConnectionState(i) == 2 then

			-- Get player
			local player = PlayerResource:GetPlayer(i)
			
				if player then				
					-- Get team
					local team = player:GetTeam()				

					-- Get level, add it to the sum
					local level = player:GetAssignedHero():GetLevel()				

					-- Get networth
					local hero_networth = 0
					for i = 0, 8 do
						local item = player:GetAssignedHero():GetItemInSlot(i)
						if item then
							hero_networth = hero_networth + GetItemCost(item:GetName())						
						end
					end

					-- Add to the relevant team
					if team == DOTA_TEAM_GOODGUYS then					
						radiant_networth = radiant_networth + hero_networth					
						radiant_levels = radiant_levels + level					
					else					
						dire_networth = dire_networth + hero_networth					
						dire_levels = dire_levels + level					
					end				
				end
			end
		end
	end	

	-- Check for the losing team. A team must be behind in both levels and networth.
	if (radiant_networth < dire_networth) and (radiant_levels < dire_levels) then
		-- Radiant is losing		
		CustomNetTables:SetTableValue("gamerules", "losing_team", {losing_team = DOTA_TEAM_GOODGUYS})
	elseif (radiant_networth > dire_networth) and (radiant_levels > dire_levels) then
		-- Dire is losing		
		CustomNetTables:SetTableValue("gamerules", "losing_team", {losing_team = DOTA_TEAM_BADGUYS})
	else -- No team is losing - one of the team is better on levels, the other on gold. No experience bonus in this case		
		CustomNetTables:SetTableValue("gamerules", "losing_team", {losing_team = 0})		
	end
end
