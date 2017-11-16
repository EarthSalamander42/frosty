--[[	Custom Blur for Frostivus
		By: Firetoad, 11-15-2017		]]

custom_phantom_assassin_blur = custom_phantom_assassin_blur or class({})

-- Active part
function custom_phantom_assassin_blur:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local duration = self:GetSpecialValueFor("active_duration")

		-- If the talent is learned, use the increased duration
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_phantom_assassin_3")
		if talent_ability and talent_ability:GetLevel() > 0 then
			duration = duration + self:GetSpecialValueFor("talent_extra_duration")
		end
		
		-- Play cast particle
		local blur_pfx = ParticleManager:CreateParticle("particles/heroes/phantom_assassin_blur.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(blur_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(blur_pfx)

		-- Play cast sound
		caster:EmitSound("Frostivus.PhantomAssassinBlur")

		-- Apply the active modifier
		caster:AddNewModifier(caster, self, "modifier_custom_blur_active", {duration = duration})
	end 
end

function custom_phantom_assassin_blur:GetIntrinsicModifierName()
	return "modifier_custom_blur_passive"
end

-- Passive modifier
LinkLuaModifier("modifier_custom_blur_passive", "hero/blur.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_blur_passive = modifier_custom_blur_passive or class({})

function modifier_custom_blur_passive:IsDebuff() return false end
function modifier_custom_blur_passive:IsHidden() return true end
function modifier_custom_blur_passive:IsPurgable() return false end

function modifier_custom_blur_passive:DeclareFunctions() 
	local funcs = {
		MODIFIER_PROPERTY_EVASION_CONSTANT
	}
	return funcs 
end

function modifier_custom_blur_passive:GetModifierEvasion_Constant()  
	return self:GetAbility():GetSpecialValueFor("passive_evasion")
end

-- Active modifier
LinkLuaModifier("modifier_custom_blur_active", "hero/blur.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_blur_active = modifier_custom_blur_active or class({})

function modifier_custom_blur_active:IsDebuff() return false end
function modifier_custom_blur_active:IsHidden() return false end
function modifier_custom_blur_active:IsPurgable() return false end

function modifier_custom_blur_active:GetStatusEffectName()
	return "particles/heroes/blur_status_fx.vpcf"
end

function modifier_custom_blur_active:StatusEffectPriority()
	return 10
end

function modifier_custom_blur_active:DeclareFunctions() 
	local funcs = {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
	return funcs 
end

function modifier_custom_blur_active:GetAbsoluteNoDamagePhysical()  
	return 1
end

function modifier_custom_blur_active:GetAbsoluteNoDamageMagical()  
	return 1
end

function modifier_custom_blur_active:GetAbsoluteNoDamagePure()  
	return 1
end