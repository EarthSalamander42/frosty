--[[	Custom Moment of Courage for Frostivus
		By: Firetoad, 11-15-2017				]]

custom_legion_commander_moment_of_courage = custom_legion_commander_moment_of_courage or class({})

function custom_legion_commander_moment_of_courage:GetIntrinsicModifierName()
	return "modifier_custom_moment_of_courage"
end

-- Passive modifier
LinkLuaModifier("modifier_custom_moment_of_courage", "hero/moment_of_courage.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_moment_of_courage = modifier_custom_moment_of_courage or class({})

function modifier_custom_moment_of_courage:IsDebuff() return false end
function modifier_custom_moment_of_courage:IsHidden() return true end
function modifier_custom_moment_of_courage:IsPurgable() return false end

function modifier_custom_moment_of_courage:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_START
	}
	return funcs
end

function modifier_custom_moment_of_courage:OnAttackStart(keys)
	if IsServer() then
		if keys.attacker == self:GetParent() and keys.attacker:IsRealHero() and self:GetAbility():IsCooldownReady() then
			self:GetParent():AddNewModifier(self:GetParent(), self:GetAbility(), "modifier_custom_moment_of_courage_buff", {})
		end
	end
end

-- Damage buff
LinkLuaModifier("modifier_custom_moment_of_courage_buff", "hero/moment_of_courage.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_moment_of_courage_buff = modifier_custom_moment_of_courage_buff or class({})

function modifier_custom_moment_of_courage_buff:IsDebuff() return false end
function modifier_custom_moment_of_courage_buff:IsHidden() return true end
function modifier_custom_moment_of_courage_buff:IsPurgable() return false end

function modifier_custom_moment_of_courage_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE
	}
	return funcs
end

function modifier_custom_moment_of_courage_buff:OnAttackLanded(keys)
	if IsServer() then
		if keys.attacker == self:GetParent() then
			local attacker = keys.attacker
			local target = keys.target
			local ability = self:GetAbility()
			local damage = keys.damage
			local ally_radius = ability:GetSpecialValueFor("ally_radius")
			local lifesteal_pct = ability:GetSpecialValueFor("lifesteal_pct")
			local duration = ability:GetSpecialValueFor("duration")

			-- Increase healing with the talent
			local talent_ability = attacker:FindAbilityByName("special_bonus_unique_legion_commander_3")
			if talent_ability and talent_ability:GetLevel() > 0 then
				lifesteal_pct = ability:GetSpecialValueFor("lifesteal_pct_talent")
			end

			-- Play hit sound
			target:EmitSound("Hero_LegionCommander.Courage")

			-- Play hit particle
			local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_legion_commander/legion_commander_courage_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControl(hit_pfx, 0, target:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(hit_pfx)

			-- Show damage done
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, target, damage, nil)

			-- Apply healing modifier to allies
			local heal_tick = damage * lifesteal_pct * 0.01 / (duration + 1)
			local heal_targets = FindUnitsInRadius(attacker:GetTeamNumber(), target:GetAbsOrigin(), nil, ally_radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
			for _, ally in pairs(heal_targets) do
				ally:AddNewModifier(attacker, ability, "modifier_custom_moment_of_courage_heal", {duration = duration})

				-- Heal allies every second
				local instances = 0
				Timers:CreateTimer(0.03, function()
					ally:Heal(heal_tick, attacker)
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, ally, heal_tick, nil)

					-- Play lifesteal particle
					local heal_pfx = ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, ally)
					ParticleManager:SetParticleControl(heal_pfx, 0, ally:GetAbsOrigin())
					ParticleManager:ReleaseParticleIndex(heal_pfx)

					-- Stop healing after enough instances
					instances = instances + 1
					if instances < (duration + 1) then
						return 1.0
					end
				end)
			end

			-- Make the ability go on cooldown
			ability:UseResources(false, false, true)

			-- Remove moment of courage modifier
			attacker:RemoveModifierByName("modifier_custom_moment_of_courage_buff")
		end
	end
end

function modifier_custom_moment_of_courage_buff:GetModifierBaseDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("bonus_damage")
end

-- Heal over time
LinkLuaModifier("modifier_custom_moment_of_courage_heal", "hero/moment_of_courage.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_moment_of_courage_heal = modifier_custom_moment_of_courage_heal or class({})

function modifier_custom_moment_of_courage_heal:IsDebuff() return false end
function modifier_custom_moment_of_courage_heal:IsHidden() return false end
function modifier_custom_moment_of_courage_heal:IsPurgable() return false end