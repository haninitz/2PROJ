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

	_update_labels()

	btn_lancer.pressed.connect(_on_lancer_pressed)
	btn_quitter.pressed.connect(_on_quitter_pressed)

	RoomManager.player_list_updated.connect(_on_list_updated)
	RoomManager.room_full.connect(_on_room_full)
	NetworkManager.player_disconnected.connect(func(_id): _refresh_slots())

	if GameConfig.is_host:
		# L'hôte est déjà dans la room via join_room_local() → on affiche directement
		_refresh_slots()
		var current: int = GameConfig.players.size()
		var total:   int = GameConfig.get_max_players()
		status_label.text = " En attente des joueurs… %d/%d" % [current, total]
	else:
		# Le client envoie sa demande de rejoindre après un court délai
		# (pour laisser le temps à la connexion ENet de s'établir)
		status_label.text = " Connexion à la room…"
		await get_tree().create_timer(0.5).timeout
		RoomManager.request_join_room.rpc_id(1,
			GameConfig.room_name,
			GameConfig.mode,
			GameConfig.format,
			GameConfig.diff,
			GameConfig.map,
			GameConfig.steam_name
		)

func _update_labels() -> void:
	label_room_name.text = "Room : %s"   % GameConfig.room_name
	label_map.text       = "Map : %s"    % GameConfig.map.to_upper()
	label_format.text    = "Format : %s" % GameConfig.format

func _on_list_updated(_rid: String, _data: Array) -> void:
	_update_labels()
	btn_lancer.visible = GameConfig.is_host
	_refresh_slots()

	var total:   int = GameConfig.get_max_players()
	var current: int = GameConfig.players.size()

	if GameConfig.is_host:
		btn_lancer.disabled = current < total
		status_label.text = \
			" Tout le monde est là — lance la partie !" \
			if not btn_lancer.disabled \
			else " En attente des joueurs… %d/%d" % [current, total]
	else:
		status_label.text = " En attente du lancement… %d/%d" % [current, total]

func _on_room_full(_rid: String) -> void:
	status_label.text = " Room pleine !"

func _refresh_slots() -> void:
	for c in slots_a.get_children(): c.queue_free()
	for c in slots_b.get_children(): c.queue_free()

	var per_team:    int   = GameConfig.get_players_per_team()
	var all_players: Array = GameConfig.players.values()
	all_players.sort_custom(func(a, b): return a.join_order < b.join_order)
	var team_a: Array = all_players.filter(func(p): return p.team == "a")
	var team_b: Array = all_players.filter(func(p): return p.team == "b")

	for i in per_team:
		var lbl := Label.new()
		if i < team_a.size():
			var you: String = " (vous)" if team_a[i].id == GameConfig.my_peer_id else ""
			lbl.text = "%s%s" % [team_a[i].name, you]
		else:
			lbl.text = "[ Slot vide ]"
		slots_a.add_child(lbl)

	for i in per_team:
		var lbl := Label.new()
		if i < team_b.size():
			var you: String = " (vous)" if team_b[i].id == GameConfig.my_peer_id else ""
			lbl.text = "%s%s" % [team_b[i].name, you]
		else:
			lbl.text = "[ Slot vide ]"
		slots_b.add_child(lbl)

	# Mise à jour du Matchmaker (hôte uniquement)
	if GameConfig.is_host:
		Matchmaker.update_room(GameConfig.room_name, GameConfig.players.size(), false)

func _on_lancer_pressed() -> void:
	if not GameConfig.is_host:
		return
	if RoomManager.rooms.has(GameConfig.room_name):
		RoomManager._start_game(GameConfig.room_name)
	else:
		status_label.text = " Room introuvable !"

func _on_quitter_pressed() -> void:
	if GameConfig.is_host:
		Matchmaker.delete_room(GameConfig.room_name)
	NetworkManager.disconnect_from_server()
	GameConfig.reset()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
