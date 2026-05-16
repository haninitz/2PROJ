class_name Renderer
extends RefCounted

const WIN_W  = 1152
const MAP_H  = 620
const CAMP_R = 42.0

const C_P1      = Color(0.10, 0.78, 0.38)   # Sam — vert vif
const C_P2      = Color(0.92, 0.12, 0.45)   # Clover — rose fuchsia
const C_NEUTRAL = Color(0.62, 0.58, 0.72)   # lavande argentée
const C_SELECT  = Color(1.00, 0.42, 0.80)   # sélection rose
const C_BG      = Color(0.10, 0.08, 0.18)   # fond violet sombre (base secrète)
const C_WATER   = Color(0.18, 0.68, 0.88)   # turquoise tropical
const C_FOREST  = Color(0.08, 0.22, 0.12)   # forêt sombre
const C_PANEL   = Color(0.08, 0.06, 0.14)   # panneau violet foncé
const C_GOLD    = Color(1.00, 0.82, 0.25)   # or
const C_SAND    = Color(0.88, 0.75, 0.58)   # sable tropical

func draw(canvas: Node2D, font: Font, camps: Array, selected_idx: int,
		forests: Array, river_x: int, bridge_y: int, bridge_h: int,
		has_water: bool, land_zones: Array, regions: Array,
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

	_draw_regions(canvas, font, camps, regions)

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

# ── Vagues simplifiées (10 bandes au lieu de ~4000 lignes) ───────────────────
func _draw_waves(canvas: Node2D, t: float) -> void:
	for i in range(10):
		var y = 30.0 + i * 58.0
		var x = 0
		while x < WIN_W - 48:
			var y1 = y + sin(x * 0.014 + t * 0.85 + i * 0.6) * 13.0
			var y2 = y + sin((x + 48) * 0.014 + t * 0.85 + i * 0.6) * 13.0
			canvas.draw_line(Vector2(x, y1), Vector2(x + 48, y2), Color(0.28, 0.55, 0.95, 0.28), 1.8)
			x += 48
	for i in range(6):
		var y = 50.0 + i * 90.0
		var x = 0
		while x < WIN_W - 64:
			var y1 = y + sin(x * 0.008 + t * 0.45 + i * 1.1) * 18.0
			var y2 = y + sin((x + 64) * 0.008 + t * 0.45 + i * 1.1) * 18.0
			canvas.draw_line(Vector2(x, y1), Vector2(x + 64, y2), Color(0.18, 0.38, 0.75, 0.13), 2.5)
			x += 64

# ── Cercles d'ondes qui s'élargissent et s'effacent ──────────────────────────
func _draw_water_ripples(canvas: Node2D, t: float) -> void:
	for i in range(5):
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
	for i in range(20):
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

# ── Forêt : 2 anneaux allégés ────────────────────────────────────────────────
func _draw_forest(canvas: Node2D, fp: Vector2, t: float) -> void:
	canvas.draw_circle(fp + Vector2(4, 4), 56, Color(0, 0, 0, 0.18))
	canvas.draw_circle(fp, 56, Color(0.07, 0.16, 0.07))

	# anneau extérieur — 6 arbres (au lieu de 11)
	for i in range(6):
		var angle = i * TAU / 6.0
		var sway  = sin(t * 1.2 + fp.x * 0.007 + i * 0.57) * 5.5
		var tp    = fp + Vector2(cos(angle) * 38.0 + sway, sin(angle) * 36.0)
		canvas.draw_circle(tp, 15, C_FOREST)

	# anneau intérieur — 4 arbres (au lieu de 7)
	for i in range(4):
		var angle = i * TAU / 4.0 + 0.3
		var sway  = sin(t * 1.5 + fp.x * 0.007 + i * 0.80) * 4.0
		var tp    = fp + Vector2(cos(angle) * 22.0 + sway, sin(angle) * 20.0)
		canvas.draw_circle(tp, 12, Color(0.15, 0.35, 0.15))

	canvas.draw_arc(fp, 56, 0, TAU, 24, Color(0.04, 0.12, 0.04), 2.0)

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

# ── Régions ───────────────────────────────────────────────────────────────────
func _region_owner(region: Dictionary, camps: Array) -> int:
	var owner = camps[region["camps"][0]].owner
	for idx in region["camps"]:
		if camps[idx].owner != owner:
			return -1
	return owner

func _draw_regions(canvas: Node2D, font: Font, camps: Array, regions: Array) -> void:
	for region in regions:
		var min_x = INF;  var max_x = -INF
		var min_y = INF;  var max_y = -INF
		for idx in region["camps"]:
			var pos = camps[idx].pos
			min_x = min(min_x, pos.x)
			max_x = max(max_x, pos.x)
			min_y = min(min_y, pos.y)
			max_y = max(max_y, pos.y)

		var pad  = 62.0
		var rx   = min_x - pad
		var ry   = min_y - pad
		var rw   = max_x - min_x + pad * 2.0
		var rh   = max_y - min_y + pad * 2.0
		var rect = Rect2(rx, ry, rw, rh)

		var owner = _region_owner(region, camps)
		var fill_col   = Color(0.50, 0.50, 0.60, 0.08)
		var border_col = Color(0.50, 0.50, 0.60, 0.22)
		var text_col   = Color(0.80, 0.80, 0.90, 0.55)
		if owner == 0:
			fill_col   = Color(C_P1.r, C_P1.g, C_P1.b, 0.10)
			border_col = Color(C_P1.r, C_P1.g, C_P1.b, 0.40)
			text_col   = Color(C_P1.r, C_P1.g, C_P1.b, 0.85)
		elif owner == 1:
			fill_col   = Color(C_P2.r, C_P2.g, C_P2.b, 0.10)
			border_col = Color(C_P2.r, C_P2.g, C_P2.b, 0.40)
			text_col   = Color(C_P2.r, C_P2.g, C_P2.b, 0.85)

		canvas.draw_rect(rect, fill_col)
		canvas.draw_rect(rect, border_col, false, 2.0)

		var cx = rx + rw / 2.0
		canvas.draw_string(font, Vector2(cx - 90, ry + 15),
			region["name"], HORIZONTAL_ALIGNMENT_CENTER, 180, 11, text_col)
		canvas.draw_string(font, Vector2(cx - 60, ry + rh - 5),
			"+%d or bonus" % region["bonus"], HORIZONTAL_ALIGNMENT_CENTER, 120, 10, C_GOLD)
