nCOUNTDOWNTIMER = 0
PHASE = 0
FROSTIVUS_WINNER = 2
COUNT_DOWN = 1
PHASE_TIME = 481 -- 481
PRESENT_SCORE_2 = 0
PRESENT_SCORE_3 = 0
if IsInToolsMode() then PHASE_TIME = 481 end -- 481

function Frostivus()
	for player_id = 0, 20 do
		if PlayerResource:GetPlayer(player_id) then
			if PlayerResource:GetTeam(player_id) == DOTA_TEAM_GOODGUYS then
				--sounds[1] = "greevil_eventstart_Stinger" -- Sound when grabbing a greeviling
				--sounds[1] = "greevil_receive_present_Stinger" -- high-pitch alert
				--sounds[2] = "greevil_loot_spawn_Stinger" -- Final boss start
				--sounds[5] = "greevil_loot_death_Stinger" -- Game end
				--sounds[2] = "Frostivus.PointScored.Team" -- team score
				--sounds[3] = "Frostivus.PointScored.Enemy" -- enemy score
				--sounds[6] = "Conquest.Stinger.GameBegin" -- Lich fight start music
				--sounds[1] = "Conquest.Stinger.HulkCreep.Generic" -- " oooOOOOOOhhhh"
				--sounds[1] = "DOTAMusic_Stinger.003" -- item unboxing
				--sounds[2] = "DOTAMusic_Stinger.004" -- mystery music
				--sounds[3] = "DOTAMusic_Stinger.005" -- fight decision
				--"Tutorial.Quest.complete_01" -- quest complete
				EmitSoundOnClient("FrostivusGameStart.RadiantSide", PlayerResource:GetPlayer(player_id))
			elseif PlayerResource:GetTeam(player_id) == DOTA_TEAM_BADGUYS then
				EmitSoundOnClient("FrostivusGameStart.DireSide", PlayerResource:GetPlayer(player_id))
			end
		end
	end
	PHASE = 1
	nCOUNTDOWNTIMER = PHASE_TIME -- 481 / 8 Min
	CustomNetTables:SetTableValue("game_options", "radiant", {score = 50, cp_score = 20})
	CustomNetTables:SetTableValue("game_options", "dire", {score = 50, cp_score = 20})
	CustomGameEventManager:Send_ServerToAllClients("show_timer", {})
	FrostivusPhase(PHASE)
	FrostivusCountdown(1.0)

	-- Spawn bosses
	SpawnZeus(BOSS_SPAWN_POINT_TABLE.zeus)
	SpawnVenomancer(BOSS_SPAWN_POINT_TABLE.venomancer)
	SpawnTreant(BOSS_SPAWN_POINT_TABLE.treant)
	SpawnNevermore(BOSS_SPAWN_POINT_TABLE.nevermore)
end

function FrostivusPhase(PHASE)
	print("Phase: ", PHASE)
	CustomGameEventManager:Send_ServerToAllClients("frostivus_phase", {Phase = tostring(PHASE)})

	-- Play phase change stinger
	if PHASE > 1 then
		for player_id = 0, 20 do
			if PlayerResource:GetPlayer(player_id) then
				EmitSoundOnClient("greevil_mega_spawn_Stinger", PlayerResource:GetPlayer(player_id))
			end
		end
	end
end

function FrostivusCountdown(tick)
	Timers:CreateTimer(function()
		if COUNT_DOWN == 1 then
			nCOUNTDOWNTIMER = nCOUNTDOWNTIMER - 1
		else
		end
		local t = nCOUNTDOWNTIMER
		local minutes = math.floor(t / 60)
		local seconds = t - (minutes * 60)
		local m10 = math.floor(minutes / 10)
		local m01 = minutes - (m10 * 10)
		local s10 = math.floor(seconds / 10)
		local s01 = seconds - (s10 * 10)
		local broadcast_gametimer = 
		{
			timer_minute_10 = m10,
			timer_minute_01 = m01,
			timer_second_10 = s10,
			timer_second_01 = s01,
		}

		CustomGameEventManager:Send_ServerToAllClients("countdown", broadcast_gametimer)
--		if t <= 120 then
--			CustomGameEventManager:Send_ServerToAllClients("time_remaining", broadcast_gametimer)
--		end

		if nCOUNTDOWNTIMER < 1 then
			nCOUNTDOWNTIMER = PHASE_TIME
			PHASE = PHASE + 1
			FrostivusPhase(PHASE)
		end
		return tick
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
				boss:FaceTowards(altar_handle:GetAbsOrigin())
			end
		end
	end

	if hero:GetLevel() <= 10 then
		hero:SetTimeUntilRespawn(10)
	else
		hero:SetTimeUntilRespawn(hero:GetLevel())
	end
end

function FrostivusAltarRespawn(hero)
	-- Base spawn
	if hero.altar == 1 or hero.altar == 7 then
		local building = Entities:FindByName(nil, "altar_"..hero.altar)
		local respawn_position = building:GetAbsOrigin() + RandomVector(RandomFloat(200, 800))
		FindClearSpaceForUnit(hero, respawn_position, true)
	-- Altar (obelisk) spawn
	else
		local building = Entities:FindByName(nil, "altar_"..hero.altar.."_tower")
		local respawn_position = building:GetAbsOrigin() + Vector(1, 1, 0):Normalized() * 200
		FindClearSpaceForUnit(hero, respawn_position, true)
	end
end