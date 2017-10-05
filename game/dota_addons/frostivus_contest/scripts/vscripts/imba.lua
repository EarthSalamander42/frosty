if GameMode == nil then _G.GameMode = class({}) end

require('libraries/timers')
require('libraries/physics')
require('libraries/projectiles')
require('libraries/projectiles_new')
require('libraries/notifications')
require('libraries/animations')
--	require('libraries/attachments')
require('libraries/astar')
require('libraries/illusionmanager')

require('internal/gamemode')
require('internal/events')
require('server/server')
require('libraries/json')
require('internal/constants')
require('internal/scoreboard_events')

require('settings')
require('events')

StoreCurrentDayCycle()

-- storage API
--require('libraries/json')
--require('libraries/storage')

--Storage:SetApiKey("35c56d290cbd168b6a58aabc43c87aff8d6b39cb")

function GameMode:OnItemPickedUp(event) 
	if event.HeroEntityIndex then
		local owner = EntIndexToHScript(event.HeroEntityIndex)
		if owner:IsHero() and event.itemname == "item_bag_of_gold" then
			GoldPickup(event)
		end
	end
end

function GameMode:PostLoadPrecache()

end

function GameMode:OnFirstPlayerLoaded()
	if GetMapName() == "frostivus_holdout" then
		GoodCamera = Entities:FindByName(nil, "radiant_capture_point")
		BadCamera = Entities:FindByName(nil, "dire_capture_point")
	else
		GoodCamera = Entities:FindByName(nil, "dota_goodguys_fort")
		BadCamera = Entities:FindByName(nil, "dota_badguys_fort")
	end

	GameRules:GetGameModeEntity():SetUnseenFogOfWarEnabled(true)

--	local developer_statues = {
--		"npc_dota_developer_cookies",
--		"npc_dota_developer_firetoad",
--		"npc_dota_developer_zimber",
--		"npc_dota_developer_starboxx",
--		"npc_dota_developer_plexus",
--	}

--	local current_location
--	local current_statue
--	local statue_entity
--	for i = 1, 4 do
--		current_location = Entities:FindByName(nil, "developer_location_0"..i):GetAbsOrigin()
--		current_statue = table.remove(developer_statues, RandomInt(1, #developer_statues))
--		if i <= 2 then
--			statue_entity = CreateUnitByName(current_statue, current_location, true, nil, nil, DOTA_TEAM_GOODGUYS)
--			statue_entity:SetForwardVector(Vector(1, 1, 0):Normalized())
--		else
--			statue_entity = CreateUnitByName(current_statue, current_location, true, nil, nil, DOTA_TEAM_BADGUYS)
--			statue_entity:SetForwardVector(Vector(-1, -1, 0):Normalized())
--		end
--		statue_entity:AddNewModifier(statue_entity, nil, "modifier_imba_contributor_statue", {})
--	end

--	CustomNetTables:SetTableValue("arena_capture", "radiant_score", {0})
--	CustomNetTables:SetTableValue("arena_capture", "dire_score", {0})
end

function GameMode:ModifierFilter( keys )
-- entindex_parent_const	215
-- entindex_ability_const	610
-- duration					-1
-- entindex_caster_const	215
-- name_const				modifier_imba_roshan_rage_stack

	if IsServer() then
		local modifier_owner = EntIndexToHScript(keys.entindex_parent_const)
		local modifier_name = keys.name_const
		local modifier_caster
		if keys.entindex_caster_const then
			modifier_caster = EntIndexToHScript(keys.entindex_caster_const)
		else
			return true
		end

	-------------------------------------------------------------------------------------------------
	-- Frantic mode duration adjustment
	-------------------------------------------------------------------------------------------------

		if IMBA_FRANTIC_MODE_ON then
			if modifier_owner:GetTeam() ~= modifier_caster:GetTeam() and keys.duration > 0 then
				keys.duration = keys.duration * 0.3
			end
		end

	-------------------------------------------------------------------------------------------------
	-- Roshan special modifier rules
	-------------------------------------------------------------------------------------------------

		if IsRoshan(modifier_owner) then
			
			-- Ignore stuns
			if modifier_name == "modifier_stunned" then
				return false
			end

			-- Halve the duration of everything else
			if modifier_caster ~= modifier_owner and keys.duration > 0 then
				keys.duration = keys.duration * 0.5
			end

			-- Fury swipes capping
			if modifier_owner:GetModifierStackCount("modifier_ursa_fury_swipes_damage_increase", nil) > 5 then
				modifier_owner:SetModifierStackCount("modifier_ursa_fury_swipes_damage_increase", nil, 5)
			end
		end

	-------------------------------------------------------------------------------------------------
	-- Tenacity debuff duration reduction
	-------------------------------------------------------------------------------------------------

		if modifier_owner.GetTenacity then						
			local original_duration = keys.duration

			local tenacity = modifier_owner:GetTenacity()
			if modifier_owner:GetTeam() ~= modifier_caster:GetTeam() and keys.duration > 0 and tenacity ~= 0 then				
				keys.duration = keys.duration * (100 - tenacity) * 0.01
			end

			Timers:CreateTimer(FrameTime(), function()
				if modifier_owner:IsNull() then
					return false
				end
				local modifier_handler = modifier_owner:FindModifierByName(modifier_name)
				if modifier_handler then
					if modifier_handler.IgnoreTenacity then
						if modifier_handler:IgnoreTenacity() then
							modifier_handler:SetDuration(original_duration, true)
						end
					end
				end
			end)
		end

		-------------------------------------------------------------------------------------------------
		-- Rune pickup logic
		-------------------------------------------------------------------------------------------------	

		if modifier_caster == modifier_owner then
			if modifier_caster:HasModifier("modifier_rune_doubledamage") then
				local duration = modifier_caster:FindModifierByName("modifier_rune_doubledamage"):GetDuration()
				modifier_caster:RemoveModifierByName("modifier_rune_doubledamage")
				modifier_caster:AddNewModifier(modifier_caster, nil, "modifier_imba_double_damage_rune", {duration = duration})
			elseif modifier_caster:HasModifier("modifier_rune_haste") then
				local duration = modifier_caster:FindModifierByName("modifier_rune_haste"):GetDuration()
				modifier_caster:RemoveModifierByName("modifier_rune_haste")
				modifier_caster:AddNewModifier(modifier_caster, nil, "modifier_imba_haste_rune", {duration = duration})
			elseif modifier_caster:HasModifier("modifier_rune_invis") then
--				PickupInvisibleRune(modifier_caster)
--				return false
			elseif modifier_caster:HasModifier("modifier_rune_regen") then
				local duration = modifier_caster:FindModifierByName("modifier_rune_regen"):GetDuration()
				modifier_caster:RemoveModifierByName("modifier_rune_regen")
				modifier_caster:AddNewModifier(modifier_caster, nil, "modifier_imba_regen_rune", {duration = duration})
			end
		end

		return true
	end
end

function GameMode:ItemAddedFilter( keys )

	-- Typical keys:
	-- inventory_parent_entindex_const: 852
	-- item_entindex_const: 1519
	-- item_parent_entindex_const: -1
	-- suggested_slot: -1
	local unit = EntIndexToHScript(keys.inventory_parent_entindex_const)
	local item = EntIndexToHScript(keys.item_entindex_const)
	local item_name = 0
	if item:GetName() then
		item_name = item:GetName()
	end

	-------------------------------------------------------------------------------------------------
	-- Aegis of the Immortal pickup logic
	-------------------------------------------------------------------------------------------------

	if item_name == "item_imba_aegis" then
		-- If this is a player, do Aegis stuff
		if unit:IsRealHero() and not unit:HasModifier("modifier_item_imba_aegis") then

			-- Display aegis pickup message for all players
			unit:AddNewModifier(unit, item, "modifier_item_imba_aegis",{})
			local line_duration = 7
			Notifications:BottomToAll({hero = unit:GetName(), duration = line_duration})
			Notifications:BottomToAll({text = PlayerResource:GetPlayerName(unit:GetPlayerID()).." ", duration = line_duration, continue = true})
			Notifications:BottomToAll({text = "#imba_player_aegis_message", duration = line_duration, style = {color = "DodgerBlue"}, continue = true})

			-- Destroy the item
			return false
		-- If this is not a player, do nothing and drop another Aegis
		else
			local drop = CreateItem("item_imba_aegis", nil, nil)
			CreateItemOnPositionSync(unit:GetAbsOrigin(), drop)
			drop:LaunchLoot(false, 250, 0.5, unit:GetAbsOrigin() + RandomVector(100))

			UTIL_Remove(item:GetContainer())
			UTIL_Remove(item)

			-- Destroy the item
			return false
		end
		return false
	end

	return true
end

function GameMode:OrderFilter(keys)
--entindex_ability	 ==> 	0
--sequence_number_const	 ==> 	20
--queue	 ==> 	0
--units	 ==> 	table: 0x031d5fd0
--entindex_target	 ==> 	0
--position_z	 ==> 	384
--position_x	 ==> 	-5694.3334960938
--order_type	 ==> 	1
--position_y	 ==> 	-6381.1127929688
--issuer_player_id_const	 ==> 	0

	local units = keys["units"]
	local unit
	if units["0"] then
		unit = EntIndexToHScript(units["0"])
	else
		return nil
	end

	-- Do special handlings if shift-casted only here! The event gets fired another time if the caster
	-- is actually doing this order
	if keys.queue == 1 then
		return true
	end
	
	------------------------------------------------------------------------------------
	-- Prevent Buyback during reincarnation
	------------------------------------------------------------------------------------
	if keys.order_type == DOTA_UNIT_ORDER_BUYBACK then
		if unit:IsReincarnating() then
			return false
		end
	end

	if keys.order_type == DOTA_UNIT_ORDER_CAST_NO_TARGET then
		local ability = EntIndexToHScript(keys.entindex_ability)

		-- Kunkka Torrent cast-handling
		if ability:GetAbilityName() == "imba_kunkka_torrent" then
			local range = ability.BaseClass.GetCastRange(ability,ability:GetCursorPosition(),unit) + GetCastRangeIncrease(unit)
			if unit:HasModifier("modifier_imba_ebb_and_flow_tide_low") or unit:HasModifier("modifier_imba_ebb_and_flow_tsunami") then
				range = range + ability:GetSpecialValueFor("tide_low_range")
			end
			local distance = (unit:GetAbsOrigin() - Vector(keys.position_x,keys.position_y,keys.position_z)):Length2D()
		
			if ( range >= distance) then
				unit:AddNewModifier(unit, ability, "modifier_imba_torrent_cast", {duration = 0.41} )
			end
		end
		
		-- Kunkka Tidebringer cast-handling
		if ability:GetAbilityName() == "imba_kunkka_tidebringer" then
			ability.manual_cast = true
		end
	elseif unit:HasModifier("modifier_imba_torrent_cast") and keys.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
		unit:RemoveModifierByName("modifier_imba_torrent_cast")
	end

	return true
end

function GameMode:DamageFilter( keys )
	if IsServer() then
		--damagetype_const
		--damage
		--entindex_attacker_const
		--entindex_victim_const
		local attacker
		local victim

		if keys.entindex_attacker_const and keys.entindex_victim_const then
			attacker = EntIndexToHScript(keys.entindex_attacker_const)
			victim = EntIndexToHScript(keys.entindex_victim_const)
		else
			return false
		end

		local damage_type = keys.damagetype_const		

		-- Lack of entities handling
		if not attacker or not victim then
			return false
		end		
		
		-- If the attacker is holding an Arcane/Archmage/Cursed Rapier and the distance is over the cap, remove the spellpower bonus from it
		if attacker:HasModifier("modifier_imba_arcane_rapier") or attacker:HasModifier("modifier_imba_arcane_rapier_2") or attacker:HasModifier("modifier_imba_rapier_cursed") then			
			local distance = (attacker:GetAbsOrigin() - victim:GetAbsOrigin()):Length2D() 

			if distance > IMBA_DAMAGE_EFFECTS_DISTANCE_CUTOFF then				
				local rapier_spellpower = 0

				-- Get all modifiers, gather how much spellpower the target has from rapiers
				local modifiers = attacker:FindAllModifiers()

				for _,modifier in pairs(modifiers) do					
					-- Increment Cursed Rapier's spellpower
					if modifier:GetName() == "modifier_imba_rapier_cursed" then
						rapier_spellpower = rapier_spellpower + modifier:GetAbility():GetSpecialValueFor("spell_power")						

					-- Increment Archmage Rapier spellpower
					elseif modifier:GetName() == "modifier_imba_arcane_rapier_2" then
						rapier_spellpower = rapier_spellpower + modifier:GetAbility():GetSpecialValueFor("spell_power")						

					-- Increment Arcane Rapier spellpower
					elseif modifier:GetName() == "modifier_imba_arcane_rapier" then
						rapier_spellpower = rapier_spellpower + modifier:GetAbility():GetSpecialValueFor("spell_power")						
					end
				end

				-- If spellpower was accumulated, reduce the damage
				if rapier_spellpower > 0 then					
					keys.damage = keys.damage / (1 + rapier_spellpower * 0.01)
				end
			end
		end				

		-- Magic shield damage prevention
		if victim:HasModifier("modifier_item_imba_initiate_robe_stacks") and victim:GetTeam() ~= attacker:GetTeam() then

			-- Parameters
			local shield_stacks = victim:GetModifierStackCount("modifier_item_imba_initiate_robe_stacks", nil)

			-- Ignore part of incoming damage
			if keys.damage > shield_stacks then
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, victim, shield_stacks, nil)
				victim:RemoveModifierByName("modifier_item_imba_initiate_robe_stacks")
				keys.damage = keys.damage - shield_stacks
			else
				SendOverheadEventMessage(nil, OVERHEAD_ALERT_MAGICAL_BLOCK, victim, keys.damage, nil)
				victim:SetModifierStackCount("modifier_item_imba_initiate_robe_stacks", victim, math.floor(shield_stacks - keys.damage))
				keys.damage = 0
			end
		end

		-- Magic barrier (pipe/hood) damage mitigation
		if victim:HasModifier("modifier_imba_hood_of_defiance_active_shield") and victim:GetTeam() ~= attacker:GetTeam() and damage_type == DAMAGE_TYPE_MAGICAL then
			local shield_modifier = victim:FindModifierByName("modifier_imba_hood_of_defiance_active_shield")

			if shield_modifier and shield_modifier.AbsorbDamage then
				keys.damage = shield_modifier:AbsorbDamage(keys.damage)
			end
		end		

		-- Reaper's Scythe kill credit logic
		if victim:HasModifier("modifier_imba_reapers_scythe") then
			
			-- Check if this is the killing blow
			local victim_health = victim:GetHealth()
			if keys.damage >= victim_health then

				-- Prevent death and trigger Reaper's Scythe's on-kill effects
				local scythe_modifier = victim:FindModifierByName("modifier_imba_reapers_scythe")
				local scythe_caster = false
				if scythe_modifier then
					scythe_caster = scythe_modifier:GetCaster()
				end
				if scythe_caster then
					keys.damage = 0

					-- Find the Reaper's Scythe ability
					local ability = scythe_caster:FindAbilityByName("imba_necrolyte_reapers_scythe")
					if not ability then return nil end
					local mod = victim:AddNewModifier(scythe_caster, ability, "modifier_imba_reapers_scythe_respawn", {})
					scythe_modifier:Destroy()
					-- Attempt to kill the target, crediting it to the caster of Reaper's Scythe
					ApplyDamage({attacker = scythe_caster, victim = victim, ability = ability, damage = victim:GetHealth() + 10, damage_type = DAMAGE_TYPE_PURE, damage_flag = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK})
				end
			end
		end		

		-- Cheese auto-healing
		if victim:HasModifier("modifier_imba_cheese_death_prevention") then

			-- Only apply if it was a real hero
			if victim:IsRealHero() then
				
				-- Check if death is imminent
				local victim_health = victim:GetHealth()
				if keys.damage >= victim_health and not ( victim:HasModifier("modifier_imba_dazzle_shallow_grave") or victim:HasModifier("modifier_imba_dazzle_nothl_protection") ) then

					-- Find the cheese item handle
					local cheese_modifier = victim:FindModifierByName("modifier_imba_cheese_death_prevention")
					local item = cheese_modifier:GetAbility()

					-- Spend a charge of Cheese if the cooldown is ready
					if item:IsCooldownReady() then
						
						-- Reduce damage by your remaining amount of health
						keys.damage = keys.damage - victim_health

						-- Play sound
						victim:EmitSound("DOTA_Item.Cheese.Activate")

						-- Fully heal yourself
						victim:Heal(victim:GetMaxHealth(), victim)
						victim:GiveMana(victim:GetMaxMana())

						-- Spend a charge
						item:SetCurrentCharges( item:GetCurrentCharges() - 1 )

						-- Trigger cooldown
						item:StartCooldown( item:GetCooldown(1) * (1 - victim:GetCooldownReduction() * 0.01) )

						-- If this was the last charge, remove the item
						if item:GetCurrentCharges() == 0 then
							victim:RemoveItem(item)
						end
					end
				end
			end
			
		end

		-- Mirana's Sacred Arrow On The Prowl guaranteed critical
		if victim:HasModifier("modifier_imba_sacred_arrow_stun") then
			local modifier_stun_handler = victim:FindModifierByName("modifier_imba_sacred_arrow_stun")
			if modifier_stun_handler then

				-- If the table doesn't exist yet, initialize it
				if not modifier_stun_handler.enemy_attackers then
					modifier_stun_handler.enemy_attackers = {}
				end

				-- Cycle through the attackers table
				local attacker_found = false
				for _,enemy in pairs(modifier_stun_handler.enemy_attackers) do
					if enemy == attacker then
						attacker_found = true
					end
				end

				-- If this attacker haven't attacked the stunned target yet, guarantee a critical
				if not attacker_found then
					
					-- Get the modifier's ability
					local stun_ability = modifier_stun_handler:GetAbility()
					if stun_ability then

						-- Get the critical damage count
						local on_prow_crit_damage_pct = stun_ability:GetSpecialValueFor("on_prow_crit_damage_pct")

						-- Increase damage and show the critical attack event
						keys.damage = keys.damage * (1 + on_prow_crit_damage_pct * 0.01)

						-- Overhead critical event
						SendOverheadEventMessage(nil, OVERHEAD_ALERT_CRITICAL, victim, keys.damage, nil)

						-- Add the attacker to the attackers table
						table.insert(modifier_stun_handler.enemy_attackers, attacker)
					end
				end
			end
		end

		-- Axe Battle Hunger kill credit
		if victim:GetTeam() == attacker:GetTeam() and keys.damage > 0 and attacker:HasModifier("modifier_imba_battle_hunger_debuff_dot") then
			-- Check if this is the killing blow
			local victim_health = victim:GetHealth()
			if keys.damage >= victim_health then
				-- Prevent death and trigger Reaper's Scythe's on-kill effects
				local battle_hunger_modifier = victim:FindModifierByName("modifier_imba_battle_hunger_debuff_dot")
				local battle_hunger_caster = false
				local battle_hunger_ability = false
				if battle_hunger_modifier then
					battle_hunger_caster = battle_hunger_modifier:GetCaster()
					battle_hunger_ability = battle_hunger_modifier:GetAbility()
				end
				if battle_hunger_caster then
					keys.damage = 0

					if not battle_hunger_ability then return nil end

					-- Attempt to kill the target, crediting it to Axe
					ApplyDamage({attacker = battle_hunger_caster, victim = victim, ability = battle_hunger_ability, damage = victim:GetHealth() + 10, damage_type = DAMAGE_TYPE_PURE, damage_flag = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK})
				end
			end
		end
		
		-- Juggernaut Deflect kill credit
		if victim:HasModifier("modifier_imba_juggernaut_blade_fury_deflect_on_kill_credit") then
			-- Check if this is the killing blow
			local victim_health = victim:GetHealth()
			local blade_fury_modifier = victim:FindModifierByName("modifier_imba_juggernaut_blade_fury_deflect_on_kill_credit")
			if keys.damage >= victim_health then
				-- Prevent death and trigger Reaper's Scythe's on-kill effects
				local blade_fury_caster = false
				local blade_fury_ability = false
				if blade_fury_modifier then
					blade_fury_caster = blade_fury_modifier:GetCaster()
					blade_fury_ability = blade_fury_modifier:GetAbility()
				end
				if blade_fury_caster then
					keys.damage = 0

					-- Find the Reaper's Scythe ability
					local scythe_ability = blade_fury_caster:FindModifierByName("modifier_imba_reapers_scythe")
					if scythe_ability then return nil end
			
					-- Prevent denying when other sources of damage occurs
					local blade_fury_damager = blade_fury_caster:FindAbilityByName("imba_juggernaut_blade_fury")
					if not blade_fury_damager then return nil end
			
					-- if not attacker then return nil end
					blade_fury_modifier:Destroy()
					-- Attempt to kill the target, crediting it to the caster of Reaper's Scythe
					ApplyDamage({attacker = blade_fury_caster, victim = victim, ability = blade_fury_ability, damage = victim:GetHealth() + 10, damage_type = DAMAGE_TYPE_PURE, damage_flag = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK})
				end
			end
		end
	end
	return true
end

--[[
	This function is called once and only once after all players have loaded into the game, right as the hero selection time begins.
	It can be used to initialize non-hero player state or adjust the hero selection (i.e. force random etc)
]]

function GameMode:OnAllPlayersLoaded()
	DebugPrint("[IMBA] All Players have loaded into the game")

	-------------------------------------------------------------------------------------------------
	-- IMBA: Game filters setup
	-------------------------------------------------------------------------------------------------

	GameRules:GetGameModeEntity():SetBountyRunePickupFilter( Dynamic_Wrap(GameMode, "BountyRuneFilter"), self )
	GameRules:GetGameModeEntity():SetExecuteOrderFilter( Dynamic_Wrap(GameMode, "OrderFilter"), self )
	GameRules:GetGameModeEntity():SetDamageFilter( Dynamic_Wrap(GameMode, "DamageFilter"), self )
--	GameRules:GetGameModeEntity():SetModifyGoldFilter( Dynamic_Wrap(GameMode, "GoldFilter"), self )
--	GameRules:GetGameModeEntity():SetModifyExperienceFilter( Dynamic_Wrap(GameMode, "ExperienceFilter"), self )
	GameRules:GetGameModeEntity():SetModifierGainedFilter( Dynamic_Wrap(GameMode, "ModifierFilter"), self )
	GameRules:GetGameModeEntity():SetItemAddedToInventoryFilter( Dynamic_Wrap(GameMode, "ItemAddedFilter"), self )

	-- CHAT
	self.chat = Chat(self.Players, self.Users, TEAM_COLORS)
	--	Chat:constructor(players, users, teamColors)
	print("Constructing Chat!")
end

random_time = 1.0
function GameMode:OnHeroInGame(hero)	
local time_elapsed = 0

	Timers:CreateTimer(function()
		if not hero:IsNull() then
			if hero:GetUnitName() == "npc_dota_hero_meepo" then
			if not hero:IsClone() then
				TrackMeepos()
			end
			end
		end
		return 0.5
	end)

	if IMBA_PICK_MODE_ALL_RANDOM then
		Timers:CreateTimer(3.0, function()
			HeroSelection:RandomHero({PlayerID = hero:GetPlayerID()})
		end)
	elseif IMBA_PICK_MODE_ALL_RANDOM_SAME_HERO then
		Timers:CreateTimer(3.0, function()
			HeroSelection:RandomSameHero({PlayerID = hero:GetPlayerID()})
		end)
	end

	-- Disabling announcer for the player who picked a hero
	Timers:CreateTimer(0.1, function()
		if hero:GetUnitName() ~= "npc_dota_hero_wisp" then
			hero.picked = true
		elseif hero.is_real_wisp then
			print("REAL WISP")
			hero.picked = true
		end
	end)

	Timers:CreateTimer(0.1, function()
		if hero.is_real_wisp then
			hero.picked = true
			return
		elseif hero:GetUnitName() ~= "npc_dota_hero_wisp" then
			hero.picked = true
			return
		elseif not hero.is_real_wisp then
			if hero:GetUnitName() == "npc_dota_hero_wisp" then
				Timers:CreateTimer(function()
					if not hero:HasModifier("modifier_imba_prevent_actions_game_start") then
						hero:AddNewModifier(hero, nil, "modifier_imba_prevent_actions_game_start", {})
						hero:AddEffects(EF_NODRAW)
						hero:SetDayTimeVisionRange(475)
						hero:SetNightTimeVisionRange(475)				
						if hero:GetTeamNumber() == DOTA_TEAM_GOODGUYS then
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), GoodCamera)
							FindClearSpaceForUnit(hero, GoodCamera:GetAbsOrigin(), false)
						else
							PlayerResource:SetCameraTarget(hero:GetPlayerOwnerID(), BadCamera)					
							FindClearSpaceForUnit(hero, BadCamera:GetAbsOrigin(), false)
						end
					end
					if time_elapsed < 0.9 then
						time_elapsed = time_elapsed + 0.1
					else			
						return nil
					end
					return 0.1
				end)
			end
			return
		end
	end)
end

function GameMode:OnGameInProgress()

	local adjusted_gold_tick_time = GOLD_TICK_TIME / ( 1 + CUSTOM_GOLD_BONUS * 0.01 )
	GameRules:SetGoldTickTime( adjusted_gold_tick_time )

	if GetMapName() == "imba_arena" then
		-- Define the bonus gold positions
		local bonus_gold_positions = {}
		bonus_gold_positions.fountain_radiant = {
			stacks = 20,
			center = Vector(-3776, -3776, 384),
			radius = 1300
		}
		bonus_gold_positions.fountain_dire = {
			stacks = 20,
			center = Vector(3712, 3712, 384),
			radius = 1300
		}
		bonus_gold_positions.center_arena = {
			stacks = 40,
			center = Vector(0, 0, 256),
			radius = 900
		}

		-- Continuously update the amount of gold/exp to gain
		Timers:CreateTimer(0, function()
			-- Apply the modifier
			local nearby_heroes = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, 6000, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
			for _, hero in pairs(nearby_heroes) do
				if not hero:HasModifier("modifier_imba_arena_passive_gold_thinker") then
					hero:AddNewModifier(hero, nil, "modifier_imba_arena_passive_gold_thinker", {})
				end
				hero:FindModifierByName("modifier_imba_arena_passive_gold_thinker"):SetStackCount(12)
			end

			-- Update stack amount, when relevant
			for _, position in pairs(bonus_gold_positions) do
				nearby_heroes = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, position.center, nil, position.radius, DOTA_UNIT_TARGET_TEAM_BOTH, DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_INVULNERABLE + DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_OUT_OF_WORLD, FIND_ANY_ORDER, false)
				for _, hero in pairs(nearby_heroes) do
					hero:FindModifierByName("modifier_imba_arena_passive_gold_thinker"):SetStackCount(position.stacks)
				end
			end
			return 0.1
		end)

		-- Set up control points
		local radiant_control_point_loc = Entities:FindByName(nil, "radiant_capture_point"):GetAbsOrigin()
		local dire_control_point_loc = Entities:FindByName(nil, "dire_capture_point"):GetAbsOrigin()
		RADIANT_CONTROL_POINT_DUMMY = CreateUnitByName("npc_dummy_unit_perma", radiant_control_point_loc, false, nil, nil, DOTA_TEAM_NOTEAM)
		DIRE_CONTROL_POINT_DUMMY = CreateUnitByName("npc_dummy_unit_perma", dire_control_point_loc, false, nil, nil, DOTA_TEAM_NOTEAM)
		RADIANT_CONTROL_POINT_DUMMY.score = 20
		DIRE_CONTROL_POINT_DUMMY.score = 20
		ArenaControlPointThinkRadiant(RADIANT_CONTROL_POINT_DUMMY)
		ArenaControlPointThinkDire(DIRE_CONTROL_POINT_DUMMY)
		Timers:CreateTimer(10, function()
			ArenaControlPointScoreThink(RADIANT_CONTROL_POINT_DUMMY, DIRE_CONTROL_POINT_DUMMY)
		end)
		CustomGameEventManager:Send_ServerToAllClients("contest_started", {})
	end
end

function GameMode:InitGameMode()
	GameMode = self

	GameMode:_InitGameMode()

	GameRules.HeroKV = LoadKeyValues("scripts/npc/npc_heroes_custom.txt")
	GameRules.UnitKV = LoadKeyValues("scripts/npc/npc_units_custom.txt")

	-- IMBA testbed command
	Convars:RegisterCommand("imba_test", Dynamic_Wrap(GameMode, 'StartImbaTest'), "Spawns several units to help with testing", FCVAR_CHEAT)
	Convars:RegisterCommand("game_time", GetGameLength, "Print the game time.", FCVAR_CHEAT)	

	CustomGameEventManager:RegisterListener("remove_units", Dynamic_Wrap(GameMode, "RemoveUnits"))

	-- Panorama event stuff
	initScoreBoardEvents()
end

-- Starts the testbed if in tools mode
function GameMode:StartImbaTest()

	-- If not in tools mode, do nothing
	if not IsInToolsMode() then
		print("IMBA testbed is only available in tools mode.")
		return nil
	end

	-- If the testbed was already initialized, do nothing
	if IMBA_TESTBED_INITIALIZED then
		print("Testbed already initialized.")
		return nil
	end

	-- Define testbed zone reference point
	local testbed_center = Vector(1500, -5000, 256)
	if GetMapName() == "imba_arena" then
		testbed_center = Vector(0, 0, 128)
	end

	-- Move any existing heroes to the testbed area, and grant them useful testing items
	local player_heroes = HeroList:GetAllHeroes()
	for _, hero in pairs(player_heroes) do
		hero:SetAbsOrigin(testbed_center + Vector(-250, 0, 0))
		hero:AddItemByName("item_imba_diffusal_blade_3")
		hero:AddItemByName("item_imba_manta")
		hero:AddItemByName("item_imba_blink")
		hero:AddItemByName("item_imba_silver_edge")
		hero:AddItemByName("item_black_king_bar")
		hero:AddItemByName("item_imba_heart")
		hero:AddItemByName("item_imba_siege_cuirass")
		hero:AddItemByName("item_imba_butterfly")
		hero:AddItemByName("item_ultimate_scepter")
		hero:AddExperience(100000, DOTA_ModifyXP_Unspecified, false, true)
		PlayerResource:SetCameraTarget(0, hero)
	end
	Timers:CreateTimer(0.1, function()
		PlayerResource:SetCameraTarget(0, nil)
	end)
	ResolveNPCPositions(testbed_center + Vector(-300, 0, 0), 128)

	-- Spawn some high health allies for benefic spell testing
	local dummy_hero
	local dummy_ability
	for i = 1, 3 do
		dummy_hero = CreateUnitByName("npc_dota_hero_axe", testbed_center + Vector(-500, (i-2) * 300, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_GOODGUYS)
		dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
		dummy_hero:SetControllableByPlayer(0, true)
		dummy_hero:AddItemByName("item_imba_heart")
		dummy_hero:AddItemByName("item_imba_heart")

		-- Add specific items to each dummy hero
		if i == 1 then
			dummy_hero:AddItemByName("item_imba_manta")
			dummy_hero:AddItemByName("item_imba_diffusal_blade_3")
		elseif i == 2 then
			dummy_hero:AddItemByName("item_imba_silver_edge")
			dummy_hero:AddItemByName("item_imba_necronomicon_5")
		elseif i == 3 then
			dummy_hero:AddItemByName("item_sphere")
			dummy_hero:AddItemByName("item_black_king_bar")
		end
	end

	-- Spawn some high health enemies to attack/spam abilities on
	for i = 1, 3 do
		dummy_hero = CreateUnitByName("npc_dota_hero_axe", testbed_center + Vector(300, (i-2) * 300, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
		dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
		dummy_hero:SetControllableByPlayer(0, true)
		dummy_hero:AddItemByName("item_imba_heart")
		dummy_hero:AddItemByName("item_imba_heart")

		-- Add specific items to each dummy hero
		if i == 1 then
			dummy_hero:AddItemByName("item_imba_manta")
			dummy_hero:AddItemByName("item_imba_diffusal_blade_3")
		elseif i == 2 then
			dummy_hero:AddItemByName("item_imba_silver_edge")
			dummy_hero:AddItemByName("item_imba_necronomicon_5")
		elseif i == 3 then
			dummy_hero:AddItemByName("item_sphere")
			dummy_hero:AddItemByName("item_black_king_bar")
		end
	end

	-- Spawn a rubick with spell steal leveled up
	dummy_hero = CreateUnitByName("npc_dota_hero_rubick", testbed_center + Vector(600, 200, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
	dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
	dummy_hero:SetControllableByPlayer(0, true)
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_ability = dummy_hero:FindAbilityByName("rubick_spell_steal")
	if dummy_ability then
		dummy_ability:SetLevel(6)
	end

	-- Spawn a pugna with nether ward leveled up and some CDR
	dummy_hero = CreateUnitByName("npc_dota_hero_pugna", testbed_center + Vector(600, 0, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
	dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
	dummy_hero:SetControllableByPlayer(0, true)
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_triumvirate")
	dummy_hero:AddItemByName("item_imba_octarine_core")
	dummy_ability = dummy_hero:FindAbilityByName("imba_pugna_nether_ward")
	if dummy_ability then
		dummy_ability:SetLevel(7)
	end

	-- Spawn an antimage with a scepter and leveled up spell shield
	dummy_hero = CreateUnitByName("npc_dota_hero_antimage", testbed_center + Vector(600, -200, 0), true, player_heroes[1], player_heroes[1], DOTA_TEAM_BADGUYS)
	dummy_hero:AddExperience(25000, DOTA_ModifyXP_Unspecified, false, true)
	dummy_hero:SetControllableByPlayer(0, true)
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_imba_heart")
	dummy_hero:AddItemByName("item_ultimate_scepter")
	dummy_ability = dummy_hero:FindAbilityByName("imba_antimage_spell_shield")
	if dummy_ability then
		dummy_ability:SetLevel(7)
	end

	-- Spawn some assorted neutrals for reasons
	neutrals_table = {}
	neutrals_table[1] = {}
	neutrals_table[2] = {}
	neutrals_table[3] = {}
	neutrals_table[4] = {}
	neutrals_table[5] = {}
	neutrals_table[6] = {}
	neutrals_table[7] = {}
	neutrals_table[8] = {}
	neutrals_table[1].name = "npc_dota_neutral_big_thunder_lizard"
	neutrals_table[1].position = Vector(-450, 800, 0)
	neutrals_table[2].name = "npc_dota_neutral_granite_golem"
	neutrals_table[2].position = Vector(-150, 800, 0)
	neutrals_table[3].name = "npc_dota_neutral_black_dragon"
	neutrals_table[3].position = Vector(150, 800, 0)
	neutrals_table[4].name = "npc_dota_neutral_prowler_shaman"
	neutrals_table[4].position = Vector(450, 800, 0)
	neutrals_table[5].name = "npc_dota_neutral_satyr_hellcaller"
	neutrals_table[5].position = Vector(-450, 600, 0)
	neutrals_table[6].name = "npc_dota_neutral_mud_golem"
	neutrals_table[6].position = Vector(-150, 600, 0)
	neutrals_table[7].name = "npc_dota_neutral_enraged_wildkin"
	neutrals_table[7].position = Vector(150, 600, 0)
	neutrals_table[8].name = "npc_dota_neutral_centaur_khan"
	neutrals_table[8].position = Vector(450, 600, 0)

	for _, neutral in pairs(neutrals_table) do
		dummy_hero = CreateUnitByName(neutral.name, testbed_center + neutral.position, true, player_heroes[1], player_heroes[1], DOTA_TEAM_NEUTRALS)
		dummy_hero:SetControllableByPlayer(0, true)
		dummy_hero:Hold()
	end

	-- Flag testbed as having been initialized
	IMBA_TESTBED_INITIALIZED = true
end

--	function GameMode:RemoveUnits(good, bad, neutral)
function GameMode:RemoveUnits()
local units = FindUnitsInRadius(DOTA_TEAM_GOODGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local units2 = FindUnitsInRadius(DOTA_TEAM_BADGUYS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local units3 = FindUnitsInRadius(DOTA_TEAM_NEUTRALS, Vector(0, 0, 0), nil, FIND_UNITS_EVERYWHERE, DOTA_UNIT_TARGET_TEAM_FRIENDLY, DOTA_UNIT_TARGET_CREEP, DOTA_UNIT_TARGET_FLAG_INVULNERABLE , FIND_ANY_ORDER, false )
local count = 0

--	if good == true then
		for _,v in pairs(units) do
			if v:HasMovementCapability() and not v:GetUnitName() == "npc_dota_creep_goodguys_melee" then
				count = count +1
				v:RemoveSelf()
			end
		end
--	end

--	if bad == true then
		for _,v in pairs(units2) do
			if v:HasMovementCapability() and not v:GetUnitName() == "npc_dota_creep_badguys_melee" then
				count = count +1
				v:RemoveSelf()
			end
		end
--	end

--	if neutral == true then
		for _,v in pairs(units3) do
			if v:HasMovementCapability() then
				count = count +1
				v:RemoveSelf()
			end
		end
--	end
end
