nCOUNTDOWNTIMER = 0
nCOUNTDOWNTIMER_PRESENT = 181
PHASE = 0
FROSTIVUS_WINNER = 2
COUNT_DOWN = 1
PHASE_TIME = {}
PHASE_TIME[1] = 601
PHASE_TIME[2] = 1
PRESENT_SCORE_2 = 0
PRESENT_SCORE_3 = 0
PRESENT_SPAWN_TIME = 10

if IsInToolsMode() then 
	PHASE_TIME[1] = 601
	PHASE_TIME[2] = 1
	PRESENT_SPAWN_TIME = 10
end

function Frostivus()
	for player_id = 0, PlayerResource:GetPlayerCount() -1 do
		if PlayerResource:GetPlayer(player_id) then
			if PlayerResource:GetTeam(player_id) == DOTA_TEAM_GOODGUYS then
				--sounds[6] = "Conquest.Stinger.GameBegin" -- Lich fight start music
				--sounds[1] = "Conquest.Stinger.HulkCreep.Generic" -- " oooOOOOOOhhhh"
				--sounds[1] = "DOTAMusic_Stinger.003" -- item unboxing
				--sounds[2] = "DOTAMusic_Stinger.004" -- mystery music
				EmitSoundOnClient("FrostivusGameStart.RadiantSide", PlayerResource:GetPlayer(player_id))
			elseif PlayerResource:GetTeam(player_id) == DOTA_TEAM_BADGUYS then
				EmitSoundOnClient("FrostivusGameStart.DireSide", PlayerResource:GetPlayer(player_id))
			end

			if PlayerResource:GetPlayer(player_id):GetAssignedHero() then
				PlayerResource:GetPlayer(player_id):GetAssignedHero():RemoveModifierByName("modifier_command_restricted")
				PlayerResource:GetPlayer(player_id):GetAssignedHero():AddNewModifier(nil, nil, "modifier_river", {})
			end
		end
	end

	CustomNetTables:SetTableValue("game_options", "radiant", {score = 0})
	CustomNetTables:SetTableValue("game_options", "dire", {score = 0})

	-- Spawn bosses
	SpawnZeus(BOSS_SPAWN_POINT_TABLE.zeus)
	SpawnVenomancer(BOSS_SPAWN_POINT_TABLE.venomancer)
	SpawnTreant(BOSS_SPAWN_POINT_TABLE.treant)
	SpawnNevermore(BOSS_SPAWN_POINT_TABLE.nevermore)
	SpawnTusk()
	SpawnMegaGreevil()

	-- Launch presents every few seconds
	local present_wave_count = 0
	Timers:CreateTimer(0, function()
		PresentWave(4 + math.floor(0.34 * present_wave_count) )
		present_wave_count = present_wave_count + 1
		return PRESENT_SPAWN_TIME
	end)
end

function FrostivusIncreaseTimer(time)
	nCOUNTDOWNTIMER = nCOUNTDOWNTIMER + time
end

function FrostivusHeroKilled(killer, hero)

	-- Player death
	if hero:HasModifier("modifier_fighting_boss") then

		-- If any hero is alive, do nothing
		local fighting_modifier = hero:FindModifierByName("modifier_fighting_boss")
		local altar_handle = fighting_modifier.altar_handle
		local altar_name = altar_handle:GetName()
		local fight_heroes = altar_handle:FindModifierByName("modifier_altar_active").fighting_heroes
		for _, hero in pairs(fight_heroes) do
			if hero and hero:IsAlive() and hero:HasModifier("modifier_fighting_boss") then
				return nil
			end
		end

		-- Else, end the encounter
		-- Notify the console that a boss fight (capture attempt) has ended in failure
		local losing_team = hero:GetTeam()
		print("boss on altar "..altar_name.." defeated team "..losing_team)

		-- Unlock the arena
		UnlockArena(altar_name, false, losing_team, nil)

		-- Delete the boss AI thinker modifier and re-apply the capture attempt detection modifier
		local nearby_bosses = FindUnitsInRadius(hero:GetTeam(), altar_handle:GetAbsOrigin(), nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
		for _, boss in pairs(nearby_bosses) do
			boss:Stop()
			if boss:HasModifier("modifier_frostivus_boss") then
				if boss:HasModifier("boss_thinker_zeus") then
					boss:RemoveModifierByName("boss_thinker_zeus")
					boss:AddNewModifier(nil, nil, "capture_start_trigger", {boss_name = "zeus", altar_handle = altar_name})
					boss:SetAbsOrigin(altar_handle:GetAbsOrigin() + Vector(0, 300, 0))
				elseif boss:HasModifier("boss_thinker_venomancer") then
					boss:RemoveModifierByName("boss_thinker_venomancer")
					boss:AddNewModifier(nil, nil, "capture_start_trigger", {boss_name = "venomancer", altar_handle = altar_name})
					boss:SetAbsOrigin(altar_handle:GetAbsOrigin() + Vector(0, 300, 0))
				elseif boss:HasModifier("boss_thinker_treant") then
					boss:RemoveModifierByName("boss_thinker_treant")
					boss:AddNewModifier(nil, nil, "capture_start_trigger", {boss_name = "treant", altar_handle = altar_name})
					boss:SetAbsOrigin(altar_handle:GetAbsOrigin() + Vector(0, 50, 0))
				elseif boss:HasModifier("boss_thinker_nevermore") then
					boss:RemoveModifierByName("boss_thinker_nevermore")
					boss:AddNewModifier(nil, nil, "capture_start_trigger", {boss_name = "nevermore", altar_handle = altar_name})
					boss:SetAbsOrigin(altar_handle:GetAbsOrigin() + Vector(0, 300, 0))
				end

				-- Destroy adds
				local nearby_summons = FindUnitsInRadius(boss:GetTeam(), altar_handle:GetAbsOrigin(), nil, 2200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
				for _,summon in pairs(nearby_summons) do
					if not summon:HasModifier("modifier_frostivus_boss") then
						summon:Kill(nil, summon)
					end
				end

				-- Reset boss status & position
				boss:Purge(true, true, false, true, true)
				boss:Heal(999999, nil)
				boss:GiveMana(boss:GetMaxMana())
				boss:FaceTowards(altar_handle:GetAbsOrigin())
			end
		end
	end
end

function FrostivusAltarRespawn(hero)
	-- fix boss respawning at dire fountain
	if hero:GetPlayerID() ~= -1 and hero:IsRealHero() then
		-- Base spawn
		local respawn_position
		if hero.altar == 1 or hero.altar == 7 then
			local building = Entities:FindByName(nil, "altar_"..hero.altar)
			respawn_position = building:GetAbsOrigin() + RandomVector(RandomFloat(300, 800))
		-- Zeus
		elseif hero.altar == 2 then
			respawn_position = Vector(-3214, 4789, 128)
		-- Veno
		elseif hero.altar == 3 then
			respawn_position = Vector(-3108, -3725, 128)
		-- Lich
		elseif hero.altar == 4 then
			respawn_position = Vector(1127, 905, 128)
		-- Treant
		elseif hero.altar == 5 then
			respawn_position = Vector(2490, 3253, 128)
		-- SF
		elseif hero.altar == 6 then
			respawn_position = Vector(2594, -3759, 128)
		end

		if hero:GetLevel() <= 10 then
			hero:SetTimeUntilRespawn(10)
		else
			hero:SetTimeUntilRespawn(hero:GetLevel())
		end

		print(hero:GetUnitName(), hero.altar, respawn_position)
		FindClearSpaceForUnit(hero, respawn_position, true)
	end
end

function DoorThink(team)
	if IsServer() then
		local door = Entities:FindByName(nil, "gate_0"..team)
		local door_obs = Entities:FindAllByName(door:GetName().."_obs")
		local door_opened = false

		Timers:CreateTimer(function()
			local units = FindUnitsInRadius(team, door:GetAbsOrigin(), nil, 800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)

			if #units > 0 and door_opened == false then
				for _, obs in pairs(door_obs) do
					obs:SetEnabled(false, true)
				end

				door_opened = true
				DoEntFire(door:GetName(), "SetAnimation", "gate_02_open", 0, nil, nil)
			elseif #units == 0 and door_opened == true then
				for _, obs in pairs(door_obs) do
					obs:SetEnabled(true, false)
				end

				door_opened = false
				DoEntFire(door:GetName(), "SetAnimation", "gate_02_close", 0, nil, nil)
			end
			return 1.0
		end)
	end
end

function GateThink()
	if IsServer() then
		local door = Entities:FindByName(nil, "nevermore_gate")
		local door_obs = Entities:FindAllByName("nevermore_gate_obs")
		local door_opened = false

		Timers:CreateTimer(function()
			local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, door:GetAbsOrigin(), nil, 350, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)

			if #units > 0 and door_opened == false then
				for _, obs in pairs(door_obs) do
					obs:SetEnabled(false, true)
				end

				door_opened = true
				DoEntFire(door:GetName(), "SetAnimation", "gate_entrance002_open", 0, nil, nil)
			elseif #units == 0 and door_opened == true then
				for _, obs in pairs(door_obs) do
					obs:SetEnabled(true, false)
				end

				door_opened = false
				DoEntFire(door:GetName(), "SetAnimation", "close_idle", 0, nil, nil)
			end
			return 0.5
		end)
	end
end
