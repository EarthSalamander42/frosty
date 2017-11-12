-- Passive gold/experience gain modifier

modifier_passive_bounty = modifier_passive_bounty or class({})

function modifier_passive_bounty:IsHidden() return true end
function modifier_passive_bounty:IsPurgable() return false end
function modifier_passive_bounty:IsDebuff() return false end

function modifier_passive_bounty:OnCreated(keys)
	if IsServer() then

		-- Parameters
		local passive_gpm = 300
		local passive_xpm = 300
		self.gold_per_tick = passive_gpm / 30
		self.xp_per_tick = passive_xpm / 30

		-- Start thinking
		self:StartIntervalThink(2.0)
	end
end

function modifier_passive_bounty:OnIntervalThink()
	if IsServer() then

		-- Grant players passive gold and experience
		for player_id = 0, 20 do
			if PlayerResource:GetPlayer(player_id) then
				local hero = PlayerResource:GetSelectedHeroEntity(player_id)
				if hero then
					
					-- Altar buffs
					local gold_bonus_modifier = hero:FindModifierByName("modifier_frostivus_altar_aura_fire_buff")
					local exp_bonus_modifier = hero:FindModifierByName("modifier_frostivus_altar_aura_zeus_buff")
					local extra_gold = 0
					local extra_exp = 0

					-- Greevil's greed
					if hero:HasModifier("custom_alchemist_goblins_greed_passive") then
						local greed_ability = hero:FindAbilityByName("custom_alchemist_goblins_greed")
						extra_gold = extra_gold + greed_ability:GetLevelSpecialValueFor("gold_per_tick", greed_ability:GetLevel() - 1)
					end

					if gold_bonus_modifier then
						extra_gold = extra_gold + 3 + gold_bonus_modifier:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_fire"):GetStackCount()
					end
					if exp_bonus_modifier then
						extra_exp = extra_exp + 4 + 2 * exp_bonus_modifier:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_zeus"):GetStackCount()
					end

					hero:ModifyGold(self.gold_per_tick + extra_gold, false, DOTA_ModifyGold_GameTick)
					hero:AddExperience(self.xp_per_tick + extra_exp, DOTA_ModifyXP_CreepKill, false, true)
				end
			end
		end
	end
end