-- Treant (nature altar) owner aura

-- Aura ability
frostivus_altar_aura_lich = class({})

function frostivus_altar_aura_lich:GetIntrinsicModifierName() return "modifier_frostivus_altar_aura_lich" end

-- Aura emitter
LinkLuaModifier("modifier_frostivus_altar_aura_lich", "boss_scripts/aura_abilities/frostivus_altar_aura_lich.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_lich = modifier_frostivus_altar_aura_lich or class({})

function modifier_frostivus_altar_aura_lich:IsHidden() return true end
function modifier_frostivus_altar_aura_lich:IsPurgable() return false end
function modifier_frostivus_altar_aura_lich:IsDebuff() return false end

function modifier_frostivus_altar_aura_lich:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_altar_aura_lich:OnIntervalThink()
	if IsServer() then
		
		-- Iterate through aura targets
		local team = self:GetCaster():GetTeam()
		local stacks = self:GetStackCount()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local all_heroes = HeroList:GetAllHeroes()
		for _, hero in pairs(all_heroes) do
			if hero:IsRealHero() and hero:GetTeam() == team then
				if not hero:HasModifier("modifier_frostivus_altar_aura_lich_buff") then
					hero:AddNewModifier(caster, ability, "modifier_frostivus_altar_aura_lich_buff", {})
				end
				hero:FindModifierByName("modifier_frostivus_altar_aura_lich_buff"):SetStackCount(stacks)
			end
		end
	end
end

-- Aura buff
LinkLuaModifier("modifier_frostivus_altar_aura_lich_buff", "boss_scripts/aura_abilities/frostivus_altar_aura_lich.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_altar_aura_lich_buff = modifier_frostivus_altar_aura_lich_buff or class({})

function modifier_frostivus_altar_aura_lich_buff:IsHidden() return false end
function modifier_frostivus_altar_aura_lich_buff:IsPurgable() return false end
function modifier_frostivus_altar_aura_lich_buff:IsDebuff() return false end
function modifier_frostivus_altar_aura_lich_buff:IsPermanent() return true end

function modifier_frostivus_altar_aura_lich_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_altar_aura_lich_buff:GetModifierBaseDamageOutgoing_Percentage()
	return 30 + 10 * self:GetStackCount()
end

function modifier_frostivus_altar_aura_lich_buff:GetModifierSpellAmplify_Percentage()
	return 15 + 5 * self:GetStackCount()
end