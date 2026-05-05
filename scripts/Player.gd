class_name Player
extends RefCounted

var name: String
var gold: int

func _init(player_name: String) -> void:
	name = player_name
	gold = 0
