modifier_river = class({})

function modifier_river:IsHidden() return false end
function modifier_river:IsDebuff() return false end
function modifier_river:IsPurgable() return false end

function modifier_river:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_river:OnIntervalThink()
	if IsServer() then
		local parent = self:GetParent()

		if self:IsInRiver() then
			if not parent:HasModifier("modifier_ice_slide") then
				parent:AddNewModifier(nil, nil, "modifier_ice_slide", {})
			end
		else
			parent:RemoveModifierByName("modifier_ice_slide")
		end
	end
end

function modifier_river:IsInRiver()
	local parent = self:GetParent()
	local origin = parent:GetAbsOrigin()

	if origin.z < 520 then
		if not parent:HasModifier("modifier_fighting_boss") then
			return true
		end
	end

	return false
end