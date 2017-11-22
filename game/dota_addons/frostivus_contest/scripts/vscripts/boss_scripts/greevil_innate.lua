-- Greevil modifiers

modifier_frostivus_greevil = modifier_frostivus_greevil or class({})

function modifier_frostivus_greevil:IsHidden() return true end
function modifier_frostivus_greevil:IsPurgable() return false end
function modifier_frostivus_greevil:IsDebuff() return false end

function modifier_frostivus_greevil:CheckState()
	local state =
	{
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true
	}
	return state
end

modifier_greevil_capture_aura = modifier_greevil_capture_aura or class({})

function modifier_greevil_capture_aura:IsHidden() return true end
function modifier_greevil_capture_aura:IsPurgable() return false end
function modifier_greevil_capture_aura:IsDebuff() return false end

function modifier_greevil_capture_aura:OnCreated(keys)
	if IsServer() then
		self.points = keys.level
	end
end

function modifier_greevil_capture_aura:DeclareFunctions()
	local funcs = {
		MODIFIER_EVENT_ON_DEATH,
	}
	return funcs
end

function modifier_greevil_capture_aura:OnDeath(keys)
	if IsServer() then
		local target = keys.unit
		if target == self:GetParent() then
			local target_loc = target:GetAbsOrigin()
			local presents_per_level = {1, 2, 3, 5}
			local present_amount = presents_per_level[self.points]
			Timers:CreateTimer(0, function()
				local item = CreateItem("item_frostivus_present", nil, nil)
				CreateItemOnPositionForLaunch(target_loc, item)
				item:LaunchLootInitialHeight(true, 150, 300, 0.8, keys.attacker:GetAbsOrigin())
				present_amount = present_amount - 1
				if present_amount > 0 then
					return 0.2
				end
			end)
		end
	end
end