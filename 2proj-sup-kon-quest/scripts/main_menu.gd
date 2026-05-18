extends Control

@onready var input_pseudo := $vbox/input_pseudo
@onready var btn_create   := $vbox/btn_create
@onready var btn_join     := $vbox/btn_join
@onready var status_label := $vbox/status_label

func _ready() -> void:
	status_label.text = ""
	input_pseudo.text = "Joueur_%d" % randi_range(100, 999)
	btn_create.pressed.connect(_on_create_pressed)
	btn_join.pressed.connect(_on_join_pressed)

func _get_pseudo() -> String:
	var p: String = input_pseudo.text.strip_edges()
	return p if not p.is_empty() else "Joueur_%d" % randi_range(100, 999)

func _on_create_pressed() -> void:
	GameConfig.steam_name = _get_pseudo()
	# L'hôte démarre le serveur ENet ICI, avant tout choix de config
	NetworkManager.create_server()
	status_label.text = "Serveur créé — choisis ton mode de jeu !"
	get_tree().change_scene_to_file("res://scenes/ChoixMode.tscn")

func _on_join_pressed() -> void:
	GameConfig.steam_name = _get_pseudo()
	GameConfig.is_host    = false
	# Pas de create_server ici — le client se connecte plus tard via l'IP du matchmaker
	get_tree().change_scene_to_file("res://scenes/ListeRooms.tscn")
