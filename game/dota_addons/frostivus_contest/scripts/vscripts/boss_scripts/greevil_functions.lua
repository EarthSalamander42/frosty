-- Greevil-related stuff

---------------------
-- Other modifiers
---------------------
--LinkLuaModifier("capture_start_trigger", "boss_scripts/capture_start_trigger.lua", LUA_MODIFIER_MOTION_NONE )

---------------------
-- Greevil stuff
---------------------

function SpawnGreevil(location, level, capturable, red, green, blue)
	local greevil_per_level = {}
	greevil_per_level[1] = "npc_frostivus_greevil_basic"
	greevil_per_level[2] = "npc_frostivus_greevil_advanced"
	greevil_per_level[3] = "npc_frostivus_greevil_super"
	local greevil = CreateUnitByName(greevil_per_level[level], location, true, nil, nil, DOTA_TEAM_NEUTRALS)
	greevil:SetForwardVector(Vector(0, -1, 0))
	greevil:SetRenderColor(red, green, blue)
	greevil:FindAbilityByName("frostivus_greevil_innate"):SetLevel(1)

	-- If this greevil is capturable (phase 2), add the capture modifier
	if capturable then
		--greevil:AddNewModifier(nil, nil, "capture_start_trigger", {boss_name = "venomancer", altar_handle = altar})
	end

	return greevil
end