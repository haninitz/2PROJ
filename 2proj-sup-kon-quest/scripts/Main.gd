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
var regions:       Array = []
var map_chosen:    bool   = false
var ai_mode:       bool   = false
var ai_difficulty: String = ""
var squad1_name:   String = ""
var squad2_name:   String = ""

@onready var ui = $UI

var font:      Font
var _renderer: Renderer

func _ready() -> void:
	font      = ThemeDB.fallback_font
	_renderer = Renderer.new()
	ui.end_turn_pressed.connect(_on_end_turn)
	ui.recruit_pressed.connect(_on_recruit)
	ui.map_selected.connect(_on_map_selected)
	ui.mode_selected.connect(_on_mode_selected)
	ui.squads_selected.connect(_on_squads_selected)
	ui.turn_confirmed.connect(_on_turn_confirmed)

func _on_mode_selected(is_ai: bool, difficulty: String) -> void:
	ai_mode       = is_ai
	ai_difficulty = difficulty

func _on_squads_selected(squad1: String, squad2: String) -> void:
	squad1_name = squad1
	squad2_name = squad2

func _on_map_selected(map_index: int) -> void:
	ui.hide_map_screen()
	map_chosen = true
	_init_data(map_index)
	GameManager.init(players, camps, regions)
	_collect_income(0)
	message = Lang.t("msg_select") % players[0].name

func _init_data(map_index: int) -> void:
	var n1 = squad1_name if squad1_name != "" else Lang.t("player1")
	var n2 = squad2_name if squad2_name != "" else Lang.t("player2")
	players = [Player.new(n1), Player.new(n2)]

	var map = MapDefs.MAPS[map_index]
	forests    = map["forests"]
	river_x    = map["river_x"]
	bridge_y   = map["bridge_y"]
	bridge_h   = map["bridge_h"]
	has_water  = map["has_water"]
	land_zones = map["land_zones"]
	regions    = map["regions"]

	camps = []
	for data in map["camps"]:
		camps.append(Camp.new(data))

# ── Boucle principale ────────────────────────────────────────────────────────
func _process(_delta: float) -> void:
	if map_chosen:
		var p: Player = players[current_player]
		var income = GameManager.calculate_income(current_player)
		var camps_owned = 0
		for camp in camps:
			if camp.owner == current_player:
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
		has_water, land_zones, regions, game_over, winner)

# ── Entrées ──────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not map_chosen or game_over:
		return
	if ui.turn_screen != null and ui.turn_screen.visible:
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
		message = Lang.t("msg_select") % players[current_player].name
		return

	if selected_idx == -1:
		if camps[clicked].owner == current_player:
			selected_idx = clicked
			ui.show_recruit(camps[clicked])
			message = Lang.t("msg_selected") % camps[clicked].name
			Sound.play("select")
		else:
			message = Lang.t("msg_not_yours")
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
		message = Lang.t("msg_need_move")
		return
	var n = camps[src].units - 1
	camps[tgt].units += n
	camps[src].units = 1
	message = Lang.t("msg_move") % [n, camps[tgt].name]
	Sound.play("move")

func _attack(src: int, tgt: int) -> void:
	if camps[src].units <= 1:
		message = Lang.t("msg_need_atk")
		return
	Combat.resolve(camps[src], camps[tgt])
	GameManager.capture_camp(tgt, camps[tgt].owner)
	message = Lang.t("msg_attack") % camps[tgt].name
	Sound.play("attack")

func _produce_unit() -> void:
	if selected_idx == -1:
		message = Lang.t("msg_no_camp")
		return
	if camps[selected_idx].owner != current_player:
		return
	var p: Player = players[current_player]
	if p.gold < 10:
		message = Lang.t("msg_no_gold")
		return
	p.gold -= 10
	camps[selected_idx].units += 1
	message = Lang.t("msg_produced") % camps[selected_idx].name

func _on_recruit(unit_type: String) -> void:
	if selected_idx == -1:
		return
	var camp: Camp = camps[selected_idx]
	if camp.owner != current_player:
		return
	if camp.queue.size() >= 3:
		message = Lang.t("msg_queue_full")
		return
	var price = UnitDefs.TYPES[unit_type]["price"]
	var p: Player = players[current_player]
	if p.gold < price:
		message = Lang.t("msg_no_gold_p") % price
		return
	p.gold -= price
	camp.queue.append(unit_type)
	ui.show_recruit(camp)
	message = Lang.t("msg_recruited") % [UnitDefs.TYPES[unit_type]["label"], camp.name]
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
	message = Lang.t("msg_select") % players[current_player].name
	_check_victory()
	if not game_over:
		ui.show_turn_screen(players[current_player].name, turn)

func _process_queues(p: int) -> void:
	for camp in camps:
		if camp.owner == p and camp.queue.size() > 0:
			camp.unit_type = camp.queue[0]
			camp.queue.remove_at(0)
			camp.units += 1

func _collect_income(p: int) -> void:
	GameManager.give_income(p)

func _on_turn_confirmed() -> void:
	pass

# ── Victoire ─────────────────────────────────────────────────────────────────
func _check_victory() -> void:
	var w = GameManager.check_end_game()
	if w != "":
		_end_game(w)

func _end_game(w: String) -> void:
	game_over = true
	winner    = w
	message   = Lang.t("msg_victory") % w.to_upper()
	ui.disable_end_btn()
	var winner_idx = 0 if w == players[0].name else 1
	ui.show_victory(w, turn, winner_idx)
	Sound.play("victory")

# ── Utilitaires ──────────────────────────────────────────────────────────────
func _camp_at(pos: Vector2) -> int:
	for i in range(camps.size()):
		if camps[i].pos.distance_to(pos) <= CAMP_R:
			return i
	return -1
