-- Venomancer's Venomous Gale (mainly projectile stuff)

frostivus_boss_venomous_gale = class({})

function frostivus_boss_venomous_gale:IsHiddenWhenStolen() return true end
function frostivus_boss_venomous_gale:IsRefreshable() return true end
function frostivus_boss_venomous_gale:IsStealable() return false end

function frostivus_boss_venomous_gale:OnProjectileHit_ExtraData(target, location, ExtraData)
	if IsServer() then
		local caster = self:GetCaster()

		-- Play hit sound
		target:EmitSound("Hero_Venomancer.VenomousGaleImpact")

		-- Apply gale modifier
		AddNewModifier(caster, self, "modifier_frostivus_venomancer_venomous_gale", ExtraData)
	end
end

--function imba_venomancer_venomous_gale:OnSpellStart()
--    if IsServer() then
--		local caster = self:GetCaster()
--		local target_loc = self:GetCursorPosition()
--		local caster_loc
--		
--		local mouth_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_venomous_gale_mouth.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
--		if self.bWardCaster then
--			caster_loc = self.bWardCaster:GetAbsOrigin()
--			ParticleManager:SetParticleControlEnt(mouth_pfx, 0, self.bWardCaster, PATTACH_POINT_FOLLOW, "attach_attack1", self.bWardCaster:GetAbsOrigin(), true)
--			ParticleManager:ReleaseParticleIndex(mouth_pfx)
--			self.bWardCaster:AddNewModifier(caster, self, "modifier_imba_venomous_gale_wardcast", {duration = 0.4})
--			self.bWardCaster:FadeGesture(ACT_DOTA_ATTACK)
--			self.bWardCaster:StartGestureWithPlaybackRate(ACT_DOTA_ATTACK, 2.3)
--			self.bWardCaster:SetForwardVector((target_loc - caster_loc):Normalized())
--		else
--			caster_loc = caster:GetAbsOrigin()
--			ParticleManager:SetParticleControlEnt(mouth_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_mouth", caster:GetAbsOrigin(), true)
--			ParticleManager:ReleaseParticleIndex(mouth_pfx)
--		end
			--local angle = 360 - (360 / projectile_count)*i
			--local velocity = RotateVector2D(direction,angle,true)
			--local projectile
			--if self.bWardCaster then
			--	travel_distance = self:GetSpecialValueFor("ward_range") + GetCastRangeIncrease(caster)
			--	projectile = 
			--	{
			--		Ability				= self,
			--		EffectName			= "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf",
			--		vSpawnOrigin		= self.bWardCaster:GetAbsOrigin(),
			--		fDistance			= travel_distance,
			--		fStartRadius		= radius,
			--		fEndRadius			= radius,
			--		Source				= caster,
			--		bHasFrontalCone		= true,
			--		bReplaceExisting	= false,
			--		iUnitTargetTeam		= self:GetAbilityTargetTeam(),
			--		iUnitTargetFlags	= self:GetAbilityTargetFlags(),
			--		iUnitTargetType		= self:GetAbilityTargetType(),
			--		fExpireTime 		= GameRules:GetGameTime() + 10.0,
			--		bDeleteOnHit		= true,
			--		vVelocity			= Vector(velocity.x,velocity.y,0) * projectile_speed,
			--		bProvidesVision		= false,
			--		ExtraData			= {index = index, strike_damage = strike_damage, duration = duration, projectile_count = projectile_count}
			--	}