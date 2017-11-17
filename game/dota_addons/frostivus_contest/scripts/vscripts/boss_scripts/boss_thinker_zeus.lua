-- Dummy boss's AI thinker

boss_thinker_zeus = class({})

-----------------------------------------------------------------------

function boss_thinker_zeus:IsHidden()
	return true
end

-----------------------------------------------------------------------

function boss_thinker_zeus:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function boss_thinker_zeus:OnCreated( params )
	if IsServer() then
		self.boss_name = "zeus"
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
		self.random_constants[1] = RandomInt(1, 360)
		self.random_constants[2] = RandomInt(1, 360)

		-- Start thinking
		self.boss_timer = 0
		self.events = {}
		self:StartIntervalThink(0.1)
	end
end

-----------------------------------------------------------------------

function boss_thinker_zeus:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH
	}
	return funcs
end

-----------------------------------------------------------------------

function boss_thinker_zeus:OnDeath(keys)
local target = keys.unit

	if IsServer() then

		-- Boss death
		if target == self:GetParent() then

			-- Notify the console that a boss fight (capture attempt) has ended with a successful kill
			print(self.boss_name.." boss is dead, winning team is "..self.team)

			-- Hide Boss Bar
			--CustomGameEventManager:Send_ServerToTeam(attacker:GetTeamNumber(), "hide_boss_hp", {})

			-- Send the boss death event to all clients
			CustomGameEventManager:Send_ServerToTeam(self.team, "AltarContestEnd", {win = true})

			-- Play the capture particle to the winning team
			local target_loc = target:GetAbsOrigin()
			for player_id = 0, 20 do
				if PlayerResource:GetPlayer(player_id) and PlayerResource:GetTeam(player_id) == self.team then
					local win_pfx = ParticleManager:CreateParticleForPlayer("particles/boss_zeus/screen_zeus_win.vpcf", PATTACH_EYES_FOLLOW, PlayerResource:GetSelectedHeroEntity(player_id), PlayerResource:GetPlayer(player_id))
					self:AddParticle(win_pfx, false, false, -1, false, false)
					ParticleManager:ReleaseParticleIndex(win_pfx)
				end
			end

			-- Respawn the boss and grant it its new capture detection modifier
			local boss
			Timers:CreateTimer(5, function()
				boss = SpawnZeus(self.altar_handle)

				-- Increase the new boss' power
				local current_power = target:FindModifierByName("modifier_frostivus_boss"):GetStackCount()
				local next_power = math.ceil(current_power * 0.25) + 1
				boss:FindModifierByName("modifier_frostivus_boss"):SetStackCount(current_power + next_power)
			end)

			-- Unlock the arena
			UnlockArena(self.altar_handle, true, self.team, "frostivus_altar_aura_zeus")

			-- Delete the boss AI thinker modifier
			target:RemoveModifierByName("boss_thinker_zeus")
		end
	end
end

-----------------------------------------------------------------------

function boss_thinker_zeus:OnIntervalThink()
	if IsServer() then

		-- Parameters
		local boss = self:GetParent()
		local altar_entity = Entities:FindByName(nil, self.altar_handle)
		local altar_loc = altar_entity:GetAbsOrigin()
		local power_stacks = boss:FindModifierByName("modifier_frostivus_boss"):GetStackCount()

		-- Sends boss health information to fighting team's clients
		UpdateBossBar(boss)
		CustomGameEventManager:Send_ServerToTeam(self.team, "OnAltarContestThink", {boss_name = self.boss_name, health = boss:GetHealth(), max_health = boss:GetMaxHealth()})

		-- Think
		self.boss_timer = self.boss_timer + 0.1

		-- Boss move script
		-- Display of mechanics
		if self.boss_timer > 1 and not self.events[1] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 2, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[1] = true
		end

		if self.boss_timer > 4 and not self.events[2] then
			self:ArcLightning(altar_loc, altar_entity, 1.0, math.max(1.1 - power_stacks * 0.05, 0.6), 425, 40, 30 + power_stacks)
			self.events[2] = true
		end

		if self.boss_timer > 6 and not self.events[3] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[3] = true
			end
		end

		if self.boss_timer > 10 and not self.events[4] then
			self:StaticField(altar_loc, altar_entity, 1.5, 300, 120)
			self.events[4] = true
		end

		if self.boss_timer > 13 and not self.events[5] then
			self:GodsWrath(altar_loc, altar_entity, 2.5, math.min(100 + 10 * power_stacks, 200), 80)
			self.events[5] = true
		end

		-- Bolt + Thor
		if self.boss_timer > 18 and not self.events[6] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 3, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[6] = true
		end

		if self.boss_timer > 19 and not self.events[7] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[7] = true
			end
		end

		-- Arc + Thor
		if self.boss_timer > 24 and not self.events[8] then
			self:ArcLightning(altar_loc, altar_entity, 1.0, math.max(1.1 - power_stacks * 0.05, 0.6), 425, 40, 30 + power_stacks)
			self.events[8] = true
		end

		if self.boss_timer > 25 and not self.events[9] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[9] = true
			end
		end

		-- Static + double Bolt + Thor + Arc
		if self.boss_timer > 29 and not self.events[10] then
			self:StaticField(altar_loc, altar_entity, 1.5, 300, 120)
			self.events[10] = true
		end

		if self.boss_timer > 31 and not self.events[11] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 3, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[11] = true
		end

		if self.boss_timer > 33 and not self.events[12] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 3, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[12] = true
		end

		if self.boss_timer > 35 and not self.events[13] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[13] = true
			end
		end

		if self.boss_timer > 37 and not self.events[14] then
			self:ArcLightning(altar_loc, altar_entity, 1.0, math.max(1.1 - power_stacks * 0.05, 0.6), 425, 40, 30 + power_stacks)
			self.events[14] = true
		end

		-- Wrath to clear static
		if self.boss_timer > 40 and not self.events[15] then
			self:GodsWrath(altar_loc, altar_entity, 2.5, math.min(100 + 10 * power_stacks, 200), 80)
			self.events[15] = true
		end

		-- Static + Thor + Bolt
		if self.boss_timer > 45 and not self.events[16] then
			self:StaticField(altar_loc, altar_entity, 1.5, 300, 120)
			self.events[16] = true
		end

		if self.boss_timer > 47 and not self.events[17] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[17] = true
			end
		end

		if self.boss_timer > 49 and not self.events[18] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 3, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[18] = true
		end

		-- Arc + Thor
		if self.boss_timer > 52 and not self.events[19] then
			self:ArcLightning(altar_loc, altar_entity, 1.0, math.max(1.1 - power_stacks * 0.05, 0.6), 425, 40, 30 + power_stacks)
			self.events[19] = true
		end

		if self.boss_timer > 52 and not self.events[20] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[20] = true
			end
		end

		-- Triple bolt
		if self.boss_timer > 54 and not self.events[21] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 4, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[21] = true
		end

		if self.boss_timer > 56 and not self.events[22] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 4, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[22] = true
		end

		if self.boss_timer > 58 and not self.events[23] then
			self:LightningBolt(altar_loc, altar_entity, RandomInt(1, 360), math.min(power_stacks + 4, 12), 2.5, 175, 350, 120, 200, 800, true)
			self.events[23] = true
		end

		-- Thor + Arc + Thor + Arc
		if self.boss_timer > 62 and not self.events[24] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[24] = true
			end
		end

		if self.boss_timer > 64 and not self.events[25] then
			self:ArcLightning(altar_loc, altar_entity, 1.0, math.max(1.1 - power_stacks * 0.05, 0.6), 425, 40, 30 + power_stacks)
			self.events[25] = true
		end

		if self.boss_timer > 67 and not self.events[26] then
			-- Find random target hero to attack
			local target = false
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), altar_loc, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				if enemy:HasModifier("modifier_fighting_boss") then
					target = enemy
					break
				end
			end
			if target then
				self:ElThor(altar_entity, target, math.max(400 - 7 * power_stacks, 325), 3.0, 350)
				self.events[26] = true
			end
		end

		if self.boss_timer > 69 and not self.events[27] then
			self:ArcLightning(altar_loc, altar_entity, 1.0, math.max(1.1 - power_stacks * 0.05, 0.6), 425, 40, 30 + power_stacks)
			self.events[27] = true
		end

		if self.boss_timer > 72 and not self.events[28] then
			self:GodsWrath(altar_loc, altar_entity, 2.5, math.min(100 + 10 * power_stacks, 200), 80)
			self.events[28] = true
		end

		-- Bolt spam
		if self.boss_timer > 77 and not self.events[29] then
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[1], 3, 3.5, 175, 350, 120, 200, 200, true)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[1] + 15, 4, 3.5, 175, 350, 120, 400, 400, false)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[1] + 30, 5, 3.5, 175, 350, 120, 600, 600, false)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[1] + 45, 6, 3.5, 175, 350, 120, 800, 800, false)
			self.events[29] = true
		end

		if self.boss_timer > 78 and not self.events[30] then
			self:ArcLightning(altar_loc, altar_entity, 2.5, math.max(1.1 - power_stacks * 0.05, 0.6), 425, 40, 30 + power_stacks)
			self.events[30] = true
		end

		-- Bolt spam 2
		if self.boss_timer > 83 and not self.events[31] then
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[2], 10, 3.5, 175, 350, 120, 800, 800, true)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[2] - 10, 9, 3.5, 175, 350, 120, 725, 725, false)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[2] - 20, 8, 3.5, 175, 350, 120, 650, 650, false)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[2] - 30, 7, 3.5, 175, 350, 120, 575, 575, false)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[2] - 40, 6, 3.5, 175, 350, 120, 500, 500, false)
			self:LightningBolt(altar_loc, altar_entity, self.random_constants[2] - 50, 5, 3.5, 175, 350, 120, 425, 425, false)
			self.events[31] = true
		end

		-- Static + double Bolt + Thor + Arc
		if self.boss_timer > 84 and not self.events[32] then
			self:StaticField(altar_loc, altar_entity, 4.0, 300, 120)
			self.events[32] = true
		end

		-- Enrage
		if self.boss_timer > 88 then
			self:GodsWrath(altar_loc, altar_entity, 10.0, 900, 300)
			self.boss_timer = self.boss_timer - 2
		end
	end
end

---------------------------
-- Zeus' moves
---------------------------

function boss_thinker_zeus:LightningBolt(center_point, altar_handle, angle, amount, delay, inner_radius, outer_radius, damage, min_radius, max_radius, cast_bar)
	local boss = self:GetParent()
	local bolt_damage = boss:GetAttackDamage() * damage * 0.01

	-- Warnings
	if cast_bar then

		-- Send cast bar event
		CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "boss_zeus_lightning_bolt", cast_time = delay})

		-- Play warning sound
		altar_handle:EmitSound("Hero_Disruptor.KineticField")
	end

	-- Define bolt positions
	local bolt_positions = {}
	for i = 1, amount do
		bolt_positions[i] = RotatePosition(center_point, QAngle(0, angle + (i - 1) * 360 / amount, 0), center_point + Vector(0, 1, 0) * RandomInt(min_radius, max_radius))
	end

	-- Draw particles
	for _, bolt_position in pairs(bolt_positions) do
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_zeus/lightning_bolt_marker.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(warning_pfx, 0, bolt_position)
		ParticleManager:SetParticleControl(warning_pfx, 1, Vector(delay, 0, 0))
		ParticleManager:ReleaseParticleIndex(warning_pfx)
	end

	-- Move boss to cast position and animate cast
	boss:MoveToPosition(center_point + Vector(0, 300, 0))
	boss:FaceTowards(center_point)
	Timers:CreateTimer(delay - 0.4, function()
		StartAnimation(boss, {duration = 0.83, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- If the fight is over, do nothing
		if not altar_handle:HasModifier("modifier_altar_active") then
			return nil
		end

		-- Sounds
		if cast_bar then

			-- Play bolt cast sound
			altar_handle:EmitSound("Hero_Zuus.LightningBolt.Cast")

			-- Impact sound
			altar_handle:EmitSound("Hero_Zuus.LightningBolt")
		end

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
				SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
			end
		end
	end)
end

-- Arc Lightning
function boss_thinker_zeus:ArcLightning(center_point, altar_handle, cast_delay, bounce_delay, bounce_radius, damage, damage_ramp)
	local boss = self:GetParent()
	local boss_position = boss:GetAbsOrigin()
	local chain_damage = boss:GetAttackDamage() * damage * 0.01
	local chain_target = false

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "boss_zeus_arc_lightning", cast_time = delay})

	-- Find nearest target hero to attack
	local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_position, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
	for _,enemy in pairs(nearby_enemies) do
		if enemy:HasModifier("modifier_fighting_boss") then
			chain_target = enemy
			break
		end
	end

	-- If there's no valid target, stop casting
	if not chain_target then
		return nil
	end

	-- Move boss to cast position and animate cast
	local chain_target_position = chain_target:GetAbsOrigin()
	boss:MoveToPosition(chain_target_position + (boss_position - chain_target_position):Normalized() * 300)
	boss:FaceTowards(chain_target_position)
	Timers:CreateTimer(cast_delay - 0.2, function()
		StartAnimation(boss, {duration = 0.83, activity=ACT_DOTA_CAST_ABILITY_1, rate=1.0})
	end)

	-- Wait [cast_delay] seconds
	Timers:CreateTimer(cast_delay, function()

		-- If the fight is over, do nothing
		if not altar_handle:HasModifier("modifier_altar_active") then
			return nil
		end

		-- Throw initial bounce
		boss:EmitSound("Hero_Zuus.ArcLightning.Cast")
		self:ArcLightningBounce(altar_handle, boss, chain_target, chain_damage, damage_ramp, bounce_radius, bounce_delay)
	end)
end

function boss_thinker_zeus:ArcLightningBounce(altar_handle, source, target, damage, damage_ramp, bounce_radius, bounce_delay)
	local boss = self:GetParent()
	local target_location = target:GetAbsOrigin() 

	-- If the fight is over, do nothing
	if not altar_handle:HasModifier("modifier_altar_active") then
		return nil
	end

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
			if enemy:HasModifier("modifier_fighting_boss") and enemy ~= target then
				self:ArcLightningBounce(altar_handle, target, enemy, damage * (1 + damage_ramp * 0.01), damage_ramp, bounce_radius, bounce_delay)
				break
			end
		end
	end)
end

-- El Thor
function boss_thinker_zeus:ElThor(altar_handle, target, radius, delay, damage)
	local boss = self:GetParent()
	local thor_damage = boss:GetAttackDamage() * damage * 0.01

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "boss_zeus_el_thor", cast_time = delay})

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
	Timers:CreateTimer(delay - 0.63, function()
		boss:FaceTowards(boss:GetAbsOrigin() + (target:GetAbsOrigin() - boss:GetAbsOrigin()):Normalized())
		StartAnimation(boss, {duration = 1.0, activity=ACT_DOTA_ATTACK, rate=1.0})
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- If the fight is over, do nothing
		if not altar_handle:HasModifier("modifier_altar_active") then
			return nil
		end

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
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), target:GetAbsOrigin(), nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		local enemies_to_hit = {}
		for _, enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_fighting_boss") then
				enemies_to_hit[#enemies_to_hit+1] = enemy
			end
		end

		-- Damage enemies
		thor_damage = thor_damage / #enemies_to_hit
		for _, victim in pairs(enemies_to_hit) do
			local damage_dealt = ApplyDamage({victim = victim, attacker = boss, ability = nil, damage = thor_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(victim, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, damage_dealt, nil)
		end
	end)
end

-- Static Field
function boss_thinker_zeus:StaticField(center_point, altar_handle, delay, radius, damage)
	local boss = self:GetParent()
	local field_damage = boss:GetAttackDamage() * damage * 0.01

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "boss_zeus_static_field", cast_time = delay})

	-- Move boss to cast position and animate cast
	boss:MoveToPosition(center_point + Vector(0, 300, 0))
	boss:FaceTowards(center_point)
	Timers:CreateTimer(delay - 0.6, function()
		StartAnimation(boss, {duration = 0.84, activity=ACT_DOTA_CAST_ABILITY_4, rate=1.0})
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- If the fight is over, do nothing
		if not altar_handle:HasModifier("modifier_altar_active") then
			return nil
		end

		-- Play cast sound
		altar_handle:EmitSound("Hero_Zuus.StaticField")

		-- Debuff players with alternating charges
		local positive = true
		if RollPercentage(50) then
			positive = false
		end
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _, enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_fighting_boss") then

				-- Particle & modifier
				if positive then
					positive = false
					enemy:AddNewModifier(boss, nil, "modifier_frostivus_zeus_positive_charge", {radius = radius, damage = field_damage})
					local static_pfx = ParticleManager:CreateParticle("particles/econ/events/ti6/maelstorm_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
					ParticleManager:SetParticleControlEnt(static_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_attack1", boss:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(static_pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
					ParticleManager:ReleaseParticleIndex(static_pfx)
				else
					positive = true
					enemy:AddNewModifier(boss, nil, "modifier_frostivus_zeus_negative_charge", {radius = radius, damage = field_damage})
					local static_pfx = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, enemy)
					ParticleManager:SetParticleControlEnt(static_pfx, 0, boss, PATTACH_POINT_FOLLOW, "attach_attack2", boss:GetAbsOrigin(), true)
					ParticleManager:SetParticleControlEnt(static_pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy:GetAbsOrigin(), true)
					ParticleManager:ReleaseParticleIndex(static_pfx)
				end
			end
		end
	end)
end

-- Static Field positive modifier
LinkLuaModifier("modifier_frostivus_zeus_positive_charge", "boss_scripts/boss_thinker_zeus.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_zeus_positive_charge = modifier_frostivus_zeus_positive_charge or class({})

function modifier_frostivus_zeus_positive_charge:IsHidden() return true end
function modifier_frostivus_zeus_positive_charge:IsPurgable() return false end
function modifier_frostivus_zeus_positive_charge:IsDebuff() return false end

function modifier_frostivus_zeus_positive_charge:OnCreated(keys)
	if IsServer() then

		-- Particle
		local parent = self:GetParent()
		self.positive_pfx = ParticleManager:CreateParticle("particles/econ/events/ti6/mjollnir_shield_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(self.positive_pfx, 0, parent:GetAbsOrigin())

		-- Parameters
		self.charged = true
		self.radius = 0
		self.damage = 0
		if keys.radius then
			self.radius = keys.radius
		end
		if keys.damage then
			self.damage = keys.damage
		end
		self:StartIntervalThink(0.03)
	end
end

function modifier_frostivus_zeus_positive_charge:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.positive_pfx, true)
		ParticleManager:ReleaseParticleIndex(self.positive_pfx)
	end
end

function modifier_frostivus_zeus_positive_charge:OnIntervalThink()
	if IsServer() and self.charged then

		-- Search for nearby charged enemies
		local boss = self:GetCaster()
		local owner = self:GetParent()
		local owner_position = owner:GetAbsOrigin()
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), owner_position, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for _, enemy in pairs(nearby_enemies) do
			if enemy ~= owner and (enemy:HasModifier("modifier_frostivus_zeus_positive_charge") or enemy:HasModifier("modifier_frostivus_zeus_negative_charge")) then
				self.charged = false

				-- Sound
				enemy:EmitSound("Item.Maelstrom.Chain_Lightning")

				-- Particle
				local enemy_position = enemy:GetAbsOrigin()
				local discharge_pfx = ParticleManager:CreateParticle("particles/econ/events/ti6/maelstorm_ti6.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
				ParticleManager:SetParticleControlEnt(discharge_pfx, 0, owner, PATTACH_POINT_FOLLOW, "attach_hitloc", owner_position, true)
				ParticleManager:SetParticleControlEnt(discharge_pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy_position, true)
				ParticleManager:ReleaseParticleIndex(discharge_pfx)

				-- Damage
				local damage_dealt = ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
				SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, owner, damage_dealt, nil)

				-- Destroy this modifier after a small duration
				Timers:CreateTimer(0.7, function()
					owner:RemoveModifierByName("modifier_frostivus_zeus_positive_charge")
				end)

				-- Knockback
				local discharge_knockback = {}
				if enemy:HasModifier("modifier_frostivus_zeus_positive_charge") then
					discharge_knockback =
					{
						center_x = enemy_position.x,
						center_y = enemy_position.y,
						center_z = enemy_position.z,
						duration = 0.35,
						knockback_duration = 0.35,
						knockback_distance = 300,
						knockback_height = 70,
						should_stun = 1
					}
				elseif enemy:HasModifier("modifier_frostivus_zeus_negative_charge") then
					local knockback_origin = owner_position + (owner_position - enemy_position):Normalized() * 100
					local distance = (owner_position - enemy_position):Length2D() * 0.5
					discharge_knockback =
					{
						center_x = knockback_origin.x,
						center_y = knockback_origin.y,
						center_z = knockback_origin.z,
						duration = 0.2,
						knockback_duration = 0.2,
						knockback_distance = distance,
						knockback_height = 40,
						should_stun = 1
					}
				end
				owner:RemoveModifierByName("modifier_knockback")
				owner:AddNewModifier(nil, nil, "modifier_knockback", discharge_knockback)

				-- Stop looking for charged enemies
				break
			end
		end
	end
end

-- Static Field negative modifier
LinkLuaModifier("modifier_frostivus_zeus_negative_charge", "boss_scripts/boss_thinker_zeus.lua", LUA_MODIFIER_MOTION_NONE )
modifier_frostivus_zeus_negative_charge = modifier_frostivus_zeus_negative_charge or class({})

function modifier_frostivus_zeus_negative_charge:IsHidden() return true end
function modifier_frostivus_zeus_negative_charge:IsPurgable() return false end
function modifier_frostivus_zeus_negative_charge:IsDebuff() return false end

function modifier_frostivus_zeus_negative_charge:OnCreated(keys)
	if IsServer() then

		-- Particle
		local parent = self:GetParent()
		self.negative_pfx = ParticleManager:CreateParticle("particles/econ/events/ti7/mjollnir_shield_ti7.vpcf", PATTACH_ABSORIGIN_FOLLOW, parent)
		ParticleManager:SetParticleControl(self.negative_pfx, 0, parent:GetAbsOrigin())

		-- Parameters
		self.charged = true
		self.radius = 0
		self.damage = 0
		if keys.radius then
			self.radius = keys.radius
		end
		if keys.damage then
			self.damage = keys.damage
		end
		self:StartIntervalThink(0.03)
	end
end

function modifier_frostivus_zeus_negative_charge:OnDestroy()
	if IsServer() then
		ParticleManager:DestroyParticle(self.negative_pfx, true)
		ParticleManager:ReleaseParticleIndex(self.negative_pfx)
	end
end

function modifier_frostivus_zeus_negative_charge:OnIntervalThink()
	if IsServer() and self.charged then

		-- Search for nearby charged enemies
		local boss = self:GetCaster()
		local owner = self:GetParent()
		local owner_position = owner:GetAbsOrigin()
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), owner_position, nil, self.radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for _, enemy in pairs(nearby_enemies) do
			if enemy ~= owner and (enemy:HasModifier("modifier_frostivus_zeus_positive_charge") or enemy:HasModifier("modifier_frostivus_zeus_negative_charge")) then
				self.charged = false

				-- Sound
				enemy:EmitSound("Item.Maelstrom.Chain_Lightning")

				-- Particle
				local enemy_position = enemy:GetAbsOrigin()
				local discharge_pfx = ParticleManager:CreateParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_ABSORIGIN_FOLLOW, owner)
				ParticleManager:SetParticleControlEnt(discharge_pfx, 0, owner, PATTACH_POINT_FOLLOW, "attach_hitloc", owner_position, true)
				ParticleManager:SetParticleControlEnt(discharge_pfx, 1, enemy, PATTACH_POINT_FOLLOW, "attach_hitloc", enemy_position, true)
				ParticleManager:ReleaseParticleIndex(discharge_pfx)

				-- Damage
				local damage_dealt = ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
				SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, owner, damage_dealt, nil)

				-- Destroy this modifier after a small duration
				Timers:CreateTimer(0.7, function()
					owner:RemoveModifierByName("modifier_frostivus_zeus_negative_charge")
				end)

				-- Knockback
				local discharge_knockback = {}
				if enemy:HasModifier("modifier_frostivus_zeus_negative_charge") then
					discharge_knockback =
					{
						center_x = enemy_position.x,
						center_y = enemy_position.y,
						center_z = enemy_position.z,
						duration = 0.35,
						knockback_duration = 0.35,
						knockback_distance = 300,
						knockback_height = 70,
						should_stun = 1
					}
				elseif enemy:HasModifier("modifier_frostivus_zeus_positive_charge") then
					local knockback_origin = owner_position + (owner_position - enemy_position):Normalized() * 100
					local distance = (owner_position - enemy_position):Length2D() * 0.5
					discharge_knockback =
					{
						center_x = knockback_origin.x,
						center_y = knockback_origin.y,
						center_z = knockback_origin.z,
						duration = 0.2,
						knockback_duration = 0.2,
						knockback_distance = distance,
						knockback_height = 40,
						should_stun = 1
					}
				end
				owner:RemoveModifierByName("modifier_knockback")
				owner:AddNewModifier(nil, nil, "modifier_knockback", discharge_knockback)

				-- Stop looking for charged enemies
				break
			end
		end
	end
end

-- God's Wrath
function boss_thinker_zeus:GodsWrath(center_point, altar_handle, delay, charge_movement, damage)
	local boss = self:GetParent()
	local wrath_damage = boss:GetAttackDamage() * damage * 0.01

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "boss_zeus_thundergod_wrath", cast_time = delay})

	-- Play warning sound
	altar_handle:EmitSound("Hero_Zuus.GodsWrath.PreCast")

	-- Move boss to cast position and animate cast
	boss:MoveToPosition(center_point + Vector(0, 300, 0))
	boss:FaceTowards(center_point)
	Timers:CreateTimer(delay - 0.4, function()
		StartAnimation(boss, {duration = 0.83, activity=ACT_DOTA_CAST_ABILITY_5, rate=1.0})
	end)

	-- Pre-cast sound
	Timers:CreateTimer(delay - 0.4, function()
		if altar_handle:HasModifier("modifier_altar_active") then
			altar_handle:EmitSound("Hero_Zuus.GodsWrath.PreCast")
		end
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- If the fight is over, do nothing
		if not altar_handle:HasModifier("modifier_altar_active") then
			return nil
		end

		-- Play cast sound
		altar_handle:EmitSound("Hero_Zuus.GodsWrath")

		-- Cast particle
		local boss_position = boss:GetAbsOrigin()
		local wrath_pfx = ParticleManager:CreateParticle("particles/econ/items/zeus/arcana_chariot/zeus_arcana_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN_FOLLOW, boss)
		ParticleManager:SetParticleControl(wrath_pfx, 0, boss_position + Vector(0, 0, 400))
		ParticleManager:SetParticleControl(wrath_pfx, 1, boss_position)
		ParticleManager:ReleaseParticleIndex(wrath_pfx)

		-- Iterate through enemies
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
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

			-- Resolve static field, if appropriate
			if enemy:HasModifier("modifier_frostivus_zeus_positive_charge") or enemy:HasModifier("modifier_frostivus_zeus_negative_charge") then
				self:GodsWrathMovement(center_point, enemy, charge_movement)
			end
		end
	end)
end

-- God's Wrath charge-based movement
function boss_thinker_zeus:GodsWrathMovement(center_point, target, charge_movement)
	local boss = self:GetParent()
	local target_position = target:GetAbsOrigin()
	local total_movement = Vector(0, 0, 0)
	local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
	for _, enemy in pairs(nearby_enemies) do
		if (target:HasModifier("modifier_frostivus_zeus_positive_charge") and enemy:HasModifier("modifier_frostivus_zeus_negative_charge")) or (target:HasModifier("modifier_frostivus_zeus_negative_charge") and enemy:HasModifier("modifier_frostivus_zeus_positive_charge")) then
			total_movement = total_movement + (enemy:GetAbsOrigin() - target_position):Normalized() * charge_movement
		elseif  (target:HasModifier("modifier_frostivus_zeus_positive_charge") and enemy:HasModifier("modifier_frostivus_zeus_positive_charge")) or (target:HasModifier("modifier_frostivus_zeus_negative_charge") and enemy:HasModifier("modifier_frostivus_zeus_negative_charge")) then
			total_movement = total_movement + (target_position - enemy:GetAbsOrigin()):Normalized() * charge_movement
		end
		Timers:CreateTimer(0.5, function()
			enemy:RemoveModifierByName("modifier_frostivus_zeus_positive_charge")
			enemy:RemoveModifierByName("modifier_frostivus_zeus_negative_charge")
		end)
	end

	-- If there's any movement to be done apply the relevant knockback
	if total_movement ~= Vector(0, 0, 0) then
		local knockback_origin = target_position - total_movement:Normalized() * 100
		local charge_knockback = {
			center_x = knockback_origin.x,
			center_y = knockback_origin.y,
			center_z = knockback_origin.z,
			duration = 0.3,
			knockback_duration = 0.3,
			knockback_distance = total_movement:Length2D(),
			knockback_height = 50,
			should_stun = 1
		}
		target:RemoveModifierByName("modifier_knockback")
		target:AddNewModifier(nil, nil, "modifier_knockback", charge_knockback)
	end
end