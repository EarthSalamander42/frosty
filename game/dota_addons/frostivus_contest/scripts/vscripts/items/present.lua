
--[[	Frostivus present ground dummies
		By: Firetoad, 11-18-2017	]]

item_frostivus_present = item_frostivus_present or class({})

function item_frostivus_present:OnSpellStart()
	if IsServer() then
		CustomGameEventManager:Send_ServerToAllClients("PresentPickedUp", {team = self:GetCaster()})
		if self:GetCaster():GetTeamNumber() == 2 then
			PRESENT_SCORE_2 = PRESENT_SCORE_2 +1
		else
			PRESENT_SCORE_3 = PRESENT_SCORE_3 +1
		end
		print(self:GetCaster():GetUnitName())
	end
end