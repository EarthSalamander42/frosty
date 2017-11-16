--[[	Custom Kraken Shell for Frostivus
		By: Firetoad, 11-15-2017				]]

custom_tidehunter_kraken_shell = custom_tidehunter_kraken_shell or class({})

function custom_tidehunter_kraken_shell:GetIntrinsicModifierName()
	return "modifier_custom_kraken_shell"
end

-- Passive modifier
LinkLuaModifier("modifier_custom_kraken_shell", "hero/kraken_shell.lua", LUA_MODIFIER_MOTION_NONE )
modifier_custom_kraken_shell = modifier_custom_kraken_shell or class({})

function modifier_custom_kraken_shell:IsDebuff() return false end
function modifier_custom_kraken_shell:IsHidden() return false end
function modifier_custom_kraken_shell:IsPurgable() return false end

function modifier_custom_kraken_shell:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
	return funcs
end

function modifier_custom_kraken_shell:GetModifierTotal_ConstantBlock()
	return self:GetStackCount()
end

function modifier_custom_kraken_shell:OnCreated(keys)
	if IsServer() then
		local ability = self:GetAbility()
		local caster = self:GetParent()
		local max_block = ability:GetSpecialValueFor("max_block")

		-- Grant initial stacks
		self:SetStackCount(caster:GetMaxHealth() * max_block * 0.01)

		-- Start thinking
		self:StartIntervalThink(0.2)
	end
end

function modifier_custom_kraken_shell:OnIntervalThink()
	if IsServer() then
		local ability = self:GetAbility()
		local caster = self:GetParent()
		local max_block = ability:GetSpecialValueFor("max_block")

		-- Recharge stacks, if necessary
		local max_stacks = caster:GetMaxHealth() * max_block * 0.01
		if self:GetStackCount() < max_stacks then
			local recovery_time = ability:GetSpecialValueFor("recovery_time")
			self:SetStackCount(math.min(self:GetStackCount() + max_stacks * 0.2 / recovery_time, max_stacks))
		end
	end
end

function modifier_custom_kraken_shell:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			if keys.original_damage >= self:GetStackCount() then
				self:SetStackCount(0)
			else
				self:SetStackCount(self:GetStackCount() - keys.original_damage)
			end
		end
	end
end