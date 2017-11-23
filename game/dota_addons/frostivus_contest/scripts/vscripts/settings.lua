-------------------------------------------------------------------------------------------------
-- Frostivus: Game settings
-------------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------------
-- Boss spawn information
-------------------------------------------------------------------------------------------------

BOSS_SPAWN_POINT_TABLE = {}

BOSS_SPAWN_POINT_TABLE.zeus = "altar_2"
BOSS_SPAWN_POINT_TABLE.venomancer = "altar_3"
BOSS_SPAWN_POINT_TABLE.lich = "altar_4"
BOSS_SPAWN_POINT_TABLE.treant = "altar_5"
BOSS_SPAWN_POINT_TABLE.nevermore = "altar_6"

RADIANT_FIGHTING = false
DIRE_FIGHTING = false

-------------------------------------------------------------------------------------------------
-- Barebones basics
-------------------------------------------------------------------------------------------------

DOTA_MAX_PLAYERS = 10						-- Maximum amount of players allowed in a game

ABANDON_TIME = 180							-- Time for a player to be considered as having abandoned the game (in seconds)
FULL_ABANDON_TIME = 15						-- Time for a team to be considered as having abandoned the game (in seconds)

IMBA_DAMAGE_EFFECTS_DISTANCE_CUTOFF = 2500	-- Range at which most on-damage effects no longer trigger

-------------------------------------------------------------------------------------------------
-- FROSTIVUS: map-based settings
-------------------------------------------------------------------------------------------------

-- NOTE: You always need at least 2 non-bounty type runes to be able to spawn or your game will crash!
ENABLED_RUNES = {}                      	-- Which runes should be enabled to spawn in our game mode?
ENABLED_RUNES[DOTA_RUNE_DOUBLEDAMAGE] = true
ENABLED_RUNES[DOTA_RUNE_HASTE] = true
ENABLED_RUNES[DOTA_RUNE_ILLUSION] = true
ENABLED_RUNES[DOTA_RUNE_INVISIBILITY] = true
ENABLED_RUNES[DOTA_RUNE_REGENERATION] = true
ENABLED_RUNES[DOTA_RUNE_BOUNTY] = true
ENABLED_RUNES[DOTA_RUNE_ARCANE] = true
--	ENABLED_RUNES[DOTA_RUNE_HAUNTED] = true
--	ENABLED_RUNES[DOTA_RUNE_MYSTERY] = true
--	ENABLED_RUNES[DOTA_RUNE_RAPIER] = true
--	ENABLED_RUNES[DOTA_RUNE_SPOOKY] = true
--	ENABLED_RUNES[DOTA_RUNE_TURBO] = true

-------------------------------------------------------------------------------------------------
-- FROSTIVUS: game mode globals
-------------------------------------------------------------------------------------------------

GAME_WINNER_TEAM = "none"													-- Tracks game winner

END_GAME_ON_KILLS = false													-- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 70												-- How many kills for a team should signify the end of the game?

REMAINING_GOODGUYS = 0														-- Remaining players on Radiant
REMAINING_BADGUYS = 0														-- Remaining players on Dire

ANCIENT_ABILITIES_LIST = {}													-- Initializes the ancients' abilities list
HERO_INITIAL_GOLD = 625														-- Gold to add to players as soon as they spawn into the game
CHEAT_ENABLED = false

DEVS = {
	54896080,	-- Cookies
	46875732	-- Firetoad
}