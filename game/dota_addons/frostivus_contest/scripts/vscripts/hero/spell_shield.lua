--[[	Custom Spell Shield for Frostivus
		By: Firetoad, 11-12-2017		]]

custom_antimage_spell_shield = custom_antimage_spell_shield or class({})

-- Active part
function custom_antimage_spell_shield:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local duration = self:GetSpecialValueFor("active_duration")

		-- If the talent is learned, use the upgraded modifier
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_antimage_4")
		if talent_ability and talent_ability:GetLevel() > 0 then
			caster:AddNewModifier(caster, self, "modifier_custom_spell_shield_active_upgraded", {duration = duration})
		else
			caster:AddNewModifier(caster, self, "modifier_custom_spell_shield_active", {duration = duration})
		end
		
		-- Play cast particle
		local shield_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_antimage/antimage_spellshield_reflect.vpcf", PATTACH_CUSTOMORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(shield_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(shield_pfx)

		-- Play cast sound
		caster:EmitSound("Hero_Antimage.SpellShield.Block")
	end 
end

function custom_antimage_spell_shield:GetIntrinsicModifierName()
	if IsServer() then

		-- If the talent is learned, use the upgraded modifier
		local talent_ability = self:GetCaster():FindAbilityByName("special_bonus_unique_antimage_4")
		if talent_ability and talent_ability:GetLevel() > 0 then
			return "modifier_custom_spell_shield_passive_upgraded"
		else
			return "modifier_custom_spell_shield_passive"
		end
	end
end

-- Passive modifier
LinkLuaModifier("modifier_custom_spell_shield_passive", "hero/spell_shield.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_spell_shield_passive = modifier_custom_spell_shield_passive or class({})

function modifier_custom_spell_shield_passive:IsDebuff() return false end
function modifier_custom_spell_shield_passive:IsHidden() return true end
function modifier_custom_spell_shield_passive:IsPurgable() return false end

function modifier_custom_spell_shield_passive:DeclareFunctions() 
	local decFuncs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
	return decFuncs 
end

function modifier_custom_spell_shield_passive:GetModifierMagicalResistanceBonus()  
	return self:GetAbility():GetSpecialValueFor("passive_mr")
end

-- Talent-upgraded passive modifier
LinkLuaModifier("modifier_custom_spell_shield_passive_upgraded", "hero/spell_shield.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_spell_shield_passive_upgraded = modifier_custom_spell_shield_passive_upgraded or class({})

function modifier_custom_spell_shield_passive_upgraded:IsDebuff() return false end
function modifier_custom_spell_shield_passive_upgraded:IsHidden() return true end
function modifier_custom_spell_shield_passive_upgraded:IsPurgable() return false end

function modifier_custom_spell_shield_passive_upgraded:DeclareFunctions() 
	local decFuncs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
	return decFuncs 
end

function modifier_custom_spell_shield_passive_upgraded:GetModifierMagicalResistanceBonus()  
	return self:GetAbility():GetSpecialValueFor("talent_mr")
end

-- Active modifier
LinkLuaModifier("modifier_custom_spell_shield_active", "hero/spell_shield.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_spell_shield_active = modifier_custom_spell_shield_active or class({})

function modifier_custom_spell_shield_active:IsDebuff() return false end
function modifier_custom_spell_shield_active:IsHidden() return false end
function modifier_custom_spell_shield_active:IsPurgable() return false end

function modifier_custom_spell_shield_active:DeclareFunctions() 
	local decFuncs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
	return decFuncs 
end

function modifier_custom_spell_shield_active:GetModifierMagicalResistanceBonus()  
	return self:GetAbility():GetSpecialValueFor("active_mr")
end

-- Talent-upgraded active modifier
LinkLuaModifier("modifier_custom_spell_shield_active_upgraded", "hero/spell_shield.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_spell_shield_active_upgraded = modifier_custom_spell_shield_active_upgraded or class({})

function modifier_custom_spell_shield_active_upgraded:IsDebuff() return false end
function modifier_custom_spell_shield_active_upgraded:IsHidden() return false end
function modifier_custom_spell_shield_active_upgraded:IsPurgable() return false end

function modifier_custom_spell_shield_active_upgraded:DeclareFunctions() 
	local decFuncs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
	return decFuncs 
end

function modifier_custom_spell_shield_active_upgraded:GetModifierMagicalResistanceBonus()  
	return 100
end