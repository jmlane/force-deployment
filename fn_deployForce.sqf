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

_queue;

// TODO: Pass deployed element data to persistence function
