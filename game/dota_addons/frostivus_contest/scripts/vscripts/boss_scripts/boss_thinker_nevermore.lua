-- Nevermore AI thinker

boss_thinker_nevermore = class({})

-----------------------------------------------------------------------

function boss_thinker_nevermore:IsHidden()
	return true
end

-----------------------------------------------------------------------

function boss_thinker_nevermore:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function boss_thinker_nevermore:OnCreated( params )
	if IsServer() then
		self.boss_name = "nevermore"
		self.team = "no team passed"
		self.altar_handle = "no altar handle passed"
		if params.team then
			self.team = params.team
		end
		if params.altar_handle then
			self.altar_handle = params.altar_handle
		end

		-- Draw boss ambient articles
		if not self.fire_pfx then
			local boss = self:GetParent()
			local boss_loc = boss:GetAbsOrigin()
			self.fire_pfx = ParticleManager:CreateParticle("particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_ambient.vpcf", PATTACH_POINT_FOLLOW, boss)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 1, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 2, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 3, boss, PATTACH_POINT_FOLLOW, "attach_arm_L", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 4, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 5, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 6, boss, PATTACH_POINT_FOLLOW, "attach_arm_R", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 7, boss, PATTACH_POINT_FOLLOW, "attach_head", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.fire_pfx, 8, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)

			self.shoulders_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/nevermore_shoulder_ambient.vpcf", PATTACH_POINT_FOLLOW, boss)
			ParticleManager:SetParticleControlEnt(self.shoulders_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_shoulder_l", boss_loc, true)
			ParticleManager:SetParticleControlEnt(self.shoulders_pfx, 4, boss, PATTACH_POINT_FOLLOW, "attach_hitloc", boss_loc, true)
			ParticleManager:ReleaseParticleIndex(self.shoulders_pfx)

			self.shadow_trail_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_trail.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
			ParticleManager:SetParticleControl(self.shadow_trail_pfx, 0, boss_loc)
			ParticleManager:ReleaseParticleIndex(self.shadow_trail_pfx)
		end

		-- Boss script constants
		self.random_constants = {}
		self.random_constants[1] = RandomInt(1, 360)
		self.random_constants[2] = RandomInt(1, 360)

		-- Start thinking
		self.boss_timer = 0
		self.events = {}
		self:StartIntervalThink(0.1)
	end
end

-----------------------------------------------------------------------

function boss_thinker_nevermore:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

-----------------------------------------------------------------------

function boss_thinker_nevermore:OnDeath(keys)
local target = keys.unit

	if IsServer() then

		-- Boss death
		if target == self:GetParent() then

			-- Notify the console that a boss fight (capture attempt) has ended with a successful kill
			print(self.boss_name.." boss is dead, winning team is "..self.team)

			-- Play the capture particle & sound to the winning team
			local target_loc = target:GetAbsOrigin()
			for player_id = 0, 20 do
				if PlayerResource:GetPlayer(player_id) and PlayerResource:GetTeam(player_id) == self.team then
					local win_pfx = ParticleManager:CreateParticleForPlayer("particles/boss_veno/screen_veno_win.vpcf", PATTACH_EYES_FOLLOW, PlayerResource:GetSelectedHeroEntity(player_id), PlayerResource:GetPlayer(player_id))
					self:AddParticle(win_pfx, false, false, -1, false, false)
					ParticleManager:ReleaseParticleIndex(win_pfx)
					EmitSoundOnClient("greevil_eventend_Stinger", PlayerResource:GetPlayer(player_id))
				end
			end

			-- Drop presents according to boss difficulty
			local current_power = target:FindModifierByName("modifier_frostivus_boss"):GetStackCount()
			local altar_loc = Entities:FindByName(nil, self.altar_handle):GetAbsOrigin()
			local present_amount = 2 + current_power
			for i = 1, present_amount do
				local item = CreateItem("item_frostivus_present", nil, nil)
				CreateItemOnPositionForLaunch(target_loc, item)
				item:LaunchLootInitialHeight(true, 150, 300, 1.0, altar_loc + RandomVector(100):Normalized() * RandomInt(100, 200))
			end

			-- Spawn a greevil that runs away
			local greevil = SpawnGreevil(target_loc, 2, false, 200, 255, 0)
			Timers:CreateTimer(3, function()
				StartAnimation(greevil, {duration = 2.5, activity=ACT_DOTA_FLAIL, rate=1.5})
				greevil:MoveToPosition(altar_loc + RandomVector(10):Normalized() * 900)
				Timers:CreateTimer(2.5, function()
					greevil:Kill(nil, greevil)
				end)
			end)

			-- Respawn the boss and grant it its new capture detection modifier
			local boss
			Timers:CreateTimer(15, function()
				boss = SpawnVenomancer(self.altar_handle)

				-- Increase the new boss' power
				local next_power = math.ceil(current_power * 0.25) + 1
				boss:FindModifierByName("modifier_frostivus_boss"):SetStackCount(current_power + next_power)
			end)

			-- Destroy any existing adds
			local nearby_summons = FindUnitsInRadius(target:GetTeam(), target:GetAbsOrigin(), nil, 1800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
			for _,summon in pairs(nearby_summons) do
				if not summon:HasModifier("modifier_frostivus_greevil") then
					summon:Kill(nil, summon)
				end
			end

			-- Unlock the arena
			UnlockArena(self.altar_handle, true, self.team, "frostivus_altar_aura_veno")

			-- Delete the boss AI thinker modifier
			target:RemoveModifierByName("boss_thinker_nevermore")
		end
	end
end

-----------------------------------------------------------------------

function boss_thinker_nevermore:OnIntervalThink()
	if IsServer() then

		-- Parameters
		local boss = self:GetParent()
		local altar_entity = Entities:FindByName(nil, self.altar_handle)
		local altar_loc = altar_entity:GetAbsOrigin()
		local power_stacks = boss:FindModifierByName("modifier_frostivus_boss"):GetStackCount()

		-- Sends boss health information to fighting team's clients
		UpdateBossBar(boss, self.team)

		-- Think
		self.boss_timer = self.boss_timer + 0.1

		-- Boss move script
		if self.boss_timer > 0 and not self.events[1] then
			self:VenomousGale(altar_loc, altar_entity, 3.0, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[1] = true
		end

		if self.boss_timer > 5 and not self.events[2] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[2] = true
		end

		if self.boss_timer > 8 and not self.events[3] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[3] = true
		end

		if self.boss_timer > 11 and not self.events[4] then
			self:UnwillingHost(altar_loc, altar_entity, 1.5, 400, 9, 15, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[4] = true
		end

		if self.boss_timer > 13 and not self.events[5] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[5] = true
		end

		if self.boss_timer > 16 and not self.events[6] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[6] = true
		end

		if self.boss_timer > 21 and not self.events[7] then
			self:GreenDeath(altar_loc, altar_entity, 3.5, 15, 4.0, RandomInt(1, 360), 80, 4.0, 2000, 125, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[7] = true
		end

		if self.boss_timer > 30 and not self.events[8] then
			self:PoisonNova(altar_loc, altar_entity, 3.0, 1, 300, 16, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[8] = true
		end

		if self.boss_timer > 34 and not self.events[9] then
			self:SpawnScourgeWard(altar_loc, altar_entity, 1.0, RandomInt(1, 360), 800, math.min(4 + 0.4 * power_stacks, 8), 150, math.min(20 + power_stacks * 5, 80), 10, 10, 4, 3, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[9] = true
		end

		if self.boss_timer > 36 and not self.events[10] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[10] = true
		end

		if self.boss_timer > 39 and not self.events[11] then
			self:Parasite(altar_loc, altar_entity, 2.0, 1, 3.0, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[11] = true
		end

		if self.boss_timer > 42 and not self.events[12] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[12] = true
		end

		if self.boss_timer > 45 and not self.events[13] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[13] = true
		end

		if self.boss_timer > 50 and not self.events[14] then
			self:SpawnScourgeWard(altar_loc, altar_entity, 0.8, self.random_constants[1], 800, math.min(4 + 0.4 * power_stacks, 8), 150, math.min(20 + power_stacks * 5, 80), 10, 10, 4, 3, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[14] = true
		end

		if self.boss_timer > 51 and not self.events[15] then
			self:SpawnScourgeWard(altar_loc, altar_entity, 0.8, self.random_constants[1] + 120, 800, math.min(4 + 0.4 * power_stacks, 8), 150, math.min(20 + power_stacks * 5, 80), 10, 10, 4, 3, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[15] = true
		end

		if self.boss_timer > 52 and not self.events[16] then
			self:SpawnScourgeWard(altar_loc, altar_entity, 0.8, self.random_constants[1] + 240, 800, math.min(4 + 0.4 * power_stacks, 8), 150, math.min(20 + power_stacks * 5, 80), 10, 10, 4, 3, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[16] = true
		end

		if self.boss_timer > 53 and not self.events[17] then
			self:UnwillingHost(altar_loc, altar_entity, 1.5, 400, 15, 15, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[17] = true
		end

		if self.boss_timer > 55 and not self.events[18] then
			self:Parasite(altar_loc, altar_entity, 2.0, 2, 3.0, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[18] = true
		end

		if self.boss_timer > 58 and not self.events[19] then
			self:PoisonNova(altar_loc, altar_entity, 2.5, 1, 300, 9, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[19] = true
		end

		if self.boss_timer > 62 and not self.events[20] then
			self:GreenDeath(altar_loc, altar_entity, 3.5, 15, 4.0, RandomInt(1, 360), 80, 4.0, 2000, 125, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[20] = true
		end

		if self.boss_timer > 71 and not self.events[21] then
			self:UnwillingHost(altar_loc, altar_entity, 1.5, 400, 10, 40, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[21] = true
		end

		if self.boss_timer > 73 and not self.events[22] then
			self:UnwillingHost(altar_loc, altar_entity, 1.5, 400, 10, 38, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[22] = true
		end

		if self.boss_timer > 75 and not self.events[23] then
			self:SpawnVileWard(altar_loc, altar_entity, 1.0, RandomInt(1, 360), 450, math.min(6 + 0.5 * power_stacks, 12), 150, math.min(20 + power_stacks * 5, 80), 10, 10, 4, 8, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[23] = true
		end

		if self.boss_timer > 80 and not self.events[24] then
			self:Parasite(altar_loc, altar_entity, 1.5, 2, 3.0, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[24] = true
		end

		if self.boss_timer > 82 and not self.events[25] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[25] = true
		end

		if self.boss_timer > 85 and not self.events[26] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[26] = true
		end

		if self.boss_timer > 91 and not self.events[27] then
			self:PoisonNova(altar_loc, altar_entity, 2.5, 1, 300, 19, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[27] = true
		end

		if self.boss_timer > 94 and not self.events[28] then
			self:SpawnVileWard(altar_loc, altar_entity, 0.8, self.random_constants[2], 450, math.min(6 + 0.5 * power_stacks, 12), 150, math.min(20 + power_stacks * 5, 80), 10, 10, 4, 8, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[28] = true
		end

		if self.boss_timer > 95 and not self.events[29] then
			self:SpawnVileWard(altar_loc, altar_entity, 0.8, self.random_constants[2] + 180, 450, math.min(6 + 0.5 * power_stacks, 12), 150, math.min(20 + power_stacks * 5, 80), 10, 10, 4, 8, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[29] = true
		end

		if self.boss_timer > 96 and not self.events[30] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[30] = true
		end

		if self.boss_timer > 99 and not self.events[31] then
			self:Parasite(altar_loc, altar_entity, 1.5, 2, 3.0, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[31] = true
		end

		if self.boss_timer > 101 and not self.events[32] then
			self:VenomousGale(altar_loc, altar_entity, 2.5, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[32] = true
		end

		if self.boss_timer > 104 and not self.events[33] then
			self:GreenDeath(altar_loc, altar_entity, 3.5, 15, 5.0, RandomInt(1, 360), 80, 4.0, 2000, 125, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[33] = true
		end

		-- Enrage
		if self.boss_timer > 113 and not self.events[34] then
			self:PoisonNova(altar_loc, altar_entity, 7.0, 10, 900, 100, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
			self.events[34] = true
		end
	end
end

---------------------------
-- Veno's moves
---------------------------

-- Venomous Gale
function boss_thinker_nevermore:VenomousGale(center_point, altar_handle, delay, angle, radius, slow, damage, duration, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ability = boss:FindAbilityByName("frostivus_boss_venomous_gale")
		local move_position = RotatePosition(center_point, QAngle(0, angle, 0), center_point + Vector(0, 1, 0) * 850)
		local dot_damage = boss:GetAttackDamage() * damage * 0.01

		-- Look for a valid target
		local target = false
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_fighting_boss") then
				target = enemy
				break
			end
		end

		-- If there's no valid target, do nothing
		if not target then
			return nil
		end

		-- Send cast bar event
		BossPhaseAbilityCast(self.team, "venomancer_venomous_gale", "boss_veno_venomous_gale", delay)

		-- Draw warning particle over the target's head
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_veno/veno_gale_warning.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		ParticleManager:SetParticleControl(warning_pfx, 0, target:GetAbsOrigin())

		-- Play warning sound
		target:EmitSound("Frostivus.AbilityWarning")

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(move_position)
		local target_loc
		Timers:CreateTimer(delay - 1.0, function()

			-- Finalize boss facing and destroy overhead warning particle
			target_loc = target:GetAbsOrigin()
			boss:FaceTowards(boss:GetAbsOrigin() + (target_loc - boss:GetAbsOrigin()):Normalized())
			ParticleManager:DestroyParticle(warning_pfx, true)
			ParticleManager:ReleaseParticleIndex(warning_pfx)

			-- Draw fixed warning particle on the ground
			warning_pfx = ParticleManager:CreateParticle("particles/boss_veno/veno_gale_warning_end.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(warning_pfx, 0, target_loc + Vector(0, 0, 250))

			-- Destroy warning particle
			Timers:CreateTimer(2.5, function()
				ParticleManager:DestroyParticle(warning_pfx, true)
				ParticleManager:ReleaseParticleIndex(warning_pfx)
			end)

			-- Animate cast point
			Timers:CreateTimer(0.6, function()
				StartAnimation(boss, {duration = 0.57, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})
			end)
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Play cast sound
			boss:EmitSound("Hero_Venomancer.VenomousGale")

			-- Shoot projectile
			self:VenomousGaleShoot(boss, boss, ability, boss:GetAbsOrigin(), target_loc, radius, slow, dot_damage, duration)
		end)
	end
end

function boss_thinker_nevermore:VenomousGaleShoot(boss, caster, ability, source, target, radius, slow, damage, duration)
	if IsServer() then

		-- Draw mouth particle
		local mouth_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_venomous_gale_mouth.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
		local projectile_particle = "particles/boss_veno/venomous_gale.vpcf"
		if caster:HasModifier("modifier_frostivus_boss") then
			ParticleManager:SetParticleControlEnt(mouth_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_mouth", caster:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(mouth_pfx)
		else
			ParticleManager:SetParticleControlEnt(mouth_pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(mouth_pfx)
			projectile_particle = "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf"
		end

		-- Projectile geometry
		local direction = (target - source):Normalized()
		local speed = ability:GetSpecialValueFor("projectile_speed")

		-- Launch projectile
		local projectile =	{
			Ability				= ability,
			EffectName			= projectile_particle,
			vSpawnOrigin		= source,
			fDistance			= 1800,
			fStartRadius		= radius,
			fEndRadius			= radius,
			Source				= boss,
			bHasFrontalCone		= false,
			bReplaceExisting	= false,
			iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
			iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
			iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
			fExpireTime 		= GameRules:GetGameTime() + 10.0,
			bDeleteOnHit		= false,
			vVelocity			= Vector(direction.x,direction.y,0) * speed,
			bProvidesVision		= false,
			ExtraData			= {slow = slow, damage = damage, duration = duration}
		}
		ProjectileManager:CreateLinearProjectile(projectile)
	end
end

-- Venomous Gale debuff modifier
LinkLuaModifier("modifier_frostivus_venomancer_venomous_gale", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_venomous_gale = modifier_frostivus_venomancer_venomous_gale or class({})

function modifier_frostivus_venomancer_venomous_gale:IsHidden() return false end
function modifier_frostivus_venomancer_venomous_gale:IsPurgable() return false end
function modifier_frostivus_venomancer_venomous_gale:IsDebuff() return true end

function modifier_frostivus_venomancer_venomous_gale:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.slow = 0
		self.damage = 0
		if keys.slow then
			self.slow = keys.slow
		end
		if keys.damage then
			self.damage = keys.damage
		end

		-- Client slow amount visibility
		self:SetStackCount(self.slow)

		-- Start thinking
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_venomancer_venomous_gale:OnIntervalThink()
	if IsServer() then

		-- Deal periodic damage
		local owner = self:GetParent()
		local caster = self:GetCaster()
		if owner and caster then
			local damage_dealt = ApplyDamage({victim = owner, attacker = caster, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, owner, damage_dealt, nil)
		end
	end
end

function modifier_frostivus_venomancer_venomous_gale:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_venomancer_venomous_gale:GetModifierMoveSpeedBonus_Percentage()
	return (-1) * self:GetStackCount()
end



-- Spawn Scourge Ward
function boss_thinker_nevermore:SpawnScourgeWard(center_point, altar_handle, delay, angle, center_distance, health, radius, slow, damage, duration, attack_delay, attack_count, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ward_position = RotatePosition(center_point, QAngle(0, angle, 0), center_point + Vector(0, 1, 0) * center_distance)
		local ward_health = boss:GetMaxHealth() * health * 0.01
		local dot_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		BossPhaseAbilityCast(self.team, "venomancer_plague_ward", "boss_veno_scourge_ward", delay)

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(center_point + Vector(0, 300, 0))
		Timers:CreateTimer(delay - 0.4, function()
			boss:FaceTowards(ward_position)
			StartAnimation(boss, {duration = 0.63, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Spawn ward
			local scourge_ward = CreateUnitByName("npc_frostivus_scourge_ward", ward_position, true, boss, boss, DOTA_TEAM_NEUTRALS)
			scourge_ward:AddNewModifier(nil, nil, "modifier_frostivus_boss_add", {})

			-- Adjust ward health
			scourge_ward:SetBaseMaxHealth(ward_health)
			scourge_ward:SetMaxHealth(ward_health)
			scourge_ward:SetHealth(ward_health)

			-- Add ward passive modifiers
			scourge_ward:AddNewModifier(nil, nil, "modifier_frostivus_venomancer_scourge_ward_thinker", {angle = angle, radius = radius, slow = slow, damage = dot_damage, debuff_duration = duration, attack_delay = attack_delay, attack_count = attack_count})

			-- Play ward spawn sound
			scourge_ward:EmitSound("Hero_Viper.Nethertoxin.Cast")

			-- Make ward face spit direction
			local target_direction = (center_point - ward_position):Normalized()
			scourge_ward:FaceTowards(center_point + target_direction)
		end)
	end
end

-- Scourge Ward Thinker
LinkLuaModifier("modifier_frostivus_venomancer_scourge_ward_thinker", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_scourge_ward_thinker = modifier_frostivus_venomancer_scourge_ward_thinker or class({})

function modifier_frostivus_venomancer_scourge_ward_thinker:IsHidden() return true end
function modifier_frostivus_venomancer_scourge_ward_thinker:IsPurgable() return false end
function modifier_frostivus_venomancer_scourge_ward_thinker:IsDebuff() return false end

function modifier_frostivus_venomancer_scourge_ward_thinker:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.angle = 0
		self.radius = 0
		self.slow = 0
		self.damage = 0
		self.debuff_duration = 0
		self.attack_delay = 1
		self.attack_count = 1
		if keys.angle then
			self.angle = keys.angle
		end
		if keys.radius then
			self.radius = keys.radius
		end
		if keys.slow then
			self.slow = keys.slow
		end
		if keys.damage then
			self.damage = keys.damage
		end
		if keys.debuff_duration then
			self.debuff_duration = keys.debuff_duration
		end
		if keys.attack_delay then
			self.attack_delay = keys.attack_delay
		end
		if keys.attack_count then
			self.attack_count = keys.attack_count
		end

		-- Animate the ward
		StartAnimation(self:GetParent(), {duration = self.attack_delay, activity=ACT_DOTA_IDLE, rate=1.0})

		-- Start thinking
		self:StartIntervalThink(self.attack_delay)
	end
end

function modifier_frostivus_venomancer_scourge_ward_thinker:OnIntervalThink()
	if IsServer() then

		-- Parameters
		local owner = self:GetParent()
		local boss = owner:GetOwner()
		local ability = boss:FindAbilityByName("frostivus_boss_venomous_gale")
		local source_loc = owner:GetAbsOrigin()
		local modifier_gale = boss:FindModifierByName("boss_thinker_nevermore")

		-- Calculate launch geometry
		local main_direction = RotatePosition(source_loc, QAngle(0, self.angle + 180, 0), source_loc + Vector(0, 1, 0) * 100)
		main_direction = (main_direction - source_loc):Normalized()
		local directions = {}
		local half_amount = ( self.attack_count - 1 ) * 0.5
		local start_amount = ( -1 ) * half_amount
		local end_amount = half_amount
		local angle_step = 0
		if self.attack_count > 1 then
			angle_step = 115 / (self.attack_count - 1)
		end
		for i = start_amount, end_amount do
			directions[i] = RotatePosition(source_loc, QAngle(0, angle_step * i, 0), source_loc + main_direction * 100)
		end

		-- Start animating the cast
		StartAnimation(owner, {duration = 1.0, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})

		-- Wait for the cast point
		Timers:CreateTimer(0.3, function()

			-- Play cast sound
			owner:EmitSound("Hero_Venomancer.VenomousGale")

			-- Launch projectiles
			for _, direction in pairs(directions) do
				modifier_gale:VenomousGaleShoot(boss, owner, ability, source_loc, direction, self.radius, self.slow, self.damage, self.debuff_duration)
			end

			-- Resume ward idle animation after attack backswing
			Timers:CreateTimer(0.7, function()
				StartAnimation(owner, {duration = self.attack_delay, activity=ACT_DOTA_IDLE, rate=1.0})
			end)
		end)
	end
end



-- Spawn Vile Ward
function boss_thinker_nevermore:SpawnVileWard(center_point, altar_handle, delay, angle, center_distance, health, radius, slow, damage, duration, attack_delay, attack_count, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ward_position = RotatePosition(center_point, QAngle(0, angle, 0), center_point + Vector(0, 1, 0) * center_distance)
		local ward_health = boss:GetMaxHealth() * health * 0.01
		local dot_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		BossPhaseAbilityCast(self.team, "greevil_miniboss_green_living_armor", "boss_veno_vile_ward", delay)

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(center_point + Vector(0, 300, 0))
		Timers:CreateTimer(delay - 0.4, function()
			boss:FaceTowards(ward_position)
			StartAnimation(boss, {duration = 0.63, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Spawn ward
			local vile_ward = CreateUnitByName("npc_frostivus_vile_ward", ward_position, true, boss, boss, DOTA_TEAM_NEUTRALS)
			vile_ward:AddNewModifier(nil, nil, "modifier_frostivus_boss_add", {})

			-- Adjust ward health
			vile_ward:SetBaseMaxHealth(ward_health)
			vile_ward:SetMaxHealth(ward_health)
			vile_ward:SetHealth(ward_health)

			-- Add ward passive modifiers
			vile_ward:AddNewModifier(nil, nil, "modifier_frostivus_venomancer_vile_ward_thinker", {radius = radius, slow = slow, damage = dot_damage, debuff_duration = duration, attack_delay = attack_delay, attack_count = attack_count})

			-- Play ward spawn sound
			vile_ward:EmitSound("Hero_Viper.Nethertoxin.Cast")
		end)
	end
end

-- Vile Ward Thinker
LinkLuaModifier("modifier_frostivus_venomancer_vile_ward_thinker", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_vile_ward_thinker = modifier_frostivus_venomancer_vile_ward_thinker or class({})

function modifier_frostivus_venomancer_vile_ward_thinker:IsHidden() return true end
function modifier_frostivus_venomancer_vile_ward_thinker:IsPurgable() return false end
function modifier_frostivus_venomancer_vile_ward_thinker:IsDebuff() return false end

function modifier_frostivus_venomancer_vile_ward_thinker:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.radius = 0
		self.slow = 0
		self.damage = 0
		self.debuff_duration = 0
		self.attack_delay = 1
		self.attack_count = 4
		if keys.radius then
			self.radius = keys.radius
		end
		if keys.slow then
			self.slow = keys.slow
		end
		if keys.damage then
			self.damage = keys.damage
		end
		if keys.debuff_duration then
			self.debuff_duration = keys.debuff_duration
		end
		if keys.attack_delay then
			self.attack_delay = keys.attack_delay
		end
		if keys.attack_count then
			self.attack_count = keys.attack_count
		end

		-- Animate the ward
		StartAnimation(self:GetParent(), {duration = self.attack_delay, activity=ACT_DOTA_IDLE, rate=1.0})

		-- Start thinking
		self:StartIntervalThink(self.attack_delay)
	end
end

function modifier_frostivus_venomancer_vile_ward_thinker:OnIntervalThink()
	if IsServer() then

		-- Parameters
		local owner = self:GetParent()
		local boss = owner:GetOwner()
		local ability = boss:FindAbilityByName("frostivus_boss_venomous_gale")
		local source_loc = owner:GetAbsOrigin()
		local modifier_gale = boss:FindModifierByName("boss_thinker_nevermore")

		-- Calculate launch geometry
		local directions = {}
		local half_amount = ( self.attack_count - 1 ) * 0.5
		local start_amount = ( -1 ) * half_amount
		local end_amount = half_amount
		local angle_step = 360 / self.attack_count
		for i = 1, self.attack_count do
			directions[i] = RotatePosition(source_loc, QAngle(0, i * angle_step, 0), source_loc + Vector(0, 1, 0) * 100)
		end

		-- Start animating the cast
		StartAnimation(owner, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

		-- Wait for the cast point
		Timers:CreateTimer(0.3, function()

			-- Play cast sound
			owner:EmitSound("Hero_Venomancer.VenomousGale")

			-- Launch projectiles
			for _, direction in pairs(directions) do
				modifier_gale:VenomousGaleShoot(boss, owner, ability, source_loc, direction, self.radius, self.slow, self.damage, self.debuff_duration)
			end

			-- Resume ward idle animation after attack backswing
			Timers:CreateTimer(0.7, function()
				StartAnimation(owner, {duration = self.attack_delay, activity=ACT_DOTA_IDLE, rate=1.0})
			end)
		end)
	end
end



-- Poison Nova
function boss_thinker_nevermore:PoisonNova(center_point, altar_handle, delay, damage, damage_amp, duration, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ability = boss:FindAbilityByName("frostivus_boss_poison_nova")
		local dot_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		BossPhaseAbilityCast(self.team, "venomancer_poison_nova", "boss_veno_poison_nova", delay)

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(center_point + Vector(0, 300, 0))
		Timers:CreateTimer(delay - 0.4, function()
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 0.87, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Play cast sound
			boss:EmitSound("Hero_Venomancer.PoisonNova")

			-- Play particles
			local nova_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_poison_nova.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(nova_pfx, 0, center_point)
			ParticleManager:SetParticleControl(nova_pfx, 1, Vector(1100, 1, 900))
			ParticleManager:SetParticleControl(nova_pfx, 2, Vector(0, 0, 0))
			ParticleManager:ReleaseParticleIndex(nova_pfx)

			local nova_caster_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_poison_nova_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
			ParticleManager:SetParticleControl(nova_caster_pfx, 0, boss:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(nova_caster_pfx)

			-- Poison enemies
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 950, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do
				enemy:EmitSound("Hero_Venomancer.PoisonNovaImpact")
				enemy:AddNewModifier(boss, ability, "modifier_frostivus_venomancer_poison_nova", {damage = dot_damage, damage_amp = damage_amp, duration = duration})
			end
		end)
	end
end

-- Poison Nova debuff modifier
LinkLuaModifier("modifier_frostivus_venomancer_poison_nova", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_poison_nova = modifier_frostivus_venomancer_poison_nova or class({})

function modifier_frostivus_venomancer_poison_nova:IsHidden() return false end
function modifier_frostivus_venomancer_poison_nova:IsPurgable() return false end
function modifier_frostivus_venomancer_poison_nova:IsDebuff() return true end

function modifier_frostivus_venomancer_poison_nova:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff_nova.vpcf"
end

function modifier_frostivus_venomancer_poison_nova:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_frostivus_venomancer_poison_nova:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.damage = 0
		self.damage_amp = 0
		if keys.damage then
			self.damage = keys.damage
		end
		if keys.damage_amp then
			self.damage_amp = keys.damage_amp
		end

		-- Client amp amount visibility
		self:SetStackCount(self.damage_amp)

		-- Start thinking
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_venomancer_poison_nova:OnIntervalThink()
	if IsServer() then

		-- Deal periodic damage
		local owner = self:GetParent()
		local boss = self:GetCaster()
		if owner and boss then
			local damage_dealt = ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, owner, damage_dealt, nil)
		end
	end
end

function modifier_frostivus_venomancer_poison_nova:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_venomancer_poison_nova:GetModifierIncomingDamage_Percentage()
	return self:GetStackCount()
end



-- Unwilling Host
function boss_thinker_nevermore:UnwillingHost(center_point, altar_handle, delay, radius, duration, damage, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ability = boss:FindAbilityByName("frostivus_boss_unwilling_host")
		local dot_damage = boss:GetAttackDamage() * damage * 0.01

		-- Look for a valid target
		local target = false
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_fighting_boss") and not enemy:HasModifier("modifier_frostivus_venomancer_unwilling_host") then
				target = enemy
				break
			end
		end

		-- If there's no valid target, do nothing
		if not target then
			return nil
		end

		-- Send cast bar event
		BossPhaseAbilityCast(self.team, "treant_eyes_in_the_forest", "boss_veno_unwilling_host", delay)

		-- Animate cast
		Timers:CreateTimer(delay - 0.3, function()
			boss:FaceTowards(target:GetAbsOrigin())
			StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Play cast sound
			boss:EmitSound("Hero_Venomancer.Attack")

			-- Play the attack particle
			local attack_pfx = ParticleManager:CreateParticle("particles/boss_veno/poison_sting_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
			ParticleManager:SetParticleControlEnt(attack_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(attack_pfx, 9, boss, PATTACH_POINT_FOLLOW, "attach_mouth", boss:GetAbsOrigin(), true)
			ParticleManager:ReleaseParticleIndex(attack_pfx)

			-- Play impact sound
			target:EmitSound("Hero_Venomancer.ProjectileImpact")

			-- Apply debuff to the target
			target:AddNewModifier(boss, ability, "modifier_frostivus_venomancer_unwilling_host", {damage = dot_damage, radius = radius, duration = duration})
		end)
	end
end

-- Unwilling Host debuff
LinkLuaModifier("modifier_frostivus_venomancer_unwilling_host", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_unwilling_host = modifier_frostivus_venomancer_unwilling_host or class({})

function modifier_frostivus_venomancer_unwilling_host:IsHidden() return false end
function modifier_frostivus_venomancer_unwilling_host:IsPurgable() return false end
function modifier_frostivus_venomancer_unwilling_host:IsDebuff() return true end

function modifier_frostivus_venomancer_unwilling_host:GetEffectName()
	return "particles/boss_veno/unwilling_host_debuff.vpcf"
end

function modifier_frostivus_venomancer_unwilling_host:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_frostivus_venomancer_unwilling_host:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.damage = 0
		self.radius = 0
		self.duration = 0
		if keys.damage then
			self.damage = keys.damage
		end
		if keys.radius then
			self.radius = keys.radius
		end
		if keys.duration then
			self.duration = keys.duration
		end

		-- Start thinking
		self:StartIntervalThink(0.03)
	end
end

function modifier_frostivus_venomancer_unwilling_host:OnIntervalThink()
	if IsServer() then

		-- Spread the virulent plague debuff to any nearby allies
		local owner = self:GetParent()
		local boss = self:GetCaster()
		local ability = self:GetAbility()
		local nearby_allies = FindUnitsInRadius(owner:GetTeam(), owner:GetAbsOrigin(), nil, self.radius, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _, ally in pairs(nearby_allies) do
			if ally ~= owner then
				ally:AddNewModifier(boss, ability, "modifier_frostivus_venomancer_virulent_plague", {damage = self.damage, duration = self:GetDuration()})
			end
		end
	end
end

-- Virulent Plague debuff
LinkLuaModifier("modifier_frostivus_venomancer_virulent_plague", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_virulent_plague = modifier_frostivus_venomancer_virulent_plague or class({})

function modifier_frostivus_venomancer_virulent_plague:IsHidden() return false end
function modifier_frostivus_venomancer_virulent_plague:IsPurgable() return false end
function modifier_frostivus_venomancer_virulent_plague:IsDebuff() return true end

function modifier_frostivus_venomancer_virulent_plague:GetTexture()
	return "custom/virulent_plague"
end

function modifier_frostivus_venomancer_virulent_plague:GetStatusEffectName()
	return "particles/status_fx/status_effect_poison_venomancer.vpcf"
end

function modifier_frostivus_venomancer_virulent_plague:StatusEffectPriority()
	return 10
end

function modifier_frostivus_venomancer_virulent_plague:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.damage = 0
		if keys.damage then
			self.damage = keys.damage
		end

		-- Play initial contagion animation
		local owner = self:GetParent()
		local contagion_pfx = ParticleManager:CreateParticle("particles/boss_veno/virulent_plague_contagion.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
		ParticleManager:SetParticleControl(contagion_pfx, 0, owner:GetAbsOrigin())
		ParticleManager:ReleaseParticleIndex(contagion_pfx)

		-- Play contagion sound
		owner:EmitSound("Hero_Venomancer.PoisonNovaImpact")

		-- Start thinking
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_venomancer_virulent_plague:OnIntervalThink()
	if IsServer() then

		-- Deal periodic damage
		local owner = self:GetParent()
		local boss = self:GetCaster()
		if owner and boss then
			local damage_dealt = ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, owner, damage_dealt, nil)
		end
	end
end

function modifier_frostivus_venomancer_virulent_plague:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_venomancer_virulent_plague:GetModifierMoveSpeedBonus_Percentage()
	return -15
end



-- Parasite
function boss_thinker_nevermore:Parasite(center_point, altar_handle, delay, amount, duration, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()

		-- Look for valid targets
		local targets_found = 0
		local targets = {}
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_fighting_boss") and not enemy:HasModifier("modifier_frostivus_venomancer_parasite") then
				targets_found = targets_found + 1
				targets[#targets+1] = enemy
				if targets_found >= amount then
					break
				end
			end
		end

		-- If there's no valid target, do nothing
		if targets_found <= 0 then
			return nil
		end

		-- Send cast bar event
		BossPhaseAbilityCast(self.team, "windrunner_windrun", "boss_veno_parasite", delay)

		-- Play warning particles and sounds
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_veno/veno_parasite_warning.vpcf", PATTACH_OVERHEAD_FOLLOW, targets[1])
		ParticleManager:SetParticleControl(warning_pfx, 0, targets[1]:GetAbsOrigin())
		targets[1]:EmitSound("Frostivus.AbilityWarning")
		local warning_pfx_2 = false
		if targets[2] then
			warning_pfx_2 = ParticleManager:CreateParticle("particles/boss_veno/veno_parasite_warning_b.vpcf", PATTACH_OVERHEAD_FOLLOW, targets[2])
			ParticleManager:SetParticleControl(warning_pfx_2, 0, targets[2]:GetAbsOrigin())
			targets[2]:EmitSound("Frostivus.AbilityWarning")
		end

		-- Animate cast
		Timers:CreateTimer(delay - 1.1, function()
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 2.8, activity=ACT_DOTA_IDLE_RARE, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Destroy warning particles
			Timers:CreateTimer(duration, function()
				ParticleManager:DestroyParticle(warning_pfx, true)
				ParticleManager:ReleaseParticleIndex(warning_pfx)
				if warning_pfx_2 then
					ParticleManager:DestroyParticle(warning_pfx_2, true)
					ParticleManager:ReleaseParticleIndex(warning_pfx_2)
				end
			end)

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Affect targeted enemies
			for _, target in pairs(targets) do

				-- Apply movement-lock debuff
				target:AddNewModifier(nil, nil, "modifier_frostivus_venomancer_parasite", {duration = duration})

				-- Forced movement
				target:MoveToPosition(center_point + (center_point - target:GetAbsOrigin()):Normalized() * 900)

				-- Play hit particle/sound
				target:EmitSound("Frostivus.ParasiteImpact")
				local contagion_pfx = ParticleManager:CreateParticle("particles/boss_veno/virulent_plague_contagion.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControl(contagion_pfx, 0, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(contagion_pfx)
			end
		end)
	end
end

-- Parasite debuff
LinkLuaModifier("modifier_frostivus_venomancer_parasite", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_parasite = modifier_frostivus_venomancer_parasite or class({})

function modifier_frostivus_venomancer_parasite:IsHidden() return true end
function modifier_frostivus_venomancer_parasite:IsPurgable() return false end
function modifier_frostivus_venomancer_parasite:IsDebuff() return true end

function modifier_frostivus_venomancer_parasite:CheckState()
	local state =	{
		[MODIFIER_STATE_COMMAND_RESTRICTED] = true
	}
	return state
end

-- Green Death
function boss_thinker_nevermore:GreenDeath(center_point, altar_handle, delay, damage, duration, angle, spawn_angle, spawn_frequency, projectile_speed, projectile_radius, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ability = boss:FindAbilityByName("frostivus_boss_green_death")
		local center_position = RotatePosition(center_point, QAngle(0, angle + 180, 0), center_point + Vector(0, 1, 0) * 900)
		local impact_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		BossPhaseAbilityCast(self.team, "windrunner_focusfire", "boss_veno_green_death", delay)

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(center_point)
		Timers:CreateTimer(1.0, function()
			boss:FaceTowards(center_position)
			StartAnimation(boss, {duration = duration + delay - 1.0, activity=ACT_DOTA_FLAIL, rate=1.0})
			Timers:CreateTimer(1.0, function()
				boss:EmitSound("Frostivus.GreenDeathCharge")
			end)
		end)

		-- Calculate projectile stuff
		local projectile_direction = (RotatePosition(center_point, QAngle(0, angle + 180, 0), center_point + Vector(0, 1, 0) * 900) - center_point):Normalized() * projectile_speed
		local elapsed_time = 0
		local spawn_interval = 1 / spawn_frequency
		local spawn_positions = {}
		for i = 1, 21 do
			spawn_positions[i] = RotatePosition(center_point, QAngle(0, angle + spawn_angle * (-0.5 + (i - 1) * 0.05) , 0), center_point + Vector(0, 1, 0) * 950)
		end

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Basic projectile data
			local green_death_projectile =	{
				Ability				= ability,
				EffectName			= "particles/boss_veno/veno_green_death.vpcf",
				vSpawnOrigin		= spawn_positions[1],
				fDistance			= 1800,
				fStartRadius		= projectile_radius,
				fEndRadius			= projectile_radius,
				Source				= boss,
				bHasFrontalCone		= false,
				bReplaceExisting	= false,
				iUnitTargetTeam		= DOTA_UNIT_TARGET_TEAM_ENEMY,
				iUnitTargetFlags	= DOTA_UNIT_TARGET_FLAG_NONE,
				iUnitTargetType		= DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC,
				fExpireTime 		= GameRules:GetGameTime() + 10.0,
				bDeleteOnHit		= false,
				vVelocity			= Vector(projectile_direction.x, projectile_direction.y, 0),
				bProvidesVision		= false,
				ExtraData			= {damage = impact_damage}
			}

			-- Projectile launch loop
			local switch = true
			local set_a = {1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21}
			local set_b = {2, 4, 6, 8, 10, 12, 14, 16, 18, 20}
			Timers:CreateTimer(0, function()

				-- Launch projectile from spawn points
				if switch then
					for _, n in pairs(set_a) do
						green_death_projectile.vSpawnOrigin = spawn_positions[n]
						ProjectileManager:CreateLinearProjectile(green_death_projectile)
					end
				else
					for _, n in pairs(set_b) do
						green_death_projectile.vSpawnOrigin = spawn_positions[n]
						ProjectileManager:CreateLinearProjectile(green_death_projectile)
					end
				end

				-- Spawn sound
				boss:EmitSound("Frostivus.GreenDeathLaunch")

				-- Switch the switch
				if switch then
					switch = false
				else
					switch = true
				end

				-- Check if the duration is over
				elapsed_time = elapsed_time + spawn_interval
				if elapsed_time < duration and boss:IsAlive() then
					return spawn_interval
				end
			end)
		end)
	end
end



-- Spawn Plague Ward passive
function boss_thinker_nevermore:SpawnPlagueWard(center_point, altar_handle, inner_radius, outer_radius, health, damage, attack_delay, duration)
	if IsServer() then
		local boss = self:GetParent()
		local sting_damage = boss:GetAttackDamage() * damage * 0.01
		local ward_position = center_point + RandomVector(100):Normalized() * RandomInt(inner_radius, outer_radius)
		local ward_health = boss:GetMaxHealth() * health * 0.01

		-- Spawn ward
		local plague_ward = CreateUnitByName("npc_frostivus_plague_ward", ward_position, true, boss, boss, DOTA_TEAM_NEUTRALS)
		plague_ward:AddNewModifier(nil, nil, "modifier_frostivus_boss_add", {})

		-- Adjust ward health
		plague_ward:SetBaseMaxHealth(ward_health)
		plague_ward:SetMaxHealth(ward_health)
		plague_ward:SetHealth(ward_health)

		-- Add ward passive modifiers
		plague_ward:AddNewModifier(nil, nil, "modifier_frostivus_venomancer_ward_poison_sting", {damage = sting_damage, attack_delay = attack_delay, debuff_duration = duration, center_x = center_point.x, center_y = center_point.y, center_z = center_point.z})

		-- Play ward spawn sound
		plague_ward:EmitSound("Hero_Venomancer.Plague_Ward")
	end
end

-- Poison Sting cast modifier
LinkLuaModifier("modifier_frostivus_venomancer_ward_poison_sting", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_ward_poison_sting = modifier_frostivus_venomancer_ward_poison_sting or class({})

function modifier_frostivus_venomancer_ward_poison_sting:IsHidden() return true end
function modifier_frostivus_venomancer_ward_poison_sting:IsPurgable() return false end
function modifier_frostivus_venomancer_ward_poison_sting:IsDebuff() return false end

function modifier_frostivus_venomancer_ward_poison_sting:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.damage = 0
		self.attack_delay = 1.0
		self.center_point = Vector(0, 0, 0)
		self.debuff_duration = 1.0
		if keys.damage then
			self.damage = keys.damage
		end
		if keys.attack_delay then
			self.attack_delay = keys.attack_delay
		end
		if keys.center_x then
			self.center_point = Vector(keys.center_x, keys.center_y, keys.center_z)
		end
		if keys.debuff_duration then
			self.debuff_duration = keys.debuff_duration
		end

		-- Animate the ward
		StartAnimation(self:GetParent(), {duration = self.attack_delay, activity=ACT_DOTA_IDLE, rate=1.0})

		-- Start thinking
		self:StartIntervalThink(self.attack_delay)
	end
end

function modifier_frostivus_venomancer_ward_poison_sting:OnIntervalThink()
	if IsServer() then

		-- Search for valid attack targets
		local owner = self:GetParent()
		local owner_loc = owner:GetAbsOrigin()
		local nearby_enemies = FindUnitsInRadius(owner:GetTeam(), self.center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		
		-- Spit poison on the first available enemy, if there is one
		for _, enemy in pairs(nearby_enemies) do

			-- Face target
			local target_direction = (enemy:GetAbsOrigin() - owner_loc):Normalized()
			owner:FaceTowards(owner_loc + target_direction)

			-- Start animating the attack
			StartAnimation(owner, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

			-- Wait for the attack point
			Timers:CreateTimer(0.3, function()

				-- Play the attack sounds
				owner:EmitSound("Hero_VenomancerWard.Attack")
				enemy:EmitSound("Hero_VenomancerWard.ProjectileImpact")

				-- Play the attack particle
				local attack_pfx = ParticleManager:CreateParticle("particles/boss_veno/poison_sting_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
				ParticleManager:SetParticleControlEnt(attack_pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(attack_pfx, 9, owner, PATTACH_POINT_FOLLOW, "attach_attack1", owner:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(attack_pfx)

				-- Apply the poison sting modifier
				enemy:AddNewModifier(nil, nil, "modifier_frostivus_venomancer_poison_sting_debuff", {damage = self.damage, ward_caster = owner:GetEntityIndex(), duration = self.debuff_duration})

				-- Resume ward idle animation after attack backswing
				Timers:CreateTimer(0.7, function()
					StartAnimation(owner, {duration = self.attack_delay, activity=ACT_DOTA_IDLE, rate=1.0})
				end)
			end)
			break
		end
	end
end

-- Poison Sting debuff modifier
LinkLuaModifier("modifier_frostivus_venomancer_poison_sting_debuff", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_poison_sting_debuff = modifier_frostivus_venomancer_poison_sting_debuff or class({})

function modifier_frostivus_venomancer_poison_sting_debuff:IsHidden() return false end
function modifier_frostivus_venomancer_poison_sting_debuff:IsPurgable() return false end
function modifier_frostivus_venomancer_poison_sting_debuff:IsDebuff() return true end
function modifier_frostivus_venomancer_poison_sting_debuff:GetAttributes()
	return {
		MODIFIER_ATTRIBUTE_MULTIPLE
	}
end

function modifier_frostivus_venomancer_poison_sting_debuff:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.damage = 0
		self.ward_caster = 0
		if keys.damage then
			self.damage = keys.damage
		end
		if keys.ward_caster then
			self.ward_caster = keys.ward_caster
		end

		-- Start thinking
		self:StartIntervalThink(1.0)
	end
end

function modifier_frostivus_venomancer_poison_sting_debuff:OnIntervalThink()
	if IsServer() then

		-- Deal periodic damage
		local owner = self:GetParent()
		local caster = EntIndexToHScript(self.ward_caster)
		if caster then
			local boss = caster:GetOwner()
			local damage_dealt = ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, owner, damage_dealt, nil)
		end
	end
end

function modifier_frostivus_venomancer_poison_sting_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_venomancer_poison_sting_debuff:GetModifierMoveSpeedBonus_Percentage()
	return (-5)
end