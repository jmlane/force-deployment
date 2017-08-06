params [
	["_orbat", [], [[[]]]]
];

if (count _orbat < 1) exitWith { "Orbat is empty" call BIS_fnc_error; };

/*
 * 1. Build a breadth first queue
 *
 *    AOs are assigned to largest formations initially. Subordinates of the
 *    first formation should not be deployed before the sibling formations.
 */
bft = {
	params [
		["_root", []],
		["_code", {}]
	];

	_q = [_root];
	diag_log format ["root, _q: %1", _q];
	while {count _q > 0} do {
		_current = _q select 0;
		_q set [0, -1];
		_q = _q - [-1];
		diag_log format ["_current: %1, _q: %2", _current, _q];

		{
			_x call _code;

			if (count _x > 2) then {
				_next = _x select 2;
				if (count _next > 0) then {
					_q pushBack _next;
				};
			};
		} forEach _current;
	};
};

// [[parent_index, echelon, pos], ...]
_queue = [];

[_orbat, {
	_echelon = _this select 0;
	_pos = _this select 1;
	_queue pushBack [_echelon, _pos];
}] call bft;

{
	diag_log _x select 0;
} forEach _queue;

/*
 * 2. Establish chain of command between formations
 *
 *    Formations at each distinct echelon are deployed after superiours and
 *    before subordinates. We need to make sure we don't lose track of chain of
 *    command in the process.
 */

/*
 * 3. Deploy formations in order from queue
 */
