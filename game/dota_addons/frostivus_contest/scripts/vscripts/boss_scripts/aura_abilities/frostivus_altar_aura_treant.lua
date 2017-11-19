-- Treant (nature altar) owner aura

-- Aura ability
frostivus_altar_aura_treant = class({})

function frostivus_altar_aura_treant:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_treant" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_treant", "boss_scripts/aura_abilities/frostivus_altar_aura_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_treant = modifier_frostivus_altar_aura_treant or class({})

function modifier_frostivus_altar_aura_treant:IsHidden() return true end
function modifier_frostivus_altar_aura_treant:IsPurgable() return false end
function modifier_frostivus_altar_aura_treant:IsDebuff() return false end

function modifier_frostivus_altar_aura_treant:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_altar_aura_treant:OnIntervalThink()
	if IsServer() then
		
		-- Iterate through aura targets
		local team = self:GetCaster():GetTeam()
		local stacks = self:GetStackCount()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local all_heroes = HeroList:GetAllHeroes()
		for _, hero in pairs(all_heroes) do
			if hero:IsRealHero() and hero:GetTeam() == team then
				if not hero:HasModifier("modifier_frostivus_altar_aura_treant_buff") then
					hero:AddNewModifier(caster, ability, "modifier_frostivus_altar_aura_treant_buff", {})
				end
				hero:FindModifierByName("modifier_frostivus_altar_aura_treant_buff"):SetStackCount(stacks)
			end
		end
	end
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_treant_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_treant_buff = modifier_frostivus_altar_aura_treant_buff or class({})

function modifier_frostivus_altar_aura_treant_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_treant_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_treant_buff:IsDebuff() return false end
function modifier_frostivus_altar_aura_treant_buff:IsPermanent() return true end

function modifier_frostivus_altar_aura_treant_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_altar_aura_treant_buff:GetModifierPhysicalArmorBonus()
	return 3 + 1 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_treant_buff:GetModifierMagicalResistanceBonus()
	return 10 + 3 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_treant_buff:GetModifierExtraHealthPercentage()
	return 0.1
end