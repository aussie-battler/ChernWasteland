// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Version: 1.2
//	@file Name: init.sqf
//	@file Author: [404] Deadbeat, [GoT] JoSchaap, AgentRev
//	@file Description: The main init.

#define DEBUG false

enableSaving [false, false];

// block script injection exploit
inGameUISetEventHandler ["PrevAction", ""];
inGameUISetEventHandler ["Action", ""];
inGameUISetEventHandler ["NextAction", ""];

_descExtPath = str missionConfigFile;
currMissionDir = compileFinal str (_descExtPath select [0, count _descExtPath - 15]);

X_Server = false;
X_Client = false;
X_JIP = false;

// versionName = ""; // Set in STR_WL_WelcomeToWasteland in stringtable.xml

if (isServer) then { X_Server = true };
if (!isDedicated) then { X_Client = true };
if (isNull player) then { X_JIP = true };

A3W_scriptThreads = [];

[DEBUG] call compile preprocessFileLineNumbers "globalCompile.sqf";

//init Wasteland Core
[] execVM "config.sqf";
[] execVM "storeConfig.sqf"; // Separated as its now v large
[] execVM "briefing.sqf";

if (!isDedicated) then
{
	[] spawn
	{
		if (hasInterface) then // Normal player
		{
			9999 cutText ["Welcome to A3Wasteland, please wait for your client to initialize", "BLACK", 0.01];

			waitUntil {!isNull player};
			player setVariable ["playerSpawning", true, true];
			playerSpawning = true;

			removeAllWeapons player;
			client_initEH = player addEventHandler ["Respawn", { removeAllWeapons (_this select 0) }];

			// Reset group & side
			[player] joinSilent createGroup playerSide;

			execVM "client\init.sqf";

			if ((vehicleVarName player) select [0,17] == "BIS_fnc_objectVar") then { player setVehicleVarName "" }; // undo useless crap added by BIS
		}
		else // Headless
		{
			waitUntil {!isNull player};
			if (getText (configFile >> "CfgVehicles" >> typeOf player >> "simulation") == "headlessclient") then
			{
				execVM "client\headless\init.sqf";
			};
		};
	};
};

if (isServer) then
{
	diag_log format ["############################# %1 #############################", missionName];
	diag_log "WASTELAND SERVER - Initializing Server";
	[] execVM "server\init.sqf";
};

if (hasInterface || isServer) then
{
	//init 3rd Party Scripts
	[] execVM "addons\R3F_LOG\init.sqf";
	[] execVM "addons\proving_ground\init.sqf";
	[] execVM "addons\JumpMF\init.sqf";
	[] execVM "addons\laptop\init.sqf";							// Addon for hack laptop mission
	[] execVM "addons\vactions\functions.sqf";				    // Micovery vehicle actions
	[] execVM "addons\APOC_Airdrop_Assistance\init.sqf";		// Airdrop
	[] execVM "addons\outlw_magRepack\MagRepack_init.sqf";
	[] execVM "fusionsmenu\admin\loop.sqf";						// Fusions adminmenu
    [] execVM "fusionsmenu\admin\activate.sqf";					// Fusions adminmenu
	[] execVM "addons\lsd_nvg\init.sqf";
	[] execVM "addons\HvT\HvT.sqf"; 							// High Value Target
	[] execVM "addons\HvT\HvD.sqf"; 							// High Value Drugrunner
	[] execVM "addons\Grenades\ToxicGas.sqf"; 					// Toxic Gas Addon
	[] execVM "addons\taru_pods\taru_init.sqf";                 // Taru Pods
	[] execVM "addons\scripts\intro.sqf";						// Welcome intro
	[] execVM "addons\AF_Keypad\AF_KP_vars.sqf";			    // Keypad for base locking
	if (isNil "drn_DynamicWeather_MainThread") then { drn_DynamicWeather_MainThread = [] execVM "addons\scripts\DynamicWeatherEffects.sqf" };
};

//AI Spawn Script Pack
//nul = [750,1200,30,300,4,[0,1,0],player,0.3,0,2500,nil,["COMBAT","SAD"],true] execVM "LV\ambientCombat.sqf";
//nul = [500,1000,30,300,6,[0.5,1,0.5],player,0.4,0,2500,nil,["COMBAT","SAD"],true] execVM "LV\ambientCombat.sqf";
//nul = [800,1000,15,100,6,[0.5,1,0.5],player,0.5,1,2500,nil,["COMBAT","SAD"],true] execVM "LV\ambientCombat.sqf";
//nul = [player,2,150,[true,false],[true,false,false],false,[3,1],[1,1],0.3,nil,nil,nil] execVM "LV\militarize.sqf";
//nul = [player,2,true,2,[4,2],1,0.3,nil,nil,nil] execVM "LV\fillHouse.sqf";
//nul = [player,2,true,true,1500,"random",true,200,150,8,0.5,80,true,false,false,true,player,false,[0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5,0.5],nil,nil,nil,true] execVM "LV\heliParadrop.sqf";
//nul = [[1],[player],500,true,true] execVM "LV\LV_functions\LV_fnc_simpleCache.sqf";