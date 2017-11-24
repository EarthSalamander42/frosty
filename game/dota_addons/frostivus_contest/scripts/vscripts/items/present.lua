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
			local team = caster:GetTeam()
			if team == DOTA_TEAM_GOODGUYS then
				PRESENT_SCORE_2 = PRESENT_SCORE_2 + 1
				CustomNetTables:SetTableValue("game_options", "radiant", {score = PRESENT_SCORE_2})
				PlaySoundForTeam(DOTA_TEAM_GOODGUYS, "Frostivus.PointScored.Team")
				PlaySoundForTeam(DOTA_TEAM_BADGUYS, "Frostivus.PointScored.Enemy")
			elseif team == DOTA_TEAM_BADGUYS then
				PRESENT_SCORE_3 = PRESENT_SCORE_3 + 1
				CustomNetTables:SetTableValue("game_options", "dire", {score = PRESENT_SCORE_3})
				PlaySoundForTeam(DOTA_TEAM_GOODGUYS, "Frostivus.PointScored.Enemy")
				PlaySoundForTeam(DOTA_TEAM_BADGUYS, "Frostivus.PointScored.Team")
			end

			-- Grant all players in the team bonus gold and experience
			for _, hero in pairs(HeroList:GetAllHeroes()) do
				if hero:GetTeam() == team then
					hero:ModifyGold(50, false, DOTA_ModifyGold_HeroKill)
					hero:AddExperience(50, DOTA_ModifyXP_HeroKill, false, true)
					SendOverheadEventMessage(PlayerResource:GetPlayer(hero:GetPlayerID()), OVERHEAD_ALERT_GOLD, hero, 50, nil)
				end
			end

			caster:AddNewModifier(nil, nil, "modifier_frostivus_present_duplicate_prevention", {duration = 0.03})
		end
	end
end
