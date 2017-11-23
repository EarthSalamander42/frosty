--[[  Custom Battle Hunger for Frostivus
		By: Firetoad, 11-13-2017    ]]

custom_axe_battle_hunger = custom_axe_battle_hunger or class({})

function custom_axe_battle_hunger:OnSpellStart(unit)
	if IsServer() then
		local caster = self:GetCaster()
		local target = unit or self:GetCursorTarget()
		local duration = self:GetSpecialValueFor("duration")

		-- If the talent is learned, use the upgraded duration
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_axe")
		if talent_ability and talent_ability:GetLevel() > 0 then
			duration = duration + self:GetSpecialValueFor("talent_duration")
		end

		-- If the target possesses a ready Linken's Sphere, do nothing
		if target:GetTeamNumber() ~= caster:GetTeamNumber() then
			if target:TriggerSpellAbsorb(self) then
				return nil
			end
		end

		-- Play sound
		target:EmitSound("Hero_Axe.Battle_Hunger")

		-- Apply battle hunger modifier
		target:AddNewModifier(caster, self, "custom_battle_hunger_debuff", {duration = duration})
	end
end

-- Battle Hunger enemy debuff
LinkLuaModifier("custom_battle_hunger_debuff", "hero/battle_hunger.lua", LUA_MODIFIER_MOTION_NONE )
custom_battle_hunger_debuff = custom_battle_hunger_debuff or class({})

function custom_battle_hunger_debuff:IsDebuff() return true end
function custom_battle_hunger_debuff:IsHidden() return false end
function custom_battle_hunger_debuff:IsPurgable() return false end

function custom_battle_hunger_debuff:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_battle_hunger.vpcf"
end

function custom_battle_hunger_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function custom_battle_hunger_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_battle_hunger.vpcf"
end

function custom_battle_hunger_debuff:StatusEffectPriority()
	return 9
end

function custom_battle_hunger_debuff:OnCreated(keys)
	if IsServer() then
		local caster = self:GetCaster()
		if not caster:HasModifier("custom_battle_hunger_caster_buff") then
			caster:AddNewModifier(caster, self:GetAbility(), "custom_battle_hunger_caster_buff", {})
		end
		
		local modifier_caster = caster:FindModifierByName("custom_battle_hunger_caster_buff")
		modifier_caster:SetStackCount(modifier_caster:GetStackCount() + 1)
	end
end

function custom_battle_hunger_debuff:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local modifier_caster = caster:FindModifierByName("custom_battle_hunger_caster_buff")
		if modifier_caster then
			modifier_caster:SetStackCount(modifier_caster:GetStackCount() - 1)
			if modifier_caster:GetStackCount() <= 0 then
				caster:RemoveModifierByName("custom_battle_hunger_caster_buff")
			end
		end
	end
end

function custom_battle_hunger_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	}
	return funcs
end

function custom_battle_hunger_debuff:GetModifierTotalDamageOutgoing_Percentage()
	return self:GetAbility():GetSpecialValueFor("damage_reduction")
end

function custom_battle_hunger_debuff:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			local caster = self:GetCaster()
			local ability = self:GetAbility()
			local damage = keys.damage
			local lifesteal_pct = ability:GetLevelSpecialValueFor("lifesteal_pct", ability:GetLevel() - 1)

			-- Play particle
			local lifesteal_pfx = ParticleManager:CreateParticle("particles/heroes/axe_hunger_lifesteal.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(lifesteal_pfx, 0, caster:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(lifesteal_pfx)

			-- Heal caster
			caster:Heal(damage * lifesteal_pct * 0.01, caster)
		end
	end
end

-- Battle Hunger caster buff
LinkLuaModifier("custom_battle_hunger_caster_buff", "hero/battle_hunger.lua", LUA_MODIFIER_MOTION_NONE )
custom_battle_hunger_caster_buff = custom_battle_hunger_caster_buff or class({})

function custom_battle_hunger_caster_buff:IsDebuff() return false end
function custom_battle_hunger_caster_buff:IsHidden() return false end
function custom_battle_hunger_caster_buff:IsPurgable() return false end

function custom_battle_hunger_caster_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function custom_battle_hunger_caster_buff:GetModifierMoveSpeedBonus_Percentage()
	return self:GetAbility():GetSpecialValueFor("speed_bonus") * self:GetStackCount()
end