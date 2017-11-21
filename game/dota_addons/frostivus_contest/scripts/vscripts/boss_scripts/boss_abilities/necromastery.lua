-- Nevermore's Necromastery (for the clientside modifier)

frostivus_boss_necromastery = class({})

function frostivus_boss_necromastery:IsHiddenWhenStolen() return true end
function frostivus_boss_necromastery:IsRefreshable() return true end
function frostivus_boss_necromastery:IsStealable() return false end