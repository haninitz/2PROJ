class_name Renderer
extends RefCounted

const WIN_W  = 1152
const MAP_H  = 620
const CAMP_R = 42.0

const C_P1      = Color(0.22, 0.45, 0.90)
const C_P2      = Color(0.88, 0.22, 0.22)
const C_NEUTRAL = Color(0.55, 0.55, 0.55)
const C_SELECT  = Color(1.00, 0.92, 0.15)
const C_BG      = Color(0.18, 0.36, 0.18)
const C_WATER   = Color(0.20, 0.42, 0.80)
const C_FOREST  = Color(0.10, 0.26, 0.10)
const C_PANEL   = Color(0.08, 0.08, 0.08)
const C_GOLD    = Color(1.00, 0.87, 0.30)
const C_SAND    = Color(0.72, 0.64, 0.44)

func draw(canvas: Node2D, font: Font, camps: Array, selected_idx: int,
		forests: Array, river_x: int, bridge_y: int, bridge_h: int,
		has_water: bool, land_zones: Array,
		game_over: bool, winner: String) -> void:

	var t = Time.get_ticks_msec() / 1000.0

	if has_water:
		canvas.draw_rect(Rect2(0, 0, WIN_W, MAP_H), C_WATER)
		_draw_waves(canvas, t)
		_draw_water_ripples(canvas, t)
		_draw_water_foam(canvas, t)
		for zone in land_zones:
			canvas.draw_rect(Rect2(zone["x"] - 18, zone["y"] - 18, zone["w"] + 36, zone["h"] + 36), C_SAND)
			canvas.draw_rect(Rect2(zone["x"], zone["y"], zone["w"], zone["h"]), C_BG)
			canvas.draw_rect(Rect2(zone["x"],                  zone["y"],                   zone["w"], 4), Color(0.10, 0.20, 0.10))
			canvas.draw_rect(Rect2(zone["x"],                  zone["y"]+zone["h"]-4,       zone["w"], 4), Color(0.10, 0.20, 0.10))
			canvas.draw_rect(Rect2(zone["x"],                  zone["y"],                   4, zone["h"]), Color(0.10, 0.20, 0.10))
			canvas.draw_rect(Rect2(zone["x"]+zone["w"]-4,     zone["y"],                   4, zone["h"]), Color(0.10, 0.20, 0.10))
	else:
		canvas.draw_rect(Rect2(0, 0, WIN_W, MAP_H), C_BG)

	if river_x > 0:
		canvas.draw_rect(Rect2(river_x - 22, 0, 44, MAP_H), C_WATER)
		_draw_river_shimmer(canvas, river_x, bridge_y, bridge_h, t)
		canvas.draw_rect(Rect2(river_x - 22, bridge_y, 44, bridge_h), C_BG)

	for fp in forests:
		_draw_forest(canvas, fp, t)

	_draw_birds(canvas, t)

	canvas.draw_rect(Rect2(0, MAP_H, WIN_W, 100), C_PANEL)

	for i in range(camps.size()):
		for j in range(i + 1, camps.size()):
			var d = camps[i].pos.distance_to(camps[j].pos)
			if d < 520.0:
				canvas.draw_line(camps[i].pos, camps[j].pos, Color(0.35, 0.35, 0.35, 0.45), 2.0)
				# particule qui glisse sur la ligne
				var progress = fmod(t * 0.45 + i * 0.4 + j * 0.7, 1.0)
				var ppos = camps[i].pos.lerp(camps[j].pos, progress)
				canvas.draw_circle(ppos, 3.5, Color(0.85, 0.85, 0.85, 0.45))

	for i in range(camps.size()):
		_draw_camp(canvas, font, camps[i], i == selected_idx, t)

	if game_over:
		canvas.draw_rect(Rect2(0, 0, WIN_W, MAP_H), Color(0, 0, 0, 0.45))

# ── 3 couches de vagues ───────────────────────────────────────────────────────
func _draw_waves(canvas: Node2D, t: float) -> void:
	var y = 20
	while y < MAP_H:
		var x = 0
		while x < WIN_W - 16:
			var y1 = y + sin(x * 0.014 + t * 0.85 + y * 0.018) * 14.0
			var y2 = y + sin((x+16) * 0.014 + t * 0.85 + y * 0.018) * 14.0
			canvas.draw_line(Vector2(x, y1), Vector2(x+16, y2), Color(0.28, 0.55, 0.95, 0.32), 2.0)
			x += 16
		y += 28
	y = 34
	while y < MAP_H:
		var x = 0
		while x < WIN_W - 14:
			var y1 = y + sin(x * 0.028 + t * 2.1 + y * 0.013) * 7.0
			var y2 = y + sin((x+14) * 0.028 + t * 2.1 + y * 0.013) * 7.0
			canvas.draw_line(Vector2(x, y1), Vector2(x+14, y2), Color(0.60, 0.82, 1.00, 0.18), 1.5)
			x += 14
		y += 28
	y = 12
	while y < MAP_H:
		var x = 0
		while x < WIN_W - 20:
			var y1 = y + sin(x * 0.008 + t * 0.45 + y * 0.030) * 20.0
			var y2 = y + sin((x+20) * 0.008 + t * 0.45 + y * 0.030) * 20.0
			canvas.draw_line(Vector2(x, y1), Vector2(x+20, y2), Color(0.18, 0.38, 0.75, 0.15), 3.0)
			x += 20
		y += 56

# ── Cercles d'ondes qui s'élargissent et s'effacent ──────────────────────────
func _draw_water_ripples(canvas: Node2D, t: float) -> void:
	for i in range(10):
		var cx = float((i * 211 + 89) % WIN_W)
		var cy = float((i * 127 + 53) % MAP_H)
		var phase = fmod(t * 0.7 + i * 1.88, TAU)
		var radius = phase / TAU * 48.0
		var alpha  = (1.0 - phase / TAU) * 0.30
		if alpha > 0.02:
			canvas.draw_arc(Vector2(cx, cy), radius, 0, TAU, 28,
				Color(0.60, 0.85, 1.00, alpha), 1.5)

# ── Écume flottante (taille variée) ──────────────────────────────────────────
func _draw_water_foam(canvas: Node2D, t: float) -> void:
	for i in range(40):
		var bx = float((i * 173 + 47) % WIN_W)
		var by = float((i * 97  + 31) % MAP_H)
		var fx = bx + sin(t * 0.85 + i * 1.4) * 20.0
		var fy = by + cos(t * 0.65 + i * 1.0) * 12.0
		var alpha = (sin(t * 1.8 + i * 2.3) + 1.0) * 0.20
		var r = 2.0 + float(i % 3) * 1.5
		canvas.draw_circle(Vector2(fx, fy), r, Color(0.88, 0.95, 1.00, alpha))

# ── Reflets animés sur la rivière ────────────────────────────────────────────
func _draw_river_shimmer(canvas: Node2D, river_x: int, bridge_y: int, bridge_h: int, t: float) -> void:
	var y = 8
	while y < MAP_H:
		if y < bridge_y or y > bridge_y + bridge_h:
			var off = sin(t * 2.5 + y * 0.12) * 9.0
			canvas.draw_line(
				Vector2(river_x - 17 + off, y),
				Vector2(river_x + 17 + off, y + 14),
				Color(0.45, 0.75, 1.00, 0.30), 2.5)
		y += 16

# ── Forêt dense : 3 anneaux d'arbres à balancement individuel ────────────────
func _draw_forest(canvas: Node2D, fp: Vector2, t: float) -> void:
	# ombre au sol
	canvas.draw_circle(fp + Vector2(4, 4), 56, Color(0, 0, 0, 0.18))
	# base sombre
	canvas.draw_circle(fp, 56, Color(0.07, 0.16, 0.07))

	# anneau extérieur — 11 arbres
	for i in range(11):
		var angle = i * TAU / 11.0
		var sway  = sin(t * 1.2 + fp.x * 0.007 + i * 0.57) * 5.5
		var tp    = fp + Vector2(cos(angle) * 40.0 + sway, sin(angle) * 38.0)
		canvas.draw_circle(tp, 15, C_FOREST)
		canvas.draw_circle(tp + Vector2(sway * 0.4, -3), 10, Color(0.15, 0.35, 0.15))

	# anneau intermédiaire — 7 arbres
	for i in range(7):
		var angle = i * TAU / 7.0 + 0.3
		var sway  = sin(t * 1.5 + fp.x * 0.007 + i * 0.80) * 4.0
		var tp    = fp + Vector2(cos(angle) * 24.0 + sway, sin(angle) * 22.0)
		canvas.draw_circle(tp, 13, Color(0.12, 0.30, 0.12))
		canvas.draw_circle(tp + Vector2(sway * 0.3, -2), 8, Color(0.20, 0.44, 0.20))

	# centre — 3 petits arbres
	for i in range(3):
		var angle = i * TAU / 3.0 + t * 0.08
		var tp    = fp + Vector2(cos(angle) * 10.0, sin(angle) * 10.0)
		canvas.draw_circle(tp, 9, Color(0.16, 0.38, 0.16))

	canvas.draw_arc(fp, 56, 0, TAU, 32, Color(0.04, 0.12, 0.04), 2.5)

# ── Oiseaux qui traversent la carte ──────────────────────────────────────────
func _draw_birds(canvas: Node2D, t: float) -> void:
	for i in range(4):
		var speed = 55.0 + i * 22.0
		var bx    = fmod(t * speed + i * 280.0, WIN_W + 120.0) - 60.0
		var by    = 55.0 + i * 75.0 + sin(t * 2.2 + i * 1.6) * 18.0
		var wing  = sin(t * 9.0 + i * 2.1) * 9.0
		var alpha = 0.55
		canvas.draw_line(Vector2(bx - 11, by - wing), Vector2(bx, by),      Color(0.15, 0.15, 0.15, alpha), 1.5)
		canvas.draw_line(Vector2(bx,      by),         Vector2(bx + 11, by - wing), Color(0.15, 0.15, 0.15, alpha), 1.5)

# ── Camp ─────────────────────────────────────────────────────────────────────
func _draw_camp(canvas: Node2D, font: Font, camp: Camp, is_selected: bool, t: float) -> void:
	var col = _owner_color(camp.owner)

	canvas.draw_circle(camp.pos + Vector2(5, 5), CAMP_R, Color(0, 0, 0, 0.25))

	if is_selected:
		var pulse = abs(sin(t * 3.5)) * 12.0
		canvas.draw_circle(camp.pos, CAMP_R + 8.0 + pulse, C_SELECT)
		# 4 points orbitaux qui tournent
		for i in range(4):
			var angle = t * 2.8 + i * TAU / 4.0
			var op = camp.pos + Vector2(cos(angle), sin(angle)) * (CAMP_R + 20.0 + pulse * 0.4)
			canvas.draw_circle(op, 5.0, C_SELECT)

	if camp.type == "port":
		canvas.draw_arc(camp.pos, CAMP_R + 5.0, 0, TAU, 48, Color(0.0, 0.15, 0.60), 4.0)
		# gouttelettes animées autour du port
		for i in range(5):
			var angle = t * 1.6 + i * TAU / 5.0
			var dist  = CAMP_R + 14.0 + sin(t * 3.5 + i) * 7.0
			var sp    = camp.pos + Vector2(cos(angle), sin(angle)) * dist
			var alpha = (sin(t * 4.5 + i * 1.5) + 1.0) * 0.30
			canvas.draw_circle(sp, 2.5, Color(0.55, 0.85, 1.00, alpha))

	canvas.draw_circle(camp.pos, CAMP_R, col)
	canvas.draw_arc(camp.pos, CAMP_R, 0, TAU, 48, Color.BLACK, 2.5)

	if camp.type == "port":
		canvas.draw_string(font, camp.pos + Vector2(-95, -CAMP_R - 20.0),
			"[ PORT ]", HORIZONTAL_ALIGNMENT_CENTER, 190, 11, Color(0.40, 0.70, 1.00))

	canvas.draw_string(font, camp.pos + Vector2(-95, -CAMP_R - 6.0),
		camp.name, HORIZONTAL_ALIGNMENT_CENTER, 190, 13, Color.WHITE)

	var tlabel = UnitDefs.TYPES[camp.unit_type]["label"]
	canvas.draw_string(font, camp.pos + Vector2(-30, -5),
		tlabel, HORIZONTAL_ALIGNMENT_LEFT, 60, 10, Color.WHITE)

	canvas.draw_string(font, camp.pos + Vector2(-30, 16),
		str(camp.units), HORIZONTAL_ALIGNMENT_CENTER, 60, 20, Color.WHITE)

	canvas.draw_string(font, camp.pos + Vector2(-50, CAMP_R + 18.0),
		"+%d or" % camp.income, HORIZONTAL_ALIGNMENT_CENTER, 100, 12, C_GOLD)

	if camp.queue.size() > 0:
		canvas.draw_string(font, camp.pos + Vector2(-40, CAMP_R + 32.0),
			"[%d en file]" % camp.queue.size(),
			HORIZONTAL_ALIGNMENT_CENTER, 80, 10, C_GOLD)

func _owner_color(owner: int) -> Color:
	match owner:
		0: return C_P1
		1: return C_P2
	return C_NEUTRAL
