--[[	Custom Degen Aura for Frostivus
		By: Firetoad, 11-15-2017				]]

custom_omniknight_degen_aura = custom_omniknight_degen_aura or class({})

function custom_omniknight_degen_aura:GetIntrinsicModifierName()
	return "modifier_custom_degen_aura"
end

-- Passive modifier
LinkLuaModifier("modifier_custom_degen_aura", "hero/degen_aura.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_degen_aura = modifier_custom_degen_aura or class({})

function modifier_custom_degen_aura:IsDebuff() return false end
function modifier_custom_degen_aura:IsHidden() return true end
function modifier_custom_degen_aura:IsPurgable() return false end

function modifier_custom_degen_aura:GetAuraRadius()
	if IsServer() then
		local radius = self:GetAbility():GetSpecialValueFor("radius")

		-- If the talent is learned, use the upgraded radius
		local talent_ability = self:GetParent():FindAbilityByName("special_bonus_unique_omniknight_2")
		if talent_ability and talent_ability:GetLevel() > 0 then
			radius = radius + self:GetAbility():GetSpecialValueFor("talent_increase")
		end
		return radius
	end
end

function modifier_custom_degen_aura:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
end

function modifier_custom_degen_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_custom_degen_aura:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_custom_degen_aura:GetModifierAura()
	return "modifier_custom_degen_aura_debuff"
end

function modifier_custom_degen_aura:IsAura()
	return true
end

-- Aura debuff
LinkLuaModifier("modifier_custom_degen_aura_debuff", "hero/degen_aura.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_degen_aura_debuff = modifier_custom_degen_aura_debuff or class({})

function modifier_custom_degen_aura_debuff:IsDebuff() return true end
function modifier_custom_degen_aura_debuff:IsHidden() return false end
function modifier_custom_degen_aura_debuff:IsPurgable() return false end

function modifier_custom_degen_aura_debuff:GetEffectName()
	return "particles/units/heroes/hero_omniknight/omniknight_degen_aura_debuff.vpcf"
end

function modifier_custom_degen_aura_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_custom_degen_aura_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_custom_degen_aura_debuff:GetModifierTotalDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("dmg_reduction")
end

function modifier_custom_degen_aura_debuff:GetModifierIncomingDamage_Percentage()
	return self:GetAbility():GetSpecialValueFor("dmg_amp")
end

function modifier_custom_degen_aura_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("move_slow")
end