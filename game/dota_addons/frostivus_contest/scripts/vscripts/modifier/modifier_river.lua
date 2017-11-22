modifier_river = class({})

function modifier_river:IsHidden() return false end
function modifier_river:IsDebuff() return false end
function modifier_river:IsPurgable() return false end

if IsServer() then
	function modifier_river:OnCreated()
		self:StartIntervalThink(FrameTime() * 2)
	end

	function modifier_river:OnIntervalThink()
		local parent = self:GetParent()

		if self:IsInRiver() then
			if not parent:HasModifier("modifier_ice_slide") then
				parent:AddNewModifier(parent, nil, "modifier_ice_slide", {})
			end
		else
			parent:RemoveModifierByName("modifier_ice_slide")
		end
	end

	function modifier_river:IsInRiver()
		local parent = self:GetParent()
		local origin = parent:GetAbsOrigin()

		if origin.z < 100.0 and not parent:HasModifier("modifier_fighting_boss") then
			return true
		end

		return false
	end
end
