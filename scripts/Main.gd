extends Node2D

const WIN_W  = 1152
const MAP_H  = 620
const CAMP_R = 42.0

var camps:          Array = []
var players:        Array = []
var current_player: int   = 0
var turn:           int   = 1
var selected_idx:   int   = -1
var game_over:      bool  = false
var winner:         String = ""
var message:        String = ""

var forests:    Array = []
var river_x:    int   = -1
var bridge_y:   int   = -1
var bridge_h:   int   = 0
var has_water:  bool  = false
var land_zones: Array = []
var map_chosen: bool  = false

@onready var ui = $UI

var font:      Font
var _renderer: Renderer

func _ready() -> void:
	font      = ThemeDB.fallback_font
	_renderer = Renderer.new()
	ui.end_turn_pressed.connect(_on_end_turn)
	ui.recruit_pressed.connect(_on_recruit)
	ui.map_selected.connect(_on_map_selected)

func _on_map_selected(map_index: int) -> void:
	ui.hide_map_screen()
	map_chosen = true
	_init_data(map_index)
	_collect_income(0)
	message = "Joueur 1 — Sélectionnez un de vos camps"

func _init_data(map_index: int) -> void:
	players = [Player.new("Joueur 1"), Player.new("Joueur 2")]

	var map = MapDefs.MAPS[map_index]
	forests    = map["forests"]
	river_x    = map["river_x"]
	bridge_y   = map["bridge_y"]
	bridge_h   = map["bridge_h"]
	has_water  = map["has_water"]
	land_zones = map["land_zones"]

	camps = []
	for data in map["camps"]:
		camps.append(Camp.new(data))

# ── Boucle principale ────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if map_chosen:
		var p: Player = players[current_player]
		var income = 0
		var camps_owned = 0
		for camp in camps:
			if camp.owner == current_player:
				income += camp.income
				camps_owned += 1
		var selected_unit = ""
		if selected_idx != -1:
			selected_unit = UnitDefs.TYPES[camps[selected_idx].unit_type]["label"]
		ui.update_hud(p.name, turn, p.gold, income, camps_owned, selected_unit, message, current_player)
	queue_redraw()

# ── Dessin : délégué au Renderer ─────────────────────────────────────────────
func _draw() -> void:
	if not map_chosen:
		return
	_renderer.draw(self, font, camps, selected_idx,
		forests, river_x, bridge_y, bridge_h,
		has_water, land_zones, game_over, winner)

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

	if clicked == -1:
		selected_idx = -1
		ui.hide_recruit()
		message = "%s — Sélectionnez un de vos camps" % players[current_player].name
		return

	if selected_idx == -1:
		if camps[clicked].owner == current_player:
			selected_idx = clicked
			ui.show_recruit(camps[clicked])
			message = "%s sélectionné — Cliquez une cible ou recrutez" % camps[clicked].name
			Sound.play("select")
		else:
			message = "Ce camp ne vous appartient pas !"
	else:
		if clicked == selected_idx:
			selected_idx = -1
			ui.hide_recruit()
		elif camps[clicked].owner == current_player:
			_move_units(selected_idx, clicked)
			selected_idx = -1
			ui.hide_recruit()
		else:
			_attack(selected_idx, clicked)
			selected_idx = -1
			ui.hide_recruit()
		_check_victory()

# ── Actions du joueur ────────────────────────────────────────────────────────
func _move_units(src: int, tgt: int) -> void:
	if camps[src].units <= 1:
		message = "Il faut au moins 2 unités pour se déplacer !"
		return
	var n = camps[src].units - 1
	camps[tgt].units += n
	camps[src].units = 1
	message = "%d unités déplacées vers %s" % [n, camps[tgt].name]
	Sound.play("move")

func _attack(src: int, tgt: int) -> void:
	if camps[src].units <= 1:
		message = "Il faut au moins 2 unités pour attaquer !"
		return
	Combat.resolve(camps[src], camps[tgt])
	message = "Attaque sur %s !" % camps[tgt].name
	Sound.play("attack")

func _produce_unit() -> void:
	if selected_idx == -1:
		message = "Sélectionnez d'abord un camp !"
		return
	if camps[selected_idx].owner != current_player:
		return
	var p: Player = players[current_player]
	if p.gold < 10:
		message = "Pas assez d'or ! (10 or requis)"
		return
	p.gold -= 10
	camps[selected_idx].units += 1
	message = "Unité produite à %s" % camps[selected_idx].name

func _on_recruit(unit_type: String) -> void:
	if selected_idx == -1:
		return
	var camp: Camp = camps[selected_idx]
	if camp.owner != current_player:
		return
	if camp.queue.size() >= 3:
		message = "File pleine ! (3 unités maximum en attente)"
		return
	var price = UnitDefs.TYPES[unit_type]["price"]
	var p: Player = players[current_player]
	if p.gold < price:
		message = "Pas assez d'or ! (%d or requis)" % price
		return
	p.gold -= price
	camp.queue.append(unit_type)
	ui.show_recruit(camp)
	message = "%s ajouté à la file de %s" % [UnitDefs.TYPES[unit_type]["label"], camp.name]
	Sound.play("recruit")

# ── Fin de tour ──────────────────────────────────────────────────────────────
func _on_end_turn() -> void:
	Sound.play("end_turn")
	selected_idx = -1
	ui.hide_recruit()
	_process_queues(current_player)
	current_player = 1 - current_player
	if current_player == 0:
		turn += 1
	_collect_income(current_player)
	message = "%s — Sélectionnez un de vos camps" % players[current_player].name
	_check_victory()

func _process_queues(p: int) -> void:
	for camp in camps:
		if camp.owner == p and camp.queue.size() > 0:
			camp.unit_type = camp.queue[0]
			camp.queue.remove_at(0)
			camp.units += 1

func _collect_income(p: int) -> void:
	var player: Player = players[p]
	for camp in camps:
		if camp.owner == p:
			player.gold += camp.income

# ── Victoire ─────────────────────────────────────────────────────────────────
func _check_victory() -> void:
	var count = [0, 0]
	for camp in camps:
		if camp.owner == 0:
			count[0] += 1
		elif camp.owner == 1:
			count[1] += 1
	if count[0] == 0:
		_end_game("Joueur 2")
	elif count[1] == 0:
		_end_game("Joueur 1")

func _end_game(w: String) -> void:
	game_over = true
	winner    = w
	message   = "VICTOIRE DE %s !" % w.to_upper()
	ui.disable_end_btn()
	ui.show_victory(w, turn)
	Sound.play("victory")

# ── Utilitaires ──────────────────────────────────────────────────────────────
func _camp_at(pos: Vector2) -> int:
	for i in range(camps.size()):
		if camps[i].pos.distance_to(pos) <= CAMP_R:
			return i
	return -1
