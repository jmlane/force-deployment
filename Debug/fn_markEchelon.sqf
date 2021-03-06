params [
	"_pos",
	["_name", "", [""]],
	["_echelon", "", [""]]
];
private [
	"_echelon_marker_type"
];

try {
	switch (_echelon) do {
		case "Battalion": {
			_echelon_marker_type = "group_5";
		};
		case "Company": {
			_echelon_marker_type = "group_4";
		};
		case "Platoon": {
			_echelon_marker_type = "group_3";
		};
		default {
			throw format ["Unknown echelon (%1)", _echelon];
		};
	};

	if (_name == "") then { _name = format ["marker_echelon_%1", _pos]; };

	_echelon_marker = createMarkerLocal [_name, _pos];
	_echelon_marker setMarkerShapeLocal "ICON";
	_echelon_marker setMarkerTypeLocal _echelon_marker_type;

	_echelon_marker;
} catch {
	[_exception] call BIS_fnc_error;
};
