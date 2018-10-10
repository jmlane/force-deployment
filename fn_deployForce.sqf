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

// Old entrypoint stuff
prepareAndPlace = {
	params [
		"_pos",
		"_formation",
		"_name",
		"_killzone_radius"
	];

	_composition = _formation select 0;
	_echelon = _formation select 1;

	[_pos, _name] call SimTools_ForceDeployment_fnc_markInstallation;
	[_pos, _echelon, _name] call SimTools_ForceDeployment_fnc_markRadii;

	{ _x hideObjectGlobal true } foreach nearestTerrainObjects [_pos, [], _killzone_radius];
	// LARs_fnc_spawnComp expects 3D ATL pos, everything else can handle 2D.
	if (count _pos == 2) then { _pos pushBack 0; };
	[_composition, _pos] call LARs_fnc_spawnComp;
};

getPosAndBlacklists = {
	params [
		"_type",
		["_parent", []], 
		["_blacklist", []],
		"_type_blacklist_radius" // Todo: this needs to be a look-up function.
	];

	_pos_list = [];
	_type_blacklist = [];

	_pos = [_type, _parent, _blacklist] call SimTools_ForceDeployment_fnc_findValidPos;

	if (_pos select 0 != 0) then {
		_pos_list pushBack _pos;
		_blacklistPair = [_pos, _type_blacklist_radius];
		_blacklist pushBack _blacklistPair;
		_type_blacklist pushBack _blacklistPair;
	};

	[_pos_list, _type_blacklist];
};

// FOBs
_fob_list = [];
_fob_blacklist = [];

_attempts = 0;
_pos_count = 0;
while {_attempts < 20 && _pos_count < _n_fobs_wanted} do {
	_pos = ["FOB", nil, _fob_blacklist] call SimTools_ForceDeployment_fnc_findValidPos;

	if (_pos select 0 != 0) then {
		_fob_list pushBack _pos;
		_fob_blacklist pushBack [_pos, 8000];
		_pos_count = _pos_count + 1;
	} else {
		_attempts = _attempts + 1;
	};
};

{
	[_x, ["FOB", "BN"], str (_forEachIndex + 1), 50] call prepareAndPlace;
} forEach _fob_list;

// COPs
_cop_list = [];
_cop_blacklist = [];
{
	_cop_blacklist pushBack [_x, 1000];
} forEach _fob_list;

{
	_attempts = 0;
	_pos_count = 0;
	while {_attempts < 20 && _pos_count < _n_cops_per_fob} do {
		_pos = ["COP", _x, _cop_blacklist] call SimTools_ForceDeployment_fnc_findValidPos;

		if (_pos select 0 != 0) then {
			_cop_list pushback _pos;
			_cop_blacklist pushback [_pos, 2000];
			_pos_count = _pos_count + 1;
		} else {
			_attempts = _attempts + 1;
		};
	};
} forEach _fob_list;

{
	_i = _forEachIndex + 1;
	_name = format ["%1/%2", ceil (_i/_n_cops_per_fob), _forEachIndex%3+1];
	[_x, ["COP", "COY"], _name, 40] call prepareAndPlace;
} forEach _cop_list;

// PBs
_pb_list = [];
_pb_blacklist = [];
{
	_pb_blacklist pushBack [_x, 500];
} forEach _cop_list;

{
	_attempts = 0;
	_pos_count = 0;
	diag_log format ["_forEachIndex (_cop_list) %1", _forEachIndex];

	while {_attempts < 20 && _pos_count < _n_pbs_per_cop} do {
		_pos = ["PB", _x, _pb_blacklist] call SimTools_ForceDeployment_fnc_findValidPos;

		diag_log format ["Attempt %1", _attempts];
		if (_pos select 0 != 0) then {
			diag_log format ["Found! %1", _pos];
			_pb_list pushback _pos;
			_pb_blacklist pushback [_pos, 600];
			_pos_count = _pos_count + 1;
		} else {
			diag_log format ["Unsafe!"];
			_attempts = _attempts + 1;
		};
	};
	diag_log format ["Search done: _pb_list: %1", _pb_list];
} forEach _cop_list;

{
	_i = _forEachIndex + 1;
	_name = format ["%1/%2/%3",
		ceil (_i/(_n_cops_per_fob * _n_pbs_per_cop)),
		ceil (_i/_n_cops_per_fob)%3+1,
		_forEachIndex%3+1];
	[_x, ["PB", "PL"], _name, 15] call prepareAndPlace;
} forEach _pb_list;

_queue;

// TODO: Pass deployed element data to persistence function
