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

func draw(canvas: Node2D, font: Font, camps: Array, selected_idx: int,
		forests: Array, river_x: int, bridge_y: int, bridge_h: int,
		game_over: bool, winner: String) -> void:

	canvas.draw_rect(Rect2(0, 0, WIN_W, MAP_H), C_BG)

	if river_x > 0:
		canvas.draw_rect(Rect2(river_x - 22, 0, 44, MAP_H), C_WATER)
		canvas.draw_rect(Rect2(river_x - 22, bridge_y, 44, bridge_h), C_BG)

	for fp in forests:
		canvas.draw_circle(fp, 52, C_FOREST)
		canvas.draw_arc(fp, 52, 0, TAU, 24, Color(0.05, 0.16, 0.05), 2.0)

	canvas.draw_rect(Rect2(0, MAP_H, WIN_W, 100), C_PANEL)

	for i in range(camps.size()):
		for j in range(i + 1, camps.size()):
			if camps[i].pos.distance_to(camps[j].pos) < 520.0:
				canvas.draw_line(camps[i].pos, camps[j].pos, Color(0.35, 0.35, 0.35, 0.55), 2.0)

	for i in range(camps.size()):
		_draw_camp(canvas, font, camps[i], i == selected_idx)

	if game_over:
		canvas.draw_rect(Rect2(0, 0, WIN_W, MAP_H), Color(0, 0, 0, 0.55))
		canvas.draw_string(font, Vector2(256, MAP_H / 2.0 + 20.0),
			"VICTOIRE DE %s !" % winner.to_upper(),
			HORIZONTAL_ALIGNMENT_CENTER, 640, 44, C_GOLD)

func _draw_camp(canvas: Node2D, font: Font, camp: Camp, is_selected: bool) -> void:
	var col = _owner_color(camp.owner)

	if is_selected:
		canvas.draw_circle(camp.pos, CAMP_R + 7.0, C_SELECT)

	canvas.draw_circle(camp.pos, CAMP_R, col)
	canvas.draw_arc(camp.pos, CAMP_R, 0, TAU, 48, Color.BLACK, 2.5)

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
