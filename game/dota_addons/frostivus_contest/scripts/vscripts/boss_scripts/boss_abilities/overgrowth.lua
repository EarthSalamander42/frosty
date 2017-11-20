-- Treant's Overgrowth (for the clientside modifier)

frostivus_boss_overgrowth = class({})

function frostivus_boss_overgrowth:IsHiddenWhenStolen() return true end
function frostivus_boss_overgrowth:IsRefreshable() return true end
function frostivus_boss_overgrowth:IsStealable() return false end