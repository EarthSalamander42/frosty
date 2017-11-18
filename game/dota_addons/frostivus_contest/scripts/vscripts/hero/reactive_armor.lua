--[[	Custom Reactive Armor for Frostivus
		By: Firetoad, 11-17-2017				]]

custom_shredder_reactive_armor = custom_shredder_reactive_armor or class({})

function custom_shredder_reactive_armor:GetIntrinsicModifierName()
	return "modifier_custom_reactive_armor"
end

-- Passive modifier
LinkLuaModifier("modifier_custom_reactive_armor", "hero/reactive_armor.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_reactive_armor = modifier_custom_reactive_armor or class({})

function modifier_custom_reactive_armor:IsDebuff() return false end
function modifier_custom_reactive_armor:IsHidden() return true end
function modifier_custom_reactive_armor:IsPurgable() return false end

function modifier_custom_reactive_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
	return funcs
end

function modifier_custom_reactive_armor:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			local caster = self:GetParent()
			local ability = self:GetAbility()
			local regen_pct = ability:GetSpecialValueFor("regen_pct")
			local regen_duration = ability:GetSpecialValueFor("regen_duration")
			local reactive_duration = ability:GetSpecialValueFor("reactive_duration")

			-- If the talent is learned, use the reduced duration
			local talent_ability = caster:FindAbilityByName("special_bonus_unique_timbersaw_2")
			if talent_ability and talent_ability:GetLevel() > 0 then
				regen_duration = regen_duration - ability:GetSpecialValueFor("talent_duration_reduction")
			end

			-- Add regen modifier
			local regen_per_tick = keys.damage * regen_pct * 0.01 / regen_duration
			caster:AddNewModifier(caster, ability, "modifier_custom_reactive_armor_regen", {duration = regen_duration, regen = regen_per_tick})

			if keys.damage_type == DAMAGE_TYPE_PHYSICAL then
				caster:AddNewModifier(caster, ability, "modifier_custom_reactive_armor_physical", {duration = reactive_duration})
			elseif keys.damage_type == DAMAGE_TYPE_MAGICAL then
				caster:AddNewModifier(caster, ability, "modifier_custom_reactive_armor_magic", {duration = reactive_duration})
			end
		end
	end
end

-- Regen modifier
LinkLuaModifier("modifier_custom_reactive_armor_regen", "hero/reactive_armor.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_reactive_armor_regen = modifier_custom_reactive_armor_regen or class({})

function modifier_custom_reactive_armor_regen:IsDebuff() return false end
function modifier_custom_reactive_armor_regen:IsHidden() return true end
function modifier_custom_reactive_armor_regen:IsPurgable() return false end

function modifier_custom_reactive_armor_regen:GetAttributes()
	local attributes = {
		MODIFIER_ATTRIBUTE_MULTIPLE
	}
	return attributes
end

function modifier_custom_reactive_armor_regen:OnCreated(keys)
	if IsServer() then
		self.regen = keys.regen
	end
end

function modifier_custom_reactive_armor_regen:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT
	}
	return funcs
end

function modifier_custom_reactive_armor_regen:GetModifierConstantHealthRegen()
	if IsServer() then
		return self.regen
	end
end

-- Armor modifier
LinkLuaModifier("modifier_custom_reactive_armor_physical", "hero/reactive_armor.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_reactive_armor_physical = modifier_custom_reactive_armor_physical or class({})

function modifier_custom_reactive_armor_physical:IsDebuff() return false end
function modifier_custom_reactive_armor_physical:IsHidden() return true end
function modifier_custom_reactive_armor_physical:IsPurgable() return false end

function modifier_custom_reactive_armor_physical:GetAttributes()
	local attributes = {
		MODIFIER_ATTRIBUTE_MULTIPLE
	}
	return attributes
end

function modifier_custom_reactive_armor_physical:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
	}
	return funcs
end

function modifier_custom_reactive_armor_physical:GetModifierPhysicalArmorBonus()
	return self:GetAbility():GetSpecialValueFor("reactive_armor")
end

-- Magic resistance modifier
LinkLuaModifier("modifier_custom_reactive_armor_magic", "hero/reactive_armor.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_reactive_armor_magic = modifier_custom_reactive_armor_magic or class({})

function modifier_custom_reactive_armor_magic:IsDebuff() return false end
function modifier_custom_reactive_armor_magic:IsHidden() return true end
function modifier_custom_reactive_armor_magic:IsPurgable() return false end

function modifier_custom_reactive_armor_magic:GetAttributes()
	local attributes = {
		MODIFIER_ATTRIBUTE_MULTIPLE
	}
	return attributes
end

function modifier_custom_reactive_armor_magic:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS
	}
	return funcs
end

function modifier_custom_reactive_armor_magic:GetModifierMagicalResistanceBonus()
	return self:GetAbility():GetSpecialValueFor("reactive_magic_resist")
end