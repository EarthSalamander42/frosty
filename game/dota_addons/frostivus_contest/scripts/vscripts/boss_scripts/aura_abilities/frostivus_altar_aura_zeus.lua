-- Zeus (lightning altar) owner aura

-- Aura ability
frostivus_altar_aura_zeus = class({})

function frostivus_altar_aura_zeus:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_zeus" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_zeus", "boss_scripts/aura_abilities/frostivus_altar_aura_zeus.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_zeus = modifier_frostivus_altar_aura_zeus or class({})

function modifier_frostivus_altar_aura_zeus:IsHidden() return true end
function modifier_frostivus_altar_aura_zeus:IsPurgable() return false end
function modifier_frostivus_altar_aura_zeus:IsDebuff() return false end

function modifier_frostivus_altar_aura_zeus:GetAuraRadius()
	return 25000
end

function modifier_frostivus_altar_aura_zeus:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_frostivus_altar_aura_zeus:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_frostivus_altar_aura_zeus:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_frostivus_altar_aura_zeus:GetModifierAura()
	return "modifier_frostivus_altar_aura_zeus_buff"
end

function modifier_frostivus_altar_aura_zeus:IsAura()
	return true
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_zeus_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_zeus.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_zeus_buff = modifier_frostivus_altar_aura_zeus_buff or class({})

function modifier_frostivus_altar_aura_zeus_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_zeus_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_zeus_buff:IsDebuff() return true end