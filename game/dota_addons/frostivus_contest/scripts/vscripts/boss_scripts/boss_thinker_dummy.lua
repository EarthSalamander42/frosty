-- Dummy boss's AI thinker

boss_thinker_dummy = class({})

-----------------------------------------------------------------------

function boss_thinker_dummy:IsHidden()
	return true
end

-----------------------------------------------------------------------

function boss_thinker_dummy:IsPurgable()
	return false
end

-----------------------------------------------------------------------

function boss_thinker_dummy:OnCreated( params )
	if IsServer() then
		self.boss_name = "no name passed"
		self.team = "no team passed"
		if params.boss_name then
			self.boss_name = params.boss_name
		end
		if params.team then
			self.team = params.team
		end

		-- Start sending health events
		self:StartIntervalThink(0.1)
	end
end

-----------------------------------------------------------------------

function boss_thinker_dummy:DeclareFunctions()
	local funcs = 
	{
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

-----------------------------------------------------------------------

function boss_thinker_dummy:OnIntervalThink()
	if IsServer() then
		-- Sends boss health information to all clients
		local boss = self:GetParent()
		CustomGameEventManager:Send_ServerToAllClients("OnAltarContestThink", {boss_name = self.boss_name, health = boss:GetHealth(), max_health = boss:GetMaxHealth()} )
		print("boss health: "..boss:GetHealth().." / "..boss:GetMaxHealth())
	end
end

-----------------------------------------------------------------------

function boss_thinker_dummy:OnDeath(keys)
local target = keys.unit

	if IsServer() then
		if target == self:GetParent() then

			-- Notify the console that a boss fight (capture attempt) has ended with a successful kill
			print(self.boss_name.." boss is dead, winning team is "..self.team)

			-- Send the boss death event to all clients
			CustomGameEventManager:Send_ServerToAllClients("AltarContestEnd", {boss_name = self.boss_name, winner = self.team})

			-- Respawn the boss and grant it its new capture detection modifier
			local dummy_boss = CreateUnitByName("npc_imba_enigma_eidolon_1", Vector(2230, -3725, 256), true, nil, nil, DOTA_TEAM_BADGUYS)
			dummy_boss:AddNewModifier(nil, nil, "capture_start_trigger", {boss_name = "dummy", altar_handle = dummy_boss})

			-- Delete the boss AI thinker modifier
			target:RemoveModifierByName("boss_thinker_dummy")
		end
	end
end
