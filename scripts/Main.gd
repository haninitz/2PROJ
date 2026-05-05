extends Node2D

# ── Dimensions ───────────────────────────────────────────────────────────────
const WIN_W   = 1152
const MAP_H   = 620
const CAMP_R  = 42.0

# ── Couleurs ─────────────────────────────────────────────────────────────────
const C_P1      = Color(0.22, 0.45, 0.90)
const C_P2      = Color(0.88, 0.22, 0.22)
const C_NEUTRAL = Color(0.55, 0.55, 0.55)
const C_SELECT  = Color(1.00, 0.92, 0.15)
const C_BG      = Color(0.18, 0.36, 0.18)
const C_WATER   = Color(0.20, 0.42, 0.80)
const C_FOREST  = Color(0.10, 0.26, 0.10)
const C_PANEL   = Color(0.08, 0.08, 0.08)
const C_GOLD    = Color(1.00, 0.87, 0.30)

# ── État du jeu ──────────────────────────────────────────────────────────────
var camps:          Array = []
var players:        Array = []
var current_player: int   = 0
var turn:           int   = 1
var selected_idx:   int   = -1
var game_over:      bool  = false
var winner:         String = ""
var message:        String = ""

# ── Données de la carte choisie ──────────────────────────────────────────────
var forests:  Array = []
var river_x:  int   = -1
var bridge_y: int   = -1
var bridge_h: int   = 0

var map_chosen: bool = false

# Référence au nœud UI (CanvasLayer enfant)
@onready var ui = $UI

var font: Font

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	font = ThemeDB.fallback_font
	# On connecte les signaux de l'UI aux fonctions du jeu
	ui.end_turn_pressed.connect(_on_end_turn)
	ui.recruit_pressed.connect(_on_recruit)
	ui.map_selected.connect(_on_map_selected)

# Appelée quand le joueur choisit une carte sur l'écran de démarrage
func _on_map_selected(map_index: int) -> void:
	ui.hide_map_screen()
	map_chosen = true
	_init_data(map_index)
	_collect_income(0)
	message = "Joueur 1 — Sélectionnez un de vos camps"

# Initialise les données du jeu pour la carte choisie
func _init_data(map_index: int) -> void:
	players = [
		{"name": "Joueur 1", "gold": 0},
		{"name": "Joueur 2", "gold": 0},
	]

	var map = MapDefs.MAPS[map_index]
	forests  = map["forests"]
	river_x  = map["river_x"]
	bridge_y = map["bridge_y"]
	bridge_h = map["bridge_h"]

	# Copie des camps pour ne pas modifier la définition d'origine
	camps = []
	for c in map["camps"]:
		camps.append({
			"name":      c["name"],
			"pos":       c["pos"],
			"owner":     c["owner"],
			"units":     c["units"],
			"income":    c["income"],
			"unit_type": "Infantry",
			"queue":     []
		})

# ── Boucle principale ────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if map_chosen:
		var p = players[current_player]
		ui.update_hud(p["name"], turn, p["gold"], message, current_player)
	queue_redraw()

# ── Dessin ───────────────────────────────────────────────────────────────────
func _draw() -> void:
	if not map_chosen:
		return

	# Fond vert de la carte
	draw_rect(Rect2(0, 0, WIN_W, MAP_H), C_BG)

	# Rivière (seulement si la carte en a une)
	if river_x > 0:
		draw_rect(Rect2(river_x - 22, 0, 44, MAP_H), C_WATER)
		draw_rect(Rect2(river_x - 22, bridge_y, 44, bridge_h), C_BG)

	# Forêts décoratives
	for fp in forests:
		draw_circle(fp, 52, C_FOREST)
		draw_arc(fp, 52, 0, TAU, 24, Color(0.05, 0.16, 0.05), 2.0)

	# Panneau noir en bas (zone UI)
	draw_rect(Rect2(0, MAP_H, WIN_W, 100), C_PANEL)

	# Lignes de connexion entre les camps proches
	for i in range(camps.size()):
		for j in range(i + 1, camps.size()):
			var pa: Vector2 = camps[i]["pos"]
			var pb: Vector2 = camps[j]["pos"]
			if pa.distance_to(pb) < 520.0:
				draw_line(pa, pb, Color(0.35, 0.35, 0.35, 0.55), 2.0)

	# Dessin de chaque camp
	for i in range(camps.size()):
		_draw_camp(i)

	# Écran de victoire
	if game_over:
		draw_rect(Rect2(0, 0, WIN_W, MAP_H), Color(0, 0, 0, 0.55))
		draw_string(font, Vector2(256, MAP_H / 2.0 + 20.0),
			"VICTOIRE DE %s !" % winner.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, 640, 44, C_GOLD)

func _draw_camp(idx: int) -> void:
	var c   = camps[idx]
	var pos: Vector2 = c["pos"]
	var col = _owner_color(c["owner"])

	# Anneau de sélection jaune
	if idx == selected_idx:
		draw_circle(pos, CAMP_R + 7.0, C_SELECT)

	# Corps et contour du camp
	draw_circle(pos, CAMP_R, col)
	draw_arc(pos, CAMP_R, 0, TAU, 48, Color.BLACK, 2.5)

	# Nom du camp (au-dessus)
	draw_string(font, pos + Vector2(-95, -CAMP_R - 6.0),
		c["name"], HORIZONTAL_ALIGNMENT_CENTER, 190, 13, Color.WHITE)

	# Type d'unité (petit texte dans le camp, en haut)
	var tlabel = UnitDefs.TYPES[c["unit_type"]]["label"]
	draw_string(font, pos + Vector2(-30, -5),
		tlabel, HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color.WHITE)

	# Nombre d'unités (centré dans le camp)
	draw_string(font, pos + Vector2(-30, 16),
		str(c["units"]), HORIZONTAL_ALIGNMENT_CENTER, 60, 20, Color.WHITE)

	# Revenu en or (en dessous du camp)
	draw_string(font, pos + Vector2(-50, CAMP_R + 18.0),
		"+%d or" % c["income"], HORIZONTAL_ALIGNMENT_CENTER, 100, 12, C_GOLD)

	# Taille de la file de recrutement
	if c["queue"].size() > 0:
		draw_string(font, pos + Vector2(-40, CAMP_R + 32.0),
			"[%d en file]" % c["queue"].size(),
			HORIZONTAL_ALIGNMENT_CENTER, 80, 10, C_GOLD)

# ── Entrées ──────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not map_chosen or game_over:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_P:
			_produce_unit()

func _handle_click(pos: Vector2) -> void:
	var clicked = _camp_at(pos)

	# Clic dans le vide : on désélectionne
	if clicked == -1:
		selected_idx = -1
		ui.hide_recruit()
		message = "%s — Sélectionnez un de vos camps" % players[current_player]["name"]
		return

	if selected_idx == -1:
		# Premier clic : sélectionner un camp
		if camps[clicked]["owner"] == current_player:
			selected_idx = clicked
			ui.show_recruit(camps[clicked])
			message = "%s sélectionné — Cliquez une cible ou recrutez" % camps[clicked]["name"]
		else:
			message = "Ce camp ne vous appartient pas !"
	else:
		# Deuxième clic : action
		if clicked == selected_idx:
			# Clic sur le même camp : désélectionner
			selected_idx = -1
			ui.hide_recruit()
		elif camps[clicked]["owner"] == current_player:
			# Clic sur un camp allié : déplacer les unités
			_move_units(selected_idx, clicked)
			selected_idx = -1
			ui.hide_recruit()
		else:
			# Clic sur un camp ennemi ou neutre : attaquer
			_attack(selected_idx, clicked)
			selected_idx = -1
			ui.hide_recruit()
		_check_victory()

# ── Actions du joueur ────────────────────────────────────────────────────────

func _move_units(src: int, tgt: int) -> void:
	if camps[src]["units"] <= 1:
		message = "Il faut au moins 2 unités pour se déplacer !"
		return
	var n = camps[src]["units"] - 1
	camps[tgt]["units"] += n
	camps[src]["units"] = 1
	message = "%d unités déplacées vers %s" % [n, camps[tgt]["name"]]

func _attack(src: int, tgt: int) -> void:
	if camps[src]["units"] <= 1:
		message = "Il faut au moins 2 unités pour attaquer !"
		return
	Combat.resolve(camps[src], camps[tgt])
	message = "Attaque sur %s !" % camps[tgt]["name"]

# Produit une unité Infantry immédiatement (touche P, 10 or)
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
	message = "Unité produite à %s" % camps[selected_idx]["name"]

# Ajoute un type d'unité dans la file de recrutement du camp sélectionné
func _on_recruit(unit_type: String) -> void:
	if selected_idx == -1:
		return
	var camp = camps[selected_idx]
	if camp["owner"] != current_player:
		return
	if camp["queue"].size() >= 3:
		message = "File pleine ! (3 unités maximum en attente)"
		return
	var price = UnitDefs.TYPES[unit_type]["price"]
	if players[current_player]["gold"] < price:
		message = "Pas assez d'or ! (%d or requis)" % price
		return
	players[current_player]["gold"] -= price
	camp["queue"].append(unit_type)
	ui.show_recruit(camp)
	message = "%s ajouté à la file de %s" % [UnitDefs.TYPES[unit_type]["label"], camp["name"]]

# ── Fin de tour ──────────────────────────────────────────────────────────────
func _on_end_turn() -> void:
	selected_idx = -1
	ui.hide_recruit()

	# Les unités en file arrivent à la fin du tour du joueur actuel
	_process_queues(current_player)

	# On passe au joueur suivant
	current_player = 1 - current_player
	if current_player == 0:
		turn += 1

	_collect_income(current_player)
	message = "%s — Sélectionnez un de vos camps" % players[current_player]["name"]
	_check_victory()

# Livre la première unité de la file pour chaque camp du joueur
func _process_queues(p: int) -> void:
	for camp in camps:
		if camp["owner"] == p and camp["queue"].size() > 0:
			var unit_type = camp["queue"][0]
			camp["queue"].remove_at(0)
			camp["units"] += 1
			camp["unit_type"] = unit_type

func _collect_income(p: int) -> void:
	for c in camps:
		if c["owner"] == p:
			players[p]["gold"] += c["income"]

# ── Victoire ─────────────────────────────────────────────────────────────────
func _check_victory() -> void:
	var c1 = 0
	var c2 = 0
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
	ui.disable_end_btn()

# ── Utilitaires ──────────────────────────────────────────────────────────────

# Retourne l'index du camp sous la position cliquée, ou -1 si aucun
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
