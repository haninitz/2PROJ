class_name Camp
extends RefCounted

var name:      String
var pos:       Vector2
var owner:     int
var units:     int
var income:    int
var unit_type: String
var type:      String   # "normal" ou "port"
var queue:     Array
var max_hp:    int
var current_hp: int

func _init(data: Dictionary) -> void:
	name       = data["name"]
	pos        = data["pos"]
	owner      = data["owner"]
	units      = data["units"]
	income     = data["income"]
	unit_type  = "Infantry"
	type       = data.get("type", "normal")
	queue      = []
	max_hp     = data.get("max_hp", 100)
	current_hp = max_hp
