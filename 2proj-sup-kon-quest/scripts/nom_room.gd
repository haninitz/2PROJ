extends Control

@onready var input_room   := $vbox/input_room
@onready var btn_create   := $vbox/btn_create
@onready var btn_back     := $vbox/btn_back
@onready var status_label := $vbox/status_label

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
	status_label.text    = "Récupération de l'IP publique..."
	btn_create.disabled  = true

	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, body):
		var ip: String = body.get_string_from_utf8().strip_edges()
		print("[NomRoom] IP publique : %s" % ip)
		GameConfig.server_ip = ip
		status_label.text    = "Enregistrement de la room '%s'..." % room_name
		Matchmaker.create_room(
			room_name, ip,
			GameConfig.format, GameConfig.map,
			GameConfig.get_max_players()
		)
		http.queue_free()
	)
	http.request("https://api.ipify.org")

func _on_room_registered(_room_name: String) -> void:
	status_label.text = "✅ Room enregistrée !"

	# ─ CORRECTION CLÉ ─────────────────────────────────────────────────────
	# L'hôte est peer 1. Appeler rpc_id(1, ...) sur soi-même ne déclenche
	# PAS request_join_room (get_remote_sender_id() retourne 0, non 1).
	# On appelle donc join_room_local() directement, sans RPC.
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
