-- Venomancer (poison altar) owner aura

-- Aura ability
frostivus_altar_aura_veno = class({})

function frostivus_altar_aura_veno:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_veno" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_veno", "boss_scripts/aura_abilities/frostivus_altar_aura_veno.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_veno = modifier_frostivus_altar_aura_veno or class({})

function modifier_frostivus_altar_aura_veno:IsHidden() return true end
function modifier_frostivus_altar_aura_veno:IsPurgable() return false end
function modifier_frostivus_altar_aura_veno:IsDebuff() return false end

function modifier_frostivus_altar_aura_veno:GetAuraRadius()
	return 25000
end

function modifier_frostivus_altar_aura_veno:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_frostivus_altar_aura_veno:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_frostivus_altar_aura_veno:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_frostivus_altar_aura_veno:GetModifierAura()
	return "modifier_frostivus_altar_aura_veno_buff"
end

function modifier_frostivus_altar_aura_veno:IsAura()
	return true
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_veno_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_veno.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_veno_buff = modifier_frostivus_altar_aura_veno_buff or class({})

function modifier_frostivus_altar_aura_veno_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_veno_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_veno_buff:IsDebuff() return true end

function modifier_frostivus_altar_aura_veno_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING
	}
	return funcs
end

function modifier_frostivus_altar_aura_veno_buff:GetModifierMoveSpeedBonus_Percentage()
	return 10 + 2 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_veno"):GetStackCount()
end

function modifier_frostivus_altar_aura_veno_buff:GetModifierAttackSpeedBonus_Constant()
	return 20 + 10 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_veno"):GetStackCount()
end

function modifier_frostivus_altar_aura_veno_buff:GetModifierPercentageCooldownStacking()
	return 10 + 2 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_veno"):GetStackCount()
end