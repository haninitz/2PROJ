extends Node2D
# =============================================================================
#  minimap.gd — SupKonQuest · Totally Spies Edition
#  Lit les camps depuis Main.gd directement
# =============================================================================

const MAP_W  : float = 1152.0
const MAP_H  : float = 620.0
const MINI_W : float = 180.0
const MINI_H : float = 98.0
const POS_X  : float = 1152.0 - 180.0 - 8.0
const POS_Y  : float = 620.0 - 98.0 - 8.0
const SCALE_X : float = MINI_W / MAP_W
const SCALE_Y : float = MINI_H / MAP_H

# Couleurs joueurs
const C_P1      = Color(0.22, 0.45, 0.90)
const C_P2      = Color(0.88, 0.22, 0.22)
const C_NEUTRAL = Color(0.55, 0.55, 0.55)


func setup() -> void:
	position = Vector2(POS_X, POS_Y)
	z_index  = 5
	visible  = false


func show_minimap() -> void:
	visible = true


func hide_minimap() -> void:
	visible = false


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var font : Font = ThemeDB.fallback_font

	# Fond
	draw_rect(Rect2(0, 0, MINI_W, MINI_H), Color(0.06, 0.10, 0.06, 0.90))

	# Grille légère
	var grid_col := Color(0.20, 0.30, 0.20, 0.20)
	var gx : float = 0.0
	while gx <= MINI_W:
		draw_line(Vector2(gx, 0), Vector2(gx, MINI_H), grid_col, 0.5)
		gx += MINI_W / 6.0
	var gy : float = 0.0
	while gy <= MINI_H:
		draw_line(Vector2(0, gy), Vector2(MINI_W, gy), grid_col, 0.5)
		gy += MINI_H / 3.0

	# Récupère les camps depuis Main.gd
	var main : Node = get_tree().get_first_node_in_group("main_node")
	if main == null:
		# Fallback: cherche via arbre de scène
		main = get_node_or_null("/root/Main")
	
	if main and main.get("camps"):
		var camps : Array = main.camps
		for camp in camps:
			if not camp:
				continue
			var pos   : Vector2 = camp.pos
			var mx    : float   = pos.x * SCALE_X
			var my    : float   = pos.y * SCALE_Y
			var owner : int     = camp.owner

			var col : Color = C_NEUTRAL
			if owner == 0:
				col = C_P1
			elif owner == 1:
				col = C_P2

			draw_circle(Vector2(mx, my), 3.5, col)
			draw_arc(Vector2(mx, my), 3.5, 0, TAU, 8,
				Color(col.r, col.g, col.b, 0.50), 1.0)

	# Bordure rose
	draw_rect(Rect2(0, 0, MINI_W, MINI_H),
		Color(1.00, 0.20, 0.58, 0.70), false, 1.5)

	# Label
	draw_string(font, Vector2(2, -3), "MINIMAP",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
		Color(1.0, 0.20, 0.58, 0.60))