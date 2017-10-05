--[[	Author: Firetoad
		Updated by: Shush
		Date: 04/08/2015	]]


imba_creep_melee_bonuses = imba_creep_melee_bonuses or class({})

function imba_creep_melee_bonuses:GetIntrinsicModifierName()
	return "modifier_imba_creep_power"	
end

imba_creep_ranged_bonuses = imba_creep_ranged_bonuses or class({})

function imba_creep_ranged_bonuses:GetIntrinsicModifierName()
	return "modifier_imba_creep_power"	
end

imba_super_creep_melee_bonuses = imba_super_creep_melee_bonuses or class({})

function imba_super_creep_melee_bonuses:GetIntrinsicModifierName()
	return "modifier_imba_creep_power"	
end

imba_super_creep_ranged_bonuses = imba_super_creep_ranged_bonuses or class({})

function imba_super_creep_ranged_bonuses:GetIntrinsicModifierName()
	return "modifier_imba_creep_power"	
end

imba_mega_creep_melee_bonuses = imba_mega_creep_melee_bonuses or class({})

function imba_mega_creep_melee_bonuses:GetIntrinsicModifierName()
	return "modifier_imba_creep_power"	
end

imba_mega_creep_ranged_bonuses = imba_mega_creep_ranged_bonuses or class({})

function imba_mega_creep_ranged_bonuses:GetIntrinsicModifierName()
	return "modifier_imba_creep_power"	
end

LinkLuaModifier("modifier_imba_creep_power", "hero/npc_upgrades", LUA_MODIFIER_MOTION_NONE)

modifier_imba_creep_power = modifier_imba_creep_power or class({})

function modifier_imba_creep_power:IsHidden() return true end
function modifier_imba_creep_power:IsPurgable() return false end
function modifier_imba_creep_power:IsDebuff() return false end

function modifier_imba_creep_power:OnCreated()
	-- Ability properties
	self.parent = self:GetParent()
	self.ability = self:GetAbility()

	-- Ability specials
	self.bonus_damage_per_minute = self.ability:GetSpecialValueFor("bonus_damage_per_minute")
	self.bonus_health_per_minute = self.ability:GetSpecialValueFor("bonus_health_per_minute")

	if IsServer() then
		Timers:CreateTimer(1, function()
			local gametime = GameRules:GetGameTime()
			if gametime > 0 then
				local stacks = math.floor(gametime / 60)
				if stacks then
					-- Set stacks
					self:SetStackCount(stacks)

					-- Set health of the creep according to stacks
					local bonus_health = self.bonus_health_per_minute * stacks
					local adjusted_hp = self.parent:GetMaxHealth() + bonus_health
					SetCreatureHealth(self.parent, adjusted_hp, true)            
				end
			end
		end)
	end
end

function modifier_imba_creep_power:DeclareFunctions()
	local decFuncs = {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE}

	return decFuncs
end

function modifier_imba_creep_power:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage_per_minute * self:GetStackCount()
end


function TowerUpgrade( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local modifier_buffs = keys.modifier_buffs

	-- Parameters
	local base_health_per_tier = ability:GetLevelSpecialValueFor("base_health_per_tier", ability_level) * TOWER_POWER_FACTOR

	-- Calculate tower tier
	local tower_tier_multiplier = 0
	if string.find(caster:GetUnitName(), "tower1") then
		return nil
	elseif string.find(caster:GetUnitName(), "tower2") then
		tower_tier_multiplier = 1
	elseif string.find(caster:GetUnitName(), "tower3") then
		tower_tier_multiplier = 2
	elseif string.find(caster:GetUnitName(), "tower4") then
		tower_tier_multiplier = 3
	end

	-- Adjust health
	SetCreatureHealth(caster, caster:GetMaxHealth() + base_health_per_tier * tower_tier_multiplier, true)

	-- Adjust damage/armor/attack speed
	AddStacks(ability, caster, caster, modifier_buffs, tower_tier_multiplier * TOWER_POWER_FACTOR, true)
end

function FountainMarker( keys )
	local caster = keys.caster
	local ability = keys.ability
	local particle_danger = keys.particle_danger

	local danger_pfx = ParticleManager:CreateParticle(particle_danger, PATTACH_CUSTOMORIGIN, nil)
	ParticleManager:SetParticleControl(danger_pfx, 0, caster:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(danger_pfx)	
end

function FountainBash( keys )
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local particle_bash = keys.particle_bash
	local sound_bash = keys.sound_bash

	-- Parameters
	local bash_radius = ability:GetLevelSpecialValueFor("bash_radius", ability_level)
	local bash_duration = ability:GetLevelSpecialValueFor("bash_duration", ability_level)
	local bash_distance = ability:GetLevelSpecialValueFor("bash_distance", ability_level)
	local bash_height = ability:GetLevelSpecialValueFor("bash_height", ability_level)
	local fountain_loc = caster:GetAbsOrigin()

	-- Knockback table
	local fountain_bash =	{
		should_stun = 1,
		knockback_duration = bash_duration,
		duration = bash_duration,
		knockback_distance = bash_distance,
		knockback_height = bash_height,
		center_x = fountain_loc.x,
		center_y = fountain_loc.y,
		center_z = fountain_loc.z
	}

	-- Find units to bash
	local nearby_enemies = FindUnitsInRadius(caster:GetTeamNumber(), fountain_loc, nil, bash_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

	-- Bash all of them
	for _,enemy in pairs(nearby_enemies) do

		-- Bash
		enemy:RemoveModifierByName("modifier_knockback")
		enemy:AddNewModifier(caster, ability, "modifier_knockback", fountain_bash)

		-- Play particle
		local bash_pfx = ParticleManager:CreateParticle(particle_bash, PATTACH_ABSORIGIN, enemy)
		ParticleManager:SetParticleControl(bash_pfx, 0, enemy:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(bash_pfx)

		-- Play sound
		enemy:EmitSound(sound_bash)
	end
end