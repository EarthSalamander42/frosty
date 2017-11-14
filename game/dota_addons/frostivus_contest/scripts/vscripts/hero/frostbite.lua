--[[  Custom Frostbite for Frostivus
		Based on Dota IMBA code
		By: Firetoad, 11-13-2017    ]]

if custom_crystal_maiden_frostbite == nil then custom_crystal_maiden_frostbite = class({}) end

function custom_crystal_maiden_frostbite:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local ability_level = self:GetLevel() - 1
		local duration = self:GetLevelSpecialValueFor("duration", ability_level)
		local boss_duration = self:GetLevelSpecialValueFor("boss_duration", ability_level)

		-- If the talent is learned, use the upgraded duration
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_crystal_maiden_1")
		if talent_ability and talent_ability:GetLevel() > 0 then
			duration = duration + self:GetSpecialValueFor("talent_duration")
			boss_duration = boss_duration + self:GetSpecialValueFor("talent_duration")
		end

		-- If the target possesses a ready Linken's Sphere, do nothing else
		if target:GetTeamNumber() ~= caster:GetTeamNumber() then
			if target:TriggerSpellAbsorb(self) then return nil end
		end
		
		-- Play cast sound
		target:EmitSound("Hero_Crystal.Frostbite")

		-- Apply a mini-stun
		target:AddNewModifier(caster, self, "modifier_stunned", {duration = 0.1})

		-- Apply the appropriate modifier to the target
		if target:HasModifier("modifier_frostivus_boss") then
			target:AddNewModifier(caster, self, "modifier_custom_frostbite_debuff", {duration = boss_duration})				
		else
			target:AddNewModifier(caster, self, "modifier_rooted", {duration = duration})
			target:AddNewModifier(caster, self, "modifier_custom_frostbite_debuff", {duration = duration})		
		end
	end
end

-- Frostbite debuff modifier
LinkLuaModifier("modifier_custom_frostbite_debuff", "hero/frostbite.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_frostbite_debuff = modifier_custom_frostbite_debuff or class({})

function modifier_custom_frostbite_debuff:IsDebuff() return true end
function modifier_custom_frostbite_debuff:IsHidden() return false end
function modifier_custom_frostbite_debuff:IsPurgable() return false end

function modifier_custom_frostbite_debuff:GetEffectName()
	return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end

function modifier_custom_frostbite_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_custom_frostbite_debuff:OnCreated(keys)
	if IsServer() then

		-- Parameters
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		local damage_per_second = ability:GetLevelSpecialValueFor("damage_per_second", ability:GetLevel() - 1)
		self.damage_per_tick = damage_per_second * 0.5

		-- Immediately proc the first damage instance
		self:OnIntervalThink()
		
		-- Get thinkin
		self:StartIntervalThink(0.5)
	end
end

function modifier_custom_frostbite_debuff:OnIntervalThink()
	if IsServer() then
		ApplyDamage({attacker = self:GetCaster(), victim = self:GetParent(), ability = self:GetAbility(), damage = self.damage_per_tick, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end

function modifier_custom_frostbite_debuff:CheckState()
	local state = {
		[MODIFIER_STATE_DISARMED] = true
	}
	return state
end

function modifier_custom_frostbite_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	}
	return funcs
end

function modifier_custom_frostbite_debuff:GetModifierTotalDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function modifier_custom_frostbite_debuff:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			local attacker = keys.attacker
			local ability = self:GetAbility()
			local damage = keys.damage
			local mana_conversion = ability:GetLevelSpecialValueFor("mana_conversion", ability:GetLevel() - 1)

			-- Play particle
			local lifesteal_pfx = ParticleManager:CreateParticle("particles/heroes/crystal_frostbite_manasteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, attacker)
			ParticleManager:SetParticleControl(lifesteal_pfx, 0, attacker:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(lifesteal_pfx)

			-- Grant attacker mana
			attacker:GiveMana(damage * mana_conversion * 0.01)
		end
	end
end