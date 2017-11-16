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
	$.Msg("Phase: " + data.Phase)
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
		var BossShortLabel = BossTable.short_label;

		$("#BossProgressBar").value = BossHP_percent / 100;
		$("#BossHealth").text = BossHP + "/" + BossMaxHP;

		if (update_boss_level == false)
		{
			if (BossShortLabel == "venomancer") {
				$("#BossProgressBar_Left").style.backgroundColor = 'gradient( linear, 0% 0%, 0% 100%, from( #326114 ), color-stop( 0.3, #54BA07 ), color-stop( .5, #54BA07 ), to( #326114 ) )';
			} else if (BossShortLabel == "zuus") {
				$("#BossProgressBar_Left").style.backgroundColor = 'gradient( linear, 0% 0%, 0% 100%, from( #1A75FF ), color-stop( 0.3, #1A75FF ), color-stop( .5, #66a3ff ), to( #326114 ) )';
			}
			$("#BossLevel").text = $.Localize("boss_level") + BossLvl
			$("#BossLabel").text = $.Localize(BossLabel)
			$("#BossIcon").style.backgroundImage = 'url("file://{images}/heroes/icons/npc_dota_hero_'+ BossShortLabel +'.png")';
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
		if ($("#AltarButton" + args.altar).BHasClass("dire")) {
			$("#AltarButton" + args.altar).RemoveClass("dire")
		}
		$("#AltarButton" + args.altar).AddClass("radiant");
	} else {
		if ($("#AltarButton" + args.altar).BHasClass("radiant")) {
			$("#AltarButton" + args.altar).RemoveClass("radiant")
		}
		$("#AltarButton" + args.altar).AddClass("dire");
	}
	$.Msg("Added a new altar: " + args.altar + " for team: " + args.team)
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
