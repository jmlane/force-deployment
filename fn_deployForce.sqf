params [
	["_orbat", []]
];

if (count _orbat < 1) exitWith {["Orbat is empty"] call BIS_fnc_error};

_fnc_switchOnEchelon = {
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

[_orbat, {
	params [
		"_echelon",
		["_pos", [], [[0]], [0,2,3]],
		["_deployment", "", [""]],
		["_children", []],
		["_parent", [], [[]]],
		["_blacklist", [], [[]]]
	];

	if (_echelon == "Platoon") then {
		_blacklist = _blacklist + _pbBacklist;
	};

	private [
		"_killzoneRadius",
		"_blacklistRadius",
		"_siblings"
	];
	[
		_echelon,
		{
			_killzoneRadius = 50;
			_blacklistRadius = 8000;
			_siblings = _fobs;
		},
		{
			_killzoneRadius = 40;
			_blacklistRadius = 2000;
			_siblings = _cops;
		},
		{
			_killzoneRadius = 15;
			_blacklistRadius = 600;
			_siblings = _pbs;
		}
	] call _fnc_switchOnEchelon;

	if (count _pos < 2) then {
		private _parentPos = if (count _parent >= 2) then {_parent select 1} else {[]};

		_siblings apply {_blacklist pushBack [_x, _blacklistRadius]};

		private _newPos = [_echelon, _parentPos, _blacklist] call SimTools_ForceDeployment_fnc_findValidPos;
		_pos set [0, _newPos select 0];
		_pos set [1, _newPos select 1];
		if (count _newPos < 3) then {_pos pushBack 0};

		if (_echelon == "Company") then {
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
	] call _fnc_switchOnEchelon pushBack _pos;

	[_pos, _killzoneRadius] call compileFinal _deployment;

	_children apply {_x set [4, [_echelon, _pos]]; _x}
}] call SimTools_ForceDeployment_fnc_breadthFirstTraversal;

_orbat
