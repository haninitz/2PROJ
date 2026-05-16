extends Control

@onready var btn_easy := $vbox/btn_easy
@onready var btn_med  := $vbox/btn_med
@onready var btn_hard := $vbox/btn_hard
@onready var btn_back := $vbox/btn_back

func _ready() -> void:
	btn_easy.pressed.connect(func(): _select_diff("easy"))
	btn_med.pressed.connect(func():  _select_diff("med"))
	btn_hard.pressed.connect(func(): _select_diff("hard"))
	btn_back.pressed.connect(_on_back_pressed)

func _select_diff(d: String) -> void:
	GameConfig.diff = d
	get_tree().change_scene_to_file("res://scenes/ChoixMap.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ChoixMode.tscn")
