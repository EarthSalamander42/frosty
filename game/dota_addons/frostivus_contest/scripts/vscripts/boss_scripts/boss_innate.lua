-- Boss innate buffs ability

frostivus_boss_innate = frostivus_boss_innate or class({})

function frostivus_boss_innate:GetIntrinsicModifierName()
	return "modifier_frostivus_boss"	
end

LinkLuaModifier("modifier_frostivus_boss", "boss_scripts/boss_innate", LUA_MODIFIER_MOTION_NONE)

modifier_frostivus_boss = modifier_frostivus_boss or class({})

function modifier_frostivus_boss:IsHidden() return false end
function modifier_frostivus_boss:IsPurgable() return false end
function modifier_frostivus_boss:IsDebuff() return false end

--function modifier_frostivus_boss:GetTextureName()
--	return ""
--end

function modifier_frostivus_boss:OnCreated()

	-- Ability properties
	local ability = self:GetAbility()
	local owner = self:GetParent()

	-- Ability specials
	self.armor_per_power = ability:GetSpecialValueFor("armor_per_power")
	self.magic_resist_per_power = 1 - ability:GetSpecialValueFor("magic_resist_per_power") * 0.01
	self.health_per_power = ability:GetSpecialValueFor("health_per_power") * 0.01
	self.damage_per_power = 250 * ability:GetSpecialValueFor("damage_per_power") * 0.01

	self:ForceRefresh()
end

function modifier_frostivus_boss:CheckState()
	local state =
	{
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
	}
	return state
end

function modifier_frostivus_boss:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
		MODIFIER_PROPERTY_MOVESPEED_MAX
	}
	return funcs
end

function modifier_frostivus_boss:GetModifierBaseAttack_BonusDamage()
	return self.damage_per_power * self:GetStackCount()
end

function modifier_frostivus_boss:GetModifierPhysicalArmorBonus()
	return self.armor_per_power * self:GetStackCount()
end

function modifier_frostivus_boss:GetModifierMagicalResistanceBonus()
	return (1 - self.magic_resist_per_power ^ self:GetStackCount()) * 100
end

function modifier_frostivus_boss:GetModifierExtraHealthPercentage()
	return self.health_per_power * self:GetStackCount()
end

function modifier_frostivus_boss:GetModifierMoveSpeedBonus_Percentage()
	return 100
end

function modifier_frostivus_boss:GetModifierMoveSpeed_AbsoluteMin()
	return 1000
end

function modifier_frostivus_boss:GetModifierMoveSpeed_Max()
	return 1000
end