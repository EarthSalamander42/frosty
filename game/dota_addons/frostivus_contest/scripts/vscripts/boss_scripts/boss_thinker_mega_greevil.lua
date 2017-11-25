-- Mega Greevil AI thinker

boss_thinker_mega_greevil = class({})

function boss_thinker_mega_greevil:IsHidden()
	return true
end

function boss_thinker_mega_greevil:IsPurgable()
	return false
end

function boss_thinker_mega_greevil:OnCreated( params )
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

		-- Altar positions
		self.radiant_altar = Entities:FindByName(nil, "altar_1")
		self.dire_altar = Entities:FindByName(nil, "altar_7")

		-- Tally damage from each team
		self.damage_taken = {}
		self.damage_taken[DOTA_TEAM_GOODGUYS] = 0
		self.damage_taken[DOTA_TEAM_BADGUYS] = 0
		self.damage_taken[DOTA_TEAM_NEUTRALS] = 0

		-- Tally damage for presents
		self.damage_taken_temp = {}
		self.damage_taken_temp[DOTA_TEAM_GOODGUYS] = 0
		self.damage_taken_temp[DOTA_TEAM_BADGUYS] = 0
		self.damage_taken_temp[DOTA_TEAM_NEUTRALS] = 0

		-- Start thinking
		self.boss_timer = 0
		self.rage_timer = 0
		self.events = {}
		self:StartIntervalThink(0.5)
	end
end

-----------------------------------------------------------------------

function boss_thinker_mega_greevil:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE
	}
	return funcs
end

function boss_thinker_mega_greevil:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * 0.5
end

function boss_thinker_mega_greevil:GetModifierBaseAttack_BonusDamage()
	return self:GetStackCount()
end

function boss_thinker_mega_greevil:OnDeath(keys)
	if IsServer() and keys.unit == self:GetParent() then
		GameRules:SetCustomVictoryMessage("Frostivus is saved!")
		GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
		GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
	end
end

-- Damage counter
function boss_thinker_mega_greevil:OnTakeDamage(keys)
	if IsServer() and keys.unit == self:GetParent() then
		local team = keys.attacker:GetTeam()
		self.damage_taken[team] = self.damage_taken[team] + keys.damage
		self.damage_taken_temp[team] = self.damage_taken_temp[team] + keys.damage
		if self.damage_taken_temp[team] >= 1000 then
			self.damage_taken_temp[team] = self.damage_taken_temp[team] - 1000
			local item = CreateItem("item_frostivus_present", nil, nil)
			CreateItemOnPositionForLaunch(self:GetParent():GetAbsOrigin(), item)
			item:LaunchLootInitialHeight(true, 600, 700, 0.8, keys.attacker:GetAbsOrigin())
		end
	end
end

-----------------------------------------------------------------------

function boss_thinker_mega_greevil:OnIntervalThink()
	if IsServer() then

		-- Parameters
		local boss = self:GetParent()

		-- Calculate destination and current speed
		local delta = 0
		if self.damage_taken[DOTA_TEAM_GOODGUYS] >= self.damage_taken[DOTA_TEAM_BADGUYS] then
			boss:MoveToPosition(self.dire_altar:GetAbsOrigin())
			delta = self.damage_taken[DOTA_TEAM_GOODGUYS] - self.damage_taken[DOTA_TEAM_BADGUYS]
		else
			boss:MoveToPosition(self.radiant_altar:GetAbsOrigin())
			delta = self.damage_taken[DOTA_TEAM_BADGUYS] - self.damage_taken[DOTA_TEAM_GOODGUYS]
		end

		self.rage_timer = self.rage_timer + 0.5
		self:SetStackCount(2 * self.rage_timer + 300 * delta / math.max(boss:GetHealth(), 10000) + 300 * (boss:GetMaxHealth() - boss:GetHealth()) / boss:GetMaxHealth())

		-- Check for the win condition
		if boss:GetAbsOrigin().x < -4700 then
			self.radiant_altar:Kill(nil, self.radiant_altar)
			GameRules:SetGameWinner(DOTA_TEAM_BADGUYS)
			self:GetParent():RemoveModifierByName("boss_thinker_mega_greevil")
		elseif boss:GetAbsOrigin().x > 4700 then
			self.dire_altar:Kill(nil, self.dire_altar)
			GameRules:SetGameWinner(DOTA_TEAM_GOODGUYS)
			self:GetParent():RemoveModifierByName("boss_thinker_mega_greevil")
		end

		-- Think
		self.boss_timer = self.boss_timer + 0.5
		local action_time = math.max(6.0 - self.rage_timer / 30, 3.0)

		-- Pick a random mechanic if it's time
		if self.boss_timer >= action_time then
			self.boss_timer = 0
			self:PerformRandomAbility(self:GetParent())
		end
	end
end

---------------------------
-- Auxiliary stuff
---------------------------

function boss_thinker_mega_greevil:PerformRandomAbility(boss)
	local random = RandomInt(0, 9)
	if random == 0 then
		self:GodsWrath(boss, boss:GetAbsOrigin(), 2.0, 90)
	elseif random == 1 then
		self:RagnaBlade(boss, boss:GetAbsOrigin(), 2.0, math.floor(1 + 0.1 * self.rage_timer))
	elseif random == 2 then
		self:Meteorain(boss, boss:GetAbsOrigin(), 2.0, 3.0 + 0.03 * self.rage_timer, 0.9, math.floor(1 + 0.1 * self.rage_timer), 250, 100)
	elseif random == 3 then
		self:CircleRaze(boss, boss:GetAbsOrigin(), 2.0, 250, 100, 300, 5)
		self:CircleRaze(boss, boss:GetAbsOrigin(), 2.5, 250, 100, 600, 9)
		if self.rage_timer > 30 then
			self:CircleRaze(boss, boss:GetAbsOrigin(), 3.0, 250, 100, 800, 12)
		end
		if self.rage_timer > 60 then
			self:CircleRaze(boss, boss:GetAbsOrigin(), 3.5, 250, 100, 1000, 16)
		end
	elseif random == 4 then
		self:VineSmash(boss:GetAbsOrigin(), boss, 3.5, 2.0, math.floor(1 + 0.1 * self.rage_timer), 150, 100)
	elseif random == 5 then
		self:Overgrowth(boss:GetAbsOrigin(), 600 + 3 * self.rage_timer, 70, 5.0)
	elseif random == 6 then
		self:PoisonNova(boss, boss:GetAbsOrigin(), 1.5, 1, 30 + 0.2 * self.rage_timer, 15)
	elseif random == 7 then
		self:LightningBolt(boss, boss:GetAbsOrigin(), RandomInt(0, 359), math.floor(7 + 0.125 * self.rage_timer), 2.5, 175, 350, 100, 300, 800, true)
	elseif random == 8 then
		self:ArcLightning(1.0, 400 + self.rage_timer, 40, 25)
	elseif random == 9 then
		self:ElThor(boss, 400, 3.0, 250)
	end
end

-- Raze a target location
function boss_thinker_mega_greevil:Raze(boss, target, delay, radius, damage, play_impact_sound)

	-- Show warning pulses
	local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/pre_raze.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(warning_pfx, 0, target)
	ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(warning_pfx)

	Timers:CreateTimer(delay, function()
	
		-- Sound
		if play_impact_sound then
			boss:EmitSound("Hero_Nevermore.Shadowraze")
		end

		-- Particles
		local raze_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/raze_blast.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(raze_pfx, 0, target)
		ParticleManager:SetParticleControl(raze_pfx, 1, Vector(0, 0, 0))
		ParticleManager:ReleaseParticleIndex(raze_pfx)

		-- Hit enemies
		local hit_enemies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, target, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(hit_enemies) do

			-- Deal damage
			local damage_dealt = ApplyDamage({victim = enemy, attacker = self:GetParent(), ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
		end
	end)
end

-- Meteor a target location
function boss_thinker_mega_greevil:Meteor(boss, target, radius, damage)

	-- Warning particle & sound
	boss:EmitSound("Hero_Invoker.ChaosMeteor.Cast")
	local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/meteorain_pre.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(warning_pfx, 0, target)
	ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))
	ParticleManager:ReleaseParticleIndex(warning_pfx)

	-- Meteor particle
	local meteor_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/meteorain.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(meteor_pfx, 0, target + Vector(300, -300, 1000))
	ParticleManager:SetParticleControl(meteor_pfx, 1, target)
	ParticleManager:SetParticleControl(meteor_pfx, 2, Vector(1.5, 0, 0))
	ParticleManager:ReleaseParticleIndex(meteor_pfx)

	-- Meteor travel delay
	Timers:CreateTimer(1.5, function()

		-- Play impact sound
		boss:EmitSound("Hero_Invoker.ChaosMeteor.Impact")

		-- Hit enemies
		local hit_enemies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, target, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, enemy in pairs(hit_enemies) do

			-- Deal damage
			local damage_dealt = ApplyDamage({victim = enemy, attacker = self:GetParent(), ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
		end
	end)
end

-- Ragna Blade
function boss_thinker_mega_greevil:RagnaBlade(boss, boss_loc, delay, target_amount)
	if IsServer() then

		-- Look for valid targets
		local targets = {}
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			targets[#targets + 1] = enemy
			if #targets >= target_amount then
				break
			end
		end

		-- If there's no valid target, do nothing
		if #targets <= 0 then
			return nil
		end

		-- Draw warning particle on the targets' position
		for _, target in pairs(targets) do
			local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/ragna_blade_pre_warning.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
			ParticleManager:SetParticleControl(warning_pfx, 0, target:GetAbsOrigin())

			-- Play warning sound
			target:EmitSound("Frostivus.AbilityWarning")

			Timers:CreateTimer(delay, function()
				ParticleManager:DestroyParticle(warning_pfx, true)
				ParticleManager:ReleaseParticleIndex(warning_pfx)
			end)
		end

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.33, function()
			boss:FaceTowards(targets[1]:GetAbsOrigin())
			StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Play cast sound
			boss:EmitSound("Hero_Lina.LagunaBlade.Immortal")

			for _,target in pairs(targets) do

				-- Play impact sound
				target:EmitSound("Hero_Lina.LagunaBladeImpact.Immortal")

				-- Play impact particle
				local impact_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/ragna_blade.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
				ParticleManager:SetParticleControlEnt(impact_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_head", boss:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(impact_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(impact_pfx)

				-- Deal damage
				local damage_dealt = ApplyDamage({victim = target, attacker = boss, ability = nil, damage = target:GetHealth() - RandomInt(1, 9), damage_type = DAMAGE_TYPE_PURE})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_DAMAGE, target, damage_dealt, nil)
			end
		end)
	end
end

-- Meteorain
function boss_thinker_mega_greevil:Meteorain(boss, boss_loc, delay, duration, spawn_delay, spawn_amount, radius, damage)
	if IsServer() then
		local impact_damage = boss:GetAttackDamage() * damage * 0.01

		-- Play warning sound
		boss:EmitSound("Hero_Invoker.ChaosMeteor.Cast")

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.33, function()
			StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			local elapsed_duration = 0
			local remaining_spawns = spawn_amount
			Timers:CreateTimer(0, function()

				-- Spawn meteors
				local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
				for _,enemy in pairs(nearby_enemies) do
					self:Meteor(boss, enemy:GetAbsOrigin(), radius, impact_damage)
					remaining_spawns = remaining_spawns - 1
					if remaining_spawns <= 0 then
						break
					end
				end

				-- Check if the duration has ended
				elapsed_duration = elapsed_duration + spawn_delay
				if elapsed_duration <= duration then
					return spawn_delay
				end
			end)
		end)
	end
end

-- Circle Raze (Sah/Voo Omoz)
function boss_thinker_mega_greevil:CircleRaze(boss, boss_loc, delay, radius, damage, distance, razes)
	if IsServer() then
		local raze_damage = boss:GetAttackDamage() * damage * 0.01

		-- Raze
		Timers:CreateTimer(delay - 1.5, function()

			-- Calculate raze points
			local raze_points = {}
			for i = 1, razes do
				raze_points[i] = RotatePosition(boss_loc, QAngle(0, (360 / razes) * (i - 1), 0), boss_loc + Vector(0, 1, 0) * distance)
			end

			-- Raze
			for _, raze_point in pairs(raze_points) do
				self:Raze(boss, raze_point, 1.5, radius, raze_damage, false)
			end
		end)

		-- Animate boss cast
		Timers:CreateTimer(delay - 0.33, function()
			StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
		end)

		-- Play raze sound
		Timers:CreateTimer(delay, function()
			boss:EmitSound("Hero_Nevermore.Shadowraze")
		end)
	end
end

-- Vine Smash
function boss_thinker_mega_greevil:VineSmash(boss_loc, boss, delay, fixate_delay, target_amount, radius, damage)
	if IsServer() then
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Look for valid targets
		local targets = {}
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _,enemy in pairs(nearby_enemies) do
			targets[#targets + 1] = enemy
			if #targets >= target_amount then
				break
			end
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
		Timers:CreateTimer(delay - 0.33, function()
			StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
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
			boss:EmitSound("Hero_Furion.ForceOfNature")

			-- Shoot vines
			for _, target_loc in pairs(target_locs) do
				self:ShootVineSmash(boss, target_loc, radius, hit_damage)
			end
		end)
	end
end

function boss_thinker_mega_greevil:ShootVineSmash(boss, target_loc, radius, damage)
	local source_loc = boss:GetAbsOrigin()
	local forward_direction = (target_loc - source_loc):Normalized()
	local spawn_count = math.ceil(radius * 0.02)
	local spawn_limit = (-0.5) * (spawn_count - 1)

	-- Calculate spawn locations
	local spawn_locations = {}
	for i = spawn_limit, (-spawn_limit) do
		spawn_locations[i] = RotatePosition(source_loc, QAngle(0, 90, 0), source_loc + forward_direction * 100 * i)
	end

	-- VINE SMASH!
	boss:EmitSound("Frostivus.TreantVineSmashTravel")
	for current_tick = 0, 18 do
		for _,spawn_loc in pairs(spawn_locations) do
			local current_loc = spawn_loc + current_tick * forward_direction * 100
			local vine_pfx = ParticleManager:CreateParticle("particles/boss_treant/vine_smash_vines.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(vine_pfx, 0, current_loc)
			ParticleManager:ReleaseParticleIndex(vine_pfx)

			-- Damage nearby enemies
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), current_loc, nil, 100, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do
				if not enemy:HasModifier("modifier_vine_smash_damage_dummy") then
					local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
					enemy:EmitSound("Hero_Treant.Overgrowth.Target")
					enemy:AddNewModifier(nil, nil, "modifier_vine_smash_damage_dummy", {duration = 0.1})
				end
			end
		end
	end
end

-- Overgrowth
function boss_thinker_mega_greevil:Overgrowth(boss_loc, radius, damage, duration)
	if IsServer() then
		local boss = self:GetParent()
		local hit_damage = boss:GetAttackDamage() * damage * 0.01

		-- Play warning sound
		boss:EmitSound("Hero_Treant.Overgrowth.CastAnim")

		StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

		-- Wait [delay] seconds
		Timers:CreateTimer(0.33, function()

			-- Find targets around Treant
			local ability_overgrowth = boss:FindAbilityByName("frostivus_boss_overgrowth")
			boss:EmitSound("Hero_Treant.Overgrowth.Cast")
			local cast_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_treant/treant_overgrowth_cast.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
			ParticleManager:SetParticleControl(cast_pfx, 0, boss:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(cast_pfx)
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_loc, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if not enemy:HasModifier("modifier_frostivus_overgrowth_root_greevil") then
					local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = hit_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
					enemy:EmitSound("Hero_Treant.Overgrowth.Target")
					enemy:AddNewModifier(boss, ability_overgrowth, "modifier_frostivus_overgrowth_root_greevil", {duration = duration})
				end
			end
		end)
	end
end

-- Overgrowth debuff
LinkLuaModifier("modifier_frostivus_overgrowth_root_greevil", "boss_scripts/boss_thinker_mega_greevil.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_overgrowth_root_greevil = modifier_frostivus_overgrowth_root_greevil or class({})

function modifier_frostivus_overgrowth_root_greevil:IsHidden() return false end
function modifier_frostivus_overgrowth_root_greevil:IsPurgable() return false end
function modifier_frostivus_overgrowth_root_greevil:IsDebuff() return true end

function modifier_frostivus_overgrowth_root_greevil:GetEffectName()
	return "particles/units/heroes/hero_treant/treant_overgrowth_vines.vpcf"
end

function modifier_frostivus_overgrowth_root_greevil:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_frostivus_overgrowth_root_greevil:CheckState()
	local state = {
		[MODIFIER_STATE_ROOTED] = true,
		[MODIFIER_STATE_DISARMED] = true
	}
	return state
end

-- Poison Nova
function boss_thinker_mega_greevil:PoisonNova(boss, boss_loc, delay, damage, damage_amp, duration)
	if IsServer() then
		local ability = boss:FindAbilityByName("frostivus_boss_poison_nova")
		local dot_damage = boss:GetAttackDamage() * damage * 0.01

		-- Move boss to cast position and animate cast
		StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

		-- Wait [delay] seconds
		Timers:CreateTimer(0.33, function()

			-- Play cast sound
			boss:EmitSound("Hero_Venomancer.PoisonNova")

			-- Play particles
			local nova_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_venomancer/venomancer_poison_nova.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(nova_pfx, 0, boss_loc)
			ParticleManager:SetParticleControl(nova_pfx, 1, Vector(1100, 1, 900))
			ParticleManager:SetParticleControl(nova_pfx, 2, Vector(0, 0, 0))
			ParticleManager:ReleaseParticleIndex(nova_pfx)

			-- Poison enemies
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_loc, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do
				enemy:EmitSound("Hero_Venomancer.PoisonNovaImpact")
				local modifier = enemy:AddNewModifier(boss, ability, "modifier_frostivus_venomancer_poison_nova_greevil", {damage = dot_damage, damage_amp = damage_amp, duration = duration})
			end
		end)
	end
end

-- Poison Nova debuff modifier
LinkLuaModifier("modifier_frostivus_venomancer_poison_nova_greevil", "boss_scripts/boss_thinker_mega_greevil.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_venomancer_poison_nova_greevil = modifier_frostivus_venomancer_poison_nova_greevil or class({})

function modifier_frostivus_venomancer_poison_nova_greevil:IsHidden() return false end
function modifier_frostivus_venomancer_poison_nova_greevil:IsPurgable() return false end
function modifier_frostivus_venomancer_poison_nova_greevil:IsDebuff() return true end

function modifier_frostivus_venomancer_poison_nova_greevil:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_poison_debuff_nova.vpcf"
end

function modifier_frostivus_venomancer_poison_nova_greevil:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_frostivus_venomancer_poison_nova_greevil:OnCreated(keys)
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

function modifier_frostivus_venomancer_poison_nova_greevil:OnIntervalThink()
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

function modifier_frostivus_venomancer_poison_nova_greevil:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
	return funcs
end

function modifier_frostivus_venomancer_poison_nova_greevil:GetModifierIncomingDamage_Percentage()
	return self:GetStackCount()
end

function boss_thinker_mega_greevil:LightningBolt(boss, boss_loc, angle, amount, delay, inner_radius, outer_radius, damage, min_radius, max_radius, cast_bar)
	local bolt_damage = boss:GetAttackDamage() * damage * 0.01

	-- Play warning sound
	boss:EmitSound("Hero_Disruptor.KineticField")

	-- Define bolt positions
	local bolt_positions = {}
	for i = 1, amount do
		bolt_positions[i] = RotatePosition(boss_loc, QAngle(0, angle + (i - 1) * 360 / amount, 0), boss_loc + Vector(0, 1, 0) * RandomInt(min_radius, max_radius))
	end

	-- Draw particles
	for _, bolt_position in pairs(bolt_positions) do
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_zeus/lightning_bolt_marker.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(warning_pfx, 0, bolt_position)
		ParticleManager:SetParticleControl(warning_pfx, 1, Vector(delay, 0, 0))
		ParticleManager:ReleaseParticleIndex(warning_pfx)
	end

	-- Move boss to cast position and animate cast
	Timers:CreateTimer(delay - 0.33, function()
		StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- Play bolt cast sound
		boss:EmitSound("Hero_Zuus.LightningBolt.Cast")

		-- Impact sound
		boss:EmitSound("Hero_Zuus.LightningBolt")

		-- Resolve bolts
		for _, bolt_position in pairs(bolt_positions) do

			-- Particles
			local bolt_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(bolt_pfx, 0, bolt_position)
			ParticleManager:SetParticleControl(bolt_pfx, 1, bolt_position + Vector(0, 0, 1000))
			ParticleManager:ReleaseParticleIndex(bolt_pfx)

			-- Damage enemies
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), bolt_position, nil, outer_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do
				local distance = (bolt_position - enemy:GetAbsOrigin()):Length2D()
				local enemy_damage = bolt_damage
				if distance > inner_radius and distance <= outer_radius then
					enemy_damage = enemy_damage * (outer_radius - distance) / (outer_radius - inner_radius)
				end
				local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = enemy_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
			end
		end
	end)
end

-- Arc Lightning
function boss_thinker_mega_greevil:ArcLightning(bounce_delay, bounce_radius, damage, damage_ramp)
	local boss = self:GetParent()
	local boss_position = boss:GetAbsOrigin()
	local chain_damage = boss:GetAttackDamage() * damage * 0.01
	local chain_target = false

	-- Find nearest target hero to attack
	local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_position, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	for _,enemy in pairs(nearby_enemies) do
		chain_target = enemy
		break
	end

	-- If there's no valid target, stop casting
	if not chain_target then
		return nil
	end

	-- Move boss to cast position and animate cast
	StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})

	-- Wait [delay] seconds
	Timers:CreateTimer(0.33, function()

		-- Throw initial bounce
		boss:EmitSound("Hero_Zuus.ArcLightning.Cast")
		self:ArcLightningBounce(boss, chain_target, chain_damage, damage_ramp, bounce_radius, bounce_delay)
	end)
end

function boss_thinker_mega_greevil:ArcLightningBounce(source, target, damage, damage_ramp, bounce_radius, bounce_delay)
	local boss = self:GetParent()
	local target_location = target:GetAbsOrigin() 

	-- Perform this bounce
	target:EmitSound("Hero_Zuus.ArcLightning.Target")
	local arc_pfx = ParticleManager:CreateParticle("particles/boss_zeus/arc_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControlEnt(arc_pfx, 0, source, PATTACH_POINT_FOLLOW, "attach_hitloc", source:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(arc_pfx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target_location, true)
	ParticleManager:ReleaseParticleIndex(arc_pfx)
	local damage_dealt = ApplyDamage({attacker = boss, victim = target, ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
	SendOverheadEventMessage(target, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage_dealt, nil)

	-- Perform another bounce, if applicable
	Timers:CreateTimer(bounce_delay, function()
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), target_location, nil, bounce_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for _,enemy in pairs(nearby_enemies) do
			if enemy ~= target then
				self:ArcLightningBounce(target, enemy, damage * (1 + damage_ramp * 0.01), damage_ramp, bounce_radius, bounce_delay)
				break
			end
		end
	end)
end

-- El Thor
function boss_thinker_mega_greevil:ElThor(boss, radius, delay, damage)
	local thor_damage = boss:GetAttackDamage() * damage * 0.01

	local target = false
	local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss:GetAbsOrigin(), nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	for _,enemy in pairs(nearby_enemies) do
		target = enemy
		break
	end

	if not target then
		return nil
	end

	-- Draw stack up marker
	local marker_pfx = ParticleManager:CreateParticle("particles/generic_particles/stack_up_center_zeus.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(marker_pfx, 0, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(marker_pfx, 1, Vector(radius, delay, 0))
	Timers:CreateTimer(delay, function()
		ParticleManager:DestroyParticle(marker_pfx, false)
		ParticleManager:ReleaseParticleIndex(marker_pfx)
	end)

	-- Play warning sound
	target:EmitSound("Frostivus.ElThorWarning")

	-- Face boss to cast position and animate cast
	Timers:CreateTimer(delay - 0.33, function()
		StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- Play impact sound
		target:EmitSound("Frostivus.ElThorImpact")

		-- Particles
		local target_position = target:GetAbsOrigin()
		local thor_pfx = ParticleManager:CreateParticle("particles/boss_zeus/el_thor.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
		ParticleManager:SetParticleControl(thor_pfx, 0, target:GetAbsOrigin())
		ParticleManager:SetParticleControl(thor_pfx, 1, Vector(radius, radius, radius))
		ParticleManager:ReleaseParticleIndex(thor_pfx)
		local bolt_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(bolt_pfx, 0, target_position)
		ParticleManager:SetParticleControl(bolt_pfx, 1, target_position + Vector(0, 0, 1000))
		ParticleManager:ReleaseParticleIndex(bolt_pfx)

		-- Count enemies
		local enemies_to_hit = FindUnitsInRadius(boss:GetTeam(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)

		-- Damage enemies
		thor_damage = thor_damage / #enemies_to_hit
		for _, victim in pairs(enemies_to_hit) do
			local damage_dealt = ApplyDamage({victim = victim, attacker = boss, ability = nil, damage = thor_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage_dealt, nil)
		end
	end)
end

-- God's Wrath
function boss_thinker_mega_greevil:GodsWrath(boss, boss_loc, delay, damage)
	local wrath_damage = boss:GetAttackDamage() * damage * 0.01

	-- Play warning sound
	boss:EmitSound("Hero_Zuus.GodsWrath.PreCast")

	-- Move boss to cast position and animate cast
	Timers:CreateTimer(delay - 0.33, function()
		StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
	end)

	-- Pre-cast sound
	Timers:CreateTimer(delay - 0.4, function()
		boss:EmitSound("Hero_Zuus.GodsWrath.PreCast")
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- Play cast sound
		boss:EmitSound("Hero_Zuus.GodsWrath")

		-- Cast particle
		local boss_position = boss:GetAbsOrigin()
		local wrath_pfx = ParticleManager:CreateParticle("particles/econ/items/zeus/arcana_chariot/zeus_arcana_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
		ParticleManager:SetParticleControl(wrath_pfx, 0, boss_position + Vector(0, 0, 400))
		ParticleManager:SetParticleControl(wrath_pfx, 1, boss_position)
		ParticleManager:ReleaseParticleIndex(wrath_pfx)

		-- Iterate through enemies
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _, enemy in pairs(nearby_enemies) do

			-- Impact sound
			enemy:EmitSound("Hero_Zuus.GodsWrath.Target")

			-- Impact particle
			local enemy_position = enemy:GetAbsOrigin()
			local impact_pfx = ParticleManager:CreateParticle("particles/econ/items/zeus/arcana_chariot/zeus_arcana_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
			ParticleManager:SetParticleControl(impact_pfx, 0, enemy_position + Vector(0, 0, 1000))
			ParticleManager:SetParticleControl(impact_pfx, 1, enemy_position)
			ParticleManager:ReleaseParticleIndex(impact_pfx)

			-- Damage
			local damage_dealt = ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = wrath_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
		end
	end)
end