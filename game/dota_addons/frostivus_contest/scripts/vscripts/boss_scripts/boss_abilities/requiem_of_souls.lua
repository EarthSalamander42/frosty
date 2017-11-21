-- Nevermore's Requiem of Souls (mainly projectile stuff)

frostivus_boss_requiem_of_souls = class({})

function frostivus_boss_requiem_of_souls:IsHiddenWhenStolen() return true end
function frostivus_boss_requiem_of_souls:IsRefreshable() return true end
function frostivus_boss_requiem_of_souls:IsStealable() return false end

function frostivus_boss_requiem_of_souls:OnProjectileHit_ExtraData(target, location, ExtraData)
	if IsServer() then
		if target then
			local caster = self:GetCaster()

			-- Play hit sound
			--target:EmitSound("Hero_Venomancer.VenomousGaleImpact")

			-- Apply gale modifier
			--target:AddNewModifier(caster, self, "modifier_frostivus_venomancer_venomous_gale", ExtraData)
		end
	end
end