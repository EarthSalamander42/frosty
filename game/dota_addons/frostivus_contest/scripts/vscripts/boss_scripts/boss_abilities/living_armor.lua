-- Treant's Living armor (for the clientside modifier)

frostivus_boss_living_armor = class({})

function frostivus_boss_living_armor:IsHiddenWhenStolen() return true end
function frostivus_boss_living_armor:IsRefreshable() return true end
function frostivus_boss_living_armor:IsStealable() return false end