-- Icewrack Lanterns modifiers

modifier_frostivus_lantern = modifier_frostivus_lantern or class({})

function modifier_frostivus_lantern:IsHidden() return true end
function modifier_frostivus_lantern:IsPurgable() return false end
function modifier_frostivus_lantern:IsDebuff() return false end

function modifier_frostivus_lantern:CheckState()
	local state =	{
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true
	}
	return state
end