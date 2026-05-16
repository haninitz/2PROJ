extends Control

@onready var btn_clover := $vbox/btn_clover
@onready var btn_sam    := $vbox/btn_sam
@onready var btn_alex   := $vbox/btn_alex
@onready var btn_jerry  := $vbox/btn_jerry
@onready var btn_back   := $vbox/btn_back

func _ready() -> void:
	btn_clover.pressed.connect(func(): _select_map("clover"))
	btn_sam.pressed.connect(func():    _select_map("sam"))
	btn_alex.pressed.connect(func():   _select_map("alex"))
	btn_jerry.pressed.connect(func():  _select_map("jerry"))
	btn_back.pressed.connect(_on_back_pressed)

func _select_map(m: String) -> void:
	GameConfig.map = m
	# Selon le mode on va vers une scène différente
	if GameConfig.mode == "multi":
		get_tree().change_scene_to_file("res://scenes/NomRoom.tscn")
	else:
		# VS IA → pas de salle d'attente
		get_tree().change_scene_to_file("res://scenes/RecapIA.tscn")

func _on_back_pressed() -> void:
	if GameConfig.mode == "multi":
		get_tree().change_scene_to_file("res://scenes/ChoixFormat.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/ChoixDiff.tscn")
