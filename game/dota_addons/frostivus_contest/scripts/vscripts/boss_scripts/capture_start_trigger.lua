-- Modifier which detects the start of an attempt to capture an altar

capture_start_trigger = class({})

-----------------------------------------------------------------------

function capture_start_trigger:IsHidden()
	return true
end

-----------------------------------------------------------------------

function capture_start_trigger:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function capture_start_trigger:OnCreated( params )
	if IsServer() then
		self.boss_name = "no name passed"
		self.altar_handle = "no altar handle"
		if params.boss_name then
			self.boss_name = params.boss_name
		end
		if params.altar_handle then
			self.altar_handle = params.altar_handle
		end
	end
end

-----------------------------------------------------------------------

function capture_start_trigger:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return funcs
end

-----------------------------------------------------------------------

function capture_start_trigger:OnTakeDamage(keys)
	if IsServer() then
		local attacker = keys.attacker
		local target = keys.unit

		-- If phase 1 has ended, do nothing
		if PHASE > 1 then
			return nil
		end

		-- Start boss fight is conditions are met
		if target == self:GetParent() and attacker:IsAlive() and attacker:IsRealHero() then

			-- If this team is participating in another boss fight, do nothing, else, flag them as fighting
			if attacker:GetTeam() == DOTA_TEAM_GOODGUYS then
				if _G.RADIANT_FIGHTING then
					return nil
				elseif _G.RADIANT_FIGHTING == false then
					_G.RADIANT_FIGHTING = true
				end
			elseif attacker:GetTeam() == DOTA_TEAM_BADGUYS then
				if _G.DIRE_FIGHTING then
					return nil
				elseif _G.DIRE_FIGHTING == false then
					_G.DIRE_FIGHTING = true
				end
			end

			-- Send the boss fight event to all clients
			local attacker_team = attacker:GetTeam()
			CustomGameEventManager:Send_ServerToTeam(attacker_team, "AltarContestStarted", {boss_name = self.boss_name})

			-- Grant the boss its appropriate AI think modifier
			target:AddNewModifier(nil, nil, "boss_thinker_"..self.boss_name, {boss_name = self.boss_name, team = attacker:GetTeam(), altar_handle = self.altar_handle})

			-- Lock the arena down
			LockArena(self.altar_handle, attacker_team, attacker)

			-- Delete the capture detection modifier
			target:RemoveModifierByName("capture_start_trigger")
		end
	end
end
