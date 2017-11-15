-- Fire boss (fire altar) owner aura

-- Aura ability
frostivus_altar_aura_fire = class({})

function frostivus_altar_aura_fire:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_fire" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_fire", "boss_scripts/aura_abilities/frostivus_altar_aura_fire.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_fire = modifier_frostivus_altar_aura_fire or class({})

function modifier_frostivus_altar_aura_fire:IsHidden() return true end
function modifier_frostivus_altar_aura_fire:IsPurgable() return false end
function modifier_frostivus_altar_aura_fire:IsDebuff() return false end

function modifier_frostivus_altar_aura_fire:GetAuraRadius()
	return 25000
end

function modifier_frostivus_altar_aura_fire:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_frostivus_altar_aura_fire:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_frostivus_altar_aura_fire:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO
end

function modifier_frostivus_altar_aura_fire:GetModifierAura()
	return "modifier_frostivus_altar_aura_fire_buff"
end

function modifier_frostivus_altar_aura_fire:IsAura()
	return true
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_fire_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_fire.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_fire_buff = modifier_frostivus_altar_aura_fire_buff or class({})

function modifier_frostivus_altar_aura_fire_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_fire_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_fire_buff:IsDebuff() return false end