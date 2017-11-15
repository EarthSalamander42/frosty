--[[	Custom Frost Arrows for Frostivus
		By: Firetoad, 11-14-2017				]]

custom_drow_ranger_frost_arrows = custom_drow_ranger_frost_arrows or class({})

function custom_drow_ranger_frost_arrows:GetIntrinsicModifierName()
	return "modifier_custom_frost_arrows_passive"
end

-- Passive modifier
LinkLuaModifier("modifier_custom_frost_arrows_passive", "hero/frost_arrows.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_frost_arrows_passive = modifier_custom_frost_arrows_passive or class({})

function modifier_custom_frost_arrows_passive:IsDebuff() return false end
function modifier_custom_frost_arrows_passive:IsHidden() return true end
function modifier_custom_frost_arrows_passive:IsPurgable() return false end

function modifier_custom_frost_arrows_passive:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_START,
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
	return funcs
end

function modifier_custom_frost_arrows_passive:OnAttackStart(keys)
	if IsServer() then
		if keys.attacker == self:GetParent() then
			if keys.target:HasModifier("modifier_frostivus_boss") then
				self:GetParent():SetRangedProjectileName("particles/heroes/drow_swift_arrow_.vpcf")
			elseif not keys.target:IsMagicImmune() then
				self:GetParent():SetRangedProjectileName("particles/units/heroes/hero_drow/drow_frost_arrow.vpcf")
			else
				self:GetParent():SetRangedProjectileName("particles/units/heroes/hero_drow/drow_base_attack.vpcf")
			end
		end
	end
end

function modifier_custom_frost_arrows_passive:OnAttackLanded(keys)
	if IsServer() then
		if keys.attacker == self:GetParent() then
			local attacker = self:GetCaster()
			local target = keys.target
			local ability = self:GetAbility()
			if target:HasModifier("modifier_frostivus_boss") then
				target:EmitSound("Frostivus.DrowSwiftArrow")
				attacker:AddNewModifier(attacker, ability, "modifier_custom_frost_arrows_buff", {duration = ability:GetSpecialValueFor("buff_duration")})
			elseif not target:IsMagicImmune() then
				target:EmitSound("Hero_DrowRanger.FrostArrows")
				target:AddNewModifier(attacker, ability, "modifier_custom_frost_arrows_debuff", {duration = ability:GetSpecialValueFor("slow_duration")})
			end
		end
	end
end

-- Agility buff
LinkLuaModifier("modifier_custom_frost_arrows_buff", "hero/frost_arrows.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_frost_arrows_buff = modifier_custom_frost_arrows_buff or class({})

function modifier_custom_frost_arrows_buff:IsDebuff() return false end
function modifier_custom_frost_arrows_buff:IsHidden() return false end
function modifier_custom_frost_arrows_buff:IsPurgable() return false end

function modifier_custom_frost_arrows_buff:GetAttributes()
	local attributes = {
		MODIFIER_ATTRIBUTE_MULTIPLE
	}
	return attributes
end

function modifier_custom_frost_arrows_buff:GetEffectName()
	return "particles/heroes/drow_swift_arrows_buff.vpcf"
end

function modifier_custom_frost_arrows_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_custom_frost_arrows_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS
	}
	return funcs
end

function modifier_custom_frost_arrows_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_bonus")
end

function modifier_custom_frost_arrows_buff:GetModifierBonusStats_Agility()
	return self:GetAbility():GetSpecialValueFor("agi_bonus")
end

-- Slow debuff
LinkLuaModifier("modifier_custom_frost_arrows_debuff", "hero/frost_arrows.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_frost_arrows_debuff = modifier_custom_frost_arrows_debuff or class({})

function modifier_custom_frost_arrows_debuff:IsDebuff() return true end
function modifier_custom_frost_arrows_debuff:IsHidden() return false end
function modifier_custom_frost_arrows_debuff:IsPurgable() return true end

function modifier_custom_frost_arrows_debuff:GetEffectName()
	return "particles/generic_gameplay/generic_slowed_cold.vpcf"
end

function modifier_custom_frost_arrows_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_custom_frost_arrows_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_frost.vpcf"
end

function modifier_custom_frost_arrows_debuff:StatusEffectPriority()
	return 8
end

function modifier_custom_frost_arrows_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_custom_frost_arrows_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("ms_slow")
end