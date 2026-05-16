extends CanvasLayer

signal end_turn_pressed
signal recruit_pressed(unit_type: String)
signal map_selected(map_index: int)
signal mode_selected(is_ai: bool, difficulty: String)

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
	_build_main_menu()

# ── Animation du menu principal ──────────────────────────────────────────────
func _process(_delta: float) -> void:
	var t = Time.get_ticks_msec() / 1000.0

	# ── Animation menu principal ──────────────────────────────────────────────
	if main_menu != null and main_menu.visible:
		var r = 0.90 + sin(t * 1.5) * 0.10
		var g = 0.78 + sin(t * 1.5 + 0.8) * 0.08
		title_label.modulate = Color(r, g, 0.18)
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
	end_btn.text = "Fin de tour"
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
	bg.bg_color = Color(0.06, 0.11, 0.06)
	map_screen.add_theme_stylebox_override("panel", bg)
	add_child(map_screen)

	var title = Label.new()
	title.text = "Choisissez une carte"
	title.position = Vector2(0, 160)
	title.size = Vector2(WIN_W, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.modulate = Color(0.90, 0.87, 0.70)
	map_screen.add_child(title)

	var sep = Label.new()
	sep.text = "────────────────────────────────────────"
	sep.position = Vector2(0, 224)
	sep.size = Vector2(WIN_W, 24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.modulate = Color(0.35, 0.55, 0.35)
	map_screen.add_child(sep)

	for i in range(MapDefs.MAPS.size()):
		var btn = Button.new()
		btn.text = MapDefs.MAPS[i]["name"]
		btn.position = Vector2(376, 280 + i * 72)
		btn.size = Vector2(400, 56)
		btn.add_theme_font_size_override("font_size", 20)
		var normal = _make_btn_style(Color(0.10, 0.24, 0.10), Color(0.40, 0.65, 0.40))
		var hover  = _make_btn_style(Color(0.16, 0.38, 0.16), Color(0.70, 0.90, 0.50))
		btn.add_theme_stylebox_override("normal",  normal)
		btn.add_theme_stylebox_override("hover",   hover)
		var idx = i
		btn.pressed.connect(func(): map_selected.emit(idx))
		map_screen.add_child(btn)

	var back_btn = Button.new()
	back_btn.text = "← Retour"
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
	bg.bg_color = Color(0.05, 0.09, 0.05)
	main_menu.add_theme_stylebox_override("panel", bg)
	add_child(main_menu)

	# bandes lumineuses verticales animées
	for i in range(6):
		var beam = ColorRect.new()
		beam.color = Color(0.20, 0.50, 0.20, 0.0)
		beam.size = Vector2(90, 720)
		beam.position = Vector2(i * 210.0, 0)
		main_menu.add_child(beam)
		menu_beams.append(beam)

	# bande centrale décorative (horizontale)
	var band = ColorRect.new()
	band.color = Color(0.10, 0.22, 0.10, 0.5)
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
	title_label.modulate = Color(1.00, 0.87, 0.20)
	main_menu.add_child(title_label)

	# sous-titre
	var sub = Label.new()
	sub.text = "Stratégie & Conquête  •  2 Joueurs"
	sub.position = Vector2(0, 308)
	sub.size = Vector2(WIN_W, 32)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.modulate = Color(0.65, 0.72, 0.65)
	main_menu.add_child(sub)

	# bouton JOUER
	var play_btn = Button.new()
	play_btn.text = "JOUER"
	play_btn.position = Vector2(WIN_W / 2 - 160, 390)
	play_btn.size = Vector2(320, 70)
	play_btn.add_theme_font_size_override("font_size", 28)
	play_btn.add_theme_color_override("font_color", Color(1.00, 0.95, 0.70))
	var pn = _make_btn_style(Color(0.12, 0.28, 0.12), Color(0.80, 0.70, 0.20))
	var ph = _make_btn_style(Color(0.20, 0.46, 0.18), Color(1.00, 0.87, 0.30))
	var pp = _make_btn_style(Color(0.08, 0.18, 0.08), Color(0.60, 0.50, 0.10))
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
	quit_btn.text = "Quitter"
	quit_btn.position = Vector2(WIN_W / 2 - 110, 478)
	quit_btn.size = Vector2(220, 46)
	quit_btn.add_theme_font_size_override("font_size", 17)
	var qn = _make_btn_style(Color(0.15, 0.15, 0.15), Color(0.35, 0.35, 0.35))
	var qh = _make_btn_style(Color(0.28, 0.10, 0.10), Color(0.65, 0.25, 0.25))
	quit_btn.add_theme_stylebox_override("normal", qn)
	quit_btn.add_theme_stylebox_override("hover",  qh)
	quit_btn.pressed.connect(func(): get_tree().quit())
	main_menu.add_child(quit_btn)

	# pied de page
	var footer = Label.new()
	footer.text = "Projet 2PROJ — SUPINFO Paris"
	footer.position = Vector2(0, 688)
	footer.size = Vector2(WIN_W, 24)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 13)
	footer.modulate = Color(0.35, 0.45, 0.35)
	main_menu.add_child(footer)

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
	ps.bg_color = Color(0.07, 0.12, 0.07)
	ps.border_color = Color(0.80, 0.70, 0.20)
	ps.set_border_width_all(3)
	ps.set_corner_radius_all(14)
	panel.add_theme_stylebox_override("panel", ps)
	victory_screen.add_child(panel)

	# titre "VICTOIRE !"
	victory_title = Label.new()
	victory_title.text = "VICTOIRE !"
	victory_title.position = Vector2(WIN_W / 2 - 340, 180)
	victory_title.size = Vector2(680, 90)
	victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title.add_theme_font_size_override("font_size", 58)
	victory_title.modulate = Color(1.00, 0.87, 0.20)
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
	sep.modulate = Color(0.40, 0.60, 0.40)
	victory_screen.add_child(sep)

	# ligne "a conquis la carte"
	var sub = Label.new()
	sub.text = "a remporté la conquête !"
	sub.position = Vector2(WIN_W / 2 - 340, 372)
	sub.size = Vector2(680, 30)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 18)
	sub.modulate = Color(0.75, 0.80, 0.75)
	victory_screen.add_child(sub)

	# tours joués (texte mis à jour dans show_victory)
	var turns_label = Label.new()
	turns_label.name = "TurnsLabel"
	turns_label.position = Vector2(WIN_W / 2 - 340, 408)
	turns_label.size = Vector2(680, 26)
	turns_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turns_label.add_theme_font_size_override("font_size", 16)
	turns_label.modulate = Color(0.55, 0.65, 0.55)
	victory_screen.add_child(turns_label)

	# bouton REJOUER
	var replay_btn = Button.new()
	replay_btn.text = "REJOUER"
	replay_btn.position = Vector2(WIN_W / 2 - 230, 462)
	replay_btn.size = Vector2(200, 58)
	replay_btn.add_theme_font_size_override("font_size", 22)
	replay_btn.add_theme_color_override("font_color", Color(1.00, 0.95, 0.70))
	var rn = _make_btn_style(Color(0.12, 0.28, 0.12), Color(0.80, 0.70, 0.20))
	var rh = _make_btn_style(Color(0.20, 0.46, 0.18), Color(1.00, 0.87, 0.30))
	replay_btn.add_theme_stylebox_override("normal", rn)
	replay_btn.add_theme_stylebox_override("hover",  rh)
	replay_btn.pressed.connect(func(): get_tree().reload_current_scene())
	victory_screen.add_child(replay_btn)

	# bouton QUITTER
	var quit_btn = Button.new()
	quit_btn.text = "Quitter"
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
		star.modulate = Color(1.00, 0.87, 0.20, 0.0)
		victory_screen.add_child(star)
		victory_sparkles.append(star)

func show_victory(winner: String, turns: int) -> void:
	var is_p1 = "1" in winner
	var col = Color(0.30, 0.60, 1.00) if is_p1 else Color(1.00, 0.30, 0.30)
	victory_winner.text = winner
	victory_winner.modulate = col
	var turns_lbl = victory_screen.get_node("TurnsLabel") as Label
	if turns_lbl:
		turns_lbl.text = "Partie terminée en %d tours" % turns
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
	bg.bg_color = Color(0.06, 0.11, 0.06)
	mode_screen.add_theme_stylebox_override("panel", bg)
	add_child(mode_screen)

	var title = Label.new()
	title.text = "Mode de jeu"
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
	sep.modulate = Color(0.35, 0.55, 0.35)
	mode_screen.add_child(sep)

	# Bouton 2 joueurs
	var btn2 = Button.new()
	btn2.text = "2 Joueurs"
	btn2.position = Vector2(WIN_W / 2 - 200, 290)
	btn2.size = Vector2(400, 70)
	btn2.add_theme_font_size_override("font_size", 24)
	var n2 = _make_btn_style(Color(0.10, 0.24, 0.10), Color(0.40, 0.65, 0.40))
	var h2 = _make_btn_style(Color(0.16, 0.38, 0.16), Color(0.70, 0.90, 0.50))
	btn2.add_theme_stylebox_override("normal", n2)
	btn2.add_theme_stylebox_override("hover",  h2)
	btn2.pressed.connect(func():
		mode_screen.visible = false
		map_screen.visible  = true
		mode_selected.emit(false, "")
	)
	mode_screen.add_child(btn2)

	var desc2 = Label.new()
	desc2.text = "Deux joueurs humains sur le même écran"
	desc2.position = Vector2(0, 370)
	desc2.size = Vector2(WIN_W, 24)
	desc2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc2.add_theme_font_size_override("font_size", 14)
	desc2.modulate = Color(0.55, 0.65, 0.55)
	mode_screen.add_child(desc2)

	# Bouton 1 joueur vs IA
	var btn1 = Button.new()
	btn1.text = "1 Joueur  (vs IA)"
	btn1.position = Vector2(WIN_W / 2 - 200, 420)
	btn1.size = Vector2(400, 70)
	btn1.add_theme_font_size_override("font_size", 24)
	var n1 = _make_btn_style(Color(0.20, 0.12, 0.05), Color(0.80, 0.55, 0.20))
	var h1 = _make_btn_style(Color(0.34, 0.20, 0.06), Color(1.00, 0.75, 0.30))
	btn1.add_theme_stylebox_override("normal", n1)
	btn1.add_theme_stylebox_override("hover",  h1)
	btn1.pressed.connect(func():
		mode_screen.visible       = false
		difficulty_screen.visible = true
	)
	mode_screen.add_child(btn1)

	var desc1 = Label.new()
	desc1.text = "Jouez contre une intelligence artificielle"
	desc1.position = Vector2(0, 500)
	desc1.size = Vector2(WIN_W, 24)
	desc1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc1.add_theme_font_size_override("font_size", 14)
	desc1.modulate = Color(0.55, 0.65, 0.55)
	mode_screen.add_child(desc1)

	var back_btn = Button.new()
	back_btn.text = "← Retour"
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
	bg.bg_color = Color(0.06, 0.08, 0.12)
	difficulty_screen.add_theme_stylebox_override("panel", bg)
	add_child(difficulty_screen)

	var title = Label.new()
	title.text = "Difficulté de l'IA"
	title.position = Vector2(0, 160)
	title.size = Vector2(WIN_W, 60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.modulate = Color(0.70, 0.87, 1.00)
	difficulty_screen.add_child(title)

	var sep = Label.new()
	sep.text = "────────────────────────────────────────"
	sep.position = Vector2(0, 230)
	sep.size = Vector2(WIN_W, 24)
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sep.modulate = Color(0.30, 0.45, 0.65)
	difficulty_screen.add_child(sep)

	var levels = [
		{"label": "Facile",   "key": "easy",   "desc": "L'IA attaque rarement et recrute peu",          "col_n": Color(0.08, 0.22, 0.08), "col_h": Color(0.14, 0.36, 0.14), "border_n": Color(0.35, 0.70, 0.35), "border_h": Color(0.55, 0.90, 0.55)},
		{"label": "Moyen",    "key": "medium", "desc": "L'IA gère ses troupes et sait attaquer",        "col_n": Color(0.18, 0.14, 0.04), "col_h": Color(0.30, 0.22, 0.06), "border_n": Color(0.80, 0.65, 0.20), "border_h": Color(1.00, 0.85, 0.30)},
		{"label": "Difficile","key": "hard",   "desc": "L'IA est agressive et optimise ses revenus",    "col_n": Color(0.22, 0.06, 0.06), "col_h": Color(0.36, 0.10, 0.10), "border_n": Color(0.80, 0.25, 0.25), "border_h": Color(1.00, 0.35, 0.35)},
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
			map_screen.visible        = true
			mode_selected.emit(true, key)
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
	back_btn.text = "← Retour"
	back_btn.position = Vector2(30, 660)
	back_btn.size = Vector2(160, 40)
	back_btn.add_theme_font_size_override("font_size", 16)
	back_btn.pressed.connect(func():
		difficulty_screen.visible = false
		mode_screen.visible       = true
	)
	difficulty_screen.add_child(back_btn)

# ── Méthodes appelées par Main.gd ────────────────────────────────────────────
func hide_map_screen() -> void:
	map_screen.visible = false

func update_hud(player_name: String, turn: int, gold: int, income: int, camps_owned: int, selected_unit: String, msg: String, p_index: int) -> void:
	var color = Color(0.22, 0.45, 0.90) if p_index == 0 else Color(0.88, 0.22, 0.22)
	info_label.text = "%s — Tour %d" % [player_name, turn]
	info_label.modulate = color
	gold_label.text = "Or : %d" % gold
	income_label.text = "+%d /tour" % income
	camps_label.text = "Camps : %d" % camps_owned
	msg_label.text = msg
	if selected_unit != "":
		unit_label.text = "Unité : %s" % selected_unit
		unit_label.visible = true
	else:
		unit_label.visible = false

func show_recruit(camp: Camp) -> void:
	var stats = UnitDefs.TYPES[camp.unit_type]
	var q_text = "vide"
	if camp.queue.size() > 0:
		var parts = []
		for t in camp.queue:
			parts.append(UnitDefs.TYPES[t]["label"])
		q_text = "  →  ".join(parts)
	camp_label.text = "%s  |  Type : %s  |  File : %s" % [camp.name, stats["label"], q_text]
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
