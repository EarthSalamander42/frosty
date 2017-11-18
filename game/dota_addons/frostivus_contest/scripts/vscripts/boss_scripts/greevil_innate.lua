-- Greevil innate buffs ability

frostivus_greevil_innate = frostivus_greevil_innate or class({})

function frostivus_greevil_innate:GetIntrinsicModifierName()
	return "modifier_frostivus_greevil"	
end

LinkLuaModifier("modifier_frostivus_greevil", "boss_scripts/greevil_innate", LUA_MODIFIER_MOTION_NONE)

modifier_frostivus_greevil = modifier_frostivus_greevil or class({})

function modifier_frostivus_greevil:IsHidden() return true end
function modifier_frostivus_greevil:IsPurgable() return false end
function modifier_frostivus_greevil:IsDebuff() return false end

function modifier_frostivus_greevil:CheckState()
	local state =
	{
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true
	}
	return state
end