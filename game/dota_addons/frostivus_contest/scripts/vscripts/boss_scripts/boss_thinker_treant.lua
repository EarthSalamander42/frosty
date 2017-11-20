-- Venomancer AI thinker

boss_thinker_treant = class({})

-----------------------------------------------------------------------

function boss_thinker_treant:IsHidden()
	return true
end

-----------------------------------------------------------------------

function boss_thinker_treant:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function boss_thinker_treant:OnCreated( params )
	if IsServer() then
		self.boss_name = "treant"
		self.team = "no team passed"
		self.altar_handle = "no altar handle passed"
		if params.team then
			self.team = params.team
		end
		if params.altar_handle then
			self.altar_handle = params.altar_handle
		end

		-- Boss script constants
		self.random_constants = {}

		-- Start thinking
		self.boss_timer = 0
		self.events = {}
		self:StartIntervalThink(0.1)
	end
end

-----------------------------------------------------------------------

function boss_thinker_treant:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

-----------------------------------------------------------------------

function boss_thinker_treant:OnDeath(keys)
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
					local win_pfx = ParticleManager:CreateParticleForPlayer("particles/boss_treant/screen_treant_win.vpcf", PATTACH_EYES_FOLLOW, PlayerResource:GetSelectedHeroEntity(player_id), PlayerResource:GetPlayer(player_id))
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
			local greevil = SpawnGreevil(target_loc, 2, false, 50, 255, 50)
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
				boss = SpawnTreant(self.altar_handle)

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
			UnlockArena(self.altar_handle, true, self.team, "frostivus_altar_aura_treant")

			-- Delete the boss AI thinker modifier
			target:RemoveModifierByName("boss_thinker_treant")
		end
	end
end

-----------------------------------------------------------------------

function boss_thinker_treant:OnIntervalThink()
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
		if self.boss_timer > 1 and not self.events[1] then
			boss:MoveToPosition(altar_loc + Vector(0, 50, 0))
			self:EyesInTheForest(altar_loc, altar_entity, 0.5, {altar_loc + RandomVector(10):Normalized() * 600}, math.min(4 + power_stacks * 0.2, 6), true)
			self.events[1] = true
		end

		if self.boss_timer > 2 and not self.events[2] then
			boss:MoveToPosition(altar_loc + Vector(0, 50, 0))
			self:EyesInTheForest(altar_loc, altar_entity, 0.5, {altar_loc + RandomVector(10):Normalized() * 600}, math.min(4 + power_stacks * 0.2, 6), true)
			self.events[2] = true
		end

		if self.boss_timer > 3 and not self.events[3] then
			boss:MoveToPosition(altar_loc + RandomVector(10):Normalized() * 600)
			self:Overgrowth(altar_loc, altar_entity, 2.5, 400, 50, 4.0, true)
			self.events[3] = true
		end

		-- Repeat cycle above
		if self.boss_timer > 10 then
			self.events[1] = false
			self.events[2] = false
			self.events[3] = false
			self.events[4] = false
			self.boss_timer = self.boss_timer - 10
		end

		-------------------------------------

		if self.boss_timer > 80 and not self.events[1] then
			boss:MoveToPosition(altar_loc + Vector(0, 50, 0))
			self:RapidGrowth(altar_loc, altar_entity, 1.5, {altar_loc + RandomVector(10):Normalized() * RandomInt(300, 850)}, math.min(4 + power_stacks * 0.2, 6), true)
			self.events[1] = true
		end

		if self.boss_timer > 80 and not self.events[1] then
			boss:MoveToPosition(altar_loc + Vector(0, 50, 0))
			self:EyesInTheForest(altar_loc, altar_entity, 1.5, {altar_loc + RandomVector(10):Normalized() * RandomInt(300, 400)}, math.min(5 + power_stacks * 0.2, 8), true)
			self.events[1] = true
		end

		if self.boss_timer > 80 and not self.events[1] then
			boss:MoveToPosition(altar_loc + RandomVector(1):Normalized() * 800)
			self:VineSmash(altar_loc, altar_entity, 3.0, 1.5, 2, 150, 120, true)
			self.events[1] = true
		end

		if self.boss_timer > 80 and not self.events[1] then
			boss:MoveToPosition(altar_loc + RandomVector(1):Normalized() * 400)
			self:RingOfThorns(altar_loc, altar_entity, 2.5, 450, 120, true)
			self.events[1] = true
		end

		if self.boss_timer > 80 and not self.events[1] then
			boss:MoveToPosition(altar_loc + Vector(0, 50, 0))
			self:LeechSeed(altar_loc, altar_entity, 1.5, 25, math.min(1 + power_stacks * 0.1, 2), true)
			self.events[1] = true
		end

		if self.boss_timer > 80 and not self.events[1] then
			boss:MoveToPosition(altar_loc + Vector(0, 50, 0))
			self:LivingArmor(altar_loc, altar_entity, 1.5, 1, math.min(5 + power_stacks, 15), true)
			self.events[1] = true
		end
	end
end

---------------------------
-- Auxiliary stuff
---------------------------

-- Returns all treantlings
function boss_thinker_treant:GetRealTrees(center_point)
	local real_trees ={}
	local nearby_allies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, ally in pairs(nearby_allies) do
		if ally:HasModifier("modifier_frostivus_treantling_passive") then
			real_trees[#real_trees + 1] = ally
		end
	end
	return real_trees
end

-- Returns a random tree, or Treant if no fake trees are available
function boss_thinker_treant:PickRandomFakeTree(center_point)
	local fake_trees ={}
	local nearby_allies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
	for _, ally in pairs(nearby_allies) do
		if ally:HasModifier("modifier_frostivus_fake_tree_passive") then
			fake_trees[#fake_trees + 1] = ally
		end
	end

	if #fake_trees >= 1 then
		return fake_trees[RandomInt(1, #fake_trees)]
	else
		return self:GetParent()
	end
end

-- Spawns a fake tree
function boss_thinker_treant:SpawnFakeTree(location, health)
	if IsServer() then
		local boss = self:GetParent()
		local tree_health = boss:GetMaxHealth() * health * 0.01

		-- Spawn random type of tree
		local fake_tree = CreateUnitByName("npc_frostivus_treant_tree_0"..RandomInt(1, 4), location, true, boss, boss, DOTA_TEAM_NEUTRALS)
		fake_tree:AddNewModifier(nil, nil, "modifier_frostivus_boss_add", {})
		fake_tree:AddNewModifier(nil, nil, "modifier_frostivus_fake_tree_passive", {})

		-- Adjust tree health
		fake_tree:SetBaseMaxHealth(tree_health)
		fake_tree:SetMaxHealth(tree_health)
		fake_tree:SetHealth(tree_health)

		-- Play tree spawn sound
		fake_tree:EmitSound("Tree.GrowBack")
	end
end

-- Fake tree passive modifier
LinkLuaModifier("modifier_frostivus_fake_tree_passive", "boss_scripts/boss_thinker_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_fake_tree_passive = modifier_frostivus_fake_tree_passive or class({})

function modifier_frostivus_fake_tree_passive:IsHidden() return true end
function modifier_frostivus_fake_tree_passive:IsPurgable() return false end
function modifier_frostivus_fake_tree_passive:IsDebuff() return true end

-- Spawns a treantling
function boss_thinker_treant:SpawnTreantling(location, health, center_point)
	if IsServer() then
		local boss = self:GetParent()
		local treant_health = boss:GetMaxHealth() * health * 0.01

		-- Spawn random type of tree
		local treantling = CreateUnitByName("npc_frostivus_treantling", location, true, boss, boss, DOTA_TEAM_NEUTRALS)
		treantling:AddNewModifier(nil, nil, "modifier_frostivus_boss_add", {})
		treantling:AddNewModifier(nil, nil, "modifier_frostivus_treantling_passive", {})

		-- Adjust tree health
		treantling:SetBaseMaxHealth(treant_health)
		treantling:SetMaxHealth(treant_health)
		treantling:SetHealth(treant_health)

		-- Play tree spawn sound
		treantling:EmitSound("Hero_Furion.Sprout")

		-- Start an idle animation
		Timers:CreateTimer(1.0, function()
			boss:FaceTowards(center_point)
			StartAnimation(treantling, {duration = 30.0, activity=ACT_DOTA_IDLE, rate=1.0})
		end)
	end
end

-- Treantling passive modifier
LinkLuaModifier("modifier_frostivus_treantling_passive", "boss_scripts/boss_thinker_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_treantling_passive = modifier_frostivus_treantling_passive or class({})

function modifier_frostivus_treantling_passive:IsHidden() return true end
function modifier_frostivus_treantling_passive:IsPurgable() return false end
function modifier_frostivus_treantling_passive:IsDebuff() return true end

-- Make Treant invisible
function boss_thinker_treant:TreantInvisStart(boss)
end

-- Make Treant visible again
function boss_thinker_treant:TreantInvisEnd(boss)
end

-- Stack Leech Seed up
function boss_thinker_treant:LeechSeedStackUp(boss, enemy)
	if not enemy:HasModifier("modifier_frostivus_leech_seed_debuff") then
		enemy:AddNewModifier(boss, boss:FindAbilityByName("frostivus_boss_leech_seed"), "modifier_frostivus_leech_seed_debuff", {})
	end
	local seed_modifier = enemy:FindModifierByName("modifier_frostivus_leech_seed_debuff")
	seed_modifier:SetStackCount(seed_modifier:GetStackCount() + 1)
end

-- Leech Seed debuff
LinkLuaModifier("modifier_frostivus_leech_seed_debuff", "boss_scripts/boss_thinker_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_leech_seed_debuff = modifier_frostivus_leech_seed_debuff or class({})

function modifier_frostivus_leech_seed_debuff:IsHidden() return false end
function modifier_frostivus_leech_seed_debuff:IsPurgable() return false end
function modifier_frostivus_leech_seed_debuff:IsDebuff() return true end

function modifier_frostivus_leech_seed_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_leech_seed_debuff:GetModifierMoveSpeedBonus_Percentage()
	return (-5) * self:GetStackCount()
end



---------------------------
-- Treant's moves
---------------------------

-- Vine Smash
function boss_thinker_treant:VineSmash(center_point, altar_handle, delay, fixate_delay, target_amount, radius, damage, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Look for valid targets
		local targets = {}
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_fighting_boss") then
				targets[#targets + 1] = enemy
				if #targets >= target_amount then
					break
				end
			end
		end

		-- If there's no valid target, do nothing
		if #targets <= 0 then
			return nil
		end

		-- Calculate medium cast location (to look at)
		local cast_position = center_point
		for _, target in pairs(targets) do
			local distance = target:GetAbsOrigin() - center_point
			cast_position = cast_position + distance:Normalized() * distance:Length2D() / #targets
		end

		-- Send cast bar event
		if send_cast_bar then
			BossPhaseAbilityCast(self.team, "treant_overgrowth", "boss_treant_vine_smash", delay)
		end

		-- Draw warning particle on the targets' position
		for _, target in pairs(targets) do
			local warning_pfx = ParticleManager:CreateParticle("particles/boss_treant/vine_smash_pre_warning.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
			ParticleManager:SetParticleControl(warning_pfx, 0, target:GetAbsOrigin())

			-- Play warning sound
			target:EmitSound("Frostivus.AbilityWarning")

			Timers:CreateTimer(fixate_delay, function()
				ParticleManager:DestroyParticle(warning_pfx, true)
				ParticleManager:ReleaseParticleIndex(warning_pfx)
			end)
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.5, function()

			-- Decide on the source
			local main_source = self:PickRandomFakeTree(center_point)
			FindClearSpaceForUnit(boss, main_source:GetAbsOrigin(), true)

			-- Boss animation
			self:TreantInvisEnd(boss)
			boss:FaceTowards(cast_position)
			StartAnimation(boss, {duration = 0.9, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
		end)

		-- Animate treantlings
		Timers:CreateTimer(delay - 0.467, function()

			-- Treantlings animation
			for _, treantling in pairs(self:GetRealTrees(center_point)) do
				treantling:FaceTowards(cast_position)
				StartAnimation(treantling, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

				-- Resume idle animation after cast
				Timers:CreateTimer(1.5, function()
					StartAnimation(treantling, {duration = 30.0, activity=ACT_DOTA_IDLE, rate=1.0})
				end)
			end
		end)

		-- Locked-on particle
		local target_locs = {}
		Timers:CreateTimer(fixate_delay, function()
			for _, target in pairs(targets) do
				local warning_pfx = ParticleManager:CreateParticle("particles/boss_treant/vine_smash_pre_warning.vpcf", PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(warning_pfx, 0, target:GetAbsOrigin())

				Timers:CreateTimer(delay - fixate_delay, function()
					ParticleManager:DestroyParticle(warning_pfx, true)
					ParticleManager:ReleaseParticleIndex(warning_pfx)
				end)
				target_locs[#target_locs + 1] = target:GetAbsOrigin()
			end
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Play cast sound
			altar_handle:EmitSound("Hero_Furion.ForceOfNature")

			-- Shoot vines
			for _, target_loc in pairs(target_locs) do
				self:ShootVineSmash(altar_handle, boss, boss, target_loc, radius, hit_damage)
				for _, source in pairs(self:GetRealTrees(center_point)) do
					self:ShootVineSmash(altar_handle, source, boss, target_loc, radius, hit_damage)
				end
			end
		end)
	end
end

function boss_thinker_treant:ShootVineSmash(altar_handle, source, boss, target_loc, radius, damage)
	local source_loc = source:GetAbsOrigin()
	local forward_direction = (target_loc - source_loc):Normalized()
	local spawn_count = math.ceil(radius * 0.02)
	local spawn_limit = (-0.5) * (spawn_count - 1)

	-- Calculate spawn locations
	local spawn_locations = {}
	for i = spawn_limit, (-spawn_limit) do
		spawn_locations[i] = RotatePosition(source_loc, QAngle(0, 90, 0), source_loc + forward_direction * 100 * i)
	end

	-- VINE SMASH!
	altar_handle:EmitSound("Frostivus.TreantVineSmashTravel")
	for current_tick = 0, 18 do
		for _,spawn_loc in pairs(spawn_locations) do
			local current_loc = spawn_loc + current_tick * forward_direction * 100
			local vine_pfx = ParticleManager:CreateParticle("particles/boss_treant/vine_smash_vines.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(vine_pfx, 0, current_loc)
			ParticleManager:ReleaseParticleIndex(vine_pfx)

			-- Damage nearby enemies
			local nearby_enemies = FindUnitsInRadius(source:GetTeam(), current_loc, nil, 100, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do
				if not enemy:HasModifier("modifier_vine_smash_damage_dummy") then
					self:LeechSeedStackUp(boss, enemy)
					local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
					enemy:EmitSound("Hero_Treant.Overgrowth.Target")
					enemy:AddNewModifier(nil, nil, "modifier_vine_smash_damage_dummy", {duration = 0.1})
				end
			end
		end
	end
end

-- Vine Smash duplicate damage prevention modifier
LinkLuaModifier("modifier_vine_smash_damage_dummy", "boss_scripts/boss_thinker_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_vine_smash_damage_dummy = modifier_vine_smash_damage_dummy or class({})

function modifier_vine_smash_damage_dummy:IsHidden() return true end
function modifier_vine_smash_damage_dummy:IsPurgable() return false end
function modifier_vine_smash_damage_dummy:IsDebuff() return false end

-- Ring of Thorns
function boss_thinker_treant:RingOfThorns(center_point, altar_handle, delay, radius, damage, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		if send_cast_bar then
			BossPhaseAbilityCast(self.team, "treant_overgrowth", "boss_treant_ring_of_thorns", delay)
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.4, function()

			-- Decide on the source
			local main_source = self:PickRandomFakeTree(center_point)
			FindClearSpaceForUnit(boss, main_source:GetAbsOrigin(), true)

			-- Boss animation
			self:TreantInvisEnd(boss)
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 1.03, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.0})
		end)

		-- Animate treantlings
		Timers:CreateTimer(delay - 0.467, function()

			-- Treantlings animation
			for _, treantling in pairs(self:GetRealTrees(center_point)) do
				treantling:FaceTowards(center_point)
				StartAnimation(treantling, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

				-- Resume idle animation after cast
				Timers:CreateTimer(1.5, function()
					StartAnimation(treantling, {duration = 30.0, activity=ACT_DOTA_IDLE, rate=1.0})
				end)
			end
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Play cast sound
			altar_handle:EmitSound("Hero_Furion.ForceOfNature")

			-- Set up particle spawn grid
			local spawn_positions = {}
			local particle_radius = 80
			for x = (-900 + particle_radius), 900, (2 * particle_radius) do
				for y = (-900 + particle_radius), 900, (2 * particle_radius) do
					spawn_positions[#spawn_positions + 1] = center_point + Vector(x, y, 0)
				end
			end

			-- Draw particles in the grid, except in the safe zones
			for _, spawn_position in pairs(spawn_positions) do
				local should_draw = true
				if (boss:GetAbsOrigin() - spawn_position):Length2D() < (radius + particle_radius * 0.5) then
					should_draw = false
				end
				for _, treantling in pairs(self:GetRealTrees(center_point)) do
					if (treantling:GetAbsOrigin() - spawn_position):Length2D() < (radius + particle_radius * 0.5) then
						should_draw = false
						break
					end
				end
				if should_draw then
					local thorns_pfx = ParticleManager:CreateParticle("particles/boss_treant/ring_of_thorns.vpcf", PATTACH_WORLDORIGIN, nil)
					ParticleManager:SetParticleControl(thorns_pfx, 0, spawn_position)
					Timers:CreateTimer(2.5, function()
						ParticleManager:DestroyParticle(thorns_pfx, false)
						ParticleManager:ReleaseParticleIndex(thorns_pfx)
					end)
				end
			end

			-- Hit enemy heroes outside the safe areas
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				local should_be_hit = true
				local enemy_loc = enemy:GetAbsOrigin()
				if (boss:GetAbsOrigin() - enemy_loc):Length2D() < radius then
					should_be_hit = false
				end
				for _, treantling in pairs(self:GetRealTrees(center_point)) do
					if (treantling:GetAbsOrigin() - enemy_loc):Length2D() < radius then
						should_be_hit = false
						break
					end
				end
				if should_be_hit then
					self:LeechSeedStackUp(boss, enemy)
					local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = hit_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
					enemy:EmitSound("Hero_Treant.Overgrowth.Target")
				end
			end
		end)
	end
end

-- Leech Seed
function boss_thinker_treant:LeechSeed(center_point, altar_handle, delay, damage, heal, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()
		local leech_damage = boss:GetAttackDamage() * damage * 0.01

		-- Look for valid targets
		local targets = {}
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_frostivus_leech_seed_debuff") then
				targets[#targets + 1] = enemy
			end
		end

		-- Send cast bar event
		if send_cast_bar then
			BossPhaseAbilityCast(self.team, "treant_leech_seed", "boss_treant_leech_seed", delay)
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.5, function()

			-- Boss animation
			self:TreantInvisEnd(boss)
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 2.3, activity=ACT_DOTA_GENERIC_CHANNEL_1, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Define seed projectile
			local boss_loc = boss:GetAbsOrigin()
			local seed_projectile = {
				Target = boss,
			--	Source = ,
				Ability = boss:FindAbilityByName("frostivus_boss_leech_seed"),
				EffectName = "particles/units/heroes/hero_treant/treant_leech_seed_projectile.vpcf",
				iMoveSpeed = 400,
				bDrawsOnMinimap = false,
				bDodgeable = false,
				bIsAttack = false,
				bVisibleToEnemies = true,
				bReplaceExisting = false,
				flExpireTime = GameRules:GetGameTime() + 20,
				bProvidesVision = false,
				ExtraData = {heal = heal}
			}

			-- Play cast sound
			boss:EmitSound("Hero_Treant.LeechSeed.Cast")

			-- Iterate through seed-affected enemies
			for _, target in pairs(targets) do

				-- Play hit sound
				target:EmitSound("Hero_Treant.LeechSeed.Target")

				-- Play hit particle
				local seed_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_leech_seed.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControl(seed_pfx, 0, boss_loc)
				ParticleManager:SetParticleControl(seed_pfx, 1, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(seed_pfx)

				-- Launch projectiles periodically
				Timers:CreateTimer(0, function()

					-- Play leech sound
					target:EmitSound("Hero_Treant.LeechSeed.Tick")

					-- Adjust and launch projectile
					seed_projectile.Source = target
					ProjectileManager:CreateTrackingProjectile(seed_projectile)

					-- Deal damage
					local damage_dealt = ApplyDamage({victim = target, attacker = boss, ability = nil, damage = leech_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(target, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage_dealt, nil)

					-- Reduce Leech Seed stacks and check if the cycle is over
					local modifier_seed = target:FindModifierByName("modifier_frostivus_leech_seed_debuff")
					modifier_seed:SetStackCount(modifier_seed:GetStackCount() - 1 )

					if modifier_seed:GetStackCount() > 0 then
						return 0.75
					else
						target:RemoveModifierByName("modifier_frostivus_leech_seed_debuff")
					end
				end)
			end
		end)
	end
end

-- Rapid Growth
function boss_thinker_treant:RapidGrowth(center_point, altar_handle, delay, positions, health, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()

		-- Send cast bar event
		if send_cast_bar then
			BossPhaseAbilityCast(self.team, "treant_leech_seed", "boss_treant_rapid_growth", delay)
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.5, function()

			-- Boss animation
			self:TreantInvisEnd(boss)
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 0.9, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Spawn fake trees on the indicated positions
			for _, spawn_location in pairs(positions) do
				self:SpawnFakeTree(spawn_location, health)
			end
		end)
	end
end

-- Eyes in the Forest
function boss_thinker_treant:EyesInTheForest(center_point, altar_handle, delay, positions, health, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()

		-- Send cast bar event
		if send_cast_bar then
			BossPhaseAbilityCast(self.team, "treant_eyes_in_the_forest", "boss_treant_eyes_in_the_forest", delay)
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.5, function()

			-- Boss animation
			self:TreantInvisEnd(boss)
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 0.9, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Spawn fake trees on the indicated positions
			for _, spawn_location in pairs(positions) do
				self:SpawnTreantling(spawn_location, health, center_point)
			end
		end)
	end
end

-- Living Armor
function boss_thinker_treant:LivingArmor(center_point, altar_handle, delay, target_amount, layers, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()

		-- Look for valid targets
		local trees ={}
		local nearby_allies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, ally in pairs(nearby_allies) do
			if (ally:HasModifier("modifier_frostivus_treantling_passive") or ally:HasModifier("modifier_frostivus_fake_tree_passive")) and not ally:HasModifier("modifier_frostivus_living_armor") then
				trees[#trees + 1] = ally
				if #trees >= target_amount then
					break
				end
			end
		end

		-- Send cast bar event
		if send_cast_bar then
			BossPhaseAbilityCast(self.team, "treant_living_armor", "boss_treant_living_armor", delay)
		end

		-- If there's no valid target, do nothing
		if #trees <= 0 then
			return nil
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.5, function()

			-- Boss animation
			self:TreantInvisEnd(boss)
			boss:FaceTowards(trees[1]:GetAbsOrigin())
			StartAnimation(boss, {duration = 0.9, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Play cast sound
			boss:EmitSound("Hero_Treant.LivingArmor.Cast")

			-- Apply living armor to the targets
			for _, tree in pairs(trees) do
				if tree and tree:IsAlive() then

					-- Play target sound
					tree:EmitSound("Hero_Treant.LivingArmor.Target")

					-- Apply the buff
					local living_armor_buff = tree:AddNewModifier(boss, boss:FindAbilityByName("frostivus_boss_living_armor"), "modifier_frostivus_living_armor", {})
					living_armor_buff:SetStackCount(layers)
				end
			end
		end)
	end
end

-- Living Armor buff
LinkLuaModifier("modifier_frostivus_living_armor", "boss_scripts/boss_thinker_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_living_armor = modifier_frostivus_living_armor or class({})

function modifier_frostivus_living_armor:IsHidden() return false end
function modifier_frostivus_living_armor:IsPurgable() return false end
function modifier_frostivus_living_armor:IsDebuff() return false end

function modifier_frostivus_living_armor:OnCreated(keys)
	if IsServer() then
		self.particle = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_livingarmor.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(self.particle, 0, self:GetParent():GetAbsOrigin())
		ParticleManager:SetParticleControl(self.particle, 1, self:GetParent():GetAbsOrigin())
	end
end

function modifier_frostivus_living_armor:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.particle, true)
		ParticleManager:ReleaseParticleIndex(self.particle)
	end
end

function modifier_frostivus_living_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
	return funcs
end

function modifier_frostivus_living_armor:OnTakeDamage(keys)
	if IsServer() then
		if keys.unit == self:GetParent() then
			self:SetStackCount(self:GetStackCount() - 1)
			if self:GetStackCount() <= 0 then
				self:GetParent():RemoveModifierByName("modifier_frostivus_living_armor")
			end
		end
	end
end

function modifier_frostivus_living_armor:GetModifierHealthRegenPercentage()
	return 10
end

function modifier_frostivus_living_armor:GetModifierIncomingDamage_Percentage()
	return -50
end


-- Overgrowth
function boss_thinker_treant:Overgrowth(center_point, altar_handle, delay, radius, damage, duration, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		if send_cast_bar then
			BossPhaseAbilityCast(self.team, "treant_overgrowth", "boss_treant_overgrowth", delay)
		end

		-- Play warning sound
		altar_handle:EmitSound("Hero_Treant.Overgrowth.CastAnim")

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.5, function()

			-- Decide on the source
			local main_source = self:PickRandomFakeTree(center_point)
			FindClearSpaceForUnit(boss, main_source:GetAbsOrigin(), true)

			-- Boss animation
			self:TreantInvisEnd(boss)
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 1.67, activity=ACT_DOTA_CAST_ABILITY_5, rate=1.0})
		end)

		-- Animate treantlings
		Timers:CreateTimer(delay - 0.467, function()

			-- Treantlings animation
			for _, treantling in pairs(self:GetRealTrees(center_point)) do
				treantling:FaceTowards(center_point)
				StartAnimation(treantling, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

				-- Resume idle animation after cast
				Timers:CreateTimer(1.5, function()
					StartAnimation(treantling, {duration = 30.0, activity=ACT_DOTA_IDLE, rate=1.0})
				end)
			end
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Find targets around Treant
			local ability_overgrowth = boss:FindAbilityByName("frostivus_boss_overgrowth")
			altar_handle:EmitSound("Hero_Treant.Overgrowth.Cast")
			local cast_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_overgrowth_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
			ParticleManager:SetParticleControl(cast_pfx, 0, boss:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(cast_pfx)
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if not enemy:HasModifier("modifier_frostivus_overgrowth_root") then
					self:LeechSeedStackUp(boss, enemy)
					local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = hit_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
					enemy:EmitSound("Hero_Treant.Overgrowth.Target")
					enemy:AddNewModifier(boss, ability_overgrowth, "modifier_frostivus_overgrowth_root", {duration = duration})
				end
			end

			-- Find targets around Treantlings
			for _, treantling in pairs(self:GetRealTrees(center_point)) do
				cast_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_overgrowth_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, treantling)
				ParticleManager:SetParticleControl(cast_pfx, 0, treantling:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(cast_pfx)
				nearby_enemies = FindUnitsInRadius(boss:GetTeam(), treantling:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
				for _,enemy in pairs(nearby_enemies) do
					if not enemy:HasModifier("modifier_frostivus_overgrowth_root") then
						self:LeechSeedStackUp(boss, enemy)
						local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = hit_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
						SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
						enemy:EmitSound("Hero_Treant.Overgrowth.Target")
						enemy:AddNewModifier(boss, ability_overgrowth, "modifier_frostivus_overgrowth_root", {duration = duration})
					end
				end
			end
		end)
	end
end

-- Overgrowth debuff
LinkLuaModifier("modifier_frostivus_overgrowth_root", "boss_scripts/boss_thinker_treant.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_overgrowth_root = modifier_frostivus_overgrowth_root or class({})

function modifier_frostivus_overgrowth_root:IsHidden() return false end
function modifier_frostivus_overgrowth_root:IsPurgable() return false end
function modifier_frostivus_overgrowth_root:IsDebuff() return true end

function modifier_frostivus_overgrowth_root:GetEffectName()
	return "particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf"
end

function modifier_frostivus_overgrowth_root:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_frostivus_overgrowth_root:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true
	}
	return state
end