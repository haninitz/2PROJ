class_name HUD
extends CanvasLayer
# ─────────────────────────────────────────────────────────────────────────────
#  HUD.gd — SupKonQuest · Totally Spies Edition
#
#  Gère tout l'affichage en jeu :
#    - Barre d'infos joueur (or, revenu, camps)
#    - Leaderboard temps réel
#    - Barre de recrutement (camp sélectionné)
#    - Panneau de sélection d'unités + bouton spell
#    - Log d'événements
#
#  Ajouté comme enfant du CanvasLayer UI principal.
#  Communique via signaux : écoute GameManager, émet recruit_pressed.
# ─────────────────────────────────────────────────────────────────────────────


# Référence autoload — initialisée dans _ready() / initialize()
var U : Node

signal recruit_pressed(unit_type: String)

const MAX_LOG : int = 6

# ── Références nœuds ──────────────────────────────────────────────────────────
var info_label   : Label
var gold_label   : Label
var income_label : Label
var camps_label  : Label
var msg_label    : Label
var unit_label   : Label

var leaderboard_container : VBoxContainer
var _lb_bg   : Panel
var _minimap : Node2D
var recruit_bar   : Control
var camp_label    : Label
var recruit_btns  : Array = []
var selection_panel   : PanelContainer
var unit_count_label  : Label
var unit_stats_label  : Label
var spell_button      : Button
var event_log         : RichTextLabel

var _log_entries : Array = []
var _lb_refresh_acc : float = 0.0


func setup(u: Node) -> void:
	U = u
	_build_stats_bar()
	_build_leaderboard()
	_build_event_log()
	_build_recruit_bar()
	_build_selection_panel()
	_connect_game_manager()
	_build_minimap()


func _ready() -> void:
	pass  # build déclenché par setup()


func _process(delta: float) -> void:
	_lb_refresh_acc += delta
	if _lb_refresh_acc >= 2.0:
		_lb_refresh_acc = 0.0
		refresh_leaderboard()
	_refresh_stats()


# ─────────────────────────────────────────────────────────────────────────────
#  CONSTRUCTION
# ─────────────────────────────────────────────────────────────────────────────

func _build_stats_bar() -> void:
	info_label   = _lbl_add(Vector2(10,  U.MAP_H + 8),  Vector2(190, 28))
	gold_label   = _lbl_add(Vector2(210, U.MAP_H + 8),  Vector2(100, 28))
	income_label = _lbl_add(Vector2(320, U.MAP_H + 8),  Vector2(110, 28))
	camps_label  = _lbl_add(Vector2(440, U.MAP_H + 8),  Vector2(160, 28))
	msg_label    = _lbl_add(Vector2(10,  U.MAP_H + 52), Vector2(580, 28))
	unit_label   = _lbl_add(Vector2(600, U.MAP_H + 52), Vector2(340, 28))
	unit_label.visible  = false
	# Cacher la barre stats jusqu'au début du jeu
	info_label.visible   =	 false
	gold_label.visible   = false
	income_label.visible = false
	camps_label.visible  = false
	msg_label.visible    = false


func _build_leaderboard() -> void:
	_lb_bg = Panel.new()
	_lb_bg.visible  = false
	var lb_bg : Panel = _lb_bg
	lb_bg.position = Vector2(U.WIN_W - 228, 6)
	lb_bg.size     = Vector2(222, 220)
	var lbs : StyleBoxFlat = StyleBoxFlat.new()
	lbs.bg_color    = Color(0.04, 0.02, 0.10, 0.88)
	lbs.border_color = U.C_PINK
	lbs.set_border_width_all(2)
	lbs.set_corner_radius_all(6)
	lb_bg.add_theme_stylebox_override("panel", lbs)
	add_child(lb_bg)

	var lt : Label = Label.new()
	lt.text     = "— Players —"
	lt.position = Vector2(0, 5)
	lt.size     = Vector2(222, 22)
	lt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lt.add_theme_font_size_override("font_size", 12)
	lt.add_theme_color_override("font_color", U.C_GOLD)
	lb_bg.add_child(lt)

	leaderboard_container = VBoxContainer.new()
	leaderboard_container.position = Vector2(6, 28)
	leaderboard_container.size     = Vector2(210, 188)
	leaderboard_container.add_theme_constant_override("separation", 5)
	lb_bg.add_child(leaderboard_container)


func _build_event_log() -> void:
	event_log = RichTextLabel.new()
	event_log.position       = Vector2(10, U.MAP_H + 5)
	event_log.size           = Vector2(500, 90)
	event_log.scroll_active  = false
	event_log.fit_content    = true
	# Style discret
	var bg : StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0.04, 0.02, 0.10, 0.70)
	bg.set_corner_radius_all(4)
	event_log.add_theme_stylebox_override("normal", bg)
	add_child(event_log)
	event_log.visible = false


func _build_recruit_bar() -> void:
	recruit_bar          = Control.new()
	recruit_bar.position = Vector2(0, U.MAP_H)
	recruit_bar.size     = Vector2(U.WIN_W - 190, 100)
	recruit_bar.visible  = false
	add_child(recruit_bar)

	camp_label          = Label.new()
	camp_label.position = Vector2(10, 6)
	camp_label.size     = Vector2(U.WIN_W - 200, 30)
	recruit_bar.add_child(camp_label)

	var ud : Node = get_node_or_null("/root/UnitDefs")
	if not ud:
		return
	var types : Dictionary = ud.get("TYPES") if ud else {}
	if types.is_empty():
		return

	var x : int = 5
	for unit_type in types.keys():
		var stats  : Dictionary = types[unit_type]
		var b : Button = Button.new()
		b.text     = "%s\n%d G" % [stats.get("label", unit_type), stats.get("price", 0)]
		b.position = Vector2(x, 38)
		b.size     = Vector2(U.BTN_W, 52)
		b.add_theme_stylebox_override("normal",
			U.flat(Color(0.10, 0.04, 0.18), U.C_PINK, 2, 6))
		b.add_theme_color_override("font_color", U.C_WHITE)
		var t : String = unit_type
		b.set_meta("unit_type", t)
		b.pressed.connect(func():
			Sound.play("recruit")
			recruit_pressed.emit(t))
		recruit_bar.add_child(b)
		recruit_btns.append(b)
		x += U.BTN_W + 2


func _build_selection_panel() -> void:
	selection_panel          = PanelContainer.new()
	selection_panel.position = Vector2(10, U.MAP_H - 140)
	selection_panel.size     = Vector2(320, 80)
	selection_panel.visible  = false
	add_child(selection_panel)

	var vb : VBoxContainer = VBoxContainer.new()
	selection_panel.add_child(vb)

	var hb : HBoxContainer = HBoxContainer.new()
	vb.add_child(hb)

	unit_count_label      = Label.new()
	unit_count_label.text = ""
	hb.add_child(unit_count_label)

	spell_button         = Button.new()
	spell_button.text    = "Q — Spell"
	spell_button.visible = false
	spell_button.pressed.connect(_on_spell_pressed)
	hb.add_child(spell_button)

	# Ligne stats (visible seulement si 1 unité sélectionnée)
	unit_stats_label          = Label.new()
	unit_stats_label.text     = ""
	unit_stats_label.visible  = false
	unit_stats_label.add_theme_font_size_override("font_size", 11)
	unit_stats_label.modulate = Color(0.80, 0.90, 1.0)
	vb.add_child(unit_stats_label)


# ─────────────────────────────────────────────────────────────────────────────
#  MISE À JOUR
# ─────────────────────────────────────────────────────────────────────────────


func _build_minimap() -> void:
	_minimap = load("res://scripts/ui/Minimap.gd").new()
	add_child(_minimap)
	_minimap.setup()



func show_hud() -> void:
	if _lb_bg:
		_lb_bg.visible = true
	if _minimap:
		_minimap.show_minimap()
	if event_log:
		event_log.visible = true
	info_label.visible   = true
	gold_label.visible   = true
	income_label.visible = true
	camps_label.visible  = true
	msg_label.visible    = true


func hide_hud() -> void:
	if _lb_bg:
		_lb_bg.visible = false

func _refresh_stats() -> void:
	var gm : Node = get_node_or_null("/root/GameManager")
	if not gm or not gm.get("game_started"):
		return

	# FIX : utilise le joueur actif plutôt que player_id=1 en dur
	var player
	if gm.has_method("get_current_player"):
		player = gm.get_current_player()
	elif gm.has_method("find_player_by_id"):
		var pid : int = gm.get("current_player_id") if gm.get("current_player_id") else 1
		player = gm.find_player_by_id(pid)
	if not player:
		return

	gold_label.text   = "%d G"      % player.gold
	income_label.text = "+%d G/tick" % player.get_income()
	camps_label.text  = "%d camps"   % player.get_camp_count()
	gold_label.add_theme_color_override("font_color",   U.C_GOLD)
	income_label.add_theme_color_override("font_color", U.C_GREEN)
	camps_label.add_theme_color_override("font_color",  Color(0.80, 0.60, 1.00))
	info_label.text     = player.player_name
	info_label.modulate = player.color

	var rem : float = 30.0
	if gm.get("income_interval") and gm.get("income_timer"):
		rem = gm.income_interval - gm.income_timer
	msg_label.text = "[%ds]" % int(rem)
	msg_label.add_theme_color_override("font_color",
		U.C_PINK if rem <= 8.0 else Color(0.80, 0.78, 0.90))


func refresh_leaderboard() -> void:
	var gm : Node = get_node_or_null("/root/GameManager")
	if not gm or not gm.get("game_started"):
		return

	for c in leaderboard_container.get_children():
		c.queue_free()

	# Tri par nombre de camps (bubble sort simple)
	var sorted : Array = gm.players.duplicate()
	for i in range(sorted.size()):
		for j in range(i + 1, sorted.size()):
			if sorted[j].get_camp_count() > sorted[i].get_camp_count():
				var tmp : Variant = sorted[i]
				sorted[i] = sorted[j]
				sorted[j] = tmp

	for pl in sorted:
		var card : Panel = Panel.new()
		var st : StyleBoxFlat = StyleBoxFlat.new()
		st.bg_color    = Color(pl.color.r * 0.14, pl.color.g * 0.14, pl.color.b * 0.14, 0.92)
		st.border_color = pl.color
		st.set_border_width_all(2)
		st.set_corner_radius_all(4)
		card.add_theme_stylebox_override("panel", st)
		card.custom_minimum_size = Vector2(208, 40)
		leaderboard_container.add_child(card)

		var bar : ColorRect = ColorRect.new()
		bar.color    = pl.color
		bar.position = Vector2(0, 0)
		bar.size     = Vector2(5, 40)
		card.add_child(bar)

		var nl : Label = Label.new()
		nl.text     = pl.player_name
		nl.position = Vector2(12, 3)
		nl.size     = Vector2(194, 17)
		nl.add_theme_font_size_override("font_size", 12)
		nl.add_theme_color_override("font_color", U.C_WHITE)
		card.add_child(nl)

		var sl : Label = Label.new()
		sl.text     = "%d camps  +%d G/tick  %d G" % [
			pl.get_camp_count(), pl.get_income(), pl.gold]
		sl.position = Vector2(12, 22)
		sl.size     = Vector2(194, 15)
		sl.add_theme_font_size_override("font_size", 10)
		sl.add_theme_color_override("font_color", pl.color)
		card.add_child(sl)


func show_recruit(camp) -> void:
	if camp == null:
		return
	var q : String = "empty"
	if camp.production_queue.size() > 0:
		var parts : Array = []
		for e in camp.production_queue:
			parts.append(e["unit_type"])
		q = " → ".join(parts)
	camp_label.text = "%s  |  Queue: %s" % [camp.camp_name, q]

	# Affiche uniquement les unités adaptées au camp
	var ud : Node = get_node_or_null("/root/UnitDefs")
	var is_port : bool = camp.get("is_port") == true
	var allowed : Array = []
	if ud:
		if is_port:
			allowed = ud.get_sea_units()
		else:
			allowed = ud.get_land_units()

	for b in recruit_btns:
		if not is_instance_valid(b):
			continue
		# Retrouve le type via le texte du bouton (stocké en metadata)
		var unit_type : String = b.get_meta("unit_type") if b.has_meta("unit_type") else ""
		b.visible = allowed.is_empty() or unit_type in allowed

	recruit_bar.visible = true


func hide_recruit() -> void:
	recruit_bar.visible = false


func update_selection_panel(selected_units: Array) -> void:
	if selected_units.is_empty():
		selection_panel.visible = false
		return
	selection_panel.visible  = true
	unit_count_label.text    = "%d unit(s)" % selected_units.size()
	var has_spell : bool = false
	for u in selected_units:
		if is_instance_valid(u) and u.get("unit_type") in ["SUPPORT", "HEALER"]:
			has_spell = true
			break
	spell_button.visible = has_spell

	# Stats — seulement si 1 unité sélectionnée
	if selected_units.size() == 1:
		var u = selected_units[0]
		if is_instance_valid(u):
			var hp_val    : float = u.get("hp")     if u.get("hp")     != null else 0.0
			var max_hp    : float = u.get("max_hp") if u.get("max_hp") != null else 0.0
			var dmg       : float = u.get("damage") if u.get("damage") != null else 0.0
			var spd       : float = u.get("speed")  if u.get("speed")  != null else 0.0
			var rng       : float = u.get("attack_range") if u.get("attack_range") != null else 0.0
			var utype     : String = str(u.get("unit_type")) if u.get("unit_type") != null else "?"
			var rng_str   : String = "melee" if rng <= 0.0 else "%.0f" % rng
			unit_stats_label.text    = "HP %d/%d  •  DMG %.0f  •  SPD %.0f  •  RNG %s  •  %s" % [
				int(hp_val), int(max_hp), dmg, spd, rng_str, utype]
			unit_stats_label.visible = true
	else:
		unit_stats_label.visible = false


func add_log(message: String) -> void:
	_log_entries.append(message)
	if _log_entries.size() > MAX_LOG:
		_log_entries.pop_front()
	if event_log:
		event_log.text = "\n".join(_log_entries)


# ─────────────────────────────────────────────────────────────────────────────
#  CALLBACKS GAMEMANAGER
# ─────────────────────────────────────────────────────────────────────────────

func _connect_game_manager() -> void:
	var gm : Node = get_node_or_null("/root/GameManager")
	if not gm:
		return
	var signal_map : Dictionary = {
		"income_distributed": _on_income_distributed,
		"camp_captured":      _on_camp_captured,
		"player_defeated":    _on_player_defeated,
		"region_captured":    _on_region_captured,
	}
	for sig_name in signal_map.keys():
		if gm.has_signal(sig_name) and not gm.get(sig_name + "_connected"):
			gm.connect(sig_name, signal_map[sig_name])


func _on_income_distributed(player, amount: int) -> void:
	refresh_leaderboard()
	add_log("+ %s +%dG" % [player.player_name.split(" ")[0], amount])


func _on_camp_captured(camp, _old: int, new_owner_id: int) -> void:
	refresh_leaderboard()
	var gm : Node = get_node_or_null("/root/GameManager")
	var owner  = gm.find_player_by_id(new_owner_id) if gm else null
	add_log("🏠 %s → %s" % [camp.camp_name,
		owner.player_name.split(" ")[0] if owner else "?"])


func _on_player_defeated(player) -> void:
	add_log("💀 %s eliminated!" % player.player_name)
	refresh_leaderboard()


func _on_region_captured(region_name: String, player) -> void:
	add_log("⭐ %s owns %s!" % [player.player_name.split(" ")[0], region_name])


# ─────────────────────────────────────────────────────────────────────────────
#  PRIVÉ
# ─────────────────────────────────────────────────────────────────────────────

func _lbl_add(pos: Vector2, sz: Vector2) -> Label:
	var l : Label = Label.new()
	l.position = pos
	l.size     = sz
	add_child(l)
	return l


func _on_spell_pressed() -> void:
	var s : Node = get_tree().get_first_node_in_group("unit_selection")
	if s and s.has_method("_activate_spell_on_selected"):
		s._activate_spell_on_selected()
