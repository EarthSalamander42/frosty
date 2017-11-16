--[[  Custom Great Cleave for Frostivus
		By: Firetoad, 11-16-2017    ]]

custom_sven_great_cleave = custom_sven_great_cleave or class({})

function custom_sven_great_cleave:GetIntrinsicModifierName()
	return "modifier_custom_great_cleave"
end

-- Passive modifier
LinkLuaModifier("modifier_custom_great_cleave", "hero/great_cleave", LUA_MODIFIER_MOTION_NONE)
modifier_custom_great_cleave = modifier_custom_great_cleave or class({})

function modifier_custom_great_cleave:IsDebuff() return false end
function modifier_custom_great_cleave:IsHidden() return true end
function modifier_custom_great_cleave:IsPurgable() return false end

function modifier_custom_great_cleave:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
	}
	return funcs
end

function modifier_custom_great_cleave:GetModifierBaseDamageOutgoing_Percentage()
	if self:GetParent():HasModifier("modifier_fighting_boss") then
		return self:GetAbility():GetSpecialValueFor("great_cleave_damage")
	else
		return 0
	end
end

function modifier_custom_great_cleave:OnAttackLanded(keys)
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		if keys.attacker == caster and caster:IsRealHero() and not caster:HasModifier("modifier_fighting_boss") then
			local cleave_particle = "particles/units/heroes/hero_sven/sven_spell_great_cleave.vpcf"
			local cleave_damage_pct = ability:GetSpecialValueFor("great_cleave_damage") / 100
			local cleave_radius_start = ability:GetSpecialValueFor("cleave_starting_width")
			local cleave_radius_end = ability:GetSpecialValueFor("cleave_ending_width")
			local cleave_distance = ability:GetSpecialValueFor("cleave_distance")
			DoCleaveAttack(caster, keys.target, ability, keys.damage * cleave_damage_pct, cleave_radius_start, cleave_radius_end, cleave_distance, cleave_particle)
		end
	end
end