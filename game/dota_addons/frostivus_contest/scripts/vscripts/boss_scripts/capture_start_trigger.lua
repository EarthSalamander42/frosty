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
local attacker = keys.attacker
local target = keys.unit

	if IsServer() then
		if target == self:GetParent() then

			-- Notify the console that a boss fight (capture attempt) was started
			print(self.boss_name.." boss hit, altar handle is "..self.altar_handle)

			-- Send the boss fight event to all clients
			CustomGameEventManager:Send_ServerToAllClients("AltarContestStarted", {boss_name = self.boss_name, team = attacker:GetTeam()})

			-- Grant the boss its appropriate AI think modifier
			target:AddNewModifier(nil, nil, "boss_thinker_"..self.boss_name, {boss_name = self.boss_name, team = attacker:GetTeam()})

			-- Delete the capture detection modifier
			target:RemoveModifierByName("capture_start_trigger")
		end
	end
end