extends Control

@onready var input_room   := $vbox/input_room
@onready var btn_create   := $vbox/btn_create
@onready var btn_back     := $vbox/btn_back
@onready var status_label := $vbox/status_label

#  Adresse Playit (hostname, pas IP brute) 
const PLAYIT_HOST := "software-reporter.gl.at.ply.gg"
const PLAYIT_PORT := 61177

func _ready() -> void:
	status_label.text = ""
	btn_create.pressed.connect(_on_create_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	Matchmaker.room_created.connect(_on_room_registered, CONNECT_ONE_SHOT)

func _on_create_pressed() -> void:
	var room_name: String = input_room.text.strip_edges()
	if room_name.is_empty():
		status_label.text = "Entre un nom de room !"
		return
	if room_name.length() < 3:
		status_label.text = "Minimum 3 caractères !"
		return

	GameConfig.room_name = room_name
	GameConfig.is_host   = true
	btn_create.disabled  = true
	status_label.text    = "Démarrage du serveur…"

	# 1. Nettoyer toute connexion résiduelle avant de créer le serveur
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
		await get_tree().create_timer(0.1).timeout

	# 2. Démarrer le serveur ENet local
	NetworkManager.create_server()

	# 2. Enregistrer la room sur le Matchmaker avec l'adresse Playit
	var max_p: int = GameConfig.get_max_players()
	status_label.text = "Enregistrement de la room…"

	# On enregistre avec le HOST Playit (le Matchmaker stocke ce hostname ;
	# les clients feront la résolution DNS eux-mêmes)
	Matchmaker.create_room(
		room_name,
		PLAYIT_HOST,          # adresse publique diffusée aux clients
		GameConfig.format,
		GameConfig.map,
		max_p
	)

func _on_room_registered(_room_name: String) -> void:
	status_label.text = "Room enregistrée !"

	# Rejoindre la room côté hôte (peer_id = 1, en local)
	RoomManager.join_room_local(
		GameConfig.room_name,
		GameConfig.mode,
		GameConfig.format,
		GameConfig.diff,
		GameConfig.map,
		GameConfig.steam_name
	)
	get_tree().change_scene_to_file("res://scenes/SalleAttente.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ChoixMap.tscn")
