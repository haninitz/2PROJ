extends Node

const PORT     := 7777
const MAX_PEERS := 32

signal connected_to_server
signal connection_failed
signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

func create_server() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, MAX_PEERS)
	if err != OK:
		push_error("[NetworkManager] Port %d occupé ! (err=%d)" % [PORT, err])
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	GameConfig.is_host    = true
	GameConfig.my_peer_id = 1
	print("[NetworkManager] ✅ Serveur démarré port %d" % PORT)

func join_server(ip: String) -> void:
	GameConfig.server_ip = ip
	var peer := ENetMultiplayerPeer.new()
	var err  := peer.create_client(ip, PORT)
	if err != OK:
		push_error("[NetworkManager] Connexion impossible à %s (err=%d)" % [ip, err])
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_fail)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	print("[NetworkManager] ⏳ Connexion à %s:%d…" % [ip, PORT])

func disconnect_from_server() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	GameConfig.reset()

func _on_connected_ok() -> void:
	GameConfig.my_peer_id = multiplayer.get_unique_id()
	GameConfig.is_host    = false
	print("[NetworkManager] ✅ Connecté ! ID = %d" % GameConfig.my_peer_id)
	connected_to_server.emit()

func _on_connection_fail() -> void:
	push_error("[NetworkManager] ❌ Connexion échouée")
	connection_failed.emit()

func _on_peer_connected(id: int) -> void:
	print("[NetworkManager] 👤 Peer connecté : %d" % id)
	player_connected.emit(id)

func _on_peer_disconnected(id: int) -> void:
	print("[NetworkManager] ❌ Peer déconnecté : %d" % id)
	player_disconnected.emit(id)
