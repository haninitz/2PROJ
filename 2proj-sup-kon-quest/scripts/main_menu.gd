extends Control

@onready var input_pseudo := $vbox/input_pseudo
@onready var btn_create   := $vbox/btn_create
@onready var btn_join     := $vbox/btn_join
@onready var btn_back     := $vbox/btn_back
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
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)

	NetworkManager.connected_to_server.connect(_on_connected_ok)
	NetworkManager.connection_failed.connect(_on_connection_fail)

func _get_pseudo() -> String:
	var p: String = input_pseudo.text.strip_edges()
	if p.is_empty():
		p = "Joueur_%d" % randi_range(100, 999)
	return p

func _on_create_pressed() -> void:
	GameConfig.steam_name = _get_pseudo()
	GameConfig.is_host    = true
	NetworkManager.create_server()

	# Trouver l'IP locale automatiquement
	var local_ip := _get_local_ip()
	GameConfig.server_ip = local_ip

	# Générer un code de room lisible
	var code := _ip_to_code(local_ip)
	GameConfig.room_name = code

	status_label.text = "Code de ta room : %s\nDonne ce code à tes amis !" % code
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/ChoixMode.tscn")

func _get_local_ip() -> String:
	var addrs := IP.get_local_addresses()
	for addr in addrs:
		if addr.begins_with("192.168.") or addr.begins_with("10."):
			return addr
	return "127.0.0.1"

func _ip_to_code(ip: String) -> String:
	# Convertit 192.168.1.42 en code court ex: "SPY042"
	var parts := ip.split(".")
	if parts.size() == 4:
		return "SPY%03d" % int(parts[3])
	return "SPY001"

func _on_join_pressed() -> void:
	GameConfig.steam_name = _get_pseudo()
	join_panel.visible    = true
	input_room.placeholder_text = "Code de la room (ex: SPY042)"
	input_room.grab_focus()

func _on_connect_pressed() -> void:
	var code: String = input_room.text.strip_edges().to_upper()
	if code.is_empty():
		status_label.text = "⚠ Entre le code de la room !"
		return

	# Décoder le code en IP
	var ip := _code_to_ip(code)
	if ip.is_empty():
		status_label.text = "⚠ Code invalide !"
		return

	GameConfig.server_ip  = ip
	GameConfig.room_name  = code
	status_label.text     = "⏳ Connexion…"
	btn_connect.disabled  = true
	NetworkManager.join_server(ip)

func _code_to_ip(code: String) -> String:
	# Décode "SPY042" → "192.168.1.42"
	# Le client doit être sur le même réseau que l'hôte
	if code.begins_with("SPY") and code.length() == 6:
		var num := int(code.substr(3))
		# Trouver le bon sous-réseau automatiquement
		var addrs := IP.get_local_addresses()
		for addr in addrs:
			if addr.begins_with("192.168.") or addr.begins_with("10."):
				var parts := addr.split(".")
				if parts.size() == 4:
					return "%s.%s.%s.%d" % [parts[0], parts[1], parts[2], num]
	return ""

func _on_connected_ok() -> void:
	# Le client va directement en salle d'attente
	# Il recevra la config de la room via RPC
	get_tree().change_scene_to_file("res://scenes/SalleAttente.tscn")

func _on_connection_fail() -> void:
	status_label.text    = "❌ Connexion échouée — vérifie l'IP"
	btn_connect.disabled = false

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
