params [
	["_size", "", [""]],
	["_position", [], [[0]]],
	["_subordinates", [], [[]]]
];

private _fnc_typeCheck = {
	params [
		["_size", "", [""]],
		["_position", [], [[0]]],
		["_subordinates", [], [[]]]
	];

	private _cfgSize = configfile >> "CfgChainOfCommand" >> "Sizes" >> _size;
	if (!isClass _cfgSize) exitWith {
		["'%1' is not a valid formation size, at %2", _size, _this] call BIS_fnc_error;
		false
	};

	if (!(count _position == 0 || count _position == 3) && {_position pushback 0; count _position != 3}) exitWith {
		["'%1' is not a valid position, at %2", _position, _this] call BIS_fnc_error;
		false
	};

	if ((_subordinates apply {_x call _fnc_typeCheck}) findIf {!_x} > 1) exitWith {
		false
	};

	true
};

if (!(_this call _fnc_typeCheck)) exitWith { nil };

[_size, _position, _subordinates]
