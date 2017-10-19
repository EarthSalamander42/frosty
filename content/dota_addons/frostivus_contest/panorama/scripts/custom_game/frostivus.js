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
	$( "#Timer_alt" ).text = timerText;
}

function OnUIUpdated(table_name, key, data)
{
	UpdateScoreUI();
}
CustomNetTables.SubscribeNetTableListener("game_options", OnUIUpdated)

function UpdateScoreUI()
{
	var RadiantScore = CustomNetTables.GetTableValue("game_options", "radiant").score;
	var DireScore = CustomNetTables.GetTableValue("game_options", "dire").score;

	$("#RadiantScoreText").SetDialogVariableInt("radiant_score", RadiantScore);
	$("#RadiantScoreText").text = RadiantScore;

	$("#DireScoreText").SetDialogVariableInt("dire_score", DireScore);
	$("#DireScoreText").text = DireScore;

	var RoshanTable = CustomNetTables.GetTableValue("game_options", "roshan");
	if (JS_PHASE == 3)
	{
		if (RoshanTable !== null)
		{
			var RoshanHP = RoshanTable.HP;
			var RoshanHP_percent = RoshanTable.HP_alt;
			var RoshanMaxHP = RoshanTable.maxHP;
			var RoshanLvl = RoshanTable.level;
			$("#RoshanProgressBar").value = RoshanHP_percent / 100;

			$("#RoshanHealth").text = RoshanHP + "/" + RoshanMaxHP;
			$("#RoshanLevel").text = "Level: " + RoshanLvl;
		}
	}
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
		$('#ScorePanel').MoveChildBefore($('#Timer'), $('#Roshan'));
		$("#RoshanTarget").style.visibility = "visible";
	}
	else if (args.Phase == 3)
	{
		$("#Frostivus2").style.visibility = "collapse";
		$("#RoshanHP").style.visibility = "visible";
	}
}

function RoshanTarget(args)
{
	$("#RoshanTarget").text = $.Localize(args.target);
	if (args.team_target == 2)
	{
		$("#RoshanTarget").style.color = "green";
	}
	else if (args.team_target == 3)
	{
		$("#RoshanTarget").style.color = "red";
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

function HallOfFame()
{
	var hudElements = $.GetContextPanel().GetParent().GetParent().GetParent().FindChildTraverse("HUDElements");

	hudElements.FindChildTraverse("topbar").style.visibility = "collapse";
	hudElements.FindChildTraverse("shop").style.visibility = "collapse";
	hudElements.FindChildTraverse("minimap_container").style.visibility = "collapse";
	hudElements.FindChildTraverse("lower_hud").style.visibility = "collapse";

	$("#RoshanHP").style.visibility = "collapse";
	$("#HallOfFame").style.visibility = "visible";

	/* Remove later, only tools testing */
	$("#Frostivus").style.visibility = "collapse";
	$("#Frostivus2").style.visibility = "collapse";

	var RoshanTable = CustomNetTables.GetTableValue("game_options", "roshan");
	var RoshanLvl = RoshanTable.level;
	$("#RoshanLevel_alt").text = "Level: " + RoshanLvl

	//Get the players for both teams
	var radiantPlayers = Game.GetPlayerIDsOnTeam( DOTATeam_t.DOTA_TEAM_GOODGUYS );
	var direPlayers = Game.GetPlayerIDsOnTeam( DOTATeam_t.DOTA_TEAM_BADGUYS );

	//Assign radiant players
	$.Each( radiantPlayers, function( player ) {
		var playerPanel = Modular.Spawn( "picking_player", $("#RadiantPlayers"), "HoF" );
		var playerInfo = Game.GetPlayerInfo( player )

		playerPanels[player] = playerPanel;

		playerPanels[player].SetHero(playerInfo.player_selected_hero);
		playerPanel.SetPlayer( player );
	});

	//Assign dire players
	$.Each( direPlayers, function( player ) {
		var playerPanel = Modular.Spawn( "picking_player", $("#DirePlayers"), "HoF" );
		var playerInfo = Game.GetPlayerInfo( player )

		playerPanels[player] = playerPanel;

		playerPanels[player].SetHero(playerInfo.player_selected_hero);
		playerPanel.SetPlayer( player );
	});
}

function OnPlayerReconnect( data ) {
	$.Msg("Frostivus: Player has reconnected!")
	var phase = data.Phase;
	$.Msg("Phase: " + phase)
}

(function()
{
	$("#AltarButton1").AddClass("radiant");
	$("#AltarButton7").AddClass("dire");

	GameEvents.Subscribe("countdown", UpdateTimer);
	GameEvents.Subscribe("update_score", UpdateScoreUI);
	GameEvents.Subscribe("frostivus_phase", Phase);
	GameEvents.Subscribe("roshan_target", RoshanTarget);
	GameEvents.Subscribe("hall_of_fame", HallOfFame);
	GameEvents.Subscribe("diretide_player_reconnected", OnPlayerReconnect);
})();
