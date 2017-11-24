-- Mega Greevil AI thinker

boss_thinker_mega_greevil = class({})

-----------------------------------------------------------------------

function boss_thinker_mega_greevil:IsHidden()
	return true
end

-----------------------------------------------------------------------

function boss_thinker_mega_greevil:IsPurgable()
	return false
end

-----------------------------------------------------------------------

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

		-- Boss script constants
		self.random_constants = {}
		self.random_constants[1] = 0

		-- Start thinking
		self.boss_timer = 0
		self.events = {}
		self:StartIntervalThink(0.1)
	end
end

-----------------------------------------------------------------------

function boss_thinker_mega_greevil:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

-----------------------------------------------------------------------

function boss_thinker_mega_greevil:OnDeath(keys)
	if IsServer() and keys.unit == self:GetParent() then
		GameRules:SetGameWinner(keys.attacker:GetTeam())
	end
end

-----------------------------------------------------------------------

function boss_thinker_mega_greevil:OnIntervalThink()
	if IsServer() then

		-- Parameters
		local boss = self:GetParent()

		-- Think
		self.boss_timer = self.boss_timer + 0.1

		-- Boss move script
		if self.boss_timer > 1 and not self.events[1] then
			self:Raze(boss, boss:GetAbsOrigin() + RandomVector(100):Normalized() * RandomInt(200, 900), math.max(2.0 - 0.05 * self.random_constants[1], 1.0), 275, 100, true)
			for i = 1, 1 + math.floor(self.random_constants[1] * 0.5) do
				self:Raze(boss, boss:GetAbsOrigin() + RandomVector(100):Normalized() * RandomInt(200, 900), math.max(2.0 - 0.05 * self.random_constants[1], 1.0), 275, 100, false)
			end
			self.random_constants[1] = self.random_constants[1] + 1
			self.events[1] = true
		end

		if self.boss_timer > math.max(5 - 0.1 * self.random_constants[1], 2.5) then
			self.boss_timer = self.boss_timer - math.max(4 - 0.1 * self.random_constants[1], 1.5)
			self.events[1] = false
		end
	end
end

---------------------------
-- Auxiliary stuff
---------------------------

-- Raze a target location
function boss_thinker_mega_greevil:Raze(altar_handle, target, delay, radius, damage, play_impact_sound)

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
					local damage = self:GetParent():GetAttackDamage() * damage * 0.01
					local damage_dealt = ApplyDamage({victim = enemy, attacker = self:GetParent(), ability = nil, damage = damage * RandomInt(90, 110) * 0.01, damage_type = DAMAGE_TYPE_MAGICAL})
					SendOverheadEventMessage(nil, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, enemy, damage_dealt, nil)
				end
			end)
		end
	end)
end