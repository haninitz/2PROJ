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

func _init(data: Dictionary) -> void:
	name      = data["name"]
	pos       = data["pos"]
	owner     = data["owner"]
	units     = data["units"]
	income    = data["income"]
	unit_type = "Infantry"
	type      = data.get("type", "normal")
	queue     = []
