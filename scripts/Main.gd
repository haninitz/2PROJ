extends Node2D

# ── Dimensions ───────────────────────────────────────────────────────────────
const WIN_W   := 1152
const MAP_H   := 620
const PANEL_H := 100

# ── Visuel ───────────────────────────────────────────────────────────────────
const CAMP_R  := 42.0

const C_P1      := Color(0.22, 0.45, 0.90)   # Bleu
const C_P2      := Color(0.88, 0.22, 0.22)   # Rouge
const C_NEUTRAL := Color(0.55, 0.55, 0.55)   # Gris
const C_SELECT  := Color(1.00, 0.92, 0.15)   # Jaune (sélection)
const C_BG      := Color(0.18, 0.36, 0.18)   # Vert carte
const C_WATER   := Color(0.20, 0.42, 0.80)   # Rivière
const C_FOREST  := Color(0.10, 0.26, 0.10)   # Forêt
const C_PANEL   := Color(0.08, 0.08, 0.08)   # Panneau UI
const C_GOLD    := Color(1.00, 0.87, 0.30)   # Or

# ── État du jeu ──────────────────────────────────────────────────────────────
var camps: Array = []
var players: Array = []
var current_player := 0
var turn := 1
var selected_idx := -1   # -1 = aucun camp sélectionné
var game_over := false
var winner := ""
var message := ""

# ── UI ───────────────────────────────────────────────────────────────────────
var font: Font
var end_btn: Button
var msg_label: Label
var info_label: Label
var gold_label: Label

# ── Positions des forêts décoratives ─────────────────────────────────────────
var forests: Array = []

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	forests = [
		Vector2(275, 148), Vector2(335, 292), Vector2(270, 442),
		Vector2(802, 148), Vector2(762, 418), Vector2(828, 452)
	]
	font = ThemeDB.fallback_font
	_init_data()
	_build_ui()
	_collect_income(0)
	message = "Joueur 1 — Sélectionnez un de vos camps"

func _init_data() -> void:
	players = [
		{"name": "Joueur 1", "gold": 0},
		{"name": "Joueur 2", "gold": 0},
	]
	# { name, pos, owner (-1=neutre / 0=J1 / 1=J2), units, income }
	camps = [
		{"name": "Fort Bleu",       "pos": Vector2(150, 200), "owner": 0,  "units": 5, "income": 10},
		{"name": "Citadelle Bleue", "pos": Vector2(150, 430), "owner": 0,  "units": 5, "income": 10},
		{"name": "Carrefour",       "pos": Vector2(440, 310), "owner": -1, "units": 2, "income": 15},
		{"name": "Passage",         "pos": Vector2(710, 310), "owner": -1, "units": 2, "income": 15},
		{"name": "Fort Rouge",      "pos": Vector2(1000, 200), "owner": 1, "units": 5, "income": 10},
		{"name": "Citadelle Rouge", "pos": Vector2(1000, 430), "owner": 1, "units": 5, "income": 10},
	]

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	end_btn = Button.new()
	end_btn.text = "Fin de tour"
	end_btn.position = Vector2(WIN_W - 185, MAP_H + 28)
	end_btn.size = Vector2(165, 44)
	end_btn.pressed.connect(_on_end_turn)
	layer.add_child(end_btn)

	msg_label = Label.new()
	msg_label.position = Vector2(10, MAP_H + 6)
	msg_label.size = Vector2(WIN_W - 200, 36)
	layer.add_child(msg_label)

	info_label = Label.new()
	info_label.position = Vector2(10, MAP_H + 52)
	info_label.size = Vector2(560, 32)
	layer.add_child(info_label)

	gold_label = Label.new()
	gold_label.position = Vector2(580, MAP_H + 52)
	gold_label.size = Vector2(260, 32)
	layer.add_child(gold_label)

# ─────────────────────────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	_update_ui()
	queue_redraw()

func _update_ui() -> void:
	var p: Dictionary = players[current_player]
	msg_label.text  = message
	info_label.text = "%s  —  Tour %d  |  [P] Produire unité (10 or)" % [p["name"], turn]
	gold_label.text = "Or : %d" % p["gold"]
	info_label.modulate = C_P1 if current_player == 0 else C_P2

# ── Dessin ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	# Fond de carte
	draw_rect(Rect2(0, 0, WIN_W, MAP_H), C_BG)

	# Rivière centrale + pont
	var rx := WIN_W / 2 - 22
	draw_rect(Rect2(rx, 0, 44, MAP_H), C_WATER)
	draw_rect(Rect2(rx, 258, 44, 92), C_BG)   # ouverture du pont

	# Forêts décoratives
	for fp in forests:
		draw_circle(fp, 52, C_FOREST)
		draw_arc(fp, 52, 0, TAU, 24, Color(0.05, 0.16, 0.05), 2.0)

	# Panneau UI
	draw_rect(Rect2(0, MAP_H, WIN_W, PANEL_H), C_PANEL)

	# Lignes de connexion entre camps proches (< 520 px)
	for i in range(camps.size()):
		for j in range(i + 1, camps.size()):
			var pa: Vector2 = camps[i]["pos"]
			var pb: Vector2 = camps[j]["pos"]
			if pa.distance_to(pb) < 520.0:
				draw_line(pa, pb, Color(0.35, 0.35, 0.35, 0.55), 2.0)

	# Camps
	for i in range(camps.size()):
		_draw_camp(i)

	# Écran de victoire
	if game_over:
		draw_rect(Rect2(0, 0, WIN_W, MAP_H), Color(0, 0, 0, 0.55))
		var w := 640.0
		draw_string(font, Vector2((WIN_W - w) / 2.0, MAP_H / 2.0 + 20.0),
			"VICTOIRE DE %s !" % winner.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, w, 44, C_GOLD)

func _draw_camp(idx: int) -> void:
	var c: Dictionary = camps[idx]
	var pos: Vector2 = c["pos"]
	var col := _owner_color(c["owner"])

	# Anneau de sélection
	if idx == selected_idx:
		draw_circle(pos, CAMP_R + 7.0, C_SELECT)

	# Corps du camp
	draw_circle(pos, CAMP_R, col)
	draw_arc(pos, CAMP_R, 0, TAU, 48, Color.BLACK, 2.5)

	# Nom (au-dessus)
	var nw := 190.0
	draw_string(font, pos + Vector2(-nw / 2.0, -CAMP_R - 6.0),
		c["name"], HORIZONTAL_ALIGNMENT_CENTER, nw, 13, Color.WHITE)

	# Nombre d'unités (au centre)
	var uw := 60.0
	draw_string(font, pos + Vector2(-uw / 2.0, 10.0),
		str(c["units"]), HORIZONTAL_ALIGNMENT_CENTER, uw, 22, Color.WHITE)

	# Revenu (en dessous)
	var iw := 100.0
	draw_string(font, pos + Vector2(-iw / 2.0, CAMP_R + 18.0),
		"+%d or" % c["income"], HORIZONTAL_ALIGNMENT_CENTER, iw, 12, C_GOLD)

# ── Entrées ──────────────────────────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if game_over:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			_produce_unit()

func _handle_click(pos: Vector2) -> void:
	var clicked := _camp_at(pos)

	if clicked == -1:
		selected_idx = -1
		message = "%s — Sélectionnez un de vos camps" % players[current_player]["name"]
		return

	if selected_idx == -1:
		# Premier clic : sélectionner un camp du joueur actuel
		if camps[clicked]["owner"] == current_player:
			selected_idx = clicked
			message = "%s sélectionné (%d unités) — Cliquez sur une cible ou [P] pour produire" \
					  % [camps[clicked]["name"], camps[clicked]["units"]]
		else:
			message = "Ce camp ne vous appartient pas !"
	else:
		# Deuxième clic : action
		if clicked == selected_idx:
			selected_idx = -1
		elif camps[clicked]["owner"] == current_player:
			_move_units(selected_idx, clicked)
			selected_idx = -1
		else:
			_attack(selected_idx, clicked)
			selected_idx = -1
		_check_victory()

func _move_units(src: int, tgt: int) -> void:
	if camps[src]["units"] <= 1:
		message = "Il faut au moins 2 unités pour se déplacer !"
		return
	var n: int = camps[src]["units"] - 1
	camps[tgt]["units"] += n
	camps[src]["units"] = 1
	message = "%d unités déplacées vers %s" % [n, camps[tgt]["name"]]

func _attack(src: int, tgt: int) -> void:
	if camps[src]["units"] <= 1:
		message = "Il faut au moins 2 unités pour attaquer !"
		return
	Combat.resolve(camps[src], camps[tgt])
	message = "Attaque sur %s !" % camps[tgt]["name"]

func _produce_unit() -> void:
	if selected_idx == -1:
		message = "Sélectionnez d'abord un camp !"
		return
	if camps[selected_idx]["owner"] != current_player:
		return
	if players[current_player]["gold"] < 10:
		message = "Pas assez d'or ! (10 or requis)"
		return
	players[current_player]["gold"] -= 10
	camps[selected_idx]["units"] += 1
	message = "Unité produite à %s — %d unités" % [camps[selected_idx]["name"], camps[selected_idx]["units"]]

func _on_end_turn() -> void:
	selected_idx = -1
	current_player = 1 - current_player
	if current_player == 0:
		turn += 1
	_collect_income(current_player)
	message = "%s — Sélectionnez un de vos camps" % players[current_player]["name"]
	_check_victory()

func _collect_income(p: int) -> void:
	for c in camps:
		if c["owner"] == p:
			players[p]["gold"] += c["income"]

func _check_victory() -> void:
	var c1 := 0
	var c2 := 0
	for c in camps:
		if c["owner"] == 0:
			c1 += 1
		elif c["owner"] == 1:
			c2 += 1
	if c1 == 0:
		_end_game("Joueur 2")
	elif c2 == 0:
		_end_game("Joueur 1")

func _end_game(w: String) -> void:
	game_over = true
	winner = w
	message = "VICTOIRE DE %s !" % w.to_upper()
	end_btn.disabled = true

# ── Utilitaires ──────────────────────────────────────────────────────────────
func _camp_at(pos: Vector2) -> int:
	for i in range(camps.size()):
		if (camps[i]["pos"] as Vector2).distance_to(pos) <= CAMP_R:
			return i
	return -1

func _owner_color(owner: int) -> Color:
	match owner:
		0: return C_P1
		1: return C_P2
	return C_NEUTRAL
