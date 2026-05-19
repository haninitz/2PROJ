class_name MainMenu
extends Node
# ─────────────────────────────────────────────────────────────────────────────
#  MainMenu.gd — SupKonQuest · Totally Spies Edition
#
#  Gère tous les écrans de navigation avant la partie :
#    - Menu principal (avec animations)
#    - Écran setup (mode + noms joueurs)
#    - Sélection de map
#    - Overlays : Multiplayer, Map Editor, Leaderboard, Settings
#
#  Signaux émis vers UI.gd (qui les relaie à Main.gd) :
#    map_selected(index)
#    mode_selected(is_ai, difficulty)
#    squads_selected(squad1, squad2)
# ─────────────────────────────────────────────────────────────────────────────


# Référence autoload — initialisée dans _ready() / initialize()
var U : Node

signal map_selected(map_index: int)
signal mode_selected(is_ai: bool, difficulty: String)
signal squads_selected(squad1: String, squad2: String)

# ── Références ────────────────────────────────────────────────────────────────
var main_menu    : Panel
var setup_screen : Panel
var map_screen   : Panel

# Pour les écrans vides de compatibilité (Main.gd les référence)
var mode_screen       : Panel
var difficulty_screen : Panel
var squad_screen      : Panel

var title_label : Label
var _sparkles   : Array = []

var _is_ai_mode    : bool   = false
var _ai_difficulty : String = "medium"

# Nœud parent auquel on attache les écrans
var _parent : Node


func initialize(parent: Node, u: Node) -> void:
	U = u
	_parent = parent
	_build_main_menu()
	_build_setup_screen()
	_build_map_screen()
	_build_compat_screens()


# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION (appelée depuis UI._process)
# ─────────────────────────────────────────────────────────────────────────────

func animate(t: float) -> void:
	if main_menu and main_menu.visible:
		_animate_menu(t)


func _animate_menu(t: float) -> void:
	if title_label:
		title_label.modulate = Color(
			0.88 + sin(t * 1.4) * 0.12,
			0.20,
			0.65 + sin(t * 1.4 + 0.9) * 0.15)
	for i in range(_sparkles.size()):
		var s : Label = _sparkles[i]
		if not is_instance_valid(s):
			continue
		var ph : float = float(i) * 0.72
		s.position.y = s.get_meta("by") + sin(t * 0.9 + ph) * 12.0
		s.position.x = s.get_meta("bx") + cos(t * 0.6 + ph) * 6.0
		s.modulate.a = (sin(t * 1.8 + ph) + 1.0) * 0.45 + 0.1
		s.rotation   = t * 0.4 + ph


# ─────────────────────────────────────────────────────────────────────────────
#  MENU PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────

func _build_main_menu() -> void:
	main_menu = U.make_screen()
	_parent.add_child(main_menu)

	# Grille de fond
	main_menu.add_child(_GridNode.new())

	# Bandes diagonales décoratives
	var band_colors : Array[Color] = [U.C_PINK, U.C_CYAN,
		U.C_GOLD, U.C_PURPLE, U.C_PINK]
	for i in range(5):
		var s : ColorRect = ColorRect.new()
		s.color    = Color(band_colors[i].r, band_colors[i].g, band_colors[i].b, 0.04)
		s.size     = Vector2(300, 720)
		s.position = Vector2(i * 240 - 60, 0)
		s.rotation = deg_to_rad(8.0)
		main_menu.add_child(s)

	U.add_badge(main_menu, "⬡  W.O.O.H.P",
		Vector2(28, 22), Vector2(118, 36), U.C_GOLD)

	# Avatars agents
	var agents : Array = [
		{"n":"Sam",    "l":"S", "c": Color(0.80, 0.55, 0.10)},
		{"n":"Clover", "l":"C", "c": U.C_PINK},
		{"n":"Alex",   "l":"A", "c": Color(0.85, 0.40, 0.10)},
	]
	for i in range(3):
		var ag : Dictionary = agents[i]
		var ax : int = 90 + i * 120
		var ay : int = 268
		var av : Panel = Panel.new()
		av.position = Vector2(ax, ay)
		av.size     = Vector2(80, 90)
		av.add_theme_stylebox_override("panel",
			U.flat(Color(ag["c"].r*0.25, ag["c"].g*0.25, ag["c"].b*0.25), ag["c"], 2, 8))
		main_menu.add_child(av)

		# Lettre (grande)
		var ll : Label = Label.new()
		ll.text     = ag["l"]
		ll.position = Vector2(ax, ay + 10)
		ll.size     = Vector2(80, 55)
		ll.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ll.add_theme_font_size_override("font_size", 36)
		ll.add_theme_color_override("font_color", ag["c"])
		main_menu.add_child(ll)

		# Prénom
		var nl : Label = Label.new()
		nl.text     = ag["n"]
		nl.position = Vector2(ax, ay + 60)
		nl.size     = Vector2(80, 20)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.add_theme_font_size_override("font_size", 11)
		nl.add_theme_color_override("font_color", Color(0.90, 0.85, 0.95))
		main_menu.add_child(nl)

		# Rôle
		var rl : Label = Label.new()
		rl.text     = "Agent"
		rl.position = Vector2(ax, ay + 74)
		rl.size     = Vector2(80, 16)
		rl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rl.add_theme_font_size_override("font_size", 9)
		rl.add_theme_color_override("font_color", Color(0.55, 0.50, 0.65))
		main_menu.add_child(rl)

	# Titre animé
	title_label = Label.new()
	title_label.text     = "SupKonQuest"
	title_label.position = Vector2(440, 190)
	title_label.size     = Vector2(680, 80)
	title_label.add_theme_font_size_override("font_size", 58)
	title_label.modulate = U.C_PINK
	main_menu.add_child(title_label)

	var sub : Label = U.lbl("TOTALLY  SPIES", Vector2(448, 278), 14, U.C_PINK)
	main_menu.add_child(sub)
	var tag : Label = U.lbl("Stratégie · Conquête · Espionnage",
		Vector2(448, 300), 13, Color(0.70, 0.60, 0.85))
	main_menu.add_child(tag)

	# Diviseur
	var d1 : ColorRect = ColorRect.new()
	d1.color = U.C_PINK; d1.position = Vector2(440, 332); d1.size = Vector2(660, 2)
	main_menu.add_child(d1)
	var d2 : ColorRect = ColorRect.new()
	d2.color = Color(U.C_CYAN.r, U.C_CYAN.g, U.C_CYAN.b, 0.35)
	d2.position = Vector2(440, 335); d2.size = Vector2(660, 1)
	main_menu.add_child(d2)

	# Boutons principaux
	var items : Array = [
		{"t":"▶  Singleplayer", "bn":Color(0.28,0.05,0.18), "bb":U.C_PINK, "fn":func(): U.goto(main_menu, setup_screen)},
		{"t":"◈  Multiplayer", "bn":Color(0.05,0.18,0.28), "bb":U.C_CYAN, "fn":func(): _open_multiplayer()},
		{"t":"✎  Map Editor", "bn":Color(0.22,0.08,0.05), "bb":U.C_GOLD, "fn":func(): _open_map_editor()},
		{"t":"⬛  Leaderboard", "bn":Color(0.15,0.05,0.28), "bb":U.C_PURPLE, "fn":func(): _open_leaderboard()},
		{"t":"⚙  Settings", "bn":Color(0.10,0.08,0.20), "bb":Color(0.55,0.50,0.75), "fn":func(): _open_settings()},
		{"t":"✕  Quit", "bn":Color(0.18,0.05,0.05), "bb":Color(0.70,0.20,0.20), "fn":func(): _parent.get_tree().quit()},
	]
	for i in range(items.size()):
		var it : Dictionary = items[i]
		var b : Button = U.btn(it["t"], Vector2(448, 354 + i * 54), Vector2(316, 44), 17)
		b.add_theme_stylebox_override("normal", U.flat(it["bn"], it["bb"], 2, 8))
		b.add_theme_stylebox_override("hover",
			U.flat(Color(it["bn"].r*1.9, it["bn"].g*1.9, it["bn"].b*1.9), it["bb"], 2, 8))
		b.add_theme_color_override("font_color", U.C_WHITE)
		b.pressed.connect(it["fn"])
		main_menu.add_child(b)

	# Boutons langue
	var lang_codes  : Array[String] = ["fr", "en", "es"]
	var lang_labels : Array[String] = ["🇫🇷 FR", "🇬🇧 EN", "🇪🇸 ES"]
	var cur_lang : String = U.get_lang()
	for i in range(3):
		var lc : String = lang_codes[i]
		var lb : Button = U.btn(lang_labels[i],
			Vector2(U.WIN_W - 195 + i * 64, 18), Vector2(58, 32), 11)
		var active : bool = lc == cur_lang
		lb.add_theme_stylebox_override("normal",
			U.flat(
				Color(0.35,0.08,0.25) if active else Color(0.12,0.05,0.12),
				U.C_PINK    if active else Color(0.40,0.15,0.35), 2, 6))
		lb.pressed.connect(func(captured_lc: String = lc):
			var lang : Node = _parent.get_node_or_null("/root/Lang")
			if lang:
				lang.current = captured_lc
			_parent.get_tree().reload_current_scene())
		main_menu.add_child(lb)

	# Étoiles flottantes
	var shapes  : Array[String] = ["✦","✧","⋆","✶","◆","◇","✸"]
	var s_colors : Array[Color] = [U.C_PINK, U.C_CYAN, U.C_GOLD,
		U.C_PURPLE, U.C_PINK_LITE]
	for i in range(22):
		var star : Label = Label.new()
		star.text = shapes[i % shapes.size()]
		star.add_theme_font_size_override("font_size", 8 + (i % 5) * 4)
		star.modulate = s_colors[i % s_colors.size()]
		var bx : float = float((i * 57 + 30) % U.WIN_W)
		var by : float = float((i * 83 + 40) % 680)
		star.position = Vector2(bx, by)
		star.set_meta("bx", bx)
		star.set_meta("by", by)
		main_menu.add_child(star)
		_sparkles.append(star)

	# Footer
	var ft : Label = U.lbl(
		"W.O.O.H.P · World Organization of Human Protection · CLASSIFIED",
		Vector2(0, 698), 9, Color(0.40, 0.30, 0.55))
	ft.size = Vector2(U.WIN_W, 20)
	ft.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu.add_child(ft)


# ─────────────────────────────────────────────────────────────────────────────
#  ÉCRAN SETUP
# ─────────────────────────────────────────────────────────────────────────────

func _build_setup_screen() -> void:
	setup_screen = U.make_screen(false)
	_parent.add_child(setup_screen)
	U.add_header(setup_screen, "▶  NEW MISSION", U.C_PINK)

	setup_screen.add_child(U.lbl("Game Mode:", Vector2(55, 140), 13, U.C_PINK))

	var btn2p : Button = U.btn("👥  2 Players", Vector2(55, 165),  Vector2(200, 42), 15)
	var btn1p : Button = U.btn("🤖  vs AI",     Vector2(265, 165), Vector2(200, 42), 15)
	btn2p.add_theme_stylebox_override("normal",
		U.flat(Color(0.05, 0.18, 0.05), U.C_GREEN, 2, 8))
	btn1p.add_theme_stylebox_override("normal",
		U.flat(Color(0.08, 0.05, 0.22), U.C_CYAN, 2, 8))
	btn2p.add_theme_color_override("font_color", U.C_WHITE)
	btn1p.add_theme_color_override("font_color", U.C_WHITE)
	setup_screen.add_child(btn2p)
	setup_screen.add_child(btn1p)

	var mode_ind : Label = Label.new()
	mode_ind.name     = "ModeInd"
	mode_ind.text     = "Mode: 2 Players"
	mode_ind.position = Vector2(55, 215)
	mode_ind.add_theme_font_size_override("font_size", 11)
	mode_ind.add_theme_color_override("font_color", U.C_GREEN)
	setup_screen.add_child(mode_ind)

	# Panel difficulté IA
	var diff_panel : Panel = Panel.new()
	diff_panel.name     = "DiffPanel"
	diff_panel.position = Vector2(55, 232)
	diff_panel.size     = Vector2(440, 52)
	diff_panel.visible  = false
	diff_panel.add_theme_stylebox_override("panel",
		U.flat(Color(0.06, 0.04, 0.18), U.C_CYAN, 1, 8))
	setup_screen.add_child(diff_panel)
	diff_panel.add_child(U.lbl("Difficulty:", Vector2(8, 14), 12, U.C_CYAN))

	var diff_data : Array = [
		{"t":"Easy",   "col": U.C_GREEN, "k":"easy"},
		{"t":"Medium", "col": U.C_GOLD,  "k":"medium"},
		{"t":"Hard",   "col": U.C_PINK,  "k":"hard"},
	]
	for i in range(3):
		var dd : Dictionary = diff_data[i]
		var db : Button = U.btn(dd["t"], Vector2(95 + i * 112, 9), Vector2(104, 34), 13)
		db.add_theme_stylebox_override("normal",
			U.flat(
				Color(dd["col"].r*0.18, dd["col"].g*0.18, dd["col"].b*0.18),
				dd["col"], 2, 6))
		db.add_theme_color_override("font_color", U.C_WHITE)
		var dk : String = dd["k"]
		db.pressed.connect(func():
			_ai_difficulty    = dk
			mode_ind.text     = "Mode: AI (%s)" % dk.capitalize()
			mode_ind.modulate = U.C_CYAN)
		diff_panel.add_child(db)

	btn2p.pressed.connect(func():
		_is_ai_mode        = false
		diff_panel.visible = false
		mode_ind.text      = "Mode: 2 Players"
		mode_ind.modulate  = U.C_GREEN)
	btn1p.pressed.connect(func():
		_is_ai_mode        = true
		diff_panel.visible = true
		mode_ind.text      = "Mode: AI (%s)" % _ai_difficulty.capitalize()
		mode_ind.modulate  = U.C_CYAN)

	# Noms joueurs
	var names_y : int = 298
	setup_screen.add_child(
		U.lbl("Player Names:", Vector2(55, names_y), 13, U.C_PINK))
	_player_row(setup_screen, "Player 1", U.C_PINK,
		Vector2(55, names_y + 24), "P1Edit")
	var p2r : Panel = _player_row(setup_screen, "Player 2", U.C_CYAN,
		Vector2(55, names_y + 82), "P2Edit")
	p2r.name = "P2Row"

	var div : ColorRect = ColorRect.new()
	div.color    = Color(U.C_PINK.r, U.C_PINK.g, U.C_PINK.b, 0.20)
	div.position = Vector2(55, names_y + 142)
	div.size     = Vector2(U.WIN_W - 110, 1)
	setup_screen.add_child(div)

	# Bouton suivant
	var next_btn : Button = U.btn("Next : Choose Map  →",
		Vector2(U.WIN_W - 320, 638), Vector2(280, 50), 18)
	next_btn.add_theme_stylebox_override("normal",
		U.flat(Color(0.28, 0.05, 0.18), U.C_PINK, 2, 10))
	next_btn.add_theme_stylebox_override("hover",
		U.flat(Color(0.45, 0.08, 0.28), U.C_PINK_LITE, 2, 10))
	next_btn.add_theme_color_override("font_color", U.C_WHITE)
	next_btn.pressed.connect(func():
		var p1e : Node = setup_screen.find_child("P1Edit", true, false)
		var p2e : Node = setup_screen.find_child("P2Edit", true, false)
		var p1n : String = p1e.text.strip_edges() if p1e else "Player 1"
		var p2n : String = "AI" if _is_ai_mode \
			else (p2e.text.strip_edges() if p2e else "Player 2")
		if p1n.is_empty(): p1n = "Player 1"
		if p2n.is_empty(): p2n = "Player 2" if not _is_ai_mode else "AI"
		mode_selected.emit(_is_ai_mode, _ai_difficulty)
		squads_selected.emit(p1n, p2n)
		U.goto(setup_screen, map_screen))
	setup_screen.add_child(next_btn)
	setup_screen.add_child(U.back_btn(
		func(): U.goto(setup_screen, main_menu)))


func _player_row(parent: Control, pname: String, col: Color,
		pos: Vector2, edit_name: String) -> Panel:
	var row : Panel = Panel.new()
	row.position = pos
	row.size     = Vector2(520, 50)
	row.add_theme_stylebox_override("panel",
		U.flat(Color(col.r*0.10, col.g*0.10, col.b*0.10), col, 1, 8))
	parent.add_child(row)

	var bar : ColorRect = ColorRect.new()
	bar.color = col; bar.position = Vector2(0, 0); bar.size = Vector2(5, 50)
	row.add_child(bar)

	row.add_child(U.lbl(pname, Vector2(14, 12), 13, col))

	var edit : LineEdit = LineEdit.new()
	edit.name     = edit_name
	edit.text     = pname
	edit.position = Vector2(115, 9)
	edit.size     = Vector2(200, 32)
	row.add_child(edit)

	return row


# ─────────────────────────────────────────────────────────────────────────────
#  SÉLECTION MAP
# ─────────────────────────────────────────────────────────────────────────────

func _build_map_screen() -> void:
	map_screen = U.make_screen(false)
	_parent.add_child(map_screen)
	U.add_header(map_screen, "🗺  SELECT MAP", U.C_GOLD)

	var map_data : Array = [
		{"name":"Beverly Hills  (Clover)", "desc":"Urban · River · Bridge", "col": U.C_PINK},
		{"name":"Jungle Techno  (Sam)", "desc":"Dense Forest · High Income", "col": U.C_GREEN},
		{"name":"Île Tropicale  (Alex)", "desc":"Island · Ocean · Ports", "col": U.C_CYAN},
		{"name":"QG WOOHP  (Jerry)", "desc":"Headquarters · Symmetric", "col": U.C_GOLD},
	]

	for i in range(map_data.size()):
		var md : Dictionary = map_data[i]
		var card : Panel = Panel.new()
		card.position = Vector2(55, 140 + i * 112)
		card.size     = Vector2(U.WIN_W - 110, 98)
		card.add_theme_stylebox_override("panel",
			U.flat(
				Color(md["col"].r*0.10, md["col"].g*0.10, md["col"].b*0.10),
				md["col"], 1, 10))
		map_screen.add_child(card)

		card.add_child(U.lbl("0%d" % (i+1), Vector2(18, 22), 28,
			Color(md["col"].r, md["col"].g, md["col"].b, 0.35)))
		card.add_child(U.lbl(md["name"], Vector2(65, 16), 20, U.C_WHITE))
		card.add_child(U.lbl(md["desc"], Vector2(65, 44), 12,
			Color(md["col"].r, md["col"].g, md["col"].b, 0.80)))

		var play : Button = U.btn("▶  Play",
			Vector2(card.size.x - 110, 27), Vector2(96, 44), 15)
		play.add_theme_stylebox_override("normal",
			U.flat(
				Color(md["col"].r*0.22, md["col"].g*0.22, md["col"].b*0.22),
				md["col"], 2, 8))
		play.add_theme_stylebox_override("hover",
			U.flat(
				Color(md["col"].r*0.40, md["col"].g*0.40, md["col"].b*0.40),
				md["col"], 2, 8))
		play.add_theme_color_override("font_color", U.C_WHITE)
		play.pressed.connect(func(idx: int = i):
			map_screen.visible = false
			map_selected.emit(idx))
		card.add_child(play)

		card.add_child(U.lbl("✦", Vector2(card.size.x - 148, 36), 18,
			Color(md["col"].r, md["col"].g, md["col"].b, 0.25)))

	map_screen.add_child(U.back_btn(
		func(): U.goto(map_screen, setup_screen)))


func hide_map_screen() -> void:
	if map_screen:
		map_screen.visible = false


# ─────────────────────────────────────────────────────────────────────────────
#  OVERLAYS
# ─────────────────────────────────────────────────────────────────────────────

func _open_multiplayer() -> void:
	_open_overlay("◈  MULTIPLAYER", U.C_CYAN, func(scr: Panel):
		var cl : Button = U.btn("Connecting...", Vector2(U.WIN_W/2-120, 280),
			Vector2(240, 46), 16)
		cl.add_theme_stylebox_override("normal",
			U.flat(Color(0.05,0.12,0.20), U.C_CYAN, 2, 8))
		cl.add_theme_color_override("font_color", U.C_WHITE)
		scr.add_child(cl)
		var fm : Button = U.btn("🔍  Find Match", Vector2(U.WIN_W/2-120, 340),
			Vector2(240, 46), 16)
		fm.add_theme_stylebox_override("normal",
			U.flat(Color(0.05,0.20,0.28), U.C_CYAN, 2, 8))
		fm.add_theme_color_override("font_color", U.C_WHITE)
		scr.add_child(fm))


func _open_map_editor() -> void:
	_open_overlay("✎  MAP EDITOR", U.C_GOLD, func(scr: Panel):
		var canvas : Panel = Panel.new()
		canvas.position = Vector2(160, 110)
		canvas.size     = Vector2(U.WIN_W - 185, 550)
		canvas.add_theme_stylebox_override("panel",
			U.flat(Color(0.04,0.03,0.10), U.C_GOLD, 1, 4))
		scr.add_child(canvas)
		var tools : Array = [
			{"t":"↖  Select",       "c":U.C_CYAN},
			{"t":"⛺  Add Camp",     "c":U.C_PINK},
			{"t":"🌲  Add Obstacle", "c":U.C_GREEN},
			{"t":"🌊  Add Water",    "c":Color(0.20,0.55,0.90)},
			{"t":"✕  Erase",        "c":Color(0.80,0.25,0.25)},
		]
		for i in range(tools.size()):
			var tb : Button = U.btn(tools[i]["t"],
				Vector2(12, 110 + i * 54), Vector2(136, 44), 12)
			tb.add_theme_stylebox_override("normal",
				U.flat(
					Color(tools[i]["c"].r*0.15, tools[i]["c"].g*0.15, tools[i]["c"].b*0.15),
					tools[i]["c"], 2, 8))
			tb.add_theme_color_override("font_color", U.C_WHITE)
			scr.add_child(tb))


func _open_leaderboard() -> void:
	_open_overlay("⬛  LEADERBOARD", U.C_PURPLE, func(scr: Panel):
		var cols_x : Array[int] = [55, 100, 340, 510, 590, 670]
		var headers : Array[String] = ["#","Player Name","ELO Rating","Wins","Losses","Camps"]
		for i in range(headers.size()):
			scr.add_child(U.lbl(headers[i], Vector2(cols_x[i], 148),
				13, U.C_PURPLE))
		var div : ColorRect = ColorRect.new()
		div.color    = Color(U.C_PURPLE.r, U.C_PURPLE.g,
			U.C_PURPLE.b, 0.5)
		div.position = Vector2(55, 168); div.size = Vector2(U.WIN_W - 110, 1)
		scr.add_child(div)
		var rows : Array = [
			["1","Champion","1850","42","8","150"],
			["2","Strategist","1720","35","12","120"],
			["3","Conqueror","1680","30","10","110"],
			["4","Tactician","1550","25","15","95"],
			["5","Warrior","1420","20","18","80"],
		]
		for r in range(rows.size()):
			for c in range(rows[r].size()):
				scr.add_child(U.lbl(rows[r][c],
					Vector2(cols_x[c], 184 + r * 44), 14,
					U.C_GOLD if r == 0 else Color(0.88, 0.85, 0.92))))


func _open_settings() -> void:
	_open_overlay("⚙  SETTINGS", Color(0.55, 0.50, 0.75), func(scr: Panel):
		# Langue
		scr.add_child(U.lbl("Language:", Vector2(55, 130), 13, U.C_PINK))
		var lang_codes  : Array[String] = ["en", "fr", "es"]
		var lang_labels : Array[String] = ["English", "Francais", "Espanol"]
		for i in range(3):
			var lc : String = lang_codes[i]
			var lb : Button = U.btn(lang_labels[i],
				Vector2(55 + i * 148, 154), Vector2(134, 36), 13)
			lb.add_theme_stylebox_override("normal",
				U.flat(Color(0.12,0.05,0.18), U.C_PINK, 2, 8))
			lb.add_theme_color_override("font_color", U.C_WHITE)
			lb.pressed.connect(func(captured_lc: String = lc):
				var lang : Node = _parent.get_node_or_null("/root/Lang")
				if lang: lang.current = captured_lc
				_parent.get_tree().reload_current_scene())
			scr.add_child(lb)

		# Volume son
		scr.add_child(U.lbl("Sound Volume:", Vector2(55, 210), 13, U.C_CYAN))
		var sv : HSlider = HSlider.new()
		sv.position = Vector2(55, 232); sv.size = Vector2(350, 22)
		sv.min_value = 0; sv.max_value = 100; sv.value = 80
		sv.value_changed.connect(func(v: float):
			AudioServer.set_bus_volume_db(
				AudioServer.get_bus_index("Master"), linear_to_db(v / 100.0)))
		scr.add_child(sv)

		# Volume musique
		scr.add_child(U.lbl("Music Volume:", Vector2(55, 270), 13, U.C_CYAN))
		var mv : HSlider = HSlider.new()
		mv.position = Vector2(55, 292); mv.size = Vector2(350, 22)
		mv.min_value = 0; mv.max_value = 100; mv.value = 50
		mv.value_changed.connect(func(v: float):
			var bus_idx : int = AudioServer.get_bus_index("Music")
			if bus_idx >= 0:
				AudioServer.set_bus_volume_db(bus_idx, linear_to_db(v / 100.0)))
		scr.add_child(mv)

		# Affichage
		scr.add_child(U.lbl("Display:", Vector2(55, 340), 13, U.C_GOLD))
		var disp : Array[String] = ["Fullscreen", "Windowed", "Borderless"]
		for i in range(3):
			var db : Button = U.btn(disp[i], Vector2(55 + i * 150, 362), Vector2(136, 36), 13)
			db.add_theme_stylebox_override("normal",
				U.flat(Color(0.14,0.10,0.04), U.C_GOLD, 2, 8))
			db.add_theme_color_override("font_color", U.C_WHITE)
			if i == 0:
				db.pressed.connect(func():
					DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN))
			scr.add_child(db))


func _open_overlay(title: String, col: Color, builder: Callable) -> void:
	main_menu.visible = false
	var scr : Panel = U.make_screen(true)
	_parent.add_child(scr)
	U.add_header(scr, title, col)
	builder.call(scr)
	scr.add_child(U.back_btn(func():
		scr.queue_free()
		main_menu.visible = true))


# ─────────────────────────────────────────────────────────────────────────────
#  ÉCRANS COMPAT (vides, référencés par Main.gd)
# ─────────────────────────────────────────────────────────────────────────────

func _build_compat_screens() -> void:
	mode_screen       = U.make_screen(false); _parent.add_child(mode_screen)
	difficulty_screen = U.make_screen(false); _parent.add_child(difficulty_screen)
	squad_screen      = U.make_screen(false); _parent.add_child(squad_screen)


# ─────────────────────────────────────────────────────────────────────────────
#  CLASSE INTERNE — Grille de fond menu
# ─────────────────────────────────────────────────────────────────────────────
class _GridNode extends Node2D:
	func _draw() -> void:
		var col : Color = Color(1.00, 0.20, 0.58, 0.04)
		var x : int = 0
		while x <= 1152:
			draw_line(Vector2(x, 0), Vector2(x, 720), col, 1.0)
			x += 48
		var y : int = 0
		while y <= 720:
			draw_line(Vector2(0, y), Vector2(1152, y), col, 1.0)
			y += 48
		var dc : Color = Color(0.00, 0.90, 0.88, 0.025)
		var i : int = 0
		while i < 1900:
			draw_line(Vector2(i, 0), Vector2(0, i), dc, 1.0)
			i += 96
