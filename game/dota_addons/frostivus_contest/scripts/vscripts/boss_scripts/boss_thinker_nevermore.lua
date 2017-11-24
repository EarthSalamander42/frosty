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
		self.harvest_cooldown = 0
		self.random_constants = {}
		self.random_constants[1] = 1
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
					local win_pfx = ParticleManager:CreateParticleForPlayer("particles/boss_nevermore/screen_nevermore_win.vpcf", PATTACH_EYES_FOLLOW, PlayerResource:GetSelectedHeroEntity(player_id), PlayerResource:GetPlayer(player_id))
					self:AddParticle(win_pfx, false, false, -1, false, false)
					ParticleManager:ReleaseParticleIndex(win_pfx)
					EmitSoundOnClient("greevil_eventend_Stinger", PlayerResource:GetPlayer(player_id))
				end
			end

			-- Drop presents according to boss difficulty
			local current_power = target:FindModifierByName("modifier_frostivus_boss"):GetStackCount()
			local altar_loc = Entities:FindByName(nil, self.altar_handle):GetAbsOrigin()
			local present_amount = 3 + current_power
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
			local greevil = SpawnGreevil(target_loc, RandomInt(2, 3), 255, 100, 0)
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

		-- Soul Harvest logic
		if self.harvest_cooldown > 0 then
			self.harvest_cooldown = self.harvest_cooldown - 0.1
		else
			local nearby_enemies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, boss:GetAbsOrigin(), nil, 550, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_CLOSEST, false)
			if #nearby_enemies >= 1 then

				-- Attack first target
				local damage = boss:GetAttackDamage() * 100 * 0.01 * self:GetNecromasteryAmp()
				self.harvest_cooldown = math.max(4.0 - power_stacks * 0.1, 2.5)
				StartAnimation(boss, {duration = 1.04, activity=ACT_DOTA_ATTACK, rate=1.0})
				Timers:CreateTimer(0.5, function()
					local attack_projectile = {
						Target = nearby_enemies[1],
						Source = boss,
						Ability = boss:FindAbilityByName("frostivus_boss_soul_harvest"),
						EffectName = "particles/econ/items/shadow_fiend/sf_desolation/sf_base_attack_desolation_fire_arcana.vpcf",
						bDodgeable = true,
						bProvidesVision = false,
						bVisibleToEnemies = true,
						bReplaceExisting = false,
						iMoveSpeed = 1200,
						iVisionRadius = 0,
					--	iVisionTeamNumber = boss:GetTeamNumber(),
						ExtraData = {damage = damage}
					}
					ProjectileManager:CreateTrackingProjectile(attack_projectile)
				end)
			end
		end

		-- Think
		self.boss_timer = self.boss_timer + 0.1

		-- Boss move script
		if self.boss_timer > 1 and not self.events[1] then
			self:Raze(altar_entity, altar_loc + RandomVector(100):Normalized() * RandomInt(250, 675), 2.0, 275, 125, true)
			for i = 1, 1 + math.floor(self.random_constants[1] * 0.5) do
				self:Raze(altar_entity, altar_loc + RandomVector(100):Normalized() * RandomInt(250, 675), 2.0, 275, 125, false)
			end
			self.random_constants[1] = self.random_constants[1] + 1
			self.events[1] = true
		end

		if self.boss_timer > 5 then
			self.boss_timer = self.boss_timer - 4
			self.events[1] = false
		end
	end
end

---------------------------
-- Auxiliary stuff
---------------------------

--"particles/econ/items/shadow_fiend/sf_fire_arcana/sf_fire_arcana_requiemofsouls_line.vpcf"

-- Returns current Necromastery bonus damage
function boss_thinker_nevermore:GetNecromasteryAmp()
	return 1 + self:GetParent():FindModifierByName("modifier_frostivus_necromastery"):GetStackCount() * 0.02
end

-- Adds one stack of Necromastery to SF
function boss_thinker_nevermore:ApplyNecromastery(amount)
	for i = 1, amount do
		self:GetParent():FindModifierByName("modifier_frostivus_necromastery"):IncrementStackCount()
	end
end

-- Raze a target location
function boss_thinker_nevermore:Raze(altar_handle, target, delay, radius, damage, play_impact_sound)

	-- Warning sound if delay > 0
	if delay > 0 and play_impact_sound then
		altar_handle:EmitSound("Ability.PreLightStrikeArray")
	end

	-- Show warning pulses
	local warning_pulses = math.floor(delay)
	Timers:CreateTimer(0, function()
		if warning_pulses >= 1 then
			local warning_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/pre_raze.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(warning_pfx, 0, target)
			ParticleManager:SetParticleControl(warning_pfx, 1, Vector(radius, 0, 0))
			ParticleManager:ReleaseParticleIndex(warning_pfx)
		end

		-- If there is more delay, show more pulses. Else, blast away.
		warning_pulses = warning_pulses - 1
		if warning_pulses >= 1 then
			return 1.0
		else

			Timers:CreateTimer(1.0, function()
			
				-- Sound
				if play_impact_sound then
					altar_handle:EmitSound("Hero_Nevermore.Shadowraze")
				end

				-- Particles
				local raze_pfx = ParticleManager:CreateParticle("particles/boss_nevermore/raze_blast.vpcf", PATTACH_WORLDORIGIN, nil)
				ParticleManager:SetParticleControl(raze_pfx, 0, target)
				ParticleManager:SetParticleControl(raze_pfx, 1, Vector(radius, 0, 0))
				ParticleManager:ReleaseParticleIndex(raze_pfx)

				-- Hit enemies
				local hit_enemies = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, target, nil, radius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
				for _, enemy in pairs(hit_enemies) do

					-- Deal damage
					local damage = self:GetParent():GetAttackDamage() * damage * 0.01 * self:GetNecromasteryAmp()
					local damage_dealt = ApplyDamage({victim = enemy, attacker = self:GetParent(), ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)

					-- Apply Necromastery
					self:ApplyNecromastery(1)
				end
			end)
		end
	end)
end