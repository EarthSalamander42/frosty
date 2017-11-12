-- Treant (nature altar) owner aura

-- Aura ability
frostivus_altar_aura_treant = class({})

function frostivus_altar_aura_treant:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_treant" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_treant", "boss_scripts/aura_abilities/frostivus_altar_aura_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_treant = modifier_frostivus_altar_aura_treant or class({})

function modifier_frostivus_altar_aura_treant:IsHidden() return true end
function modifier_frostivus_altar_aura_treant:IsPurgable() return false end
function modifier_frostivus_altar_aura_treant:IsDebuff() return false end

function modifier_frostivus_altar_aura_treant:GetAuraRadius()
	return 25000
end

function modifier_frostivus_altar_aura_treant:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_frostivus_altar_aura_treant:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_frostivus_altar_aura_treant:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_frostivus_altar_aura_treant:GetModifierAura()
	return "modifier_frostivus_altar_aura_treant_buff"
end

function modifier_frostivus_altar_aura_treant:IsAura()
	return true
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_treant_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_treant_buff = modifier_frostivus_altar_aura_treant_buff or class({})

function modifier_frostivus_altar_aura_treant_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_treant_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_treant_buff:IsDebuff() return true end

function modifier_frostivus_altar_aura_treant_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_altar_aura_treant_buff:GetModifierPhysicalArmorBonus()
	return 4 + 1 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_treant"):GetStackCount()
end

function modifier_frostivus_altar_aura_treant_buff:GetModifierMagicalResistanceBonus()
	return 16 + 4 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_treant"):GetStackCount()
end

function modifier_frostivus_altar_aura_treant_buff:GetModifierExtraHealthPercentage()
	return 10 + 2 * self:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_treant"):GetStackCount()
end