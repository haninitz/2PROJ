extends Control

@onready var label_room_name := $vbox/label_room_name
@onready var label_map       := $vbox/label_map
@onready var label_format    := $vbox/label_format
@onready var slots_a         := $vbox/slots_a
@onready var slots_b         := $vbox/slots_b
@onready var btn_lancer      := $vbox/btn_lancer
@onready var btn_quitter     := $vbox/btn_quitter
@onready var status_label    := $vbox/status_label

func _ready() -> void:
	status_label.text   = ""
	btn_lancer.disabled = true
	btn_lancer.visible  = GameConfig.is_host

	label_room_name.text = "Room : %s" % GameConfig.room_name
	label_map.text       = "Map : %s" % GameConfig.map.to_upper()
	label_format.text    = "Format : %s" % GameConfig.format

	btn_lancer.pressed.connect(_on_lancer_pressed)
	btn_quitter.pressed.connect(_on_quitter_pressed)

	RoomManager.player_list_updated.connect(_on_list_updated)
	NetworkManager.player_connected.connect(func(_id): _refresh_slots())
	NetworkManager.player_disconnected.connect(func(_id): _refresh_slots())

	if GameConfig.is_host:
		# L'hôte est déjà dans la room — juste rafraîchir
		_refresh_slots()
		status_label.text = "⏳ En attente des joueurs… 1/%d" % GameConfig.get_max_players()
	else:
		# Le client cherche la room disponible sur le serveur
		status_label.text = "⏳ Recherche d'une room…"
		await get_tree().create_timer(0.5).timeout
		_ask_available_room.rpc_id(1, GameConfig.steam_name)
		_refresh_slots()

func _on_list_updated(_rid: String, data: Array) -> void:
	# Mettre à jour la map et room_name depuis les données reçues
	if not data.is_empty() and not GameConfig.is_host:
		# Récupérer les infos de la room depuis RoomManager via le serveur
		label_room_name.text = "Room : %s" % GameConfig.room_name
		label_map.text       = "Map : %s" % GameConfig.map.to_upper()
		label_format.text    = "Format : %s" % GameConfig.format

	_refresh_slots()

	var total:   int = GameConfig.get_max_players()
	var current: int = GameConfig.players.size()

	if GameConfig.is_host:
		btn_lancer.disabled = current < total
		if not btn_lancer.disabled:
			status_label.text = "✅ Tout le monde est là — lance la partie !"
		else:
			status_label.text = "⏳ En attente des joueurs… %d/%d" % [current, total]
	else:
		status_label.text = "⏳ En attente du lancement… %d/%d" % [current, total]

func _refresh_slots() -> void:
	for c in slots_a.get_children(): c.queue_free()
	for c in slots_b.get_children(): c.queue_free()

	var per_team: int = GameConfig.get_players_per_team()
	var team_a := GameConfig.players.values().filter(func(p): return p.team == "a")
	var team_b := GameConfig.players.values().filter(func(p): return p.team == "b")

	for i in per_team:
		var lbl := Label.new()
		if i < team_a.size():
			var you: String = " (vous)" if team_a[i].id == GameConfig.my_peer_id else ""
			lbl.text = "🩷 %s%s" % [team_a[i].name, you]
		else:
			lbl.text = "[ Slot vide ]"
		slots_a.add_child(lbl)

	for i in per_team:
		var lbl := Label.new()
		if i < team_b.size():
			var you: String = " (vous)" if team_b[i].id == GameConfig.my_peer_id else ""
			lbl.text = "💙 %s%s" % [team_b[i].name, you]
		else:
			lbl.text = "[ Slot vide ]"
		slots_b.add_child(lbl)

@rpc("any_peer", "reliable")
func _ask_available_room(player_name: String) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	for rid in RoomManager.rooms:
		var room: Dictionary = RoomManager.rooms[rid]
		var max_p: int = RoomManager._format_to_max(room.format)
		if room.players.size() < max_p:
			RoomManager.request_join_room.rpc_id(
				sender, rid, room.mode, room.format,
				room.diff, room.map, player_name
			)
			return
	# Aucune room disponible — notifier le client
	_no_room_found.rpc_id(sender)

@rpc("authority", "reliable")
func _no_room_found() -> void:
	status_label.text = "❌ Aucune room disponible — demande à l'hôte de créer une partie !"

func _on_lancer_pressed() -> void:
	if RoomManager.rooms.has(GameConfig.room_name):
		RoomManager._start_game(GameConfig.room_name)
	else:
		status_label.text = "⚠ Room introuvable !"

func _on_quitter_pressed() -> void:
	NetworkManager.disconnect_from_server()
	GameConfig.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
