--[[	Custom Mist Coil for Frostivus
		Based on Dota IMBA code
		By: Firetoad, 11-12-2017		]]

custom_abaddon_death_coil = custom_abaddon_death_coil or class({})

function custom_abaddon_death_coil:OnSpellStart(unit)
	if IsServer() then

		-- Parameters
		local caster = self:GetCaster()
		local target = unit or self:GetCursorTarget()
		local health_cost = self:GetLevelSpecialValueFor("self_damage", self:GetLevel() - 1)
		
		-- Play cast sound
		caster:EmitSound("Hero_Abaddon.DeathCoil.Cast")

		-- Deal self damage
		if health_cost > 0 then
			ApplyDamage({ victim = caster, attacker = caster, ability = self, damage = health_cost, damage_type = DAMAGE_TYPE_PURE })
		end

		-- Launch the projectile
		local coil_projectile = {
			Target = target,
			Source = caster,
			Ability = self,
			EffectName = "particles/units/heroes/hero_abaddon/abaddon_death_coil.vpcf",
			bDodgeable = false,
			bProvidesVision = true,
			bVisibleToEnemies = true,
			bReplaceExisting = false,
			iMoveSpeed = self:GetSpecialValueFor("projectile_speed"),
			iVisionRadius = 0,
			iVisionTeamNumber = caster:GetTeamNumber(),
		}
		ProjectileManager:CreateTrackingProjectile(coil_projectile)
	end
end

function custom_abaddon_death_coil:OnProjectileHit(target, location)
	if IsServer() then

		-- Parameters
		local caster = self:GetCaster()
		local ability_level = self:GetLevel() - 1
		local damage = self:GetLevelSpecialValueFor("damage", ability_level)
		local heal = self:GetLevelSpecialValueFor("heal", ability_level)
		local bonus_heal_pct = self:GetLevelSpecialValueFor("bonus_heal_pct", ability_level)
		local mist_duration = self:GetLevelSpecialValueFor("mist_duration", ability_level)

		-- Play hit sound
		target:EmitSound("Hero_Abaddon.DeathCoil.Target")

		-- Increase healing with the talent
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_abaddon_2")
		if talent_ability and talent_ability:GetLevel() > 0 then
			print("talent activated!")
			bonus_heal_pct = bonus_heal_pct + self:GetSpecialValueFor("talent_extra_heal")
		end

		-- Enemy effect
		if target:GetTeam() ~= caster:GetTeam() then

			-- If the target has Linken's Sphere, block effect entirely
			if target:TriggerSpellAbsorb(self) then
				return nil
			end

			-- Apply the Mist
			target:AddNewModifier(caster, self, "modifier_death_coil_debuff", {duration = mist_duration})

			-- Apply damage
			ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})

		-- Ally effect
		else

			-- Calculate total heal
			local ally_heal = heal + target:GetMaxHealth() * bonus_heal_pct * 0.01
	
			-- Heal the target
			target:Heal(ally_heal, caster)
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, ally_heal, nil)

			-- Apply the Mist
			target:AddNewModifier(caster, self, "modifier_death_coil_buff", {duration = mist_duration})
		end
	end
end

-- Mist Coil enemy debuff
LinkLuaModifier("modifier_death_coil_debuff", "hero/mist_coil.lua", LUA_MODIFIER_MOTION_NONE )
modifier_death_coil_debuff = modifier_death_coil_debuff or class({})

function modifier_death_coil_debuff:IsDebuff() return true end
function modifier_death_coil_debuff:IsHidden() return false end
function modifier_death_coil_debuff:IsPurgable() return false end

function modifier_death_coil_debuff:GetEffectName()
	return "particles/generic_particles/abaddon_mist_coil_debuff.vpcf"
end

function modifier_death_coil_debuff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_death_coil_debuff:OnCreated(keys)
	if IsServer() then
		self.damage_taken = 0
	end
end

function modifier_death_coil_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
	return funcs
end

function modifier_death_coil_debuff:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			self.damage_taken = self.damage_taken + keys.damage
		end
	end
end

function modifier_death_coil_debuff:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		local enemy_damage_pct = ability:GetLevelSpecialValueFor("enemy_damage_pct", ability:GetLevel() - 1)
		local damage = self.damage_taken * enemy_damage_pct * 0.01
		ApplyDamage({victim = self:GetParent(), attacker = self:GetCaster(), damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, self:GetParent(), damage, nil)
	end
end

-- Mist Coil ally buff
LinkLuaModifier("modifier_death_coil_buff", "hero/mist_coil.lua", LUA_MODIFIER_MOTION_NONE )
modifier_death_coil_buff = modifier_death_coil_buff or class({})

function modifier_death_coil_buff:IsDebuff() return false end
function modifier_death_coil_buff:IsHidden() return false end
function modifier_death_coil_buff:IsPurgable() return false end

function modifier_death_coil_buff:GetEffectName()
	return "particles/generic_particles/abaddon_mist_coil_buff.vpcf"
end

function modifier_death_coil_buff:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_death_coil_buff:OnCreated(keys)
	if IsServer() then
		self.damage_taken = 0
	end
end

function modifier_death_coil_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
	return funcs
end

function modifier_death_coil_buff:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			self.damage_taken = self.damage_taken + keys.damage
		end
	end
end

function modifier_death_coil_buff:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		local ally_heal_pct = ability:GetLevelSpecialValueFor("ally_heal_pct", ability:GetLevel() - 1)
		local heal = self.damage_taken * ally_heal_pct * 0.01
		self:GetParent():Heal(heal, self:GetCaster())
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, self:GetParent(), heal, nil)
	end
end