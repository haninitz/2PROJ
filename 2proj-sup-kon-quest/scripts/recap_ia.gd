extends Control

@onready var label_mode := $vbox/label_mode
@onready var label_diff := $vbox/label_diff
@onready var label_map  := $vbox/label_map
@onready var btn_lancer := $vbox/btn_lancer
@onready var btn_back   := $vbox/btn_back

func _ready() -> void:
	# Afficher le récap des choix
	label_mode.text = "Mode : VS IA"
	label_diff.text = "Difficulté : %s" % _get_diff_label()
	label_map.text  = "Map : %s" % GameConfig.map.to_upper()

	btn_lancer.pressed.connect(_on_lancer_pressed)
	btn_back.pressed.connect(_on_back_pressed)

func _get_diff_label() -> String:
	match GameConfig.diff:
		"easy": return "Facile"
		"med":  return "Moyen"
		"hard": return "Difficile"
	return GameConfig.diff

func _on_lancer_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ChoixMap.tscn")
