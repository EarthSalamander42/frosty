nCOUNTDOWNTIMER = 0
PHASE = 0

FROSTIVUS_WINNER = 2
COUNT_DOWN = 1
PHASE_TIME = 481 -- 481
if IsInToolsMode() then
	PHASE_TIME = 481 -- 481
end

function Frostivus()
	EmitGlobalSound("announcer_diretide_2012_announcer_welcome_05")
	EmitGlobalSound("DireTideGameStart.DireSide")
	PHASE = 1
	nCOUNTDOWNTIMER = PHASE_TIME -- 481 / 8 Min
	CustomNetTables:SetTableValue("game_options", "radiant", {score = 50, cp_score = 20})
	CustomNetTables:SetTableValue("game_options", "dire", {score = 50, cp_score = 20})
	CustomGameEventManager:Send_ServerToAllClients("show_timer", {})
	FrostivusPhase(PHASE)
	FrostivusCountdown(1.0)
	-- Set up control points
	local radiant_control_point_loc = Entities:FindByName(nil, "altar_2")
	local dire_control_point_loc = Entities:FindByName(nil, "altar_6")
 	radiant_control_point_loc.score = 20
	dire_control_point_loc.score = 20
	ArenaControlPointThinkRadiant(radiant_control_point_loc)
	ArenaControlPointThinkDire(dire_control_point_loc)
	Timers:CreateTimer(10, function()
		ArenaControlPointScoreThink(radiant_control_point_loc, dire_control_point_loc)
	end)
end

function FrostivusPhase(PHASE)
--	local units = FindUnitsInRadius(1, Vector(0,0,0), nil, 25000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)

--	for _, unit in ipairs(units) do
--		if unit:GetName() == "npc_dota_roshan" then
--			local AImod = unit:FindModifierByName("modifier_imba_roshan_ai_diretide")
--			if AImod then
--				AImod:SetStackCount(PHASE)
--				unit:Interrupt()
--			else
--				print("ERROR - Could not find Roshans AI modifier")
--			end
--		end
--	end
	CustomGameEventManager:Send_ServerToAllClients("frostivus_phase", {Phase = tostring(PHASE)})
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
			print("Phase:", PHASE)
			if PHASE == 2 then
				if CustomNetTables:GetTableValue("game_options", "dire").score > CustomNetTables:GetTableValue("game_options", "radiant").score then
					FROSTIVUS_WINNER = 3
				end
			elseif PHASE == 3 then
				nCOUNTDOWNTIMER = 120
				COUNT_DOWN = 0
				local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0,0,0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_ALL, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)		
				for _, unit in pairs(units) do
					if unit:GetUnitName() == "npc_diretide_roshan" then
--						UpdateRoshanBar(unit, 0.03)
					else
--						if unit:IsCreep() then
--							unit:RemoveSelf()						
--						end
					end
				end
				local ents = Entities:FindAllByName("lane_*")
				for _, ent in pairs(ents) do
					ent:RemoveSelf()
				end
			elseif PHASE == 4 then
				GameRules:SetGameWinner(DOTA_TEAM_NEUTRALS)
			end
		elseif nCOUNTDOWNTIMER == 120 and PHASE == 3 then
			local hero = FindUnitsInRadius(2, Entities:FindByName(nil, "roshan_arena_"..FROSTIVUS_WINNER):GetAbsOrigin(), nil, 700, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
			if #hero > 0 then
				print("A hero is near...")
				COUNT_DOWN = 1
			end
		end
		return tick
	end)
end

function UpdateRoshanBar(roshan, level, time)
	Timers:CreateTimer(function()
		CustomNetTables:SetTableValue("game_options", "roshan", {
			level = level,
			HP = roshan:GetHealth(),
			HP_alt = roshan:GetHealthPercent(),
			maxHP = roshan:GetMaxHealth()
		})
		return time
	end)
end

function FrostivusIncreaseTimer(time)
	nCOUNTDOWNTIMER = nCOUNTDOWNTIMER + time
end

function FrostivusHeroKilled(hero)
	if hero:GetTeamNumber() == 2 then
--		CustomNetTables:SetTableValue("game_options", "radiant", {score = CustomNetTables:GetTableValue("game_options", "radiant").score +1})
		CustomNetTables:SetTableValue("game_options", "dire", {score = CustomNetTables:GetTableValue("game_options", "dire").score -1})
	else
		CustomNetTables:SetTableValue("game_options", "radiant", {score = CustomNetTables:GetTableValue("game_options", "radiant").score -1})
--		CustomNetTables:SetTableValue("game_options", "dire", {score = CustomNetTables:GetTableValue("game_options", "dire").score +1})
	end
end

-- TODO: make a panorama panel to choose at wich altar to respawn
function FrostivusAltarRespawn(hero)
	if hero:GetTeamNumber() == 2 then
		altar = Entities:FindByName(nil, "altar_1")
	else
		altar = Entities:FindByName(nil, "altar_7")
	end

	local respawn_position = altar:GetAbsOrigin() + RandomVector(RandomFloat(200, 900))
	FindClearSpaceForUnit(hero, respawn_position, true)
end

-- Arena control point logic
function ArenaControlPointThinkRadiant(control_point)

	-- Create the control point particle, if this is the first iteration
	if not control_point.particle then
		control_point.particle = ParticleManager:CreateParticle("particles/customgames/capturepoints/cp_allied_wind.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(control_point.particle, 0, control_point:GetAbsOrigin())
	end

	-- Check how many heroes are near the control point
	local allied_heroes = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, control_point:GetAbsOrigin(), nil, 600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	local enemy_heroes = FindUnitsInRadius(DOTA_TEAM_BADGUYS, control_point:GetAbsOrigin(), nil, 600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	local score_change = #allied_heroes - #enemy_heroes

	-- Calculate the new score
	local old_score = control_point.score
	control_point.score = math.max(math.min(control_point.score + score_change, 20), -20)

	-- If this control point changed disposition, update the UI and particle accordingly
	if old_score >= 0 and control_point.score < 0 then
		CustomGameEventManager:Send_ServerToAllClients("radiant_point_to_dire", {})
		ParticleManager:DestroyParticle(control_point.particle, true)
		control_point.particle = ParticleManager:CreateParticle("particles/customgames/capturepoints/cp_wind_captured.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(control_point.particle, 0, control_point:GetAbsOrigin())
		control_point:EmitSound("Imba.ControlPointTaken")
	elseif old_score < 0 and control_point.score >= 0 then
		CustomGameEventManager:Send_ServerToAllClients("radiant_point_to_radiant", {})
		ParticleManager:DestroyParticle(control_point.particle, true)
		control_point.particle = ParticleManager:CreateParticle("particles/customgames/capturepoints/cp_allied_wind.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(control_point.particle, 0, control_point:GetAbsOrigin())
		control_point:EmitSound("Imba.ControlPointTaken")
	end

	-- Update the progress bar
	CustomNetTables:SetTableValue("game_options", "radiant", {cp_score = control_point.score})
	CustomGameEventManager:Send_ServerToAllClients("radiant_progress_update", {})

	-- Run this function again after a second
	Timers:CreateTimer(1, function()
		ArenaControlPointThinkRadiant(control_point)
	end)
end

function ArenaControlPointThinkDire(control_point)

	-- Create the control point particle, if this is the first iteration
	if not control_point.particle then
		control_point.particle = ParticleManager:CreateParticle("particles/customgames/capturepoints/cp_metal_captured.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(control_point.particle, 0, control_point:GetAbsOrigin())
	end

	-- Check how many heroes are near the control point
	local allied_heroes = FindUnitsInRadius(DOTA_TEAM_BADGUYS, control_point:GetAbsOrigin(), nil, 600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	local enemy_heroes = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, control_point:GetAbsOrigin(), nil, 600, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
	local score_change = #allied_heroes - #enemy_heroes

	-- Calculate the new score
	local old_score = control_point.score
	control_point.score = math.max(math.min(control_point.score + score_change, 20), -20)

	-- If this control point changed disposition, update the UI and particle accordingly
	if old_score >= 0 and control_point.score < 0 then
		CustomGameEventManager:Send_ServerToAllClients("dire_point_to_radiant", {})
		ParticleManager:DestroyParticle(control_point.particle, true)
		control_point.particle = ParticleManager:CreateParticle("particles/customgames/capturepoints/cp_allied_metal.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(control_point.particle, 0, control_point:GetAbsOrigin())
		control_point:EmitSound("Imba.ControlPointTaken")
	elseif old_score < 0 and control_point.score >= 0 then
		CustomGameEventManager:Send_ServerToAllClients("dire_point_to_dire", {})
		ParticleManager:DestroyParticle(control_point.particle, true)
		control_point.particle = ParticleManager:CreateParticle("particles/customgames/capturepoints/cp_metal_captured.vpcf", PATTACH_CUSTOMORIGIN, nil)
		ParticleManager:SetParticleControl(control_point.particle, 0, control_point:GetAbsOrigin())
		control_point:EmitSound("Imba.ControlPointTaken")
	end

	-- Update the progress bar
	CustomNetTables:SetTableValue("game_options", "dire", {cp_score = control_point.score})
	CustomGameEventManager:Send_ServerToAllClients("dire_progress_update", {})

	-- Run this function again after a second
	Timers:CreateTimer(1, function()
		ArenaControlPointThinkDire(control_point)
	end)
end

function ArenaControlPointScoreThink(radiant_cp, dire_cp)

	-- Fetch current scores
	local radiant = CustomNetTables:GetTableValue("game_options", "radiant")
	local dire = CustomNetTables:GetTableValue("game_options", "dire")

	print("Radiant CP:", radiant_cp.score)
	print("Dire CP", dire_cp.score)

	-- Update scores
	if radiant_cp.score >= 0 then
		radiant.score = radiant.score + 1
	else
		dire.score = dire.score + 1
	end
	if dire_cp.score >= 0 then
		dire.score = dire.score + 1
	else
		radiant.score = radiant.score + 1
	end

--	-- Check if one of the teams won the game
--	if radiant.score >= KILLS_TO_END_GAME_FOR_TEAM then
--		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
--		GAME_WINNER_TEAM = "Radiant"
--	elseif dire.score >= KILLS_TO_END_GAME_FOR_TEAM then
--		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
--		GAME_WINNER_TEAM = "Dire"
--	end

	-- Call this function again after 10 seconds
	Timers:CreateTimer(10, function()
		ArenaControlPointScoreThink(radiant_cp, dire_cp)
	end)
end
