-- Treant (nature altar) owner aura

-- Aura ability
frostivus_altar_aura_lich = class({})

function frostivus_altar_aura_lich:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_lich" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_lich", "boss_scripts/aura_abilities/frostivus_altar_aura_lich.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_lich = modifier_frostivus_altar_aura_lich or class({})

function modifier_frostivus_altar_aura_lich:IsHidden() return true end
function modifier_frostivus_altar_aura_lich:IsPurgable() return false end
function modifier_frostivus_altar_aura_lich:IsDebuff() return false end

function modifier_frostivus_altar_aura_lich:GetAuraRadius()
	return 25000
end

function modifier_frostivus_altar_aura_lich:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_frostivus_altar_aura_lich:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_frostivus_altar_aura_lich:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_frostivus_altar_aura_lich:GetModifierAura()
	return "modifier_frostivus_altar_aura_lich_buff"
end

function modifier_frostivus_altar_aura_lich:IsAura()
	return true
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_lich_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_lich.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_lich_buff = modifier_frostivus_altar_aura_lich_buff or class({})

function modifier_frostivus_altar_aura_lich_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_lich_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_lich_buff:IsDebuff() return true end

function modifier_frostivus_altar_aura_lich_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_altar_aura_lich_buff:GetModifierBaseDamageOutgoing_Percentage()
	return 30 + 10 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_lich"):GetStackCount()
end

function modifier_frostivus_altar_aura_lich_buff:GetModifierSpellAmplify_Percentage()
	return 15 + 5 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_lich"):GetStackCount()
end