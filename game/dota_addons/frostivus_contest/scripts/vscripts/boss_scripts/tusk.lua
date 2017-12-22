-- Boss innate buffs ability

frostivus_tusk = frostivus_tusk or class({})

function frostivus_tusk:GetIntrinsicModifierName()
	return "modifier_frostivus_tusk"	
end

LinkLuaModifier("modifier_frostivus_tusk", "boss_scripts/tusk", LUA_MODIFIER_MOTION_NONE)

modifier_frostivus_tusk = modifier_frostivus_tusk or class({})

function modifier_frostivus_tusk:IsHidden() return false end
function modifier_frostivus_tusk:IsPurgable() return false end
function modifier_frostivus_tusk:IsDebuff() return false end

function modifier_frostivus_tusk:OnCreated()
	self:StartIntervalThink(5.0)
end

function modifier_frostivus_tusk:OnIntervalThink()
	if IsServer() then

		-- Play a random aggressive animation
		Timers:CreateTimer(1.0, function()
			local random = RandomInt(1, 5)
			if random == 1 then
				StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_ATTACK, rate=1.0})
			elseif random == 2 then
				StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
			elseif random == 3 then
				StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_GENERIC_CHANNEL_1, rate=1.0})
			elseif random == 4 then
				StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_SPAWN, rate=1.0})
			elseif random == 5 then
				StartAnimation(self:GetParent(), {duration = 2.0, activity=ACT_DOTA_CAST_ABILITY_5, rate=1.0})
			end
		end)

		-- Attack sounds
		self:GetParent():EmitSound("Hero_Tusk.PreAttack")
		Timers:CreateTimer(0.36, function()
			self:GetParent():EmitSound("Hero_Tusk.Attack")
		end)
	end
end

function modifier_frostivus_tusk:CheckState()
	if IsServer() then
		local state = {
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_FLYING_FOR_PATHING_PURPOSES_ONLY] = true
		}
		return state
	end
end

function modifier_frostivus_tusk:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN,
		MODIFIER_PROPERTY_MOVESPEED_MAX,
		MODIFIER_EVENT_ON_DEATH
	}
	return funcs
end

function modifier_frostivus_tusk:GetModifierMoveSpeedBonus_Percentage()
	return 100
end

function modifier_frostivus_tusk:GetModifierMoveSpeed_AbsoluteMin()
	return 1000
end

function modifier_frostivus_tusk:GetModifierMoveSpeed_Max()
	return 1000
end

function modifier_frostivus_tusk:OnDeath(keys)
	if keys.unit == self:GetParent() then
		StartPhaseTwo()
		StartPhaseThree()

		-- Play phase 3 stinger
		PlaySoundForTeam(DOTA_TEAM_GOODGUYS, "greevil_loot_spawn_Stinger")
		PlaySoundForTeam(DOTA_TEAM_BADGUYS, "greevil_loot_spawn_Stinger")
	end
end