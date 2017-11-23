--[[	Custom Purification for Frostivus
		By: Firetoad, 11-15-2017				]]

custom_omniknight_purification = custom_omniknight_purification or class({})

function custom_omniknight_purification:OnSpellStart()
	if IsServer() then
		-- Parameters
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local rare_cast_response = "omniknight_omni_ability_purif_03"
		local target_cast_response = {"omniknight_omni_ability_purif_01", "omniknight_omni_ability_purif_02", "omniknight_omni_ability_purif_04", "omniknight_omni_ability_purif_05", "omniknight_omni_ability_purif_06", "omniknight_omni_ability_purif_07", "omniknight_omni_ability_purif_08"}
		local self_cast_response = {"omniknight_omni_ability_purif_01", "omniknight_omni_ability_purif_05", "omniknight_omni_ability_purif_06", "omniknight_omni_ability_purif_07", "omniknight_omni_ability_purif_08"}

		-- Play cast responses    
		if caster == target then
			if RollPercentage(50) then
				EmitSoundOn(self_cast_response[math.random(1, #self_cast_response)], caster)
			end
		else
			-- Roll for rare response
			if RollPercentage(5) then
				EmitSoundOn(rare_cast_response, caster)

			-- Roll for normal reponse
			elseif RollPercentage(50) then
				EmitSoundOn(target_cast_response[math.random(1,#target_cast_response)], caster)
			end
		end
		
		-- Purification!
		Purification(caster, self, target)

		-- If the appropriate talent is learned, purify a second random target
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_omniknight_4")
		if talent_ability and talent_ability:GetLevel() > 0 then
			local bounce_radius = self:GetSpecialValueFor("talent_search_radius")

			-- Find a target to jump to
			local allies = FindUnitsInRadius(caster:GetTeamNumber(),
												caster:GetAbsOrigin(),
												nil,
												bounce_radius + 100,
												DOTA_UNIT_TARGET_TEAM_FRIENDLY,
												DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
												DOTA_UNIT_TARGET_FLAG_NONE,
												FIND_ANY_ORDER,
												false)

			-- Find a bounce target
			for _,ally in pairs(allies) do

				if ally ~= target then
					-- Purify it
					Purification(caster, self, ally)

					-- Stop at the first valid bounce target
					break
				end
			end
		end
	end
end

function Purification(caster, ability, target)
	if IsServer() then
		-- Parameters
		local base_heal = ability:GetSpecialValueFor("base_heal")
		local bonus_heal = ability:GetSpecialValueFor("bonus_heal")
		local radius = ability:GetSpecialValueFor("radius")

		-- If the appropriate talent is learned, increase healing amount
		local talent_ability = caster:FindAbilityByName("special_bonus_unique_omniknight_1")
		if talent_ability and talent_ability:GetLevel() > 0 then
			base_heal = base_heal + ability:GetSpecialValueFor("talent_extra_heal")
		end
		local total_heal = base_heal + target:GetMaxHealth() * bonus_heal * 0.01

		-- Add cast particle
		local cast_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(cast_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(cast_pfx, 1, target:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(cast_pfx)

		-- Add AoE particle
		local aoe_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(aoe_pfx, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(aoe_pfx, 1, Vector(radius, 1, 1))
		ParticleManager:ReleaseParticleIndex(aoe_pfx)    

		-- Play hit sound
		target:EmitSound("Hero_Omniknight.Purification")

		-- Heal target
		target:Heal(total_heal, caster)    
		SendOverheadEventMessage(nil, OVERHEAD_ALERT_HEAL, target, total_heal, nil)

		-- Find enemies around the target
		local enemies = FindUnitsInRadius(caster:GetTeamNumber(),
											target:GetAbsOrigin(),
											nil,
											radius,
											DOTA_UNIT_TARGET_TEAM_ENEMY,
											DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
											DOTA_UNIT_TARGET_FLAG_NONE,
											FIND_ANY_ORDER,
											false)

		-- Damage them
		for _,enemy in pairs(enemies) do
			ApplyDamage({victim = enemy, attacker = caster, damage = base_heal, damage_type = DAMAGE_TYPE_PURE, ability = ability})  

			-- Add hit particle
			local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_omniknight/omniknight_purification_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			ParticleManager:SetParticleControlEnt(hit_pfx, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(hit_pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
			ParticleManager:SetParticleControl(hit_pfx, 3, Vector(radius, 0, 0))
			ParticleManager:ReleaseParticleIndex(hit_pfx)
		end
	end
end