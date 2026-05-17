# ============================================================
# Matchmaker.gd — AUTOLOAD
# Nom dans Autoloads : "Matchmaker"
# Gère la connexion WebSocket au serveur de matchmaking
# ============================================================
extends Node

const SERVER_URL := "wss://sup-kon-quest-matchmaker.onrender.com"

signal room_created(room_name: String)
signal room_found(ip: String)
signal room_not_found
signal matchmaker_error

var socket := WebSocketPeer.new()
var connected := false
var pending_action := ""

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	socket.poll()
	match socket.get_ready_state():
		WebSocketPeer.STATE_OPEN:
			if not connected:
				connected = true
				print("[Matchmaker]  Connecté au serveur")
				_send_pending()
			while socket.get_available_packet_count() > 0:
				_on_message(socket.get_packet().get_string_from_utf8())
		WebSocketPeer.STATE_CLOSED:
			if connected:
				connected = false
				print("[Matchmaker] Déconnecté")

func _connect_to_server() -> void:
	if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		return
	socket.connect_to_url(SERVER_URL)
	print("[Matchmaker]  Connexion au matchmaker…")

func create_room(room_name: String, ip: String) -> void:
	pending_action = JSON.stringify({
		"action": "create",
		"room":   room_name,
		"ip":     ip
	})
	_connect_to_server()

func find_room(room_name: String) -> void:
	pending_action = JSON.stringify({
		"action": "find",
		"room":   room_name
	})
	_connect_to_server()

func delete_room(room_name: String) -> void:
	pending_action = JSON.stringify({
		"action": "delete",
		"room":   room_name
	})
	_connect_to_server()

func _send_pending() -> void:
	if pending_action.is_empty():
		return
	socket.send_text(pending_action)
	pending_action = ""

func _on_message(msg: String) -> void:
	print("[Matchmaker] Message reçu : ", msg)
	var data: Dictionary = JSON.parse_string(msg)
	if data == null:
		return
	match data.get("status", ""):
		"created":
			print("[Matchmaker]  Room '%s' créée" % data.get("room", ""))
			room_created.emit(data.get("room", ""))
		"found":
			print("[Matchmaker]  Room trouvée → IP : %s" % data.get("ip", ""))
			room_found.emit(data.get("ip", ""))
		"not_found":
			print("[Matchmaker]  Room introuvable")
			room_not_found.emit()
