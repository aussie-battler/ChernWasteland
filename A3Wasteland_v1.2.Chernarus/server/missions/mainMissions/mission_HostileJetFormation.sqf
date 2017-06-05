// ******************************************************************************************
// * This project is licensed under the GNU Affero GPL v3. Copyright © 2014 A3Wasteland.com *
// ******************************************************************************************
//	@file Name: mission_HostileJetFormation.sqf
//	@file Author: JoSchaap, AgentRev, LouD

if (!isServer) exitwith {};
#include "mainMissionDefines.sqf"

private ["_planeChoices", "_convoyVeh", "_veh1", "_veh2", "_createVehicle", "_vehicles", "_leader", "_speedMode", "_waypoint", "_vehicleName", "_vehicleName2", "_numWaypoints", "_cash", "_box1", "_box2", "_box3"];

_setupVars =
{
	_missionType = "Hostile Jets";
	_locationsArray = nil; // locations are generated on the fly from towns
};

_setupObjects =
{
	_missionPos = markerPos (((call cityList) call BIS_fnc_selectRandom) select 0);

	_planeChoices =
	[
		["CUP_B_A10_CAS_USA", "CUP_B_A10_CAS_USA"],
		["CUP_B_F35B_CAS_BAF", "CUP_B_F35B_CAS_BAF"]
	];

	_convoyVeh = _planeChoices call BIS_fnc_selectRandom;

	_veh1 = _convoyVeh select 0;
	_veh2 = _convoyVeh select 1;

	_createVehicle =
	{
		private ["_type","_position","_direction","_vehicle","_soldier"];
		
		_type = _this select 0;
		_position = _this select 1;
		_direction = _this select 2;
		

		_vehicle = createVehicle [_type, _position, [], 0, "FLY"]; // Added to make it fly
		_vehicle setVariable ["R3F_LOG_disabled", true, true];
		_vel = [velocity _vehicle, -(_direction)] call BIS_fnc_rotateVector2D; // Added to make it fly
		_vehicle setDir _direction;
		_vehicle setVelocity _vel; // Added to make it fly
		_vehicle setVariable [call vChecksum, true, false];
		_aiGroup addVehicle _vehicle;

		// add pilot
		_soldier = [_aiGroup, _position] call createRandomSoldierC; 
		_soldier moveInDriver _vehicle;
		// lock the vehicle untill the mission is finished and initialize cleanup on it
		
		// Reset all flares to 0
		if (_type isKindOf "Air") then
		{
			{
				if (["CMFlare", _x] call fn_findString != -1) then
				{
					_vehicle removeMagazinesTurret [_x, [-1]];
				};
			} forEach getArray (configFile >> "CfgVehicles" >> _type >> "magazines");

			//_vehicle addMagazineTurret ["60Rnd_CMFlare_Chaff_Magazine", [-1]];
		};
		
		[_vehicle, _aiGroup] spawn checkMissionVehicleLock;
		_vehicle
	};

	_aiGroup = createGroup CIVILIAN;

	_vehicles =
	[
		[_veh1, _missionPos vectorAdd ([[random 50, 0, 0], random 360] call BIS_fnc_rotateVector2D), 0] call _createVehicle,
		[_veh2, _missionPos vectorAdd ([[random 50, 0, 0], random 360] call BIS_fnc_rotateVector2D), 0] call _createVehicle
	];

	_leader = effectiveCommander (_vehicles select 0);
	_aiGroup selectLeader _leader;
	_leader setRank "LIEUTENANT";
	
	_aiGroup setCombatMode "RED";
	_aiGroup setBehaviour "COMBAT";
	_aiGroup setFormation "STAG COLUMN";

	_speedMode = if (missionDifficultyHard) then { "NORMAL" } else { "LIMITED" };

	_aiGroup setSpeedMode _speedMode;

	// behaviour on waypoints
	{
		_waypoint = _aiGroup addWaypoint [markerPos (_x select 0), 0];
		_waypoint setWaypointType "MOVE";
		_waypoint setWaypointCompletionRadius 50;
		_waypoint setWaypointCombatMode "GREEN";
		_waypoint setWaypointBehaviour "SAFE";
		_waypoint setWaypointFormation "STAG COLUMN";
		_waypoint setWaypointSpeed _speedMode;
	} forEach ((call cityList) call BIS_fnc_arrayShuffle);

	_missionPos = getPosATL leader _aiGroup;

	_missionPicture = getText (configFile >> "CfgVehicles" >> _veh1 >> "picture");
	_vehicleName = getText (configFile >> "CfgVehicles" >> _veh1 >> "displayName");
	_vehicleName2 = getText (configFile >> "CfgVehicles" >> _veh2 >> "displayName");

	_missionHintText = format ["A formation of Jets containing two <t color='%3'>%1</t> are patrolling Chernarus. Destroy them and recover their cargo!", _vehicleName, _vehicleName2, mainMissionColor];

	_numWaypoints = count waypoints _aiGroup;
};

_waitUntilMarkerPos = {getPosATL _leader};
_waitUntilExec = nil;
_waitUntilCondition = {currentWaypoint _aiGroup >= _numWaypoints};

_failedExec = nil;

// _vehicles are automatically deleted or unlocked in missionProcessor depending on the outcome

_successExec =
{
	// Mission completed

	//Money
	for "_i" from 1 to 10 do
	{
		_cash = createVehicle ["Land_Money_F", _lastPos, [], 5, "None"];
		_cash setPos ([_lastPos, [[2 + random 3,0,0], random 360] call BIS_fnc_rotateVector2D] call BIS_fnc_vectorAdd);
		_cash setDir random 360;
		_cash setVariable ["cmoney", 10000, true];
		_cash setVariable ["owner", "world", true];
	};

	_box1 = createVehicle ["Box_NATO_Wps_F", _lastPos, [], 5, "None"];
	_box1 setDir random 360;
	[_box1, "mission_USSpecial"] call fn_refillbox;

	_box2 = createVehicle ["Box_East_Wps_F", _lastPos, [], 5, "None"];
	_box2 setDir random 360;
	[_box2, "mission_USLaunchers"] call fn_refillbox;

	_box3 = createVehicle ["Box_IND_WpsSpecial_F", _lastPos, [], 5, "None"];
	_box3 setDir random 360;
	[_box3, "mission_Main_A3snipers"] call fn_refillbox;
	
	{ _x setVariable ["R3F_LOG_disabled", false, true] } forEach [_box1, _box2, _box3];

	_successHintMessage = "The sky is clear again, the enemy patrol was taken out! Ammo crates and some money have fallen near the pilot.";
};

_this call mainMissionProcessor;
