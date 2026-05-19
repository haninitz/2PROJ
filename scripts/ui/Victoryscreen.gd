class_name VictoryScreen
extends Node
# ─────────────────────────────────────────────────────────────────────────────
#  VictoryScreen.gd — SupKonQuest · Totally Spies Edition
#
#  Gère deux écrans de fin/transition :
#    - Écran de victoire (avec confettis et étoiles animés)
#    - Écran de changement de tour
#
#  Usage :
#    var vs = VictoryScreen.new()
#    vs.initialize(parent_node)
#    vs.show_victory("Clover", 42)
#    vs.show_turn_screen("Neon Squad", 3)
# ─────────────────────────────────────────────────────────────────────────────


# Référence autoload — initialisée dans _ready() / initialize()
var U : Node

signal turn_confirmed

# ── Écran victoire ────────────────────────────────────────────────────────────
var victory_screen   : Panel
var victory_title    : Label
var victory_winner   : Label
var victory_sparkles : Array = []

# ── Écran de tour ─────────────────────────────────────────────────────────────
var turn_screen       : Panel
var turn_name_label   : Label
var turn_num_label    : Label
var turn_prompt_label : Label

# ── Interne ───────────────────────────────────────────────────────────────────
var _confetti_pieces : Array = []
var _parent          : Node


func initialize(parent: Node, u: Node) -> void:
	U = u
	_parent = parent
	_build_victory_screen()
	_build_turn_screen()


# ─────────────────────────────────────────────────────────────────────────────
#  ANIMATION (appelée depuis UI._process)
# ─────────────────────────────────────────────────────────────────────────────

func animate(t: float) -> void:
	if victory_screen and victory_screen.visible:
		_animate_victory(t)


func _animate_victory(t: float) -> void:
	if victory_title:
		var p : float = 1.0 + sin(t * 2.5) * 0.045
		victory_title.scale = Vector2(p, p)

	for i in range(victory_sparkles.size()):
		var star : Label = victory_sparkles[i]
		if not is_instance_valid(star):
			continue
		var angle : float = t * 1.1 + float(i) * TAU / float(victory_sparkles.size())
		star.position = Vector2(
			U.WIN_W / 2.0 + cos(angle) * 320.0 - 14,
			340.0 + sin(angle) * 180.0 - 14)
		star.modulate.a = (sin(t * 3.5 + float(i)) + 1.0) * 0.55

	for c in _confetti_pieces:
		var lbl : Label = c["label"]
		if not is_instance_valid(lbl):
			continue
		var yf : float = fmod(t * c["speed"] * 0.018 + c["phase"], 1.15)
		lbl.position.x = c["xb"] + sin(t * c["drift"] * 0.5 + c["xb"] * 0.008) * 30.0
		lbl.position.y = yf * 780.0 - 30.0
		lbl.rotation   = t * 0.8 + c["phase"]
		lbl.modulate.a = clamp(0.85 - max(0.0, lbl.position.y - 680.0) / 80.0, 0.0, 1.0)


# ─────────────────────────────────────────────────────────────────────────────
#  CONSTRUCTION
# ─────────────────────────────────────────────────────────────────────────────

func _build_victory_screen() -> void:
	victory_screen = U.make_screen(false)
	var ov : StyleBoxFlat = StyleBoxFlat.new()
	ov.bg_color = Color(0, 0, 0, 0.80)
	victory_screen.add_theme_stylebox_override("panel", ov)
	_parent.add_child(victory_screen)

	# Panneau central
	var panel : Panel = Panel.new()
	panel.position = Vector2(U.WIN_W / 2 - 360, 120)
	panel.size     = Vector2(720, 440)
	panel.add_theme_stylebox_override("panel",
		U.flat(Color(0.08, 0.04, 0.18), U.C_PINK, 3, 16))
	victory_screen.add_child(panel)

	U.add_badge(victory_screen, "MISSION  COMPLETE",
		Vector2(U.WIN_W / 2 - 100, 130), Vector2(200, 26), U.C_PINK)

	# Titre (animé)
	victory_title = Label.new()
	victory_title.text     = "✦  VICTORY  ✦"
	victory_title.position = Vector2(U.WIN_W / 2 - 360, 168)
	victory_title.size     = Vector2(720, 90)
	victory_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_title.add_theme_font_size_override("font_size", 60)
	victory_title.modulate = U.C_PINK
	victory_screen.add_child(victory_title)

	# Nom du gagnant
	victory_winner = Label.new()
	victory_winner.position = Vector2(U.WIN_W / 2 - 360, 268)
	victory_winner.size     = Vector2(720, 55)
	victory_winner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_winner.add_theme_font_size_override("font_size", 36)
	victory_screen.add_child(victory_winner)

	victory_screen.add_child(U.lbl(
		"Agent has secured all territories",
		Vector2(U.WIN_W / 2 - 360, 328), 14, Color(0.75, 0.60, 0.90)))

	# Boutons
	var rb : Button = U.btn("↺  Play Again",
		Vector2(U.WIN_W / 2 - 240, 510), Vector2(200, 55), 20)
	rb.add_theme_stylebox_override("normal",
		U.flat(Color(0.28, 0.05, 0.18), U.C_PINK, 2, 10))
	rb.add_theme_color_override("font_color", U.C_WHITE)
	rb.pressed.connect(func(): _parent.get_tree().reload_current_scene())
	victory_screen.add_child(rb)

	# FIX : bouton Quit appelle bien quit() et non reload()
	var qb : Button = U.btn("✕  Quit",
		Vector2(U.WIN_W / 2 + 40, 510), Vector2(200, 55), 20)
	qb.add_theme_stylebox_override("normal",
		U.flat(Color(0.18, 0.05, 0.05), Color(0.70, 0.20, 0.20), 2, 10))
	qb.add_theme_color_override("font_color", U.C_WHITE)
	qb.pressed.connect(func(): _parent.get_tree().quit())
	victory_screen.add_child(qb)

	# Étoiles orbitales
	var shapes : Array[String] = ["✦","✧","◆","✶","⋆"]
	var colors : Array[Color] = [U.C_PINK, U.C_CYAN,
		U.C_GOLD, U.C_PURPLE]
	for i in range(12):
		var s : Label = Label.new()
		s.text = shapes[i % shapes.size()]
		s.add_theme_font_size_override("font_size", 18 + (i % 4) * 6)
		s.modulate   = colors[i % colors.size()]
		s.modulate.a = 0.0
		victory_screen.add_child(s)
		victory_sparkles.append(s)

	# Confettis
	_confetti_pieces.clear()
	var c_shapes : Array[String] = ["✦","○","+","×","◆"]
	var c_colors : Array[Color] = [U.C_PINK, U.C_CYAN,
		U.C_GOLD, U.C_PURPLE, U.C_WHITE]
	for i in range(40):
		var p : Label = Label.new()
		p.text = c_shapes[i % c_shapes.size()]
		p.add_theme_font_size_override("font_size", 8 + (i % 4) * 3)
		p.modulate  = c_colors[i % c_colors.size()]
		p.position  = Vector2(float((i * 30 + 10) % U.WIN_W), -30.0)
		victory_screen.add_child(p)
		_confetti_pieces.append({
			"label": p,
			"xb":    float((i * 30 + 10) % U.WIN_W),
			"speed": 50.0 + float(i % 7) * 22.0,
			"drift": sin(float(i) * 1.7) * 0.8,
			"phase": float(i) * 0.44
		})


func _build_turn_screen() -> void:
	turn_screen = U.make_screen(false)
	turn_screen.add_theme_stylebox_override("panel",
		U.flat(Color(0.02, 0.01, 0.06, 0.96), U.C_BG, 0, 0))
	_parent.add_child(turn_screen)

	turn_name_label = Label.new()
	turn_name_label.position = Vector2(0, 295)
	turn_name_label.size     = Vector2(U.WIN_W, 110)
	turn_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_name_label.add_theme_font_size_override("font_size", 64)
	turn_name_label.modulate = U.C_PINK
	turn_screen.add_child(turn_name_label)

	turn_num_label = Label.new()
	turn_num_label.position = Vector2(0, 410)
	turn_num_label.size     = Vector2(U.WIN_W, 40)
	turn_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_screen.add_child(turn_num_label)

	turn_prompt_label = Label.new()
	turn_prompt_label.text     = U.lt("turn_prompt")
	turn_prompt_label.position = Vector2(0, 560)
	turn_prompt_label.size     = Vector2(U.WIN_W, 30)
	turn_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_screen.add_child(turn_prompt_label)


# ─────────────────────────────────────────────────────────────────────────────
#  API PUBLIQUE
# ─────────────────────────────────────────────────────────────────────────────

func show_victory(winner_name: String, _turns: int) -> void:
	victory_winner.text     = winner_name
	victory_winner.modulate = U.C_PINK
	victory_screen.visible  = true


func show_turn_screen(squad_name: String, turn_number: int) -> void:
	turn_name_label.text = squad_name
	turn_num_label.text  = U.lt("turn_number") % turn_number
	turn_screen.visible  = true


func handle_input(event: InputEvent) -> void:
	if not turn_screen or not turn_screen.visible:
		return
	if (event is InputEventMouseButton or event is InputEventKey) and event.pressed:
		turn_screen.visible = false
		turn_confirmed.emit()
