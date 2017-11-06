"use strict";

var JS_PHASE = 0
var playerPanels = {};

function UpdateTimer( data )
{
	var timerText = "";
	timerText += data.timer_minute_10;
	timerText += data.timer_minute_01;
	timerText += ":";
	timerText += data.timer_second_10;
	timerText += data.timer_second_01;

	$( "#Timer" ).text = timerText;
}

function OnUIUpdated(table_name, key, data)
{
	UpdateScoreUI();
}
CustomNetTables.SubscribeNetTableListener("game_options", OnUIUpdated)

var update_boss_level = false
function UpdateScoreUI()
{
	var RadiantScore = CustomNetTables.GetTableValue("game_options", "radiant").score;
	var DireScore = CustomNetTables.GetTableValue("game_options", "dire").score;

	$("#RadiantScoreText").SetDialogVariableInt("radiant_score", RadiantScore);
	$("#RadiantScoreText").text = RadiantScore;

	$("#DireScoreText").SetDialogVariableInt("dire_score", DireScore);
	$("#DireScoreText").text = DireScore;
}

function Phase(args)
{
	$("#PhaseLabel").text = $.Localize("#diretide_phase_" + args.Phase);
	JS_PHASE = args.Phase

	if (args.Phase == 1)
	{
		$("#Frostivus").style.visibility = "visible";
		$("#Frostivus2").style.visibility = "visible";
	}
	if (args.Phase == 2)
	{
		$('#ScorePanel').MoveChildBefore($('#Timer'), $('#Boss'));
	}
	else if (args.Phase == 3)
	{
		$("#Frostivus2").style.visibility = "collapse";
		$("#BossHP").style.visibility = "visible";
	}
}

function FrostivusInfo()
{
	$.DispatchEvent("UIShowTextTooltip", $("#PhaseLabel"), $.Localize("#diretide_phase_" + JS_PHASE + "_desc"));
}

var toggle = false
function FrostivusAltar() {
	if (toggle == false) {
		$("#FrostivusAltarMenu").style.visibility = "visible";
		toggle = true
	}
	else {
		$("#FrostivusAltarMenu").style.visibility = "collapse";
		toggle = false
	}
}

function ChooseAltar(number) {
	var altar = $("#AltarButton" + number)
	var playerInfo = Game.GetPlayerInfo( Players.GetLocalPlayer() )
//	$.Msg(playerInfo)

	if (playerInfo.player_team_id == 2) {
		if (altar.BHasClass("radiant")) {
			/* remove selected class from the previous button */
			var panel_table = $("#FrostivusAltarMenu").FindChildrenWithClassTraverse("selected");
			for (var i = 0; i < panel_table.length; i++) {
				panel_table[i].RemoveClass("selected")
			}
			// TODO: Send to lua wich altar is chosen

			altar.AddClass("selected");
		}
	} else if (playerInfo.player_team_id == 3) {
		if (altar.BHasClass("dire")) {
			/* remove selected class from the previous button */
			var panel_table = $("#FrostivusAltarMenu").FindChildrenWithClassTraverse("selected");
			for (var i = 0; i < panel_table.length; i++) {
				panel_table[i].RemoveClass("selected")
			}
			// TODO: Send to lua wich altar is chosen

			altar.AddClass("selected");
		}
	}
}

function OnPlayerReconnect( data ) {
	$.Msg("Frostivus: Player has reconnected!")
	var phase = data.Phase;
	$.Msg("Phase: " + phase)
}

function ShowBossBar(args)
{
	$("#BossHP").style.visibility = "visible";

	var BossTable = CustomNetTables.GetTableValue("game_options", "boss");
	if (BossTable !== null)
	{
		var BossHP = BossTable.HP;
		var BossHP_percent = BossTable.HP_alt;
		var BossMaxHP = BossTable.maxHP;
		var BossLvl = BossTable.level;
		var BossLabel = BossTable.label;

		$("#BossProgressBar").value = BossHP_percent / 100;
		$("#BossHealth").text = BossHP + "/" + BossMaxHP;

		if (update_boss_level == false)
		{
			$.Msg($("#BossLevel").text + BossLvl)
			$.Msg("Setup Boss name: " + BossLabel)

			$("#BossLevel").text = $("#BossLevel").text + BossLvl
			$("#BossLabel").text = $.Localize(BossLabel)
			update_boss_level = true
		}
	}
}

function HideBossBar(args)
{
	$("#BossHP").style.visibility = "collapse";
	update_boss_level = false
}

(function()
{
	$("#AltarButton1").AddClass("radiant");
	$("#AltarButton7").AddClass("dire");

	GameEvents.Subscribe("countdown", UpdateTimer);
	GameEvents.Subscribe("update_score", UpdateScoreUI);
	GameEvents.Subscribe("frostivus_phase", Phase);
	GameEvents.Subscribe("diretide_player_reconnected", OnPlayerReconnect);
	GameEvents.Subscribe("show_boss_hp", ShowBossBar);
	GameEvents.Subscribe("hide_boss_hp", HideBossBar);
})();
