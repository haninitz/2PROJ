extends Control

@onready var room_list    := $vbox/scroll/room_list
@onready var btn_refresh  := $vbox/btn_refresh
@onready var btn_back     := $vbox/btn_back
@onready var status_label := $vbox/status_label

func _ready() -> void:
	status_label.text = ""
	btn_refresh.pressed.connect(_on_refresh_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	Matchmaker.room_list_received.connect(_on_list_received)
	Matchmaker.room_found.connect(_on_room_found)
	Matchmaker.room_not_found.connect(_on_room_not_found)
	# Charger la liste automatiquement
	_on_refresh_pressed()

func _on_refresh_pressed() -> void:
	status_label.text = "Chargement des rooms..."
	# Vider la liste
	for c in room_list.get_children():
		c.queue_free()
	Matchmaker.get_room_list()

func _on_list_received(rooms: Array) -> void:
	for c in room_list.get_children():
		c.queue_free()

	if rooms.is_empty():
		status_label.text = "Aucune room disponible"
		return

	status_label.text = "%d room(s) disponible(s)" % rooms.size()

	for room in rooms:
		var btn              := Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		var players: int      = room.get("players", 0)
		var max_p: int        = room.get("max_players", 2)
		var full: bool        = room.get("full", false)
		var started: bool     = room.get("started", false)
		var room_name: String = room.get("name", "")
		var map_name: String  = room.get("map", "")
		var format: String    = room.get("format", "")

		if started:
			btn.text     = "EN COURS | %s | %s | %s | %d/%d" % [room_name, format, map_name.to_upper(), players, max_p]
			btn.disabled = true
		elif full:
			btn.text     = "PLEINE | %s | %s | %s | %d/%d" % [room_name, format, map_name.to_upper(), players, max_p]
			btn.disabled = true
		else:
			btn.text = "%s | %s | %s | %d/%d joueurs" % [room_name, format, map_name.to_upper(), players, max_p]
			# Stocker toute la config dans la closure
			var r_name:   String = room_name
			var r_map:    String = map_name
			var r_format: String = format
			var r_mode:   String = room.get("mode", "multi")
			var r_diff:   String = room.get("diff", "med")
			var r_max:    int    = max_p
			btn.pressed.connect(func(): _join_room(r_name, r_map, r_format, r_mode, r_diff, r_max))

		room_list.add_child(btn)

func _join_room(room_name: String, map: String, format: String,
		mode: String, diff: String, _max_p: int) -> void:
	status_label.text    = "Connexion a '%s'..." % room_name
	# Stocker la config AVANT de se connecter
	GameConfig.room_name = room_name
	GameConfig.map       = map
	GameConfig.format    = format
	GameConfig.mode      = mode
	GameConfig.diff      = diff
	Matchmaker.find_room(room_name)

func _on_room_found(ip: String) -> void:
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(_r, _c, _h, body):
		var my_ip: String = body.get_string_from_utf8().strip_edges()
		var final_ip: String = ip
		if my_ip == ip:
			final_ip = "127.0.0.1"
		print("[ListeRooms] Connexion a : %s" % final_ip)
		GameConfig.server_ip = final_ip
		NetworkManager.join_server(final_ip)
		http.queue_free()
	)
	http.request("https://api.ipify.org")
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_fail)

func _on_connected() -> void:
	get_tree().change_scene_to_file("res://scenes/SalleAttente.tscn")

func _on_connection_fail() -> void:
	status_label.text = "Connexion echouee !"

func _on_room_not_found() -> void:
	status_label.text = "Room introuvable !"

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
