extends Control

@onready var input_room   := $vbox/input_room
@onready var btn_create   := $vbox/btn_create
@onready var btn_back     := $vbox/btn_back
@onready var status_label := $vbox/status_label

func _ready() -> void:
	status_label.text = ""
	btn_create.pressed.connect(_on_create_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	Matchmaker.room_created.connect(_on_room_registered)

func _on_create_pressed() -> void:
	var room_name: String = input_room.text.strip_edges()
	if room_name.is_empty():
		status_label.text = "Entre un nom de room !"
		return
	if room_name.length() < 3:
		status_label.text = "Minimum 3 caracteres !"
		return

	GameConfig.room_name = room_name
	GameConfig.is_host   = true

	# Recuperer l'IP publique puis enregistrer la room
	status_label.text = "Enregistrement de la room..."
	btn_create.disabled = true
	_register_room(room_name)

func _register_room(room_name: String) -> void:
	# Recuperer l'IP publique via un service externe
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(func(result, _code, _headers, body):
		var ip := "127.0.0.1"
		if result == HTTPRequest.RESULT_SUCCESS:
			ip = body.get_string_from_utf8().strip_edges()
		print("[NomRoom] IP publique : %s" % ip)
		GameConfig.server_ip = ip
		# Enregistrer sur le matchmaker
		Matchmaker.create_room(room_name, ip)
		http.queue_free()
	)
	http.request("https://api.ipify.org")

func _on_room_registered(_room_name: String) -> void:
	status_label.text = "Room enregistree ! En attente des joueurs..."
	# Ajouter l'hote dans GameConfig.players
	GameConfig.players[1] = {
		"id":    1,
		"name":  GameConfig.steam_name,
		"team":  "a",
		"ready": true
	}
	get_tree().change_scene_to_file("res://scenes/SalleAttente.tscn")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ChoixMap.tscn")
