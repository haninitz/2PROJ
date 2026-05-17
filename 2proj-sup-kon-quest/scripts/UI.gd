extends CanvasLayer

signal end_turn_pressed
signal recruit_pressed(unit_type: String)
signal map_selected(map_index: int)
signal mode_selected(is_ai: bool, difficulty: String)
signal squads_selected(squad1: String, squad2: String)
signal turn_confirmed

const WIN_W  = 1152
const MAP_H  = 620
const BTN_W  = 134

# HUD normal
var msg_label:    Label
var info_label:   Label
var gold_label:   Label
var income_label: Label
var camps_label:  Label
var unit_label:   Label
var end_btn:      Button

# Barre de recrutement
var recruit_bar:  Control
var camp_label:   Label
var recruit_btns: Array = []

# Écrans
var map_screen:        Panel
var main_menu:         Panel
var mode_screen:       Panel
var difficulty_screen: Panel
var squad_screen:      Panel
var squad_title_label: Label
var _p1_squad:         String = ""
var _squad_prev_screen: Panel  = null
var turn_screen:       Panel
var turn_name_label:   Label
var turn_num_label:    Label
var turn_prompt_label: Label
var title_label:       Label
var menu_beams:        Array = []

# Écran victoire/défaite
var victory_screen:   Panel
var victory_title:    Label
var victory_winner:   Label
var victory_sparkles: Array = []

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_hud()
	_build_recruit_bar()
	_build_map_screen()
	_build_victory_screen()
	_build_mode_screen()
	_build_difficulty_screen()
	_build_squad_screen()
	_build_turn_screen()
	_build_main_menu()

# ── Animation du menu principal ──────────────────────────────────────────────
func _process(_delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0

	# ── Animation menu principal ──────────────────────────────────────────────
	if main_menu != null and main_menu.visible:
		var r = 0.90 + sin(t * 1.5) * 0.10
		var b = 0.70 + sin(t * 1.5 + 0.8) * 0.10
		title_label.modulate = Color(r, 0.25, b)
		for i in range(menu_beams.size()):
			var x = fmod(i * 210.0 + t * 38.0, float(WIN_W + 100)) - 100.0
			menu_beams[i].position.x = x
			menu_beams[i].color.a = (sin(t * 1.2 + i * 1.1) + 1.0) * 0.055

	# ── Animation écran victoire ──────────────────────────────────────────────
	if victory_screen != null and victory_screen.visible:
		# titre qui pulse
		var pulse = 1.0 + sin(t * 2.5) * 0.045
		victory_title.scale  = Vector2(pulse, pulse)
		victory_winner.scale = Vector2(pulse * 0.98, pulse * 0.98)
		# étoiles orbitales
		for i in range(victory_sparkles.size()):
			var angle = t * 1.1 + i * TAU / victory_sparkles.size()
			var cx = WIN_W / 2.0
			var cy = 330.0
			victory_sparkles[i].position = Vector2(
				cx + cos(angle) * 310.0 - 14,
				cy + sin(angle) * 175.0 - 14
			)
			victory_sparkles[i].modulate.a = (sin(t * 3.5 + i * 1.1) + 1.0) * 0.55

# ── HUD ──────────────────────────────────────────────────────────────────────
func _build_hud() -> void:
	info_label = Label.new()
	info_label.position = Vector2(10, MAP_H + 8)
	info_label.size = Vector2(190, 28)
	add_child(info_label)

	gold_label = Label.new()
	gold_label.position = Vector2(210, MAP_H + 8)
	gold_label.size = Vector2(100, 28)
	add_child(gold_label)

	income_label = Label.new()
	income_label.position = Vector2(320, MAP_H + 8)
	income_label.size = Vector2(110, 28)
	add_child(income_label)

	camps_label = Label.new()
	camps_label.position = Vector2(440, MAP_H + 8)
	camps_label.size = Vector2(160, 28)
	add_child(camps_label)

	msg_label = Label.new()
	msg_label.position = Vector2(10, MAP_H + 52)
	msg_label.size = Vector2(580, 28)
	add_child(msg_label)

	unit_label = Label.new()
	unit_label.position = Vector2(600, MAP_H + 52)
	unit_label.size = Vector2(340, 28)
	unit_label.visible = false
	add_child(unit_label)

	end_btn = Button.new()
	end_btn.text = Lang.t("end_turn")
	end_btn.position = Vector2(WIN_W - 185, MAP_H + 28)
	end_btn.size = Vector2(165, 44)
	end_btn.pressed.connect(func(): end_turn_pressed.emit())
	add_child(end_btn)

# ── Barre de recrutement ─────────────────────────────────────────────────────
func _build_recruit_bar() -> void:
	recruit_bar = Control.new()
	recruit_bar.position = Vector2(0, MAP_H)
	recruit_bar.size = Vector2(WIN_W - 190, 100)
	recruit_bar.visible = false
	add_child(recruit_bar)

	camp_label = Label.new()
	camp_label.position = Vector2(10, 6)
	camp_label.size = Vector2(WIN_W - 200, 30)
	recruit_bar.add_child(camp_label)

	var x = 5
	for unit_type in UnitDefs.TYPES.keys():
		var stats = UnitDefs.TYPES[unit_type]
		var btn = Button.new()
		btn.text = "%s\n%d or" % [stats["label"], stats["price"]]
		btn.position = Vector2(x, 38)
		btn.size = Vector2(BTN_W, 52)
		var t = unit_type
		btn.pressed.connect(func(): recruit_pressed.emit(t))
		recruit_bar.add_child(btn)
		recruit_btns.append(btn)
		x += BTN_W + 2

# ── Écran de sélection de carte ──────────────────────────────────────────────
func _build_map_screen() -> void:
	map_screen = Panel.new()
	map_screen.position = Vector2(0, 0)
	map_screen.size = Vector2(WIN_W, 720)
	map_screen.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.14)
	map_screen.add_theme_stylebox_override("panel", bg)
	add_child(map_screen)

	var title = Label.new()
	title.text = Lang.t("map_title")
	title.position = Vector2(0, 160)
	title.size = Vector2(WIN_W, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(1.00, 0.35, 0.75)
	map_screen.add_child(title)

	var sep = Label.new()
	sep.text = "────────────────────────────────────────"
	sep.position = Vector2(0, 224)
	sep.size = Vector2(WIN_W, 24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.modulate = Color(0.70, 0.25, 0.55)
	map_screen.add_child(sep)

	for i in range(MapDefs.MAPS.size()):
		var btn = Button.new()
		btn.text = MapDefs.MAPS[i]["name"]
		btn.position = Vector2(376, 280 + i * 72)
		btn.size = Vector2(400, 56)
		btn.add_theme_font_size_override("font_size", 20)
		var normal = _make_btn_style(Color(0.30, 0.06, 0.20), Color(0.85, 0.25, 0.60))
		var hover  = _make_btn_style(Color(0.50, 0.08, 0.32), Color(1.00, 0.45, 0.80))
		btn.add_theme_stylebox_override("normal",  normal)
		btn.add_theme_stylebox_override("hover",   hover)
		var idx = i
		btn.pressed.connect(func(): map_selected.emit(idx))
		map_screen.add_child(btn)

	var back_btn = Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(30, 660)
	back_btn.size = Vector2(160, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(func():
		map_screen.visible = false
		main_menu.visible  = true
	)
	map_screen.add_child(back_btn)

# ── Menu principal ────────────────────────────────────────────────────────────
func _build_main_menu() -> void:
	main_menu = Panel.new()
	main_menu.position = Vector2(0, 0)
	main_menu.size = Vector2(WIN_W, 720)
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.14)
	main_menu.add_theme_stylebox_override("panel", bg)
	add_child(main_menu)

	# bandes lumineuses verticales animées — rose fuchsia
	for i in range(6):
		var beam = ColorRect.new()
		beam.color = Color(0.85, 0.10, 0.55, 0.0)
		beam.size = Vector2(90, 720)
		beam.position = Vector2(i * 210.0, 0)
		main_menu.add_child(beam)
		menu_beams.append(beam)

	# bande centrale décorative (horizontale)
	var band = ColorRect.new()
	band.color = Color(0.70, 0.10, 0.45, 0.5)
	band.position = Vector2(0, 340)
	band.size = Vector2(WIN_W, 2)
	main_menu.add_child(band)

	# titre
	title_label = Label.new()
	title_label.text = "SupKontQuest"
	title_label.position = Vector2(0, 190)
	title_label.size = Vector2(WIN_W, 110)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.modulate = Color(1.00, 0.35, 0.75)
	main_menu.add_child(title_label)

	# sous-titre
	var sub = Label.new()
	sub.text = Lang.t("subtitle")
	sub.position = Vector2(0, 308)
	sub.size = Vector2(WIN_W, 32)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.modulate = Color(0.78, 0.65, 0.88)
	main_menu.add_child(sub)

	# bouton JOUER
	var play_btn = Button.new()
	play_btn.text = Lang.t("play")
	play_btn.position = Vector2(WIN_W / 2 - 160, 390)
	play_btn.size = Vector2(320, 70)
	play_btn.add_theme_font_size_override("font_size", 28)
	play_btn.add_theme_color_override("font_color", Color(1.00, 0.95, 0.70))
	var pn = _make_btn_style(Color(0.35, 0.06, 0.22), Color(1.00, 0.35, 0.75))
	var ph = _make_btn_style(Color(0.55, 0.08, 0.35), Color(1.00, 0.55, 0.88))
	var pp = _make_btn_style(Color(0.20, 0.04, 0.14), Color(0.70, 0.20, 0.55))
	play_btn.add_theme_stylebox_override("normal",  pn)
	play_btn.add_theme_stylebox_override("hover",   ph)
	play_btn.add_theme_stylebox_override("pressed", pp)
	play_btn.pressed.connect(func():
		main_menu.visible  = false
		mode_screen.visible = true
	)
	main_menu.add_child(play_btn)

	# bouton Quitter
	var quit_btn = Button.new()
	quit_btn.text = Lang.t("quit")
	quit_btn.position = Vector2(WIN_W / 2 - 110, 478)
	quit_btn.size = Vector2(220, 46)
	quit_btn.add_theme_font_size_override("font_size", 17)
	var qn = _make_btn_style(Color(0.15, 0.12, 0.20), Color(0.45, 0.38, 0.55))
	var qh = _make_btn_style(Color(0.28, 0.08, 0.18), Color(0.70, 0.25, 0.50))
	quit_btn.add_theme_stylebox_override("normal", qn)
	quit_btn.add_theme_stylebox_override("hover",  qh)
	quit_btn.pressed.connect(func(): get_tree().quit())
	main_menu.add_child(quit_btn)

	# pied de page
	var footer = Label.new()
	footer.text = Lang.t("footer")
	footer.position = Vector2(0, 688)
	footer.size = Vector2(WIN_W, 24)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.modulate = Color(0.55, 0.40, 0.65)
	main_menu.add_child(footer)

	# Boutons de langue FR / EN / ES
	var langs = ["fr", "en", "es"]
	var labels = ["FR", "EN", "ES"]
	for i in range(langs.size()):
		var lb = Button.new()
		lb.text = labels[i]
		lb.position = Vector2(WIN_W - 185 + i * 62, 18)
		lb.size = Vector2(52, 34)
		lb.add_theme_font_size_override("font_size", 14)
		var is_active = langs[i] == Lang.current
		var ln = _make_btn_style(
			Color(0.40, 0.08, 0.28) if is_active else Color(0.18, 0.06, 0.14),
			Color(1.00, 0.45, 0.80) if is_active else Color(0.55, 0.25, 0.45)
		)
		lb.add_theme_stylebox_override("normal", ln)
		lb.add_theme_stylebox_override("hover",  _make_btn_style(Color(0.55, 0.10, 0.36), Color(1.00, 0.55, 0.88)))
		var lang_code = langs[i]
		lb.pressed.connect(func():
			Lang.current = lang_code
			get_tree().reload_current_scene()
		)
		main_menu.add_child(lb)

# ── Écran victoire / défaite ─────────────────────────────────────────────────
func _build_victory_screen() -> void:
	victory_screen = Panel.new()
	victory_screen.position = Vector2(0, 0)
	victory_screen.size = Vector2(WIN_W, 720)
	victory_screen.visible = false
	var overlay_style = StyleBoxFlat.new()
	overlay_style.bg_color = Color(0, 0, 0, 0.78)
	victory_screen.add_theme_stylebox_override("panel", overlay_style)
	add_child(victory_screen)

	# panneau central
	var panel = Panel.new()
	panel.position = Vector2(WIN_W / 2 - 340, 150)
	panel.size = Vector2(680, 400)
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.05, 0.18)
	ps.border_color = Color(1.00, 0.35, 0.75)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", ps)
	victory_screen.add_child(panel)

	# titre "VICTOIRE !"
	victory_title = Label.new()
	victory_title.text = Lang.t("victory_title")
	victory_title.position = Vector2(WIN_W / 2 - 340, 180)
	victory_title.size = Vector2(680, 90)
	victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title.add_theme_font_size_override("font_size", 58)
	victory_title.modulate = Color(1.00, 0.35, 0.75)
	victory_screen.add_child(victory_title)

	# nom du vainqueur
	victory_winner = Label.new()
	victory_winner.text = ""
	victory_winner.position = Vector2(WIN_W / 2 - 340, 278)
	victory_winner.size = Vector2(680, 60)
	victory_winner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_winner.add_theme_font_size_override("font_size", 38)
	victory_screen.add_child(victory_winner)

	# séparateur
	var sep = Label.new()
	sep.text = "─────────────────────────────────────"
	sep.position = Vector2(WIN_W / 2 - 340, 344)
	sep.size = Vector2(680, 24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.modulate = Color(0.70, 0.25, 0.55)
	victory_screen.add_child(sep)

	# ligne "a conquis la carte"
	var sub = Label.new()
	sub.text = Lang.t("victory_sub")
	sub.position = Vector2(WIN_W / 2 - 340, 372)
	sub.size = Vector2(680, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.modulate = Color(0.80, 0.65, 0.90)
	victory_screen.add_child(sub)

	# tours joués (texte mis à jour dans show_victory)
	var turns_label = Label.new()
	turns_label.name = "TurnsLabel"
	turns_label.position = Vector2(WIN_W / 2 - 340, 408)
	turns_label.size = Vector2(680, 26)
	turns_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turns_label.add_theme_font_size_override("font_size", 16)
	turns_label.modulate = Color(0.65, 0.55, 0.80)
	victory_screen.add_child(turns_label)

	# bouton REJOUER
	var replay_btn = Button.new()
	replay_btn.text = Lang.t("replay")
	replay_btn.position = Vector2(WIN_W / 2 - 230, 462)
	replay_btn.size = Vector2(200, 58)
	replay_btn.add_theme_font_size_override("font_size", 22)
	replay_btn.add_theme_color_override("font_color", Color(1.00, 0.90, 0.95))
	var rn = _make_btn_style(Color(0.30, 0.06, 0.20), Color(1.00, 0.35, 0.75))
	var rh = _make_btn_style(Color(0.50, 0.08, 0.32), Color(1.00, 0.55, 0.88))
	replay_btn.add_theme_stylebox_override("normal", rn)
	replay_btn.add_theme_stylebox_override("hover",  rh)
	replay_btn.pressed.connect(func(): get_tree().reload_current_scene())
	victory_screen.add_child(replay_btn)

	# bouton QUITTER
	var quit_btn = Button.new()
	quit_btn.text = Lang.t("quit")
	quit_btn.position = Vector2(WIN_W / 2 + 30, 462)
	quit_btn.size = Vector2(200, 58)
	quit_btn.add_theme_font_size_override("font_size", 22)
	var qn = _make_btn_style(Color(0.20, 0.08, 0.08), Color(0.50, 0.20, 0.20))
	var qh = _make_btn_style(Color(0.40, 0.10, 0.10), Color(0.75, 0.25, 0.25))
	quit_btn.add_theme_stylebox_override("normal", qn)
	quit_btn.add_theme_stylebox_override("hover",  qh)
	quit_btn.pressed.connect(func(): get_tree().quit())
	victory_screen.add_child(quit_btn)

	# étoiles orbitales
	for i in range(10):
		var star = Label.new()
		star.text = "*"
		star.add_theme_font_size_override("font_size", 22)
		star.modulate = Color(1.00, 0.35, 0.80, 0.0)
		victory_screen.add_child(star)
		victory_sparkles.append(star)

func show_victory(winner: String, turns: int, winner_idx: int = 0) -> void:
	var col = Color(0.10, 0.78, 0.38) if winner_idx == 0 else Color(0.92, 0.12, 0.45)
	victory_winner.text = winner
	victory_winner.modulate = col
	var turns_lbl = victory_screen.get_node("TurnsLabel") as Label
	if turns_lbl:
		turns_lbl.text = Lang.t("victory_turns") % turns
	victory_screen.visible = true

# ── Utilitaire style bouton ───────────────────────────────────────────────────
func _make_btn_style(bg: Color, border: Color) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(8)
	return s

# ── Écran sélection du mode (1 joueur / 2 joueurs) ───────────────────────────
func _build_mode_screen() -> void:
	mode_screen = Panel.new()
	mode_screen.position = Vector2(0, 0)
	mode_screen.size = Vector2(WIN_W, 720)
	mode_screen.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.14)
	mode_screen.add_theme_stylebox_override("panel", bg)
	add_child(mode_screen)

	var title = Label.new()
	title.text = Lang.t("mode_title")
	title.position = Vector2(0, 160)
	title.size = Vector2(WIN_W, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(0.90, 0.87, 0.70)
	mode_screen.add_child(title)

	var sep = Label.new()
	sep.text = "────────────────────────────────────────"
	sep.position = Vector2(0, 230)
	sep.size = Vector2(WIN_W, 24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.modulate = Color(0.70, 0.25, 0.55)
	mode_screen.add_child(sep)

	# Bouton 2 joueurs
	var btn2 = Button.new()
	btn2.text = Lang.t("mode_2p")
	btn2.position = Vector2(WIN_W / 2 - 200, 290)
	btn2.size = Vector2(400, 70)
	btn2.add_theme_font_size_override("font_size", 24)
	var n2 = _make_btn_style(Color(0.30, 0.06, 0.20), Color(0.85, 0.25, 0.60))
	var h2 = _make_btn_style(Color(0.50, 0.08, 0.32), Color(1.00, 0.45, 0.80))
	btn2.add_theme_stylebox_override("normal", n2)
	btn2.add_theme_stylebox_override("hover",  h2)
	btn2.pressed.connect(func():
		mode_screen.visible = false
		mode_selected.emit(false, "")
		_show_squad_screen(mode_screen)
	)
	mode_screen.add_child(btn2)

	var desc2 = Label.new()
	desc2.text = Lang.t("mode_2p_desc")
	desc2.position = Vector2(0, 370)
	desc2.size = Vector2(WIN_W, 24)
	desc2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc2.add_theme_font_size_override("font_size", 14)
	desc2.modulate = Color(0.75, 0.60, 0.85)
	mode_screen.add_child(desc2)

	# Bouton 1 joueur vs IA
	var btn1 = Button.new()
	btn1.text = Lang.t("mode_1p")
	btn1.position = Vector2(WIN_W / 2 - 200, 420)
	btn1.size = Vector2(400, 70)
	btn1.add_theme_font_size_override("font_size", 24)
	var n1 = _make_btn_style(Color(0.08, 0.22, 0.30), Color(0.25, 0.65, 0.90))
	var h1 = _make_btn_style(Color(0.12, 0.35, 0.48), Color(0.40, 0.85, 1.00))
	btn1.add_theme_stylebox_override("normal", n1)
	btn1.add_theme_stylebox_override("hover",  h1)
	btn1.pressed.connect(func():
		mode_screen.visible       = false
		difficulty_screen.visible = true
	)
	mode_screen.add_child(btn1)

	var desc1 = Label.new()
	desc1.text = Lang.t("mode_1p_desc")
	desc1.position = Vector2(0, 500)
	desc1.size = Vector2(WIN_W, 24)
	desc1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc1.add_theme_font_size_override("font_size", 14)
	desc1.modulate = Color(0.60, 0.80, 0.95)
	mode_screen.add_child(desc1)

	var back_btn = Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(30, 660)
	back_btn.size = Vector2(160, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(func():
		mode_screen.visible = false
		main_menu.visible   = true
	)
	mode_screen.add_child(back_btn)

# ── Écran sélection de la difficulté IA ──────────────────────────────────────
func _build_difficulty_screen() -> void:
	difficulty_screen = Panel.new()
	difficulty_screen.position = Vector2(0, 0)
	difficulty_screen.size = Vector2(WIN_W, 720)
	difficulty_screen.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.14)
	difficulty_screen.add_theme_stylebox_override("panel", bg)
	add_child(difficulty_screen)

	var title = Label.new()
	title.text = Lang.t("diff_title")
	title.position = Vector2(0, 160)
	title.size = Vector2(WIN_W, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(1.00, 0.35, 0.75)
	difficulty_screen.add_child(title)

	var sep = Label.new()
	sep.text = "────────────────────────────────────────"
	sep.position = Vector2(0, 230)
	sep.size = Vector2(WIN_W, 24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.modulate = Color(0.70, 0.25, 0.55)
	difficulty_screen.add_child(sep)

	var levels = [
		{"label": Lang.t("diff_easy"), "key": "easy",   "desc": Lang.t("diff_easy_desc"), "col_n": Color(0.06, 0.28, 0.16), "col_h": Color(0.10, 0.45, 0.25), "border_n": Color(0.10, 0.78, 0.38), "border_h": Color(0.30, 1.00, 0.55)},
		{"label": Lang.t("diff_med"),  "key": "medium", "desc": Lang.t("diff_med_desc"),  "col_n": Color(0.30, 0.06, 0.20), "col_h": Color(0.50, 0.08, 0.32), "border_n": Color(1.00, 0.35, 0.75), "border_h": Color(1.00, 0.55, 0.88)},
		{"label": Lang.t("diff_hard"), "key": "hard",   "desc": Lang.t("diff_hard_desc"), "col_n": Color(0.22, 0.06, 0.06), "col_h": Color(0.36, 0.10, 0.10), "border_n": Color(0.90, 0.20, 0.20), "border_h": Color(1.00, 0.35, 0.35)},
	]

	for i in range(levels.size()):
		var lvl = levels[i]
		var btn = Button.new()
		btn.text = lvl["label"]
		btn.position = Vector2(WIN_W / 2 - 200, 280 + i * 110)
		btn.size = Vector2(400, 70)
		btn.add_theme_font_size_override("font_size", 26)
		var bn = _make_btn_style(lvl["col_n"], lvl["border_n"])
		var bh = _make_btn_style(lvl["col_h"], lvl["border_h"])
		btn.add_theme_stylebox_override("normal", bn)
		btn.add_theme_stylebox_override("hover",  bh)
		var key = lvl["key"]
		btn.pressed.connect(func():
			difficulty_screen.visible = false
			mode_selected.emit(true, key)
			_show_squad_screen(difficulty_screen)
		)
		difficulty_screen.add_child(btn)

		var desc = Label.new()
		desc.text = lvl["desc"]
		desc.position = Vector2(0, 358 + i * 110)
		desc.size = Vector2(WIN_W, 22)
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 13)
		desc.modulate = Color(0.55, 0.65, 0.75)
		difficulty_screen.add_child(desc)

	var back_btn = Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(30, 660)
	back_btn.size = Vector2(160, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(func():
		difficulty_screen.visible = false
		mode_screen.visible       = true
	)
	difficulty_screen.add_child(back_btn)

# ── Écran sélection des squads ───────────────────────────────────────────────
const SQUADS = [
	"Neon Squad", "Shadow Squad", "Crimson Squad", "Cyber Squad",
	"Phantom Squad", "Eclipse Squad", "Nova Squad", "Storm Squad"
]

func _show_squad_screen(prev_screen: Panel = null) -> void:
	_p1_squad = ""
	_squad_prev_screen = prev_screen
	squad_title_label.text = Lang.t("squad_p1")
	for child in squad_screen.get_children():
		if child is Button:
			child.disabled = false
			child.modulate = Color(1, 1, 1, 1)
	squad_screen.visible = true

func _build_squad_screen() -> void:
	squad_screen = Panel.new()
	squad_screen.position = Vector2(0, 0)
	squad_screen.size = Vector2(WIN_W, 720)
	squad_screen.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.14)
	squad_screen.add_theme_stylebox_override("panel", bg)
	add_child(squad_screen)

	squad_title_label = Label.new()
	squad_title_label.position = Vector2(0, 130)
	squad_title_label.size = Vector2(WIN_W, 60)
	squad_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	squad_title_label.add_theme_font_size_override("font_size", 30)
	squad_title_label.modulate = Color(1.00, 0.35, 0.75)
	squad_screen.add_child(squad_title_label)

	var sep = Label.new()
	sep.text = "────────────────────────────────────────"
	sep.position = Vector2(0, 198)
	sep.size = Vector2(WIN_W, 24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.modulate = Color(0.70, 0.25, 0.55)
	squad_screen.add_child(sep)

	var back_btn = Button.new()
	back_btn.text = Lang.t("back")
	back_btn.position = Vector2(30, 660)
	back_btn.size = Vector2(160, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(func():
		squad_screen.visible = false
		if _squad_prev_screen != null:
			_squad_prev_screen.visible = true
		else:
			main_menu.visible = true
	)
	squad_screen.add_child(back_btn)

	# 8 boutons en grille 2×4
	for i in range(SQUADS.size()):
		var col = i / 4
		var row = i % 4
		var btn = Button.new()
		btn.text = SQUADS[i]
		btn.position = Vector2(176 + col * 424, 240 + row * 100)
		btn.size = Vector2(376, 72)
		btn.add_theme_font_size_override("font_size", 22)
		var bn = _make_btn_style(Color(0.30, 0.06, 0.20), Color(0.85, 0.25, 0.60))
		var bh = _make_btn_style(Color(0.50, 0.08, 0.32), Color(1.00, 0.45, 0.80))
		btn.add_theme_stylebox_override("normal", bn)
		btn.add_theme_stylebox_override("hover",  bh)
		var squad_name = SQUADS[i]
		btn.pressed.connect(func(): _on_squad_picked(squad_name))
		squad_screen.add_child(btn)

func _on_squad_picked(squad_name: String) -> void:
	if _p1_squad == "":
		# Joueur 1 vient de choisir
		_p1_squad = squad_name
		squad_title_label.text = Lang.t("squad_p2")
		# Désactiver le squad déjà pris
		for child in squad_screen.get_children():
			if child is Button and child.text == squad_name:
				child.disabled = true
				child.modulate = Color(0.5, 0.5, 0.5, 0.6)
	else:
		# Joueur 2 vient de choisir
		squad_screen.visible = false
		map_screen.visible   = true
		squads_selected.emit(_p1_squad, squad_name)

# ── Écran changement de tour ─────────────────────────────────────────────────
func _build_turn_screen() -> void:
	turn_screen = Panel.new()
	turn_screen.position = Vector2(0, 0)
	turn_screen.size = Vector2(WIN_W, 720)
	turn_screen.visible = false
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.02, 0.08, 0.96)
	turn_screen.add_theme_stylebox_override("panel", bg)
	add_child(turn_screen)

	# Ligne décorative haute
	var line_top = ColorRect.new()
	line_top.color = Color(0.70, 0.20, 0.50, 0.6)
	line_top.position = Vector2(100, 220)
	line_top.size = Vector2(WIN_W - 200, 2)
	turn_screen.add_child(line_top)

	# "C'est votre tour !"
	var title = Label.new()
	title.text = Lang.t("turn_title")
	title.position = Vector2(0, 240)
	title.size = Vector2(WIN_W, 50)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.modulate = Color(0.78, 0.65, 0.88)
	turn_screen.add_child(title)

	# Nom du squad (grand)
	turn_name_label = Label.new()
	turn_name_label.position = Vector2(0, 295)
	turn_name_label.size = Vector2(WIN_W, 110)
	turn_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_name_label.add_theme_font_size_override("font_size", 64)
	turn_name_label.modulate = Color(1.00, 0.35, 0.75)
	turn_screen.add_child(turn_name_label)

	# Numéro de tour
	turn_num_label = Label.new()
	turn_num_label.position = Vector2(0, 410)
	turn_num_label.size = Vector2(WIN_W, 40)
	turn_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_num_label.add_theme_font_size_override("font_size", 22)
	turn_num_label.modulate = Color(0.65, 0.55, 0.80)
	turn_screen.add_child(turn_num_label)

	# Ligne décorative basse
	var line_bot = ColorRect.new()
	line_bot.color = Color(0.70, 0.20, 0.50, 0.6)
	line_bot.position = Vector2(100, 460)
	line_bot.size = Vector2(WIN_W - 200, 2)
	turn_screen.add_child(line_bot)

	# "Cliquez n'importe où pour commencer"
	turn_prompt_label = Label.new()
	turn_prompt_label.text = Lang.t("turn_prompt")
	turn_prompt_label.position = Vector2(0, 560)
	turn_prompt_label.size = Vector2(WIN_W, 30)
	turn_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_prompt_label.add_theme_font_size_override("font_size", 18)
	turn_prompt_label.modulate = Color(0.60, 0.50, 0.70)
	turn_screen.add_child(turn_prompt_label)

func _input(event: InputEvent) -> void:
	if turn_screen == null or not turn_screen.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		turn_screen.visible = false
		turn_confirmed.emit()
	elif event is InputEventKey and event.pressed:
		turn_screen.visible = false
		turn_confirmed.emit()

func show_turn_screen(squad_name: String, turn_number: int) -> void:
	turn_name_label.text = squad_name
	turn_num_label.text  = Lang.t("turn_number") % turn_number
	turn_screen.visible  = true

# ── Méthodes appelées par Main.gd ────────────────────────────────────────────
func hide_map_screen() -> void:
	map_screen.visible = false

func update_hud(player_name: String, turn: int, gold: int, income: int, camps_owned: int, selected_unit: String, msg: String, p_index: int) -> void:
	var color = Color(0.10, 0.78, 0.38) if p_index == 0 else Color(0.92, 0.12, 0.45)
	info_label.text = Lang.t("player_turn") % [player_name, turn]
	info_label.modulate = color
	gold_label.text = Lang.t("gold") % gold
	income_label.text = Lang.t("income") % income
	camps_label.text = Lang.t("camps") % camps_owned
	msg_label.text = msg
	if selected_unit != "":
		unit_label.text = Lang.t("unit_label") % selected_unit
		unit_label.visible = true
	else:
		unit_label.visible = false

func show_recruit(camp: Camp) -> void:
	var stats = UnitDefs.TYPES[camp.unit_type]
	var q_text = Lang.t("queue_empty")
	if camp.queue.size() > 0:
		var parts = []
		for t in camp.queue:
			parts.append(UnitDefs.TYPES[t]["label"])
		q_text = "  →  ".join(parts)
	camp_label.text = "%s  |  %s : %s  |  %s : %s" % [camp.name, Lang.t("queue_type"), stats["label"], Lang.t("queue_label"), q_text]
	msg_label.visible    = false
	info_label.visible   = false
	gold_label.visible   = false
	income_label.visible = false
	camps_label.visible  = false
	unit_label.visible   = false
	recruit_bar.visible  = true

func hide_recruit() -> void:
	recruit_bar.visible  = false
	msg_label.visible    = true
	info_label.visible   = true
	gold_label.visible   = true
	income_label.visible = true
	camps_label.visible  = true

func disable_end_btn() -> void:
	end_btn.disabled = true
