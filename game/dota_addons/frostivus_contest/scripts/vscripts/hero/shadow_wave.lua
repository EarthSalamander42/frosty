--[[  Custom Shadow Wave for Frostivus
		By: Firetoad, 11-14-2017    ]]

if custom_dazzle_shadow_wave == nil then custom_dazzle_shadow_wave = class({}) end

function custom_dazzle_shadow_wave:GetCooldown()
	if self:GetCaster():HasModifier("modifier_custom_shadow_wave_talent") then
		return self:GetSpecialValueFor("talent_cooldown")
	else
		return self:GetSpecialValueFor("cooldown")
	end
end

function custom_dazzle_shadow_wave:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()

		-- Play cast sound
		caster:EmitSound("Hero_Dazzle.Shadow_Wave")

		-- Clear targets hit table
		self.targets_hit = {}

		-- Add caster to tables
		self.targets_hit[1] = caster

		-- Heal the caster
		self:WaveHit(caster)

		-- Start bouncing
		self:BounceFrom(caster)

		-- Draw effect on the caster
		local wave_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_shadow_wave.vpcf", PATTACH_CUSTOMORIGIN, caster)
		ParticleManager:SetParticleControlEnt(wave_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(wave_pfx, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(wave_pfx)

		-- Add talent modifier, if necessary
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_dazzle_1")
		if talent_ability and talent_ability:GetLevel() > 0 and not caster:HasModifier("modifier_custom_shadow_wave_talent") then
			caster:AddNewModifier(caster, self, "modifier_custom_shadow_wave_talent", {})
		end
	end
end

function custom_dazzle_shadow_wave:WaveHit(target)
	if IsServer() then
		local caster = self:GetCaster()
		local base_heal = self:GetSpecialValueFor("base_heal")
		local bonus_heal = self:GetSpecialValueFor("bonus_heal")
		local buff_duration = self:GetSpecialValueFor("buff_duration")

		-- Increase healing if talent is present
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_dazzle_2")
		if talent_ability and talent_ability:GetLevel() > 0 then
			base_heal = base_heal + self:GetSpecialValueFor("talent_healing")
		end

		-- Heal
		local total_healing = base_heal + bonus_heal * (target:GetMaxHealth() - target:GetHealth()) * 0.01
		target:Heal(total_healing, caster)
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, total_healing, nil)

		-- Apply modifier
		target:AddNewModifier(caster, self, "modifier_custom_shadow_wave_buff", {duration = buff_duration})
	end
end

function custom_dazzle_shadow_wave:BounceFrom(source)
	if IsServer() then
		local caster = self:GetCaster()
		local bounce_distance = self:GetSpecialValueFor("bounce_distance")

		-- Find bounce targets
		local bounce_sources = {}
		local valid_bounce_targets = {}
		local bounce_targets = FindUnitsInRadius(caster:GetTeamNumber(), source:GetAbsOrigin(), nil, bounce_distance, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_CLOSEST, false)
		for _, bounce_target in pairs(bounce_targets) do
			local is_valid_target = true
			for _, hit_target in pairs(self.targets_hit) do
				if hit_target == bounce_target then
					is_valid_target = false
					break
				end
			end

			if is_valid_target then
				valid_bounce_targets[#valid_bounce_targets + 1] = bounce_target
				self.targets_hit[#self.targets_hit + 1] = bounce_target
			end
		end

		-- Draw bounces and apply effect
		for _, valid_bounce_target in pairs(valid_bounce_targets) do
			local wave_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_dazzle/dazzle_shadow_wave.vpcf", PATTACH_CUSTOMORIGIN, source)
			ParticleManager:SetParticleControlEnt(wave_pfx, 0, source, PATTACH_POINT_FOLLOW, "attach_hitloc", source:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(wave_pfx, 1, valid_bounce_target, PATTACH_POINT_FOLLOW, "attach_hitloc", valid_bounce_target:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(wave_pfx)
			self:WaveHit(valid_bounce_target)
			self:BounceFrom(valid_bounce_target)
		end
	end
end

-- Shadow Wave buff modifier
LinkLuaModifier("modifier_custom_shadow_wave_buff", "hero/shadow_wave.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_shadow_wave_buff = modifier_custom_shadow_wave_buff or class({})

function modifier_custom_shadow_wave_buff:IsDebuff() return false end
function modifier_custom_shadow_wave_buff:IsHidden() return false end
function modifier_custom_shadow_wave_buff:IsPurgable() return false end

function modifier_custom_shadow_wave_buff:GetStatusEffectName()
	return "particles/status_fx/status_effect_alacrity.vpcf"
end

function modifier_custom_shadow_wave_buff:StatusEffectPriority()
	return 7
end

function modifier_custom_shadow_wave_buff:OnCreated()
	local ability = self:GetAbility()
	self.bonus_ms = ability:GetSpecialValueFor("buff_ms")
	self.bonus_as = ability:GetSpecialValueFor("buff_as")
end

function modifier_custom_shadow_wave_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
	return funcs
end

function modifier_custom_shadow_wave_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_ms
end

function modifier_custom_shadow_wave_buff:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_as
end

--Talent learned modifier
LinkLuaModifier("modifier_custom_shadow_wave_talent", "hero/shadow_wave.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_shadow_wave_talent = modifier_custom_shadow_wave_talent or class({})

function modifier_custom_shadow_wave_talent:IsDebuff() return false end
function modifier_custom_shadow_wave_talent:IsHidden() return true end
function modifier_custom_shadow_wave_talent:IsPurgable() return false end
function modifier_custom_shadow_wave_talent:IsPermanent() return true end