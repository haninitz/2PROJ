extends CanvasLayer

signal end_turn_pressed
signal recruit_pressed(unit_type: String)
signal map_selected(map_index: int)

const WIN_W  = 1152
const MAP_H  = 620
const BTN_W  = 134   # largeur d'un bouton de recrutement

# HUD normal (affiché quand aucun camp n'est sélectionné)
var msg_label:   Label
var info_label:  Label
var gold_label:  Label
var end_btn:     Button

# Barre de recrutement (remplace le HUD quand un camp est sélectionné)
var recruit_bar:    Control
var camp_label:     Label   # nom du camp + file
var recruit_btns:   Array = []

# Écran de sélection de carte
var map_screen: Panel

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_hud()
	_build_recruit_bar()
	_build_map_screen()

# ── HUD normal ───────────────────────────────────────────────────────────────
func _build_hud() -> void:
	msg_label = Label.new()
	msg_label.position = Vector2(10, MAP_H + 6)
	msg_label.size = Vector2(WIN_W - 200, 36)
	add_child(msg_label)

	info_label = Label.new()
	info_label.position = Vector2(10, MAP_H + 50)
	info_label.size = Vector2(560, 32)
	add_child(info_label)

	gold_label = Label.new()
	gold_label.position = Vector2(580, MAP_H + 50)
	gold_label.size = Vector2(260, 32)
	add_child(gold_label)

	end_btn = Button.new()
	end_btn.text = "Fin de tour"
	end_btn.position = Vector2(WIN_W - 185, MAP_H + 28)
	end_btn.size = Vector2(165, 44)
	end_btn.pressed.connect(func(): end_turn_pressed.emit())
	add_child(end_btn)

# ── Barre de recrutement (dans le panneau bas) ───────────────────────────────
func _build_recruit_bar() -> void:
	recruit_bar = Control.new()
	recruit_bar.position = Vector2(0, MAP_H)
	recruit_bar.size = Vector2(WIN_W - 190, 100)
	recruit_bar.visible = false
	add_child(recruit_bar)

	# Ligne 1 : nom du camp et état de la file
	camp_label = Label.new()
	camp_label.position = Vector2(10, 6)
	camp_label.size = Vector2(WIN_W - 200, 30)
	recruit_bar.add_child(camp_label)

	# Ligne 2 : 7 boutons de recrutement côte à côte
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
	add_child(map_screen)

	var title = Label.new()
	title.text = "SupKontQuest\nChoisissez une carte"
	title.position = Vector2(0, 180)
	title.size = Vector2(WIN_W, 100)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	map_screen.add_child(title)

	for i in range(MapDefs.MAPS.size()):
		var btn = Button.new()
		btn.text = MapDefs.MAPS[i]["name"]
		btn.position = Vector2(376, 320 + i * 72)
		btn.size = Vector2(400, 58)
		btn.add_theme_font_size_override("font_size", 20)
		var idx = i
		btn.pressed.connect(func(): map_selected.emit(idx))
		map_screen.add_child(btn)

# ── Méthodes appelées par Main.gd ────────────────────────────────────────────

func hide_map_screen() -> void:
	map_screen.visible = false

func update_hud(player_name: String, turn: int, gold: int, msg: String, p_index: int) -> void:
	msg_label.text = msg
	info_label.text = "%s  —  Tour %d  |  [P] Produire (10 or)" % [player_name, turn]
	gold_label.text = "Or : %d" % gold
	info_label.modulate = Color(0.22, 0.45, 0.90) if p_index == 0 else Color(0.88, 0.22, 0.22)

# Affiche la barre de recrutement en bas à la place du HUD
func show_recruit(camp: Dictionary) -> void:
	var stats = UnitDefs.TYPES[camp["unit_type"]]

	# Texte : nom du camp, type actuel, file
	var q_text = "vide"
	if camp["queue"].size() > 0:
		var parts = []
		for t in camp["queue"]:
			parts.append(UnitDefs.TYPES[t]["label"])
		q_text = "  →  ".join(parts)
	camp_label.text = "%s  |  Type : %s  |  File : %s" % [camp["name"], stats["label"], q_text]

	# Cache le HUD normal, affiche la barre de recrutement
	msg_label.visible   = false
	info_label.visible  = false
	gold_label.visible  = false
	recruit_bar.visible = true

func hide_recruit() -> void:
	recruit_bar.visible = false
	msg_label.visible   = true
	info_label.visible  = true
	gold_label.visible  = true

func disable_end_btn() -> void:
	end_btn.disabled = true
