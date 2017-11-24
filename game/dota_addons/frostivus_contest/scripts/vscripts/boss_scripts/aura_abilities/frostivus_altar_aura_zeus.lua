-- Zeus (lightning altar) owner aura

-- Aura ability
frostivus_altar_aura_zeus = class({})

function frostivus_altar_aura_zeus:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_zeus" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_zeus", "boss_scripts/aura_abilities/frostivus_altar_aura_zeus.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_zeus = modifier_frostivus_altar_aura_zeus or class({})

function modifier_frostivus_altar_aura_zeus:IsHidden() return true end
function modifier_frostivus_altar_aura_zeus:IsPurgable() return false end
function modifier_frostivus_altar_aura_zeus:IsDebuff() return false end

function modifier_frostivus_altar_aura_zeus:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_altar_aura_zeus:OnIntervalThink()
	if IsServer() then
		
		-- Iterate through aura targets
		local team = self:GetCaster():GetTeam()
		local stacks = self:GetStackCount()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local all_heroes = HeroList:GetAllHeroes()
		for _, hero in pairs(all_heroes) do
			if hero:IsRealHero() and hero:GetTeam() == team then
				if not hero:HasModifier("modifier_frostivus_altar_aura_zeus_buff") then
					hero:AddNewModifier(caster, ability, "modifier_frostivus_altar_aura_zeus_buff", {})
				end
				hero:FindModifierByName("modifier_frostivus_altar_aura_zeus_buff"):SetStackCount(stacks)
			end
		end
	end
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_zeus_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_zeus.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_zeus_buff = modifier_frostivus_altar_aura_zeus_buff or class({})

function modifier_frostivus_altar_aura_zeus_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_zeus_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_zeus_buff:IsDebuff() return false end
function modifier_frostivus_altar_aura_zeus_buff:IsPermanent() return true end

function modifier_frostivus_altar_aura_zeus_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
		MODIFIER_PROPERTY_BONUS_DAY_VISION
	}
	return funcs
end

function modifier_frostivus_altar_aura_zeus_buff:GetModifierAttackRangeBonus()
	return 100 + 25 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_zeus_buff:GetModifierCastRangeBonusStacking()
	return 120 + 30 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_zeus_buff:GetBonusDayVision()
	return 200 + 50 * self:GetStackCount()
end