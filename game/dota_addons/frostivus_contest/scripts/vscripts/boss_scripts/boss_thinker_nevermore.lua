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
			local present_amount = 1 + current_power
			Timers:CreateTimer(0, function()
				local item = CreateItem("item_frostivus_present", nil, nil)
				CreateItemOnPositionForLaunch(target_loc, item)
				item:LaunchLootInitialHeight(true, 150, 300, 0.8, keys.attacker:GetAbsOrigin())
				present_amount = present_amount - 1
				if present_amount > 0 then
					return 0.2
				end
			end)

			-- Spawn a greevil that runs away
			local greevil = SpawnGreevil(target_loc, 1, false, 255, 100, 0)
			Timers:CreateTimer(3, function()
				StartAnimation(greevil, {duration = 2.5, activity=ACT_DOTA_FLAIL, rate=1.5})
				greevil:MoveToPosition(altar_loc + RandomVector(10):Normalized() * 900)
				Timers:CreateTimer(2.5, function()
					greevil:Kill(nil, greevil)
				end)
			end)

			-- Respawn the boss and grant it its new capture detection modifier
			local boss
			local current_level = target:GetLevel()
			Timers:CreateTimer(15, function()
				boss = SpawnNevermore(self.altar_handle)

				-- Increase the new boss' power
				local next_power = math.ceil(current_power * 0.25) + 1
				boss:FindModifierByName("modifier_frostivus_boss"):SetStackCount(current_power + next_power)
				for i = 1, current_level do
					boss:HeroLevelUp(false)
				end
			end)

			-- Destroy any existing adds
			local nearby_summons = FindUnitsInRadius(target:GetTeam(), target:GetAbsOrigin(), nil, 1800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
			for _,summon in pairs(nearby_summons) do
				if not summon:HasModifier("modifier_frostivus_greevil") then
					summon:Kill(nil, summon)
				end
			end

			-- Unlock the arena
			UnlockArena(self.altar_handle, true, self.team, "frostivus_altar_aura_fire")

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
		--if self.boss_timer > 0 and not self.events[1] then
		--	self:VenomousGale(altar_loc, altar_entity, 3.0, RandomInt(0, 359), 225, math.min(20 + power_stacks * 5, 80), 10, 10, 250, 750, math.min(1 + 0.25 * power_stacks, 4), 6, math.max(2.0 - 0.05 * power_stacks, 1.0), 4)
		--	self.events[1] = true
		--end
	end
end

---------------------------
-- Auxiliary stuff
---------------------------

-- Returns all treantlings
function boss_thinker_nevermore:GetRealTrees(center_point)
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
function boss_thinker_nevermore:PickRandomFakeTree(center_point)
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
function boss_thinker_nevermore:SpawnFakeTree(location, health)
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
LinkLuaModifier("modifier_frostivus_fake_tree_passive", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_fake_tree_passive = modifier_frostivus_fake_tree_passive or class({})

function modifier_frostivus_fake_tree_passive:IsHidden() return true end
function modifier_frostivus_fake_tree_passive:IsPurgable() return false end
function modifier_frostivus_fake_tree_passive:IsDebuff() return true end

-- Spawns a treantling
function boss_thinker_nevermore:SpawnTreantling(location, health, center_point)
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
LinkLuaModifier("modifier_frostivus_treantling_passive", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_treantling_passive = modifier_frostivus_treantling_passive or class({})

function modifier_frostivus_treantling_passive:IsHidden() return true end
function modifier_frostivus_treantling_passive:IsPurgable() return false end
function modifier_frostivus_treantling_passive:IsDebuff() return true end

-- Make Treant invisible
function boss_thinker_nevermore:TreantInvisStart(boss)

	-- Play invis sound
	boss:EmitSound("Hero_Treant.NaturesGuise.On")

	-- Add invis/invul modifiers
	boss:AddNewModifier(nil, nil, "modifier_invisible", {})
	boss:AddNewModifier(nil, nil, "modifier_invulnerable", {})

	-- Remove Treant's model after fade animation
	Timers:CreateTimer(0.5, function()
		boss:AddNoDraw()

		-- Destroy cosmetics
		boss.head:AddEffects(EF_NODRAW)
		boss.shoulders:AddEffects(EF_NODRAW)
		boss.arms:AddEffects(EF_NODRAW)
		boss.feet:AddEffects(EF_NODRAW)
	end)
end

-- Make Treant visible again
function boss_thinker_nevermore:TreantInvisEnd(boss)

	-- Remove invis modifier
	boss:RemoveModifierByName("modifier_invisible")
	boss:RemoveModifierByName("modifier_invulnerable")

	-- Re-add Treant's model
	boss:RemoveNoDraw()

	-- Cosmetics
	boss.head:RemoveEffects(EF_NODRAW)
	boss.shoulders:RemoveEffects(EF_NODRAW)
	boss.arms:RemoveEffects(EF_NODRAW)
	boss.feet:RemoveEffects(EF_NODRAW)

	-- Play de-invis sound
	boss:EmitSound("Hero_Treant.NaturesGuise.Off")
end

-- Stack Leech Seed up
function boss_thinker_nevermore:LeechSeedStackUp(boss, enemy)
	if not enemy:HasModifier("modifier_frostivus_leech_seed_debuff") then
		enemy:AddNewModifier(boss, boss:FindAbilityByName("frostivus_boss_leech_seed"), "modifier_frostivus_leech_seed_debuff", {})
	end
	local seed_modifier = enemy:FindModifierByName("modifier_frostivus_leech_seed_debuff")
	seed_modifier:SetStackCount(seed_modifier:GetStackCount() + 1)
end

-- Leech Seed debuff
LinkLuaModifier("modifier_frostivus_leech_seed_debuff", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
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
function boss_thinker_nevermore:VineSmash(center_point, altar_handle, delay, fixate_delay, target_amount, radius, damage, send_cast_bar)
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

		-- If there are fake trees available, make the boss invisible
		if self:PickRandomFakeTree(center_point) ~= boss then
			self:TreantInvisStart(boss)
		end

		-- Calculate medium cast location (to look at)
		local cast_position = center_point
		for _, target in pairs(targets) do
			local distance = target:GetAbsOrigin() - center_point
			cast_position = cast_position + distance:Normalized() * distance:Length2D() / #targets
		end

		-- Send cast bar event
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "frostivus_boss_vine_smash", "boss_treant_vine_smash", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_vine_smash", "boss_treant_vine_smash", delay)
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

function boss_thinker_nevermore:ShootVineSmash(altar_handle, source, boss, target_loc, radius, damage)
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
LinkLuaModifier("modifier_vine_smash_damage_dummy", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
modifier_vine_smash_damage_dummy = modifier_vine_smash_damage_dummy or class({})

function modifier_vine_smash_damage_dummy:IsHidden() return true end
function modifier_vine_smash_damage_dummy:IsPurgable() return false end
function modifier_vine_smash_damage_dummy:IsDebuff() return false end

-- Rock Smash
function boss_thinker_nevermore:RockSmash(center_point, altar_handle, optional_target, rock_number, delay, radius, damage, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()
		local tiny = self.tiny_entities[1]
		local rock = self.tiny_entities[1 + rock_number]
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Pick a target position, if necessary
		local target_loc = center_point + RandomVector(10):Normalized() * (900 - radius) * 0.5
		if optional_target then
			target_loc = optional_target
		end

		-- Move Tiny to the rock's side
		tiny:MoveToPosition(rock:GetAbsOrigin() + Vector(50, 0, 0))

		-- Send cast bar event
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "tiny_toss", "boss_treant_rock_smash", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "tiny_toss", "boss_treant_rock_smash", delay)
		end

		-- Draw warning particle on the target position
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_treant/rock_smash_warning.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(warning_pfx, 0, target_loc)
		ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))

		-- Play warning sound
		altar_handle:EmitSound("Frostivus.AbilityWarning")

		-- Animate tiny cast
		Timers:CreateTimer(delay - 1.5, function()
			rock:EmitSound("Hero_Tiny.Toss.Target")
			tiny:EmitSound("Ability.TossThrow")
			tiny:FaceTowards(target_loc)
			StartAnimation(tiny, {duration = 0.53, activity=ACT_TINY_TOSS, rate=1.0})
			self:ThrowRock(rock, target_loc)
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Play impact sound
			altar_handle:EmitSound("Ability.TossImpact")

			-- Destroy the warning particle
			ParticleManager:DestroyParticle(warning_pfx, true)
			ParticleManager:ReleaseParticleIndex(warning_pfx)

			-- Play impact particle
			local impact_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_toss_impact.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(impact_pfx, 0, target_loc)
			ParticleManager:ReleaseParticleIndex(impact_pfx)

			-- Destroy the rock
			rock:Kill(nil, rock)

			-- Damage players in the AOE
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), target_loc, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do

				-- Add Leech Seed stacks
				self:LeechSeedStackUp(boss, enemy)

				-- Show damage dealt
				local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = hit_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_PHYSICAL})
				SendOverheadEventMessage(enemy, OVERHEAD_ALERT_DAMAGE, enemy, damage_dealt, nil)

				-- Play hit particle
				local hit_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_toss_impact.vpcf", PATTACH_WORLDORIGIN, enemy)
				ParticleManager:SetParticleControl(hit_pfx, 0, enemy:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(hit_pfx)
			end
		end)
	end
end

-- Throws a Rock
function boss_thinker_nevermore:ThrowRock(rock, target_loc)
	if IsServer() then
		local source_loc = rock:GetAbsOrigin()
		rock:AddNewModifier(nil, nil, "modifier_phased", {})

		-- Calculate trajectory
		local direction = (target_loc - source_loc):Normalized()
		local length = (target_loc - source_loc):Length2D()
		local tick_length = length * 0.03 / 1.2
		local horizontal_tick = direction * tick_length

		-- Calculate height during trajectory
		local height = {}
		local missing_height = 750
		local current_height = 0
		local dummy_var = 0
		for i = 1, 20 do
			height[i] = current_height + missing_height * (0.075 + 0.005 * i)
			current_height = height[i]
			missing_height = 750 - current_height
		end
		for i = 21, 40 do
			height[i]= height[41 - i]
		end

		-- Move the rock
		local current_spot = source_loc
		local traveled_distance = 0
		local height_tick = 1
		Timers:CreateTimer(0.03, function()
			rock:SetAbsOrigin(current_spot + horizontal_tick + Vector(0, 0, height[height_tick]))
			current_spot = current_spot + horizontal_tick
			traveled_distance = traveled_distance + tick_length
			if traveled_distance < length then
				height_tick = height_tick + 1
				return 0.03
			end
		end)
	end
end

-- Ring of Thorns
function boss_thinker_nevermore:RingOfThorns(center_point, altar_handle, delay, radius, damage, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "frostivus_boss_ring_of_thorns", "boss_treant_ring_of_thorns", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_ring_of_thorns", "boss_treant_ring_of_thorns", delay)
		end

		-- If there are fake trees available, make the boss invisible
		if self:PickRandomFakeTree(center_point) ~= boss then
			self:TreantInvisStart(boss)
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
function boss_thinker_nevermore:LeechSeed(center_point, altar_handle, delay, damage, heal, send_cast_bar)
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
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "treant_leech_seed", "boss_treant_leech_seed", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "treant_leech_seed", "boss_treant_leech_seed", delay)
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
function boss_thinker_nevermore:RapidGrowth(center_point, altar_handle, delay, positions, health, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()

		-- Send cast bar event
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "treant_eyes_in_the_forest", "boss_treant_rapid_growth", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "treant_eyes_in_the_forest", "boss_treant_rapid_growth", delay)
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
function boss_thinker_nevermore:EyesInTheForest(center_point, altar_handle, delay, positions, health, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()

		-- Send cast bar event
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "frostivus_boss_eyes_in_the_forest", "boss_treant_eyes_in_the_forest", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "frostivus_boss_eyes_in_the_forest", "boss_treant_eyes_in_the_forest", delay)
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
function boss_thinker_nevermore:LivingArmor(center_point, altar_handle, delay, target_amount, layers, send_cast_bar)
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
		if send_cast_bar ==  1	then
			BossPhaseAbilityCast(self.team, "treant_living_armor", "boss_treant_living_armor", delay)
		elseif send_cast_bar ==  2	then
			BossPhaseAbilityCastAlt(self.team, "treant_living_armor", "boss_treant_living_armor", delay)
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
LinkLuaModifier("modifier_frostivus_living_armor", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
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
function boss_thinker_nevermore:Overgrowth(center_point, altar_handle, delay, radius, damage, duration, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Send cast bar event
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "treant_overgrowth", "boss_treant_overgrowth", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "treant_overgrowth", "boss_treant_overgrowth", delay)
		end

		-- Play warning sound
		altar_handle:EmitSound("Hero_Treant.Overgrowth.CastAnim")

		-- If there are fake trees available, make the boss invisible
		if self:PickRandomFakeTree(center_point) ~= boss then
			self:TreantInvisStart(boss)
		end

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
LinkLuaModifier("modifier_frostivus_overgrowth_root", "boss_scripts/boss_thinker_nevermore.lua", LUA_MODIFIER_MOTION_NONE )
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

-- Nature's Guise
function boss_thinker_nevermore:NaturesGuise(center_point, altar_handle, delay, send_cast_bar)
	if IsServer() then
		local boss = self:GetParent()

		-- Send cast bar event
		if send_cast_bar == 1 then
			BossPhaseAbilityCast(self.team, "treant_natures_guise", "boss_treant_natures_guise", delay)
		elseif send_cast_bar == 2 then
			BossPhaseAbilityCastAlt(self.team, "treant_natures_guise", "boss_treant_natures_guise", delay)
		end

		-- Play warning sound
		boss:EmitSound("Hero_Treant.Eyes.Cast")

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.5, function()

			-- Boss animation
			boss:FaceTowards(center_point)
			StartAnimation(boss, {duration = 0.9, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Go invis if there is at least one tree to hide in
			if self:PickRandomFakeTree(center_point) ~= boss then
				self:TreantInvisStart(boss)
			end
		end)
	end
end