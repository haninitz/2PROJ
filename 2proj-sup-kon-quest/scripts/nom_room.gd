extends Control

@onready var input_room   := $vbox/input_room
@onready var btn_create   := $vbox/btn_create
@onready var btn_back     := $vbox/btn_back
@onready var status_label := $vbox/status_label

func _ready() -> void:
	status_label.text = ""
	btn_create.pressed.connect(_on_create_pressed)
	btn_back.pressed.connect(_on_back_pressed)

func _on_create_pressed() -> void:
	var room_name: String = input_room.text.strip_edges()
	if room_name.is_empty():
		status_label.text = "⚠ Entre un nom de room !"
		return
	if room_name.length() < 3:
		status_label.text = "⚠ Minimum 3 caractères !"
		return

	GameConfig.room_name = room_name
	GameConfig.is_host   = true

	# L'hôte se met dans GameConfig.players directement
	GameConfig.players[1] = {
		"id":    1,
		"name":  GameConfig.steam_name,
		"team":  "a",
		"ready": true
	}

	RoomManager.request_join_room.rpc_id(1,
		room_name,
		GameConfig.mode,
		GameConfig.format,
		GameConfig.diff,
		GameConfig.map,
		GameConfig.steam_name
	)

	get_tree().change_scene_to_file("res://scenes/SalleAttente.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ChoixMap.tscn")
