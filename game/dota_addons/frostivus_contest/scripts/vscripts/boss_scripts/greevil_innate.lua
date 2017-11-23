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

function modifier_greevil_capture_aura:CheckState()
	local state =	{
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true
	}
	return state
end

function modifier_greevil_capture_aura:DeclareFunctions() 
	local funcs = {
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_MAGICAL,
		MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PURE
	}
	return funcs 
end

function modifier_greevil_capture_aura:GetAbsoluteNoDamagePhysical()  
	return 1
end

function modifier_greevil_capture_aura:GetAbsoluteNoDamageMagical()  
	return 1
end

function modifier_greevil_capture_aura:GetAbsoluteNoDamagePure()  
	return 1
end

function modifier_greevil_capture_aura:OnCreated(keys)
	if IsServer() then

		-- Start movement
		local starting_node = Entities:FindAllByNameWithin("greevil_node", self:GetParent():GetAbsOrigin(), 100)
		self.think_counter = 0
		self.previous_nodes = {}
		self.previous_nodes[1] = starting_node[1]
		self.previous_nodes[2] = starting_node[1]
		self.previous_nodes[3] = starting_node[1]
		self.current_target = self:FindValidNextNode(700)
		self:GetParent():MoveToPosition(self.current_target:GetAbsOrigin())
		self:StartIntervalThink(0.03)
	end
end

function modifier_greevil_capture_aura:OnIntervalThink()
	if IsServer() then

		-- Search for a hero to capture this Greevil
		local nearby_heroes = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, self:GetParent():GetAbsOrigin(), nil, 200, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		for _, hero in pairs(nearby_heroes) do
			if hero:IsRealHero() and not hero:HasModifier("modifier_greevil_captured_owner") then
				hero:AddNewModifier(nil, nil, "modifier_greevil_captured_owner", {greevil = self:GetParent():entindex()})
				self:GetParent():RemoveModifierByName("modifier_greevil_capture_aura")
				self:GetParent():AddNewModifier(nil, nil, "modifier_greevil_captured_greevil", {capturer_entindex = hero:entindex()})
				PlaySoundForTeam(hero:GetTeam(), "greevil_eventstart_Stinger")
				break
			end
		end

		-- Heavy operations only once a second
		self.think_counter = self.think_counter + 1
		if self.think_counter >= 30 then
			-- If the target was reached, find a new one
			if (self:GetParent():GetAbsOrigin() - self.current_target:GetAbsOrigin()):Length2D() < 150 then
				self.previous_nodes[3] = self.previous_nodes[2]
				self.previous_nodes[2] = self.previous_nodes[1]
				self.previous_nodes[1] = self.current_target
				self.current_target = self:FindValidNextNode(700)
			end

			-- Keep moving
			self:GetParent():MoveToPosition(self.current_target:GetAbsOrigin())
			self.think_counter = 0
		end
	end
end

function modifier_greevil_capture_aura:FindValidNextNode(radius)

	-- If a valid candidate is found, return it
	local target_candidates = Entities:FindAllByNameWithin("greevil_node", self:GetParent():GetAbsOrigin(), radius)
	for _, target_candidate in pairs(target_candidates) do
		if target_candidate ~= self.previous_nodes[1] and target_candidate ~= self.previous_nodes[2] and target_candidate ~= self.previous_nodes[3] then
			return target_candidate
		end
	end

	-- Else, search in a bigger radius
	return self:FindValidNextNode(radius + 300)
end




modifier_greevil_captured_owner = modifier_greevil_captured_owner or class({})

function modifier_greevil_captured_owner:IsHidden() return true end
function modifier_greevil_captured_owner:IsPurgable() return false end
function modifier_greevil_captured_owner:IsDebuff() return false end

function modifier_greevil_captured_owner:OnCreated(keys)
	if IsServer() then

		-- Capture parent greevil
		self.greevil = EntIndexToHScript(keys.greevil)

		-- Increase stacks according to greevil type
		if self.greevil:GetUnitName() == "npc_frostivus_greevil_basic" then
			self:SetStackCount(1)
		elseif self.greevil:GetUnitName() == "npc_frostivus_greevil_advanced" then
			self:SetStackCount(2)
		elseif self.greevil:GetUnitName() == "npc_frostivus_greevil_super" then
			self:SetStackCount(3)
		elseif self.greevil:GetUnitName() == "npc_frostivus_greevil_gold" then
			self:SetStackCount(4)
		end
	end
end

function modifier_greevil_captured_owner:CheckState()
	local state =	{
		[MODIFIER_STATE_DISARMED] = true,
		[MODIFIER_STATE_SILENCED] = true,
		[MODIFIER_STATE_MUTED] = true
	}
	return state
end

function modifier_greevil_captured_owner:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION,
		MODIFIER_EVENT_ON_DEATH
	}
	return funcs 
end

function modifier_greevil_captured_owner:OnDeath(keys)
	if IsServer() then

		-- If this is the owner dying, release the greevil
		if keys.unit == self:GetParent() then
			self.greevil:RemoveModifierByName("modifier_greevil_captured_greevil")
			self.greevil:AddNewModifier(nil, nil, "modifier_greevil_capture_aura", {})
		end
	end
end

function modifier_greevil_captured_owner:GetModifierMoveSpeedBonus_Percentage()
	return -(25 + 10 * self:GetStackCount())
end

function modifier_greevil_captured_owner:GetModifierProvidesFOWVision()
	return 1
end





modifier_greevil_captured_greevil = modifier_greevil_captured_greevil or class({})

function modifier_greevil_captured_greevil:IsHidden() return true end
function modifier_greevil_captured_greevil:IsPurgable() return false end
function modifier_greevil_captured_greevil:IsDebuff() return false end

function modifier_greevil_captured_greevil:CheckState()
	local state =	{
		[MODIFIER_STATE_NO_HEALTH_BAR] = true,
		[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_MAGIC_IMMUNE] = true,
		[MODIFIER_STATE_ROOTED] = true
	}
	return state
end

function modifier_greevil_captured_greevil:DeclareFunctions() 
	local funcs = {
		MODIFIER_PROPERTY_PROVIDES_FOW_POSITION
	}
	return funcs 
end

function modifier_greevil_captured_greevil:GetModifierProvidesFOWVision()
	return 1
end

function modifier_greevil_captured_greevil:OnCreated(keys)
	if IsServer() then
		self.capturer = EntIndexToHScript(keys.capturer_entindex)
		StartAnimation(self:GetParent(), {duration = 480, activity=ACT_DOTA_FLAIL, rate=1.5})
		self:StartIntervalThink(0.03)
	end
end

function modifier_greevil_captured_greevil:OnDestroy()
	if IsServer() then
		EndAnimation(self:GetParent())
	end
end

function modifier_greevil_captured_greevil:OnIntervalThink()
	if IsServer() then
		local greevil = self:GetParent()
		greevil:SetAbsOrigin(self.capturer:GetAbsOrigin() - self.capturer:GetForwardVector() * 150)

		-- Search for an altar to end this Greevil's misery
		local nearby_units = FindUnitsInRadius(self.capturer:GetTeam(), self.capturer:GetAbsOrigin(), nil, 200, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_BUILDING, DOTA_UNIT_TARGET_FLAG_INVULNERABLE, FIND_ANY_ORDER, false)
		for _, unit in pairs(nearby_units) do
			if unit:GetUnitName() == "npc_dota_altar" or unit:GetUnitName() == "npc_dota_altar_minor" then

				-- Free capturer & captured
				local capturer = self.capturer
				capturer:RemoveModifierByName("modifier_greevil_captured_owner")
				greevil:RemoveModifierByName("modifier_greevil_captured_greevil")

				-- Calculate gifts
				local greevil_pos = greevil:GetAbsOrigin()
				local present_amount = 1
				if greevil:GetUnitName() == "npc_frostivus_greevil_advanced" then
					present_amount = 2
				elseif greevil:GetUnitName() == "npc_frostivus_greevil_super" then
					present_amount = 3
				elseif greevil:GetUnitName() == "npc_frostivus_greevil_gold" then
					present_amount = 5
				end

				-- Success stinger
				PlaySoundForTeam(self.capturer:GetTeam(), "Tutorial.Quest.complete_01")

				-- Presents!
				Timers:CreateTimer(0, function()
					local item = CreateItem("item_frostivus_present", nil, nil)
					CreateItemOnPositionForLaunch(greevil_pos, item)
					item:LaunchLootInitialHeight(true, 150, 300, 0.8, capturer:GetAbsOrigin())
					present_amount = present_amount - 1
					if present_amount > 0 then
						return 0.2
					end
				end)

				-- Kill the poor thing
				greevil:Kill(nil, greevil)
			end
		end
	end
end