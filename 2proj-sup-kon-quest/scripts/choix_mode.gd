extends Control

@onready var btn_multi := $vbox/btn_multi
@onready var btn_ai    := $vbox/btn_ai
@onready var btn_back  := $vbox/btn_back

func _ready() -> void:
	btn_multi.pressed.connect(_on_multi_pressed)
	btn_ai.pressed.connect(_on_ai_pressed)
	btn_back.pressed.connect(_on_back_pressed)

func _on_multi_pressed() -> void:
	GameConfig.mode = "multi"
	get_tree().change_scene_to_file("res://scenes/ChoixFormat.tscn")

func _on_ai_pressed() -> void:
	GameConfig.mode = "ai"
	get_tree().change_scene_to_file("res://scenes/ChoixDiff.tscn")

func _on_back_pressed() -> void:
	NetworkManager.disconnect_from_server()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
