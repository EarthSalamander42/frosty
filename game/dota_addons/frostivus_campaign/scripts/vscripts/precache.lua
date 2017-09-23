if GetMapName() == "frostivus_2017" then
	g_ItemPrecache =
	{
		"item_tombstone",
		"item_bag_of_gold",
		"item_health_potion",
		"item_mana_potion",
		"item_life_rune",
--		"item_orb_of_passage",
	}

	g_UnitPrecache =
	{
		"npc_treasure_chest",
		"npc_dota_creature_techies_land_mine", -- spawned by treasure_chest trap
		"npc_dota_crate",
		"npc_dota_vase",
		"npc_dota_tavern_tuskarr",
		"npc_dota_tavern_kardel",
		"npc_dota_tavern_rylai",
	}

	g_ModelPrecache =
	{
		"models/gameplay/attrib_tome_int.vmdl",
		"models/gameplay/attrib_tome_agi.vmdl",
		"models/gameplay/attrib_tome_str.vmdl",
	}

	g_ParticlePrecache =
	{
--		"particles/msg_fx/msg_resist_schinese.vpcf",
	}

	g_ParticleFolderPrecache =
	{
		
		"particles/units/heroes/hero_sniper", -- Kardel VIP
		"particles/units/heroes/hero_crystal_maiden", -- Rylai VIP
	}

	g_SoundPrecache =
	{
		"soundevents/game_sounds_dungeon.vsndevts",
		"soundevents/game_sounds_dungeon_enemies.vsndevts",
		"soundevents/game_sounds_creeps.vsndevts",
		"soundevents/game_sounds_roshan_halloween.vsndevts", 
	}
end