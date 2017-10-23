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

		-- Start sending health events
		self:StartIntervalThink(0.1)
	end
end

-----------------------------------------------------------------------

function boss_thinker_zeus:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

-----------------------------------------------------------------------

function boss_thinker_zeus:OnIntervalThink()
	if IsServer() then
		-- Sends boss health information to all clients
		local boss = self:GetParent()
		CustomGameEventManager:Send_ServerToAllClients("OnAltarContestThink", {boss_name = self.boss_name, health = boss:GetHealth(), max_health = boss:GetMaxHealth()} )
		print("boss health: "..boss:GetHealth().." / "..boss:GetMaxHealth())
	end
end

-----------------------------------------------------------------------

function boss_thinker_zeus:OnDeath(keys)
local target = keys.unit

	if IsServer() then
		if target == self:GetParent() then

			-- Notify the console that a boss fight (capture attempt) has ended with a successful kill
			print(self.boss_name.." boss is dead, winning team is "..self.team)

			-- Send the boss death event to all clients
			CustomGameEventManager:Send_ServerToAllClients("AltarContestEnd", {boss_name = self.boss_name, winner = self.team})

			-- Respawn the boss and grant it its new capture detection modifier
			local boss = SpawnZeus(self.altar_handle)

			-- Increase the new boss' power
			local current_power = target:FindModifierByName("modifier_frostivus_boss"):GetStackCount()
			local next_power = math.ceil(current_power * 0.25) + 1
			boss:FindModifierByName("modifier_frostivus_boss"):SetStackCount(current_power + next_power)

			-- Unlock the arena
			UnlockArena(self.altar_handle)

			-- Delete the boss AI thinker modifier
			target:RemoveModifierByName("boss_thinker_zeus")
		end
	end
end
