--[[	Custom Greevil's Greed for Frostivus
		By: Firetoad, 11-12-2017				]]

custom_alchemist_goblins_greed = custom_alchemist_goblins_greed or class({})

function custom_alchemist_goblins_greed:GetIntrinsicModifierName()
	return "custom_alchemist_goblins_greed_passive"
end

-- Passive modifier
LinkLuaModifier("custom_alchemist_goblins_greed_passive", "hero/greevils_greed.lua", LUA_MODIFIER_MOTION_NONE )
custom_alchemist_goblins_greed_passive = custom_alchemist_goblins_greed_passive or class({})

function custom_alchemist_goblins_greed_passive:IsDebuff() return false end
function custom_alchemist_goblins_greed_passive:IsHidden() return true end
function custom_alchemist_goblins_greed_passive:IsPurgable() return false end

function custom_alchemist_goblins_greed_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
	return funcs
end

function custom_alchemist_goblins_greed_passive:OnAttackLanded(keys)
	if IsServer() then
		if keys.attacker == self:GetParent() and keys.target:IsHero() and keys.attacker:IsRealHero() then
			local attacker = keys.attacker
			local ability = self:GetAbility()
			local gold = ability:GetLevelSpecialValueFor("gold_per_hit", ability:GetLevel() -1)
			attacker:ModifyGold(gold, false, DOTA_ModifyGold_CreepKill)
			SendOverheadEventMessage(attacker, OVERHEAD_ALERT_GOLD, attacker, gold, nil)
		end
	end
end