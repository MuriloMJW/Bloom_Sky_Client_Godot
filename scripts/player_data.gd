extends Resource

class_name PlayerData


const PLAYER_BITMASK_LAYOUT = [
	# attribute,                    bitmask,        data_type
	{"attribute": "x",              "mask": 1 << 0, "data_type": "float"},
	{"attribute": "y",              "mask": 1 << 1, "data_type": "float"},
	{"attribute": "is_alive",       "mask": 1 << 2, "data_type": "u8"},
	{"attribute": "hp",             "mask": 1 << 3, "data_type": "u8"},
	{"attribute": "team_id",        "mask": 1 << 4, "data_type": "u8"},
	{"attribute": "team",           "mask": 1 << 5, "data_type": "string"},
	{"attribute": "total_kills",    "mask": 1 << 6, "data_type": "u16"},
	{"attribute": "speed",          "mask": 1 << 7, "data_type": "float"},
	{"attribute": "shoot_cooldown", "mask": 1 << 8, "data_type": "float"}
	
]

@export var id = null
@export var team_id = null
@export var team = null
@export var x = null
@export var y = null
@export var is_alive = null
@export var hp = null
@export var is_my_player = null
@export var total_kills = null
@export var speed = null
@export var shoot_cooldown = null
