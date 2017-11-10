-- Venomancer's Venomous Gale (mainly projectile stuff)

frostivus_boss_venomous_gale = class({})

function frostivus_boss_venomous_gale:IsHiddenWhenStolen() return true end
function frostivus_boss_venomous_gale:IsRefreshable() return true end
function frostivus_boss_venomous_gale:IsStealable() return false end

function frostivus_boss_venomous_gale:OnProjectileHit_ExtraData(target, location, ExtraData)
	if IsServer() then
		if target then
			local caster = self:GetCaster()

			-- Play hit sound
			target:EmitSound("Hero_Venomancer.VenomousGaleImpact")

			-- Apply gale modifier
			target:AddNewModifier(caster, self, "modifier_frostivus_venomancer_venomous_gale", ExtraData)
		end
	end
end