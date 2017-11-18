modifier_river_radiation = class({})

function modifier_river_radiation:IsHidden()
	return false
end

function modifier_river_radiation:IsDebuff()
	return true
end

function modifier_river_radiation:IsPurgable()
	return false
end

if IsServer() then
	function modifier_river_radiation:OnCreated()
		self:StartIntervalThink(0.5)
		self:OnIntervalThink()
	end

	function modifier_river_radiation:OnIntervalThink()
		local amount = self:GetParent():GetMaxHealth() / 50 -- 2%

		local damageTable = {
			victim = self:GetParent(),
			attacker = self:GetParent(),
			damage = amount,
			damage_type = DAMAGE_TYPE_PURE,
		}
		ApplyDamage(damageTable)
	end
end
