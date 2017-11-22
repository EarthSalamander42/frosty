-- Greevil-related stuff

---------------------
-- Greevil stuff
---------------------

function SpawnGreevil(location, level, red, green, blue)
	local greevil_per_level = {}
	greevil_per_level[1] = "npc_frostivus_greevil_basic"
	greevil_per_level[2] = "npc_frostivus_greevil_advanced"
	greevil_per_level[3] = "npc_frostivus_greevil_super"
	greevil_per_level[4] = "npc_frostivus_greevil_gold"
	local greevil = CreateUnitByName(greevil_per_level[level], location, true, nil, nil, DOTA_TEAM_NEUTRALS)
	greevil:SetForwardVector(Vector(0, -1, 0))
	if level ~= 4 then
		greevil:SetRenderColor(red, green, blue)
	end

	-- Add phase-appropriate modifiers
	if PHASE == 2 then
		greevil:AddNewModifier(nil, nil, "modifier_greevil_capture_aura", {level = level})
	else
		greevil:AddNewModifier(nil, nil, "modifier_frostivus_greevil", {})
	end

	return greevil
end