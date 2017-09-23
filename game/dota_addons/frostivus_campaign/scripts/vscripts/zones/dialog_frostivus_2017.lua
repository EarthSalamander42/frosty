if GetMapName() == "frostivus_2017" then
	_G.DialogDefinition =
	{
		npc_dota_tavern_tuskarr =
		{
			{ -- start of speak_to_tuskarr
				szText = "Dialog_TavernTuskarr_LearnAboutFrostivus",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true, 
				Gesture = ACT_DOTA_IDLE_RARE,
			},
			{
				szText = "Dialog_TavernTuskarr_LearnAboutFrostivus_02",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = false, 
				Gesture = ACT_DOTA_IDLE_RARE,
			}, -- end of speak_to_tuskarr
		},

		npc_dota_tavern_kardel =
		{
			{ -- start of rylai_is_back
				szText = "Dialog_TavernKardel_RylaiIsBack",
				szRequireQuestActive = "rylai_is_back",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true, 
				Gesture = ACT_DOTA_IDLE,
			},
			{
				szText = "Dialog_TavernKardel_RylaiIsBack_02",
				szRequireQuestActive = "rylai_is_back",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true, 
				Gesture = ACT_DOTA_IDLE,
			},
			{
				szText = "Dialog_TavernKardel_RylaiIsBack_confirm",
				szRequireQuestActive = "rylai_is_back",
				flAdvanceTime = 30.0,
				bSendToAll = true,
				bAdvance = true, 
				bPlayersConfirm = true,
				szConfirmToken = "LearnAboutFrostivus",
				Gesture = ACT_DOTA_IDLE,
				SpawnVIP = "npc_dota_tavern_rylai",
				SpawnPointVIP = "tavern_holdout_spawner_rylai_vip",
				CameraFocusUnit = "npc_dota_tavern_rylai",
				CameraFocusDuration = 12.0, -- Must go with CameraFocusUnit
			}, -- end of rylai_is_back
		},

		npc_dota_friendly_bristleback_son =
		{
			{
				szText = "Dialog_FriendlyBristlebackSon_PreMission",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_LOADOUT,
			},
			{
				szText = "Dialog_FriendlyBristlebackSon_PreMission_02",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_LOADOUT,
			},
			{
				szText = "Dialog_FriendlyBristlebackSon",
				flAdvanceTime = 30.0,
				bSendToAll = true,
				bAdvance = true,
				bPlayersConfirm = true,
				szConfirmToken = "LearnAboutEscort",
				Gesture = ACT_DOTA_LOADOUT,
				szLogicRelay = "desert_start_babyback_relay",
				InitialGoalEntity = "desert_start_path_1",
			},
		},
		npc_dota_creature_lycan_boss =
		{
			{
				szText = "",
				Gesture = ACT_DOTA_VICTORY, 
				Sound = "lycan_lycan_battlebegins_01",
				bSkipBossIntro = false,

				bSendToAll = true,
				bAdvance = true, 

				flAdvanceTime = 5.0,
			},
		},
		npc_dota_creature_temple_guardian =
		{
			{
				szText = "",
				Gesture = ACT_DOTA_CAST_ABILITY_5, 
				flAdvanceTime = 8.0,
				bAdvance = true,
				bSkipBossIntro = true,
			}
		},
		npc_dota_creature_ogre_tank_boss =
		{
			{
				szText = "",
				Gesture = ACT_DOTA_CAPTURE, 
				Sound = "ogre_magi_ogmag_attack_04",
				bSkipBossIntro = false,

				bSendToAll = true,
				bAdvance = true, 

				flAdvanceTime = 5.0,
			},
		},
		npc_dota_creature_spider_boss =
		{
			{
				szText = "",
				Gesture = ACT_DOTA_CAST_ABILITY_2, 
				Sound = "broodmother_broo_spawn_04",
				bSkipBossIntro = false,

				bSendToAll = true,
				bAdvance = true, 

				flAdvanceTime = 5.0,
			},
		},
		npc_dota_creature_sand_king =
		{
			{
				szText = "",
				Gesture = ACT_DOTA_RAZE_3, 
				Sound = "sandking_skg_rare_02",
				bSkipBossIntro = false,

				bSendToAll = true,
				bAdvance = true, 

				flAdvanceTime = 5.0,
			},
		},
		npc_dota_injured_contact =
		{
			{
				szText = "Dialogue_theod_quest_text",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "Dialogue_theod_quest_text_02",
				flAdvanceTime = 15.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
		},
		npc_dota_desert_townfolk_1 =
		{
			{
				szText = "desert_town_folk_01_01",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_01_02",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_01_03",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_01_04",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_01_05",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_01_06",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = false,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
		},
		npc_dota_desert_townfolk_2 =
		{
			{
				szText = "desert_town_folk_02_01",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_02_02",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_02_03",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_02_04",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_02_05",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_02_06",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
		},
		npc_dota_desert_townfolk_3 =
		{
			{
				szText = "desert_town_folk_03_01",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_03_02",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_03_03",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_03_04",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_03_05",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
		},
		npc_dota_desert_townfolk_4 =
		{
			{
				szText = "desert_town_folk_04_01",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bDialogStopsMovement = true,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_04_02",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bDialogStopsMovement = true,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_04_03",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bDialogStopsMovement = true,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_04_04",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bDialogStopsMovement = true,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_04_05",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bDialogStopsMovement = true,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_04_06",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = false,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bDialogStopsMovement = true,
			},
		},
		npc_dota_desert_townfolk_5 =
		{
			{
				szText = "desert_town_folk_05_01",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_05_02",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_05_03",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_05_04",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_05_05",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
		},
		npc_dota_desert_townfolk_6 =
		{
			{
				szText = "desert_town_folk_06_01",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_06_02",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_06_03",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_06_04",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_06_05",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_06_06",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_06_07",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = false,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
		},	
		npc_dota_desert_townfolk_7 =
		{
			{
				szText = "desert_town_folk_07_01",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_07_02",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_07_03",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
			{
				szText = "desert_town_folk_07_04",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_07_05",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
				bForceBreak = true,
			},
			{
				szText = "desert_town_folk_07_06",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = false,
				Gesture = ACT_DOTA_IDLE_IMPATIENT,
			},
		},	
		npc_dota_bristleback_grandpa =
		{
			{
				szText = "desert_town_bristleback_grandpa",
				flAdvanceTime = 10.0,
				bSendToAll = false,
				bAdvance = false,
				Gesture = ACT_DOTA_IDLE_RARE,
				szLogicRelay = "desert_town_bristleback_grandpa_relay",
			},
		},
		npc_dota_friendly_bristleback =
		{
			{
				szText = "Dialog_BristleDad",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = false,
				Gesture = ACT_DOTA_LOADOUT,
				bForceBreak = true,
				szAdvanceQuestActive = "reach_desert_outpost",
			},
			{
				szText = "Dialog_BristleDad_GoToOutpost",
				szRequireQuestActive = "reach_desert_outpost",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = false, 
				Gesture = ACT_DOTA_IDLE,
				szLogicRelay = "desert_expanse_bristleback_dad_relay",
			},
		},
		npc_dota_temple_wisp =
		{
			{
				szText = "dia_wisp_temple_01",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
			},
			{
				szText = "dia_wisp_temple_02",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
			},
			{
				szText = "dia_wisp_temple_03",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
			},
			{
				szText = "dia_wisp_temple_04",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
			},
			{
				szText = "dia_wisp_temple_05",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
			},
			{
				szText = "dia_wisp_temple_06",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
			},
			{
				szText = "dia_wisp_temple_07",
				flAdvanceTime = 10.0,
				bSendToAll = true,
				bAdvance = false,
				Gesture = ACT_DOTA_VICTORY,
			},
		},
		npc_dota_creature_invoker =
		{
			{
				szText = "dia_special_guest_01",
				Sound = "invoker_invo_happy_05",

				flAdvanceTime = 5.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
				bForceBreak = true,
			},
			{
				szText = "dia_special_guest_02",
				Sound = "invoker_invo_happy_07",

				flAdvanceTime = 5.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
			},
			{
				szText = "dia_special_guest_03",
				Sound = "invoker_invo_happy_06",

				flAdvanceTime = 5.0,
				bSendToAll = false,
				bAdvance = true,
				Gesture = ACT_DOTA_VICTORY,
				bForceBreak = true,
			},
			{
				szText = "dia_special_guest_04",
				Sound = "invoker_invo_happy_08",

				flAdvanceTime = 5.0,
				bSendToAll = false,
				bAdvance = false,
				Gesture = ACT_DOTA_VICTORY,
			},
		},
		npc_dota_journal_note_01 =
		{
			{
				szText = "chef_journal_01",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},
		npc_dota_journal_note_02 =
		{
			{
				szText = "chef_journal_02",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_03 =
		{
			{
				szText = "chef_journal_03",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_04 =
		{
			{
				szText = "chef_journal_04",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_05 =
		{
			{
				szText = "chef_journal_05",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_06 =
		{
			{
				szText = "chef_journal_06",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_07 =
		{
			{
				szText = "chef_journal_07",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_08 =
		{
			{
				szText = "chef_journal_08",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_09 =
		{
			{
				szText = "chef_journal_09",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
		npc_dota_journal_note_10 =
		{
			{
				szText = "chef_journal_10",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},
		npc_dota_journal_note_11 =
		{
			{
				szText = "chef_journal_11",
				flAdvanceTime = 100.0,
				bSendToAll = false,
				bAdvance = false,
				bSkipFacePlayer = true,
			},
		},	
	}
end
