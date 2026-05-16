extends Node

signal player_list_updated(room_id: String, data: Array)
signal room_full(room_id: String)

var rooms:       Dictionary = {}
var player_room: Dictionary = {}

@rpc("any_peer", "reliable")
func request_join_room(room_id: String, mode: String,
		format: String, diff: String, map: String, player_name: String) -> void:
	if not multiplayer.is_server():
		return

	var sender := multiplayer.get_remote_sender_id()

	if not rooms.has(room_id):
		_create_room(room_id, mode, format, diff, map)

	var room: Dictionary = rooms[room_id]
	var max_p: int = _format_to_max(format)

	if room.players.size() >= max_p:
		_notify_full.rpc_id(sender, room_id)
		return

	var team: String = "a" if room.players.size() < max_p / 2 else "b"
	room.players[sender] = {
		"id":    sender,
		"name":  player_name,
		"team":  team,
		"ready": false
	}
	player_room[sender] = room_id

	_confirm_join.rpc_id(sender, room_id, team)
	_broadcast_list(room_id)
	print("[RoomManager] Joueur %d → room '%s' (team %s)" % [sender, room_id, team])

	# Lancer automatiquement si room pleine
	if room.players.size() >= max_p:
		_start_game(room_id)

@rpc("any_peer", "reliable")
func set_player_ready(room_id: String, is_ready: bool) -> void:
	if not multiplayer.is_server():
		return
	var sender := multiplayer.get_remote_sender_id()
	if not rooms.has(room_id):
		return
	if rooms[room_id].players.has(sender):
		rooms[room_id].players[sender]["ready"] = is_ready
	_broadcast_list(room_id)

func remove_player(peer_id: int) -> void:
	if not player_room.has(peer_id):
		return
	var rid: String = player_room[peer_id]
	if rooms.has(rid):
		rooms[rid].players.erase(peer_id)
		_broadcast_list(rid)
		if rooms[rid].players.is_empty():
			rooms.erase(rid)
	player_room.erase(peer_id)

func _create_room(room_id: String, mode: String, format: String,
		diff: String, map: String) -> void:
	rooms[room_id] = {
		"id":      room_id,
		"mode":    mode,
		"format":  format,
		"diff":    diff,
		"map":     map,
		"players": {}
	}
	print("[RoomManager] Room '%s' créée (mode=%s format=%s)" % [room_id, mode, format])

func _start_game(room_id: String) -> void:
	if not rooms.has(room_id):
		return
	var room: Dictionary = rooms[room_id]
	print("[RoomManager] 🚀 Lancement room '%s'" % room_id)

	# Envoyer la config à chaque joueur puis changer de scène
	for pid in room.players:
		_do_start.rpc_id(pid,
			room.mode,
			room.format,
			room.diff,
			room.map,
			room.players.values()
		)

func _broadcast_list(room_id: String) -> void:
	if not rooms.has(room_id):
		return
	var data: Array = rooms[room_id].players.values()
	for pid in rooms[room_id].players:
		_receive_list.rpc_id(pid, room_id, data)
	player_list_updated.emit(room_id, data)

# ── RPC côté CLIENT ──────────────────────────────────────────
@rpc("authority", "reliable")
func _confirm_join(room_id: String, team: String) -> void:
	# Mettre à jour la config avec les vraies valeurs de la room
	if RoomManager.rooms.has(room_id):
		var room = RoomManager.rooms[room_id]
		GameConfig.mode      = room.mode
		GameConfig.format    = room.format
		GameConfig.diff      = room.diff
		GameConfig.map       = room.map
		GameConfig.room_name = room_id
	print("[RoomManager] ✅ Rejoint room '%s' équipe %s" % [room_id, team])

@rpc("authority", "reliable")
func _notify_full(room_id: String) -> void:
	print("[RoomManager] ❌ Room '%s' pleine" % room_id)
	room_full.emit(room_id)

@rpc("authority", "reliable")
func _receive_list(room_id: String, data: Array) -> void:
	GameConfig.players.clear()
	for p in data:
		GameConfig.players[p.id] = p
	player_list_updated.emit(room_id, data)

@rpc("authority", "reliable")
func _do_start(mode: String, format: String, diff: String,
		map: String, players_data: Array) -> void:
	# Stocker la config
	GameConfig.mode   = mode
	GameConfig.format = format
	GameConfig.diff   = diff
	GameConfig.map    = map
	# Stocker les joueurs
	GameConfig.players.clear()
	for p in players_data:
		GameConfig.players[p.id] = p
	# Lancer le jeu
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _format_to_max(format: String) -> int:
	match format:
		"1v1": return 2
		"2v2": return 4
		"3v3": return 6
	return 2
