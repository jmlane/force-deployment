params [
	["_config", getMissionConfig "CfgORBAT", [configNull]]
];

private _orbats = "true" configClasses _config;

private _fnc_traverseSubclasses = {
	params [
		["_class", configNull, [configNull]]
	];

	private _subordinates = getArray (_class >> "subordinates");
	if (count _subordinates < 1 && {_subordinates = _class call BIS_fnc_returnChildren; count _subordinates < 1}) exitWith {
		[getText (_class >> "size"), getArray (_class >> "position"), []]
	};

	_subordinates = _subordinates apply {[_x] call _fnc_traverseSubclasses};
	[getText (_class >> "size"), getArray (_class >> "position"), _subordinates];
};

_orbats apply {[_x] call _fnc_traverseSubclasses}
