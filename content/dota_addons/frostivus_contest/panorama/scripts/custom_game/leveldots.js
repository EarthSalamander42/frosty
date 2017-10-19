'use strict';

(function () {
	GameEvents.Subscribe("dota_player_update_selected_unit", function () {$.Schedule(0.1, InjectBottomAbilityDotsStyle)})
	GameEvents.Subscribe("dota_player_update_query_unit", function () {$.Schedule(0.1, InjectQueryAbilityDotsStyle)})
}())

function GetHUDRootUI(){
	var rootUI = $.GetContextPanel();
	while(rootUI.id != "Hud" && rootUI.GetParent() != null){
		rootUI = rootUI.GetParent();
	}
	return rootUI;
}

function InjectAbilityDotsStyle(abilitiesPanel, dotStyles, containerStyles) {
	abilitiesPanel.ApplyStyles(false)

	// Loop through ability panels
	abilitiesPanel.Children().forEach(function (abilityPanel) {
		var abilityLevelContainer = abilityPanel.FindChildTraverse("AbilityLevelContainer")

		// Figure out the group of styles in dotStyles to apply
		for (var dotClassName in dotStyles) {
			if (abilityPanel.BHasClass(dotClassName)) {
				break
			}
		}
		// Figure out the group of styles in containerStyles to apply
		for (var containerClassName in containerStyles) {
			if (abilityPanel.BHasClass(containerClassName)) {
				break
			}
		}
		//  Apply styles to AbilityLevelContainer
		if (containerStyles !== null) {
			for (var attribute in containerStyles[containerClassName]) {
				abilityLevelContainer.style[attribute] = containerStyles[containerClassName][attribute]
			}
		}
		//  Loop through level dots and apply style
		abilityLevelContainer.Children().forEach(function (levelDot) {
			for (var attribute in dotStyles[dotClassName]) {
				levelDot.style[attribute] = dotStyles[dotClassName][attribute]
			}
		})
	})
	abilitiesPanel.ApplyStyles(true)
}

function InjectBottomAbilityDotsStyle() {
	var abilitiesPanel = GetHUDRootUI().FindChildTraverse("abilities")
	var dotStyles = {	AbilityMaxLevel6: {width: "7px", height: "4px", margin: "3px 1px 3px 1px"},
						default: {width: null, margin: null}}
	InjectAbilityDotsStyle(abilitiesPanel, dotStyles, null)
}

function InjectQueryAbilityDotsStyle() {
	var abilitiesPanel = GetHUDRootUI().FindChildTraverse("abilities")
	var dotStyles = {	AbilityMaxLevel6: {width: "3px", height: "3px", margin: "0px 1.4px 1px 1.4px"},
						default: {width: null, height: null, margin: null}}
	var containerStyles = {	AbilityMaxLevel6: {"margin-left": "1px"},
							default: {"margin": null}}
	InjectAbilityDotsStyle(abilitiesPanel, dotStyles, containerStyles)

	// Also call styling function for bottom panel in case user has set unit query to override
	// hero control panel

	InjectBottomAbilityDotsStyle()
}