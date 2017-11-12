-- Venomancer (poison altar) owner aura

-- Aura ability
frostivus_altar_aura_veno = class({})

function frostivus_altar_aura_veno:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_veno" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_veno", "boss_scripts/aura_abilities/frostivus_altar_aura_veno.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_veno = modifier_frostivus_altar_aura_veno or class({})

function modifier_frostivus_altar_aura_veno:IsHidden() return true end
function modifier_frostivus_altar_aura_veno:IsPurgable() return false end
function modifier_frostivus_altar_aura_veno:IsDebuff() return false end

function modifier_frostivus_altar_aura_veno:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_altar_aura_veno:OnIntervalThink()
	if IsServer() then
		
		-- Iterate through aura targets
		local team = self:GetCaster():GetTeam()
		local stacks = self:GetStackCount()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local all_heroes = HeroList:GetAllHeroes()
		for _, hero in pairs(all_heroes) do
			if hero:IsRealHero() and hero:GetTeam() == team then
				if not hero:HasModifier("modifier_frostivus_altar_aura_veno_buff") then
					hero:AddNewModifier(caster, ability, "modifier_frostivus_altar_aura_veno_buff", {})
				end
				hero:FindModifierByName("modifier_frostivus_altar_aura_veno_buff"):SetStackCount(stacks)
			end
		end
	end
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_veno_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_veno.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_veno_buff = modifier_frostivus_altar_aura_veno_buff or class({})

function modifier_frostivus_altar_aura_veno_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_veno_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_veno_buff:IsDebuff() return false end
function modifier_frostivus_altar_aura_veno_buff:IsPermanent() return true end

function modifier_frostivus_altar_aura_veno_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE_STACKING
	}
	return funcs
end

function modifier_frostivus_altar_aura_veno_buff:GetModifierMoveSpeedBonus_Percentage()
	return 10 + 2 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_veno_buff:GetModifierAttackSpeedBonus_Constant()
	return 20 + 10 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_veno_buff:GetModifierPercentageCooldownStacking()
	return 10 + 2 * self:GetStackCount()
end