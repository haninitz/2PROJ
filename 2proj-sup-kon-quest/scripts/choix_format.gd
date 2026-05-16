extends Control

@onready var btn_1v1  := $vbox/btn_1v1
@onready var btn_2v2  := $vbox/btn_2v2
@onready var btn_3v3  := $vbox/btn_3v3
@onready var btn_back := $vbox/btn_back

func _ready() -> void:
	btn_1v1.pressed.connect(func(): _select_format("1v1"))
	btn_2v2.pressed.connect(func(): _select_format("2v2"))
	btn_3v3.pressed.connect(func(): _select_format("3v3"))
	btn_back.pressed.connect(_on_back_pressed)

func _select_format(f: String) -> void:
	GameConfig.format = f
	get_tree().change_scene_to_file("res://scenes/ChoixMap.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ChoixMode.tscn")
