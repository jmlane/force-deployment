params [
	["_orbat", []]
];

if (count _orbat < 1) exitWith { "Orbat is empty" call BIS_fnc_error; };

breadthFirstTraversal = {
	params [
		["_tree", []],
		["_nodeCode", {}]
	];

	private _q = [_tree];

	while {count _q > 0} do {
		private _current = _q deleteAt 0;

		{
			private _enqueue = _x call _nodeCode;

			if (count _enqueue > 0) then {
				_q pushBack _enqueue;
			};
		} forEach _current;
	};
};

// [[echelon, pos, parentArrayRef], ...]
private _queue = [];

[_orbat, {
	params [
		"_echelon",
		"_pos",
		["_children", []],
		["_parent", []]
	];

	private _element = [_echelon, _pos, _parent];
	_queue pushBack _element;

	{
		// Set index 3 explicitly for leaf (childless) nodes
		_x set [3, _element];
	} forEach _children;

	_children;
}] call breadthFirstTraversal;

prepareAndPlace = {
	params [
		"_echelon",
		"_composition",
		"_pos",
		"_name",
		"_killzoneRadius"
	];

	// Debug aids
	[_pos, _name] call SimTools_ForceDeployment_fnc_markInstallation;
	[_pos, _echelon, _name] call SimTools_ForceDeployment_fnc_markRadii;

	// TODO: Figure out if MVP compositions are doing this in their inits/triggers
	{ _x hideObjectGlobal true } foreach nearestTerrainObjects [_pos, [], _killzoneRadius];

	// LARs_fnc_spawnComp expects 3D ATL pos, everything else can handle 2D.
	if (count _pos == 2) then { _pos pushBack 0; };

	[_composition, _pos] call LARs_fnc_spawnComp;
};

{
	_x call {
		params [
			"_echelon",
			["_pos", [], [[0]], [0,2,3]],
			["_parent", [], [[]], [0,3]]
		];

		private [
			"_composition",
			"_killzoneRadius"
		];
		switch (toUpper _echelon) do {
			case "BN": {
				_composition = "FOB";
				_killzoneRadius = 50;
				_siblingBlacklistRadius = 8000;
			};
			case "COY": {
				_composition = "COP";
				_killzoneRadius = 40;
				_siblingBlacklistRadius = 2000;
			};
			case "PL": {
				_composition = "PB";
				_killzoneRadius = 15;
				_siblingBlacklistRadius = 600;
			};
			default {
				format ["Unknown echelon '(%1)'", _echelon] call BIS_fnc_error;
			};
		};

		if (count _pos < 2) then {
			private _parentPos = [];
			if (count _parent > 2) then {_parentPos = _parent select 1};
			// TODO: Add blacklist areas
			_pos = [_composition, _parentPos] call SimTools_ForceDeployment_fnc_findValidPos;
		};

		// TODO: Add naming scheme
		private _name = str _forEachIndex;
		[_echelon, _composition, _pos, _name, _killzoneRadius] call prepareAndPlace;

		_pos;
	};
} forEach _queue;

_queue;

// TODO: Pass deployed element data to persistence function
