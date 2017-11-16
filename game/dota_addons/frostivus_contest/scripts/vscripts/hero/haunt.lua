--[[  Custom Haunt for Frostivus
		By: Firetoad, 11-16-2017    ]]

custom_spectre_haunt = custom_spectre_haunt or class({})

function custom_spectre_haunt:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local duration = self:GetSpecialValueFor("haunt_duration")

		-- If the talent is learned, use the upgraded duration
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_spectre_4")
		if talent_ability and talent_ability:GetLevel() > 0 then
			duration = duration + self:GetSpecialValueFor("talent_duration")
		end

		-- If the target possesses a ready Linken's Sphere, do nothing
		if target:GetTeamNumber() ~= caster:GetTeamNumber() then
			if target:TriggerSpellAbsorb(self) then
				return nil
			end
		end

		-- Play sounds
		caster:EmitSound("Hero_Spectre.HauntCast")
		target:EmitSound("Hero_Spectre.Haunt")

		-- Apply haunt modifier
		target:AddNewModifier(caster, self, "modifier_custom_haunt_debuff", {duration = duration})
	end
end

-- Haunt target debuff
LinkLuaModifier("modifier_custom_haunt_debuff", "hero/haunt.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_haunt_debuff = modifier_custom_haunt_debuff or class({})

function modifier_custom_haunt_debuff:IsDebuff() return true end
function modifier_custom_haunt_debuff:IsHidden() return false end
function modifier_custom_haunt_debuff:IsPurgable() return false end

function modifier_custom_haunt_debuff:GetEffectName()
	return "particles/heroes/haunt.vpcf"
end

function modifier_custom_haunt_debuff:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_custom_haunt_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
	return funcs
end

function modifier_custom_haunt_debuff:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			Timers:CreateTimer(0.2, function()

				-- Attack
				local caster = self:GetCaster()
				local target = self:GetParent()
				local remaining_duration = self:GetRemainingTime()
				target:RemoveModifierByName("modifier_custom_haunt_debuff")
				self:GetCaster():PerformAttack(target, true, true, true, true, false, false, true)
				target:AddNewModifier(caster, self:GetAbility(), "modifier_custom_haunt_debuff", {duration = remaining_duration})

				-- Play particle
				local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_spectre/spectre_desolate.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControl(hit_pfx, 0, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(hit_pfx)
			end)
		end
	end
end