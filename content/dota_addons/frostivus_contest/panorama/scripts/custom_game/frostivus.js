"use strict";

var JS_PHASE = 0
var update_boss_level = false
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

function Phase(args)
{
	$("#PhaseLabel").text = $.Localize("#frostivus_phase_" + args.Phase);
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
	$.DispatchEvent("UIShowTextTooltip", $("#PhaseLabel"), $.Localize("#frostivus_phase_" + JS_PHASE + "_desc"));
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
	var playerInfo = Game.GetPlayerInfo(Players.GetLocalPlayer())

	if (playerInfo.player_team_id == 2) {
		if (altar.BHasClass("radiant")) {
			var panel_table = $("#FrostivusAltarMenu").FindChildrenWithClassTraverse("selected");
			for (var i = 0; i < panel_table.length; i++) {
				panel_table[i].RemoveClass("selected")
			}
			altar.AddClass("selected");
			GameEvents.SendCustomGameEventToServer("spawn_point", {"player": Players.GetLocalPlayer(), "altar": number});
		}
	} else if (playerInfo.player_team_id == 3) {
		if (altar.BHasClass("dire")) {
			var panel_table = $("#FrostivusAltarMenu").FindChildrenWithClassTraverse("selected");
			for (var i = 0; i < panel_table.length; i++) {
				panel_table[i].RemoveClass("selected")
			}
			altar.AddClass("selected");
			GameEvents.SendCustomGameEventToServer("spawn_point", {"player": Players.GetLocalPlayer(), "altar": number});
		}
	}
}

function OnPlayerReconnect( data ) {
	$.Msg("Frostivus: Player has reconnected!")
	var phase = data.Phase;
	$.Msg("Phase: " + phase)
}

function UpdateBossBar(args) {
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
			$("#BossLevel").text = $.Localize("boss_level") + BossLvl
			$("#BossLabel").text = $.Localize(BossLabel)
			update_boss_level = true
		}
	}
}
CustomNetTables.SubscribeNetTableListener("game_options", UpdateBossBar)

function ShowBossBar(args)
{
	$("#BossHP").style.visibility = "visible";
}

function HideBossBar(args)
{
	$("#BossHP").style.visibility = "collapse";
	$("#BossLevel").text = "";
	update_boss_level = false
}

function UpdateAltar(args)
{
	if (args.team == 2) {
		$("#AltarButton" + args.altar).AddClass("radiant");
	} else {
		$("#AltarButton" + args.altar).AddClass("dire");
	}
	$.Msg("Adde a new altar: " + args.altar + "for team: " + args.team)
}

(function()
{
	$("#AltarButton1").AddClass("radiant");
	$("#AltarButton7").AddClass("dire");

	GameEvents.Subscribe("countdown", UpdateTimer);
	GameEvents.Subscribe("frostivus_phase", Phase);
	GameEvents.Subscribe("diretide_player_reconnected", OnPlayerReconnect);
	GameEvents.Subscribe("show_boss_hp", ShowBossBar);
	GameEvents.Subscribe("hide_boss_hp", HideBossBar);
	GameEvents.Subscribe("update_altar", UpdateAltar);
})();
