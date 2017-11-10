-- Venomancer's Poison Nova (for the clientside modifier)

frostivus_boss_poison_nova = class({})

function frostivus_boss_poison_nova:IsHiddenWhenStolen() return true end
function frostivus_boss_poison_nova:IsRefreshable() return true end
function frostivus_boss_poison_nova:IsStealable() return false end