--[[	Frostivus present ground dummies
		By: Firetoad, 11-18-2017	]]

item_frostivus_present = item_frostivus_present or class({})

function item_frostivus_present:OnSpellStart()
	if IsServer() then
		CustomGameEventManager:Send_ServerToAllClients("PresentPickedUp", {team = self:GetCaster()})
		print(self:GetCaster():GetUnitName())
	end
end