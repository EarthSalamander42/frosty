-- Passive gold/experience gain modifier

modifier_passive_bounty = modifier_passive_bounty or class({})

function modifier_passive_bounty:IsHidden() return true end
function modifier_passive_bounty:IsPurgable() return false end
function modifier_passive_bounty:IsDebuff() return false end

function modifier_passive_bounty:OnCreated(keys)
	if IsServer() then

		-- Parameters
		self.passive_gpm = 240
		self.passive_xpm = 240
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
					local gold_bonus_modifier = hero:FindModifierByName("modifier_frostivus_altar_aura_fire_buff")
					local exp_bonus_modifier = hero:FindModifierByName("modifier_frostivus_altar_aura_zeus_buff")
					if gold_bonus_modifier then
						hero:ModifyGold(self.gold_per_tick + (90 + gold_bonus_modifier:GetCaster():FindModifierByName("modifier_frostivus_altar_aura_fire"):GetStackCount() * 30) / 30, false, DOTA_ModifyGold_GameTick)
					else
						hero:ModifyGold(self.gold_per_tick, false, DOTA_ModifyGold_GameTick)
					end
					if exp_bonus_modifier then
						hero:AddExperience(self.xp_per_tick + (90 + exp_bonus_modifier::GetCaster():FindModifierByName("modifier_frostivus_altar_aura_zeus"):GetStackCount() * 30) / 30, DOTA_ModifyXP_CreepKill, false, true)
					else
						hero:AddExperience(self.xp_per_tick, DOTA_ModifyXP_CreepKill, false, true)
					end
				end
			end
		end
	end
end