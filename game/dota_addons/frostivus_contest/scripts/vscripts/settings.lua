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

-------------------------------------------------------------------------------------------------
-- Boss reward information
-------------------------------------------------------------------------------------------------

BASE_BOSS_EXP_REWARD = 240
BASE_BOSS_GOLD_REWARD = 400
BONUS_BOUNTY_PER_MINUTE = 10

-------------------------------------------------------------------------------------------------
-- Barebones basics
-------------------------------------------------------------------------------------------------

DOTA_MAX_PLAYERS = 10						-- Maximum amount of players allowed in a game

ABANDON_TIME = 180															-- Time for a player to be considered as having abandoned the game (in seconds)
FULL_ABANDON_TIME = 15														-- Time for a team to be considered as having abandoned the game (in seconds)

IMBA_DAMAGE_EFFECTS_DISTANCE_CUTOFF = 2500									-- Range at which most on-damage effects no longer trigger

HERO_RESPAWN_TIME_PER_LEVEL = {}											-- Hero respawn time per level
HERO_RESPAWN_TIME_PER_LEVEL[1] = 6
HERO_RESPAWN_TIME_PER_LEVEL[2] = 8
HERO_RESPAWN_TIME_PER_LEVEL[3] = 10
HERO_RESPAWN_TIME_PER_LEVEL[4] = 12
HERO_RESPAWN_TIME_PER_LEVEL[5] = 14
HERO_RESPAWN_TIME_PER_LEVEL[6] = 18
HERO_RESPAWN_TIME_PER_LEVEL[7] = 20
HERO_RESPAWN_TIME_PER_LEVEL[8] = 22
HERO_RESPAWN_TIME_PER_LEVEL[9] = 24
HERO_RESPAWN_TIME_PER_LEVEL[10] = 26
HERO_RESPAWN_TIME_PER_LEVEL[11] = 28
HERO_RESPAWN_TIME_PER_LEVEL[12] = 32
HERO_RESPAWN_TIME_PER_LEVEL[13] = 34
HERO_RESPAWN_TIME_PER_LEVEL[14] = 36
HERO_RESPAWN_TIME_PER_LEVEL[15] = 38
HERO_RESPAWN_TIME_PER_LEVEL[16] = 40
HERO_RESPAWN_TIME_PER_LEVEL[17] = 42
HERO_RESPAWN_TIME_PER_LEVEL[18] = 46
HERO_RESPAWN_TIME_PER_LEVEL[19] = 48
HERO_RESPAWN_TIME_PER_LEVEL[20] = 50
HERO_RESPAWN_TIME_PER_LEVEL[21] = 52
HERO_RESPAWN_TIME_PER_LEVEL[22] = 54
HERO_RESPAWN_TIME_PER_LEVEL[23] = 56
HERO_RESPAWN_TIME_PER_LEVEL[24] = 58
HERO_RESPAWN_TIME_PER_LEVEL[25] = 60

-------------------------------------------------------------------------------------------------
-- IMBA: map-based settings
-------------------------------------------------------------------------------------------------

-- NOTE: You always need at least 2 non-bounty type runes to be able to spawn or your game will crash!
ENABLED_RUNES = {}                      -- Which runes should be enabled to spawn in our game mode?
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
-- IMBA: game mode globals
-------------------------------------------------------------------------------------------------

GAME_WINNER_TEAM = "none"													-- Tracks game winner

END_GAME_ON_KILLS = false													-- Should the game end after a certain number of kills?
KILLS_TO_END_GAME_FOR_TEAM = 70												-- How many kills for a team should signify the end of the game?

IMBA_HERO_PICK_RULE = 0                                                     -- 0 : All Unique Heroes, 1 : Allow teams to pick same hero, 2 : Allow all to pick same hero

REMAINING_GOODGUYS = 0														-- Remaining players on Radiant
REMAINING_BADGUYS = 0														-- Remaining players on Dire

ANCIENT_ABILITIES_LIST = {}													-- Initializes the ancients' abilities list

HERO_INITIAL_GOLD = 625														-- Gold to add to players as soon as they spawn into the game

CHEAT_ENABLED = false

-------------------------------------------------------------------------------------------------
-- IMBA: Test mode variables
-------------------------------------------------------------------------------------------------

IMBA_TESTBED_INITIALIZED = false

-------------------------------------------------------------------------------------------------
-- IMBA: Keyvalue tables
-------------------------------------------------------------------------------------------------

HERO_ABILITY_LIST = LoadKeyValues("scripts/npc//KV/nonhidden_ability_list.kv")

IMBA_DEVS = {
	54896080,	-- Cookies
	46875732	-- Firetoad
}