-- Venomancer AI thinker

boss_thinker_venomancer = class({})

-----------------------------------------------------------------------

function boss_thinker_venomancer:IsHidden()
	return true
end

-----------------------------------------------------------------------

function boss_thinker_venomancer:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function boss_thinker_venomancer:OnCreated( params )
	if IsServer() then
		self.boss_name = "venomancer"
		self.team = "no team passed"
		self.altar_handle = "no altar handle passed"
		if params.team then
			self.team = params.team
		end
		if params.altar_handle then
			self.altar_handle = params.altar_handle
		end

		-- Start thinking
		self.boss_timer = 0
		self.events = {}
		self:StartIntervalThink(0.1)
	end
end

-----------------------------------------------------------------------

function boss_thinker_venomancer:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

-----------------------------------------------------------------------

function boss_thinker_venomancer:OnDeath(keys)
local target = keys.unit

	if IsServer() then

		-- Boss death
		if target == self:GetParent() then

			-- Notify the console that a boss fight (capture attempt) has ended with a successful kill
			print(self.boss_name.." boss is dead, winning team is "..self.team)

			-- Send the boss death event to all clients
			CustomGameEventManager:Send_ServerToTeam(self.team, "AltarContestEnd", {win = true})

			-- Respawn the boss and grant it its new capture detection modifier
			local boss
			Timers:CreateTimer(5, function()
				boss = SpawnVenomancer(self.altar_handle)

				-- Increase the new boss' power
				local current_power = target:FindModifierByName("modifier_frostivus_boss"):GetStackCount()
				local next_power = math.ceil(current_power * 0.25) + 1
				boss:FindModifierByName("modifier_frostivus_boss"):SetStackCount(current_power + next_power)
			end)

			-- Clear any ongoing modifiers
			local nearby_enemies = FindUnitsInRadius(target:GetTeam(), target:GetAbsOrigin(), nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
			for _,enemy in pairs(nearby_enemies) do
				enemy:RemoveModifierByName("modifier_frostivus_venomancer_poison_sting_debuff")
			end

			-- Destroy any existing adds
			local nearby_summons = FindUnitsInRadius(target:GetTeam(), target:GetAbsOrigin(), nil, 1800, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
			for _,summon in pairs(nearby_summons) do
				summon:Kill(nil, summon)
			end

			-- Unlock the arena
			UnlockArena(self.altar_handle, true, self.team)

			-- Delete the boss AI thinker modifier
			target:RemoveModifierByName("boss_thinker_venomancer")
		end
	end
end

-----------------------------------------------------------------------

function boss_thinker_venomancer:OnIntervalThink()
	if IsServer() then

		-- Parameters
		local boss = self:GetParent()
		local altar_entity = Entities:FindByName(nil, self.altar_handle)
		local altar_loc = altar_entity:GetAbsOrigin()
		local power_stacks = boss:FindModifierByName("modifier_frostivus_boss"):GetStackCount()

		-- Sends boss health information to fighting team's clients
		CustomGameEventManager:Send_ServerToTeam(self.team, "OnAltarContestThink", {boss_name = self.boss_name, health = boss:GetHealth(), max_health = boss:GetMaxHealth()})

		-- Think
		self.boss_timer = self.boss_timer + 0.1

		-- Boss move script
		-- Test of mechanics
		if self.boss_timer > 2 and not self.events[1] then
			self:VenomousGale(altar_loc, altar_entity, 3.0, RandomInt(0, 359), math.max(-24 - power_stacks * 4, -80), 100, 10, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[1] = true
		end

		if self.boss_timer > 6 and not self.events[2] then
			self:VenomousGale(altar_loc, altar_entity, 3.0, RandomInt(0, 359), math.max(-24 - power_stacks * 4, -80), 100, 10, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[2] = true
		end

		-- Repeat
		if self.boss_timer > 10 then
			self.boss_timer = 0
			self.events[1] = false
			self.events[2] = false
			self.events[3] = false
		end

		if self.boss_timer > 15 and not self.events[1] then
			self:SpawnScourgeWard(altar_loc, altar_entity, 1.0, 0, 700, math.min(5 + 0.4 * power_stacks, 10), 4, 3, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[1] = true
		end

		if self.boss_timer > 16 and not self.events[2] then
			self:SpawnVileWard(altar_loc, altar_entity, 1.0, 0, 400, math.min(8 + 0.5 * power_stacks, 15), 4, 8, 250, 800, math.min(2 + 0.25 * power_stacks, 5), 6, math.max(1.75 - 0.05 * power_stacks, 1.0), 4)
			self.events[2] = true
		end


	end
end

---------------------------
-- Veno's moves
---------------------------

-- Venomous Gale
function boss_thinker_venomancer:VenomousGale(center_point, altar_handle, delay, angle, slow, damage, duration, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
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
		CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_veno_venomous_gale", cast_time = delay})

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(move_position)
		Timers:CreateTimer(delay - 1.0, function()
			boss:FaceTowards(boss:GetAbsOrigin() + (target:GetAbsOrigin() - boss:GetAbsOrigin()):Normalized())
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
			self:VenomousGaleShoot(boss, ability, boss:GetAbsOrigin(), target:GetAbsOrigin(), slow, damage, duration)
		end)
	end
end

function boss_thinker_venomancer:VenomousGaleShoot(boss, ability, source, target, slow, damage, duration)
end

-- Spawn Scourge Ward
function boss_thinker_venomancer:SpawnScourgeWard(center_point, altar_handle, delay, angle, center_distance, health, attack_delay, attack_count, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ward_position = RotatePosition(center_point, QAngle(0, angle, 0), center_point + Vector(0, 1, 0) * center_distance)
		local ward_health = boss:GetMaxHealth() * health * 0.01

		-- Send cast bar event
		CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_veno_scourge_ward", cast_time = delay})

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(center_point + Vector(0, 300, 0))
		Timers:CreateTimer(delay - 0.4, function()
			boss:FaceTowards(Vector(0, -1, 0))
			StartAnimation(boss, {duration = 0.63, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Spawn ward
			local scourge_ward = CreateUnitByName("npc_frostivus_scourge_ward", ward_position, true, boss, boss, DOTA_TEAM_NEUTRALS)

			-- Adjust ward health
			scourge_ward:SetBaseMaxHealth(ward_health)
			scourge_ward:SetMaxHealth(ward_health)
			scourge_ward:SetHealth(ward_health)

			-- Add ward passive modifiers
			--scourge_ward:AddNewModifier(nil, nil, "modifier_frostivus_venomancer_scourge_ward_thinker", {damage = sting_damage, attack_delay = attack_delay, debuff_duration = duration, center_x = center_point.x, center_y = center_point.y, center_z = center_point.z})

			-- Play ward spawn sound
			scourge_ward:EmitSound("Hero_Viper.Nethertoxin.Cast")
		end)
	end
end

-- Spawn Vile Ward
function boss_thinker_venomancer:SpawnVileWard(center_point, altar_handle, delay, angle, center_distance, health, attack_delay, attack_count, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)
	if IsServer() then
		local boss = self:GetParent()
		local ward_position = RotatePosition(center_point, QAngle(0, angle, 0), center_point + Vector(0, 1, 0) * center_distance)
		local ward_health = boss:GetMaxHealth() * health * 0.01

		-- Send cast bar event
		CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_veno_vile_ward", cast_time = delay})

		-- Move boss to cast position and animate cast
		boss:MoveToPosition(center_point + Vector(0, 300, 0))
		Timers:CreateTimer(delay - 0.4, function()
			boss:FaceTowards(Vector(0, -1, 0))
			StartAnimation(boss, {duration = 0.63, activity=ACT_DOTA_CAST_ABILITY_3, rate=1.0})
		end)

		-- Wait [delay] seconds
		Timers:CreateTimer(delay, function()

			-- Proc passive
			self:SpawnPlagueWard(center_point, altar_handle, plague_inner_radius, plague_outer_radius, plague_health, plague_damage, plague_attack_delay, plague_duration)

			-- Spawn ward
			local vile_ward = CreateUnitByName("npc_frostivus_vile_ward", ward_position, true, boss, boss, DOTA_TEAM_NEUTRALS)

			-- Adjust ward health
			vile_ward:SetBaseMaxHealth(ward_health)
			vile_ward:SetMaxHealth(ward_health)
			vile_ward:SetHealth(ward_health)

			-- Add ward passive modifiers
			--vile_ward:AddNewModifier(nil, nil, "modifier_frostivus_venomancer_vile_ward_thinker", {damage = sting_damage, attack_delay = attack_delay, debuff_duration = duration, center_x = center_point.x, center_y = center_point.y, center_z = center_point.z})

			-- Play ward spawn sound
			vile_ward:EmitSound("Hero_Viper.Nethertoxin.Cast")
		end)
	end
end

-- Spawn Plague Ward passive
function boss_thinker_venomancer:SpawnPlagueWard(center_point, altar_handle, inner_radius, outer_radius, health, damage, attack_delay, duration)
	if IsServer() then
		local boss = self:GetParent()
		local sting_damage = boss:GetAttackDamage() * damage * 0.01
		local ward_position = center_point + RandomVector(100):Normalized() * RandomInt(inner_radius, outer_radius)
		local ward_health = boss:GetMaxHealth() * health * 0.01

		-- Spawn ward
		local plague_ward = CreateUnitByName("npc_frostivus_plague_ward", ward_position, true, boss, boss, DOTA_TEAM_NEUTRALS)

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
LinkLuaModifier("modifier_frostivus_venomancer_ward_poison_sting", "boss_scripts/boss_thinker_venomancer.lua", LUA_MODIFIER_MOTION_NONE )
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
		local nearby_enemies = FindUnitsInRadius(owner:GetTeam(), self.center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		
		-- Spit poison on the first available enemy, if there is one
		for _, enemy in pairs(nearby_enemies) do

			-- Face target
			local target_direction = (enemy:GetAbsOrigin() - owner:GetAbsOrigin()):Normalized()
			owner:FaceTowards(target_direction)

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
LinkLuaModifier("modifier_frostivus_venomancer_poison_sting_debuff", "boss_scripts/boss_thinker_venomancer.lua", LUA_MODIFIER_MOTION_NONE )
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
			ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_POISON_DAMAGE, owner, self.damage, nil)
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



function boss_thinker_venomancer:LightningBolt(center_point, altar_handle, start_direction, amount, delay, inner_radius, outer_radius, damage)
	local boss = self:GetParent()
	local bolt_damage = boss:GetAttackDamage() * damage * 0.01

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_zeus_lightning_bolt", cast_time = delay})

	-- Define bolt positions
	local bolt_positions = {}
	for i = 1, amount do
		bolt_positions[i] = RotatePosition(center_point, QAngle(0, (i - 1) * 360 / amount, 0), center_point + start_direction * RandomInt(200, 800))
	end

	-- Draw particles
	for _, bolt_position in pairs(bolt_positions) do
		local warning_pfx = ParticleManager:CreateParticle("particles/boss_zeus/lightning_bolt_marker.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(warning_pfx, 0, bolt_position)
		ParticleManager:SetParticleControl(warning_pfx, 1, Vector(delay, 0, 0))
		ParticleManager:ReleaseParticleIndex(warning_pfx)
	end

	-- Play warning sound
	altar_handle:EmitSound("Hero_Disruptor.KineticField")

	-- Move boss to cast position and animate cast
	boss:MoveToPosition(center_point + Vector(0, 300, 0))
	Timers:CreateTimer(delay - 0.4, function()
		StartAnimation(boss, {duration = 0.83, activity=ACT_DOTA_CAST_ABILITY_2, rate=1.0})
	end)

	-- Wait [delay] seconds
	Timers:CreateTimer(delay, function()

		-- If the fight is over, do nothing
		if not altar_handle:HasModifier("modifier_altar_active") then
			return nil
		end

		-- Play bolt cast sound
		altar_handle:EmitSound("Hero_Zuus.LightningBolt.Cast")

		-- Resolve bolts
		for _, bolt_position in pairs(bolt_positions) do

			-- Particles
			local bolt_pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_lightning_bolt.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(bolt_pfx, 0, bolt_position)
			ParticleManager:SetParticleControl(bolt_pfx, 1, bolt_position + Vector(0, 0, 1000))
			ParticleManager:ReleaseParticleIndex(bolt_pfx)

			-- Impact sound
			altar_handle:EmitSound("Hero_Zuus.LightningBolt")

			-- Damage enemies
			local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), bolt_position, nil, outer_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
			for _, enemy in pairs(nearby_enemies) do
				local distance = (bolt_position - enemy:GetAbsOrigin()):Length2D()
				local enemy_damage = bolt_damage
				if distance > inner_radius and distance <= outer_radius then
					enemy_damage = enemy_damage * (outer_radius - distance) / (outer_radius - inner_radius)
				end
				ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = enemy_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
				SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, enemy_damage, nil)
			end
		end
	end)
end

-- Arc Lightning
function boss_thinker_venomancer:ArcLightning(center_point, altar_handle, cast_delay, bounce_delay, bounce_radius, damage, damage_ramp)
	local boss = self:GetParent()
	local boss_position = boss:GetAbsOrigin()
	local chain_damage = boss:GetAttackDamage() * damage * 0.01
	local chain_target = false

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_zeus_arc_lightning", cast_time = delay})

	-- Find nearest target hero to attack
	local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), boss_position, nil, 1800, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
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

function boss_thinker_venomancer:ArcLightningBounce(altar_handle, source, target, damage, damage_ramp, bounce_radius, bounce_delay)
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
	ApplyDamage({attacker = boss, victim = target, ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
	SendOverheadEventMessage(target, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, target, damage, nil)

	-- Perform another bounce, if applicable
	Timers:CreateTimer(bounce_delay, function()
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), target_location, nil, bounce_radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
		for _,enemy in pairs(nearby_enemies) do
			if enemy:HasModifier("modifier_fighting_boss") and enemy ~= target then
				self:ArcLightningBounce(target, enemy, damage * (1 + damage_ramp * 0.01), damage_ramp, bounce_radius, bounce_delay)
				break
			end
		end
	end)
end

-- El Thor
function boss_thinker_venomancer:ElThor(altar_handle, target, radius, delay, damage)
	local boss = self:GetParent()
	local thor_damage = boss:GetAttackDamage() * damage * 0.01

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_zeus_el_thor", cast_time = delay})

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
		boss:FaceTowards((target:GetAbsOrigin() - boss:GetAbsOrigin()):Normalized())
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
			ApplyDamage({victim = victim, attacker = boss, ability = nil, damage = thor_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(victim, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, victim, thor_damage, nil)
		end
	end)
end

-- Static Field
function boss_thinker_venomancer:StaticField(center_point, altar_handle, delay, radius, damage)
	local boss = self:GetParent()
	local field_damage = boss:GetAttackDamage() * damage * 0.01

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_zeus_static_field", cast_time = delay})

	-- Move boss to cast position and animate cast
	boss:MoveToPosition(center_point + Vector(0, 300, 0))
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
LinkLuaModifier("modifier_frostivus_zeus_positive_charge", "boss_scripts/boss_thinker_venomancer.lua", LUA_MODIFIER_MOTION_NONE )
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
				ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
				SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, owner, self.damage, nil)

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
LinkLuaModifier("modifier_frostivus_zeus_negative_charge", "boss_scripts/boss_thinker_venomancer.lua", LUA_MODIFIER_MOTION_NONE )
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
				ApplyDamage({victim = owner, attacker = boss, ability = nil, damage = self.damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
				SendOverheadEventMessage(owner, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, owner, self.damage, nil)

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
function boss_thinker_venomancer:GodsWrath(center_point, altar_handle, delay, charge_movement, damage)
	local boss = self:GetParent()
	local wrath_damage = boss:GetAttackDamage() * damage * 0.01

	-- Send cast bar event
	CustomGameEventManager:Send_ServerToTeam(self.team, "BossStartedCast", {boss_name = self.boss_name, ability_name = "#boss_zeus_thundergod_wrath", cast_time = delay})

	-- Play warning sound
	altar_handle:EmitSound("Hero_Zuus.GodsWrath.PreCast")

	-- Move boss to cast position and animate cast
	boss:MoveToPosition(center_point + Vector(0, 300, 0))
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
		local nearby_enemies = FindUnitsInRadius(boss:GetTeam(), center_point, nil, 900, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
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
			ApplyDamage({victim = enemy, attacker = boss, ability = nil, damage = wrath_damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
			SendOverheadEventMessage(enemy, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, wrath_damage, nil)

			-- Resolve static field, if appropriate
			if enemy:HasModifier("modifier_frostivus_zeus_positive_charge") or enemy:HasModifier("modifier_frostivus_zeus_negative_charge") then
				self:GodsWrathMovement(center_point, enemy, charge_movement)
			end
		end
	end)
end

-- God's Wrath charge-based movement
function boss_thinker_venomancer:GodsWrathMovement(center_point, target, charge_movement)
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