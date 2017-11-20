-- Treant's Leech Seed (for the clientside modifier)

frostivus_boss_leech_seed = class({})

function frostivus_boss_leech_seed:IsHiddenWhenStolen() return true end
function frostivus_boss_leech_seed:IsRefreshable() return true end
function frostivus_boss_leech_seed:IsStealable() return false end

function frostivus_boss_leech_seed:OnProjectileHit_ExtraData(target, location, ExtraData)
	if IsServer() then
		if target then
			local heal = target:GetMaxHealth() * ExtraData.heal * 0.01
			target:Heal(heal, target)
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, heal, nil)
		end
	end
end