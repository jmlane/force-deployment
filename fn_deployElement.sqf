params [
	["_sibling_count", 3, 0],
	["_sibling_blacklist_radius", 800, 0],
	["_pos_blacklist", [], [[], 0]],
	["_max_attempts", 20, 0]
];

private _pos_list = [];

{
	private _attempts = 0;
	private _pos_count = 0;
	diag_log format ["_forEachIndex (_cop_list) %1", _forEachIndex];

	while {_attempts < _max_attempts && _pos_count < _sibling_count} do {
		private _pos = ["PB", _x, _pos_blacklist] call SimTools_ForceDeployment_fnc_findValidPos;

		diag_log format ["Attempt %1", _attempts];
		if (_pos select 0 != 0) then {
			diag_log format ["Found! %1", _pos];
			_pos_list pushback _pos;
			_pos_blacklist pushback [_pos, _sibling_blacklist_radius];
			_pos_count = _pos_count + 1;
		} else {
			diag_log format ["Unsafe!"];
			_attempts = _attempts + 1;
		};
	};
	diag_log format ["Search done: _pos_list: %1", _pos_list];
} forEach _cop_list;

{
	_i = _forEachIndex + 1;
	_name = format ["%1/%2/%3",
		ceil (_i/(_n_cops_per_fob * _sibling_count)),
		ceil (_i/_n_cops_per_fob)%3+1,
		_forEachIndex%3+1];
	[_x, ["PB", "PL"], _name, 15] call prepareAndPlace;
} forEach _pos_list;
