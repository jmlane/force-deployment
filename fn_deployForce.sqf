params [
	["_orbat", []]
];

if (count _orbat < 1) exitWith { "Orbat is empty" call BIS_fnc_error; };

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
}] call SimTools_ForceDeployment_fnc_breadthFirstTraversal;

prepareAndPlace = {
	params [
		"_echelon",
		"_composition",
		"_pos",
		"_name",
		"_killzoneRadius"
	];

	// TODO: Figure out if MVP compositions are doing this in their inits/triggers
	{ _x hideObjectGlobal true } foreach nearestTerrainObjects [_pos, [], _killzoneRadius];

	// LARs_fnc_spawnComp expects 3D ATL pos, everything else can handle 2D.
	if (count _pos == 2) then { _pos pushBack 0; };

	[_composition, _pos] call LARs_fnc_spawnComp;
};

switchOnEchelon = {
	params [
		"_echelon",
		"_BNCode",
		"_COYCode",
		"_PLCode",
		[
			"_defaultCode",
			{ format ["Unknown echelon '(%1)'", _echelon] call BIS_fnc_error; },
			{}
		]
	];

	switch (_echelon) do {
		case "Battalion": _BNCode;
		case "Company": _COYCode;
		case "Platoon": _PLCode;
		default _defaultCode;
	};
};

private _fobs = [];
private _cops = [];
private _pbs = [];
private _pbBacklist = [];
{
	private _next = [
		_x select 0,
		_x select 1,
		_x select 2
	];
	if (_x select 0 == "Platoon") then {
		_next pushBack _pbBacklist;
	};
	_next call {
		params [
			"_echelon",
			["_pos", [], [[0]], [0,2,3]],
			["_parent", [], [[]], [0,3]],
			["_blacklist", [], [[]]]
		];

		private [
			"_composition",
			"_killzoneRadius",
			"_blacklistRadius",
			"_siblings"
		];
		[
			_echelon,
			{
				_composition = "FOB";
				_killzoneRadius = 50;
				_blacklistRadius = 8000;
				_siblings = _fobs;
			},
			{
				_composition = "COP";
				_killzoneRadius = 40;
				_blacklistRadius = 2000;
				_siblings = _cops;
			},
			{
				_composition = "PB";
				_killzoneRadius = 15;
				_blacklistRadius = 600;
				_siblings = _pbs;
			}
		] call switchOnEchelon;

		if (count _pos < 2) then {
			private _parentPos = [];
			if (count _parent > 2) then {_parentPos = _parent select 1};

			{
				_blacklist pushBack [_x, _blacklistRadius];
			} forEach _siblings;

			private _newPos = [_composition, _parentPos, _blacklist] call SimTools_ForceDeployment_fnc_findValidPos;
			_pos set [0, _newPos select 0];
			_pos set [1, _newPos select 1];
			if (count _newPos < 3) then { _pos pushBack 0; };

			if (toUpper _echelon == "I") then {
				private _vector = (_pos vectorFromTo _parentPos);
				_vector = _vector vectorMultiply 1000;
				private _dir = (_vector select 0) atan2 (_vector select 1);
				if (_dir < 0) then {_dir = 360 + _dir};
				private _blacklistCenter = _pos vectorAdd _vector;

				_pbBacklist pushBack ([_blacklistCenter, [2000, 1000, _dir, true]]);
			};
		};

		[
			_echelon,
			{ _fobs },
			{ _cops },
			{ _pbs }
		] call switchOnEchelon pushBack _pos;

		// TODO: Add naming scheme
		private _name = str _forEachIndex;
		[_echelon, _composition, _pos, _name, _killzoneRadius] call prepareAndPlace;
		_x set [1, _pos];

		_pos
	};
} forEach _queue;

_orbat
