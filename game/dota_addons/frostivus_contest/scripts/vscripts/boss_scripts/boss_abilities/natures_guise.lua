-- Treant's Nature's Guise (for the ability texture)

frostivus_boss_natures_guise = class({})

function frostivus_boss_natures_guise:IsHiddenWhenStolen() return true end
function frostivus_boss_natures_guise:IsRefreshable() return true end
function frostivus_boss_natures_guise:IsStealable() return false end

function frostivus_boss_natures_guise:GetAbilityTexture()
	return "treant_natures_guise"
end