-- Boss-fighting related functions


---------------------
-- Other modifiers
---------------------
LinkLuaModifier("capture_start_trigger", "boss_scripts/capture_start_trigger.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("boss_thinker_zeus", "boss_scripts/boss_thinker_zeus.lua", LUA_MODIFIER_MOTION_NONE )

---------------------
-- Arena lockdown
---------------------

function LockArena(altar, team)
	local altar_handle = Entities:FindByName(nil, altar)
	local altar_loc = altar_handle:GetAbsOrigin()

	-- Particle & Sound
	altar_handle:EmitSound("Hero_Rattletrap.Power_Cogs")
	altar_handle.arena_fence_pfx = ParticleManager:CreateParticle("particles/arena_wall/arena_lock.vpcf", PATTACH_WORLDORIGIN, nil)
	ParticleManager:SetParticleControl(altar_handle.arena_fence_pfx, 0, altar_loc)

	-- Apply altar controller modifier to altar entity
	altar_handle:AddNewModifier(nil, nil, "modifier_altar_active", {team = team})
end

function UnlockArena(altar)
	local altar_handle = Entities:FindByName(nil, altar)
	ParticleManager:DestroyParticle(altar_handle.arena_fence_pfx, true)
	ParticleManager:ReleaseParticleIndex(altar_handle.arena_fence_pfx)

	-- Stop altar controlled modifier
	altar_handle:RemoveModifierByName("modifier_altar_active")
end


-- Fighting boss modifier
LinkLuaModifier("modifier_fighting_boss", "boss_scripts/boss_functions.lua", LUA_MODIFIER_MOTION_NONE )

modifier_fighting_boss = class({})

function modifier_fighting_boss:IsHidden()
	return true
end

function modifier_fighting_boss:IsPurgable()
	return false
end


-- Altar controller modifier
LinkLuaModifier("modifier_altar_active", "boss_scripts/boss_functions.lua", LUA_MODIFIER_MOTION_NONE )

modifier_altar_active = class({})

function modifier_altar_active:IsHidden()
	return true
end

function modifier_altar_active:IsPurgable()
	return false
end

function modifier_altar_active:OnCreated( params )
	if IsServer() then
		self.team = "no team passed"
		if params.team then
			self.team = params.team
		end

		self.fighting_heroes = {}
		self:StartIntervalThink(0.03)
	end
end

function modifier_altar_active:OnDestroy( params )
	if IsServer() then
		-- Clean fighting heroes list
		for _, hero in pairs(self.fighting_heroes) do
			hero:AddExperience(BASE_BOSS_EXP_REWARD * (1 + BONUS_BOUNTY_PER_MINUTE * 0.01 * GameRules:GetDOTATime(false, false) / 60), DOTA_ModifyXP_CreepKill, false, true)
			hero:ModifyGold(BASE_BOSS_GOLD_REWARD * (1 + BONUS_BOUNTY_PER_MINUTE * 0.01 * GameRules:GetDOTATime(false, false) / 60), false, DOTA_ModifyGold_CreepKill)
			SendOverheadEventMessage(hero, OVERHEAD_ALERT_GOLD, hero, BASE_BOSS_GOLD_REWARD * (1 + BONUS_BOUNTY_PER_MINUTE * 0.01 * GameRules:GetDOTATime(false, false) / 60), nil)
			hero:RemoveModifierByName("modifier_fighting_boss")
		end
	end
end

function modifier_altar_active:OnIntervalThink()
	if IsServer() then
		local altar_handle = self:GetParent()
		local altar_loc = altar_handle:GetAbsOrigin() 
		local nearby_fighters = FindUnitsInRadius(self.team, altar_loc, nil, 950, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, FIND_ANY_ORDER, false)
		for _, fighter in pairs(nearby_fighters) do

			-- Add any allies to the fighter list
			if fighter:GetTeam() == self.team and not fighter:HasModifier("modifier_fighting_boss") then
				self.fighting_heroes[#self.fighting_heroes+1] = fighter
				fighter:AddNewModifier(nil, nil, "modifier_fighting_boss", {})
			end

			-- Push away any enemies
			if fighter:GetTeam() ~= self.team and not fighter:HasModifier("modifier_frostivus_boss") and not fighter:HasModifier("modifier_knockback") then
				local enemy_knockback =
				{
					center_x = altar_loc.x,
					center_y = altar_loc.y,
					center_z = altar_loc.z,
					duration = 0.35,
					knockback_duration = 0.35,
					knockback_distance = 400,
					knockback_height = 70,
					should_stun = 1
				}

			 	-- Apply knockback on enemies hit
			 	fighter:EmitSound("Hero_Rattletrap.Power_Cogs_Impact")
			 	fighter:AddNewModifier(nil, nil, "modifier_knockback", enemy_knockback)
			 end
		end

		-- Keep fighting heroes inside the ring
		for _, hero in pairs(self.fighting_heroes) do
			local hero_position = hero:GetAbsOrigin()
			local direction = (hero_position - altar_loc)
			if direction:Length2D() > 900 then
				FindClearSpaceForUnit(hero, altar_loc + direction:Normalized() * 900, false)
			end
		end
	end
end


---------------------
-- Spawner functions
---------------------
function SpawnZeus(altar)
	local altar_loc = Entities:FindByName(nil, altar):GetAbsOrigin()
	local boss = CreateUnitByName("npc_frostivus_boss_zeus", altar_loc + Vector(0, 300, 0), true, nil, nil, DOTA_TEAM_NEUTRALS)
	boss:SetForwardVector(Vector(0, -1, 0))
	boss:AddNewModifier(nil, nil, "capture_start_trigger", {boss_name = "zeus", altar_handle = altar})

	-- Cosmetics
	boss:FindAbilityByName("frostivus_boss_innate"):SetLevel(1)
	boss.head = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/zeus/zeus_hair_arcana.vmdl"})
	boss.head:FollowEntity(boss, true)
	boss.hands = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/zeus/zeus_bracers.vmdl"})
	boss.hands:FollowEntity(boss, true)
	boss.pants = SpawnEntityFromTableSynchronous("prop_dynamic", {model = "models/heroes/zeus/zeus_belt.vmdl"})
	boss.pants:FollowEntity(boss, true)

	return boss
end