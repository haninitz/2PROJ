extends Control
 
@onready var room_list    := $vbox/scroll/room_list
@onready var btn_refresh  := $vbox/btn_refresh
@onready var btn_back     := $vbox/btn_back
@onready var status_label := $vbox/status_label
 
#  Playit config
const PLAYIT_HOST := "software-reporter.gl.at.ply.gg"
const PLAYIT_IP   := "147.185.221.19"   # IP résolue de ce tunnel (pour détection locale)
const PLAYIT_PORT := 61177
 
func _ready() -> void:
	status_label.text = ""
	btn_refresh.pressed.connect(_on_refresh_pressed)
	btn_back.pressed.connect(_on_back_pressed)
 
	Matchmaker.room_list_received.connect(_on_list_received)
	Matchmaker.room_found.connect(_on_room_found)
	Matchmaker.room_not_found.connect(_on_room_not_found)
 
	# Brancher les signaux réseau ici (une seule fois)
	NetworkManager.connected_to_server.connect(_on_connected)
	NetworkManager.connection_failed.connect(_on_connection_fail)
 
	# Charger la liste automatiquement
	_on_refresh_pressed()
 
func _on_refresh_pressed() -> void:
	status_label.text = "Chargement des rooms…"
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
		var btn                  := Button.new()
		btn.custom_minimum_size   = Vector2(0, 50)
		var players: int          = room.get("players", 0)
		var max_p: int            = room.get("max_players", 2)
		var full: bool            = room.get("full", false)
		var started: bool         = room.get("started", false)
		var room_name: String     = room.get("name", "")
		var map_name: String      = room.get("map", "")
		var format: String        = room.get("format", "")
 
		if started:
			btn.text     = "EN COURS | %s | %s | %s | %d/%d" \
				% [room_name, format, map_name.to_upper(), players, max_p]
			btn.disabled = true
		elif full:
			btn.text     = "PLEINE | %s | %s | %s | %d/%d" \
				% [room_name, format, map_name.to_upper(), players, max_p]
			btn.disabled = true
		else:
			btn.text = "%s | %s | %s | %d/%d joueurs" \
				% [room_name, format, map_name.to_upper(), players, max_p]
			var r_name:   String = room_name
			var r_map:    String = map_name
			var r_format: String = format
			var r_mode:   String = room.get("mode", "multi")
			var r_diff:   String = room.get("diff", "med")
			var r_max:    int    = max_p
			btn.pressed.connect(
				func(): _join_room(r_name, r_map, r_format, r_mode, r_diff, r_max)
			)
 
		room_list.add_child(btn)
 
#  Clic sur une room 
func _join_room(room_name: String, map: String, format: String,
		mode: String, diff: String, _max_p: int) -> void:
	status_label.text    = "Connexion à '%s'…" % room_name
	GameConfig.room_name = room_name
	GameConfig.map       = map
	GameConfig.format    = format
	GameConfig.mode      = mode
	GameConfig.diff      = diff
	# Le Matchmaker va renvoyer l'adresse (hostname Playit) via room_found
	Matchmaker.find_room(room_name)
 
# Adresse reçue du Matchmaker
func _on_room_found(address: String) -> void:
	status_label.text = "Résolution de l'adresse…"
	print("[ListeRooms] Adresse reçue : %s" % address)
 
	# Cas 1 : c'est déjà une IP numérique
	if address.is_valid_ip_address():
		await _decide_and_connect(address)
		return
 
	# Cas 2 : c'est un hostname → résolution DNS asynchrone
	var resolver_id := IP.resolve_hostname_queue_item(address)
	var resolved_ip := ""
 
	while true:
		await get_tree().create_timer(0.1).timeout
		var dns_status := IP.get_resolve_item_status(resolver_id)
		if dns_status == IP.RESOLVER_STATUS_DONE:
			resolved_ip = IP.get_resolve_item_address(resolver_id)
			IP.erase_resolve_item(resolver_id)
			print("[ListeRooms] DNS : %s → %s" % [address, resolved_ip])
			break
		elif dns_status == IP.RESOLVER_STATUS_ERROR:
			IP.erase_resolve_item(resolver_id)
			status_label.text = "Erreur DNS — vérifie ta connexion"
			return
 
	await _decide_and_connect(resolved_ip)
 
# Choisir IP finale + port (Playit ou local)
func _decide_and_connect(resolved_ip: String) -> void:
	# On récupère l'IP publique du client pour savoir si on est l'hôte
	var http := HTTPRequest.new()
	add_child(http)
 
	var done := false
	var my_public_ip := ""
 
	http.request_completed.connect(
		func(_r, _c, _h, body):
			my_public_ip = body.get_string_from_utf8().strip_edges()
			done = true
	)
	http.request("https://api.ipify.org")
 
	# Attendre la réponse HTTP (max 5 s)
	var t := 0.0
	while not done and t < 5.0:
		await get_tree().create_timer(0.1).timeout
		t += 0.1
	http.queue_free()
 
	var final_ip:   String = resolved_ip
	var final_port: int    = PLAYIT_PORT   # par défaut on passe par Playit
 
	# Si le client et le serveur ont la même IP publique → même réseau local
	# On se connecte directement en localhost sur le port local
	if my_public_ip != "" and my_public_ip == resolved_ip:
		final_ip   = "127.0.0.1"
		final_port = NetworkManager.LOCAL_PORT
		print("[ListeRooms] Même réseau → connexion locale 127.0.0.1:%d" % final_port)
	else:
		print("[ListeRooms] Réseau différent → tunnel Playit %s:%d" % [final_ip, final_port])
 
	status_label.text    = "Connexion à %s:%d…" % [final_ip, final_port]
	GameConfig.server_ip = final_ip
	NetworkManager.join_server_with_port(final_ip, final_port)
 
func _on_connected() -> void:
	get_tree().change_scene_to_file("res://scenes/SalleAttente.tscn")
 
func _on_connection_fail() -> void:
	status_label.text = "Connexion échouée — réessaie"
 
func _on_room_not_found() -> void:
	status_label.text = "Room introuvable !"
 
func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
