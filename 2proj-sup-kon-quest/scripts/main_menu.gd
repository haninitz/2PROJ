extends Control

@onready var input_pseudo := $vbox/input_pseudo
@onready var btn_create   := $vbox/btn_create
@onready var btn_join     := $vbox/btn_join
@onready var join_panel   := $vbox/join_panel
@onready var input_room   := $vbox/join_panel/vbox/ip_input
@onready var btn_connect  := $vbox/join_panel/vbox/btn_connect
@onready var btn_cancel   := $vbox/join_panel/vbox/btn_cancel
@onready var status_label := $vbox/status_label

func _ready() -> void:
	join_panel.visible = false
	status_label.text  = ""
	input_pseudo.text  = "Joueur_%d" % randi_range(100, 999)

	btn_create.pressed.connect(_on_create_pressed)
	btn_join.pressed.connect(_on_join_pressed)
	btn_connect.pressed.connect(_on_connect_pressed)
	btn_cancel.pressed.connect(func(): join_panel.visible = false)

	NetworkManager.connected_to_server.connect(_on_connected_ok)
	NetworkManager.connection_failed.connect(_on_connection_fail)
	Matchmaker.room_not_found.connect(_on_room_not_found)
	Matchmaker.room_found.connect(_on_room_found)

func _get_pseudo() -> String:
	var p: String = input_pseudo.text.strip_edges()
	if p.is_empty():
		p = "Joueur_%d" % randi_range(100, 999)
	return p

func _get_local_ip() -> String:
	var addrs := IP.get_local_addresses()
	for addr in addrs:
		if addr.begins_with("192.168.") or addr.begins_with("10.") or addr.begins_with("172."):
			return addr
	return "127.0.0.1"

func _on_create_pressed() -> void:
	GameConfig.steam_name = _get_pseudo()
	GameConfig.is_host    = true
	NetworkManager.create_server()
	status_label.text = " Serveur créé — choisis ton mode de jeu !"
	get_tree().change_scene_to_file("res://scenes/ChoixMode.tscn")

func _on_join_pressed() -> void:
	GameConfig.steam_name = _get_pseudo()
	join_panel.visible    = true
	input_room.placeholder_text = "Nom de la room (ex: partie_clover)"
	input_room.grab_focus()

func _on_connect_pressed() -> void:
	var room_name: String = input_room.text.strip_edges()
	if room_name.is_empty():
		status_label.text = " Entre le nom de la room !"
		return
	GameConfig.room_name  = room_name
	status_label.text     = " Recherche de la room '%s'…" % room_name
	btn_connect.disabled  = true
	# Chercher la room sur le matchmaker
	Matchmaker.find_room(room_name)

func _on_room_found(ip: String) -> void:
	status_label.text = " Room trouvée — connexion…"
	GameConfig.server_ip = ip
	NetworkManager.join_server(ip)

func _on_room_not_found() -> void:
	status_label.text    = " Room '%s' introuvable !" % GameConfig.room_name
	btn_connect.disabled = false

func _on_connected_ok() -> void:
	get_tree().change_scene_to_file("res://scenes/SalleAttente.tscn")

func _on_connection_fail() -> void:
	status_label.text    = " Connexion échouée"
	btn_connect.disabled = false
