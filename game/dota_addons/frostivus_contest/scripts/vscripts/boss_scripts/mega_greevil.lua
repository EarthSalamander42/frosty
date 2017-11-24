-- Boss innate buffs ability

frostivus_mega_greevil = frostivus_mega_greevil or class({})

function frostivus_mega_greevil:GetIntrinsicModifierName()
	return "modifier_frostivus_mega_greevil"	
end

LinkLuaModifier("modifier_frostivus_mega_greevil", "boss_scripts/mega_greevil", LUA_MODIFIER_MOTION_NONE)

modifier_frostivus_mega_greevil = modifier_frostivus_mega_greevil or class({})

function modifier_frostivus_mega_greevil:IsHidden() return false end
function modifier_frostivus_mega_greevil:IsPurgable() return false end
function modifier_frostivus_mega_greevil:IsDebuff() return false end

function modifier_frostivus_mega_greevil:OnCreated()
	self:StartIntervalThink(5.0)
end

function modifier_frostivus_mega_greevil:OnIntervalThink()
	if IsServer() then

		-- Play a random aggressive animation
		local random = RandomInt(1, 4)
		if random == 1 then
			StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_ATTACK, rate=1.0})
		elseif random == 2 then
			StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_FLAIL, rate=1.0})
		elseif random == 3 then
			StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_SPAWN, rate=1.0})
		end
	end
end

function modifier_frostivus_mega_greevil:CheckState()
	if IsServer() then
		local state = {
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
		}
		return state
	end
end

function modifier_frostivus_mega_greevil:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
		MODIFIER_PROPERTY_MOVESPEED_MAX
	}
	return funcs
end

function modifier_frostivus_mega_greevil:GetModifierMoveSpeedBonus_Percentage()
	return 100
end

function modifier_frostivus_mega_greevil:GetModifierMoveSpeed_AbsoluteMin()
	return 1000
end

function modifier_frostivus_mega_greevil:GetModifierMoveSpeed_Max()
	return 1000
end