--[[	Frostivus present ground dummies
		By: Firetoad, 11-18-2017	]]

item_frostivus_present = item_frostivus_present or class({})

LinkLuaModifier("modifier_frostivus_present_duplicate_prevention", "items/present.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_present_duplicate_prevention = modifier_frostivus_present_duplicate_prevention or class({})

function modifier_frostivus_present_duplicate_prevention:IsHidden() return true end
function modifier_frostivus_present_duplicate_prevention:IsPurgable() return false end
function modifier_frostivus_present_duplicate_prevention:IsDebuff() return true end

function item_frostivus_present:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		if caster:HasModifier("modifier_frostivus_present_duplicate_prevention") then
			caster:RemoveModifierByName("modifier_frostivus_present_duplicate_prevention")
		else
			if caster:GetTeam() == DOTA_TEAM_GOODGUYS then
				PRESENT_SCORE_2 = PRESENT_SCORE_2 + 1
				GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_GOODGUYS, PRESENT_SCORE_2)
			elseif caster:GetTeam() == DOTA_TEAM_BADGUYS then
				PRESENT_SCORE_3 = PRESENT_SCORE_3 + 1
				GameRules:GetGameModeEntity():SetTopBarTeamValue(DOTA_TEAM_BADGUYS, PRESENT_SCORE_3)
			end
			caster:AddNewModifier(nil, nil, "modifier_frostivus_present_duplicate_prevention", {duration = 0.03})
			print("Radiant: "..PRESENT_SCORE_2)
			print("Dire: "..PRESENT_SCORE_3)
		end
	end
end
