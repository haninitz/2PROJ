extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  map_tropical_painter.gd — VERSION 3 (sans TileMap)
#  Attache ce script directement à MapTropical (Node2D)
#  Aucun nœud enfant requis — tout est dessiné via _draw()
# ─────────────────────────────────────────────────────────────────────────────

const MAP_W = 1152
const MAP_H = 620

# ── Île centrale ──────────────────────────────────────────────────────────────
const ISLAND_CX = 576.0
const ISLAND_CY = 310.0
const ISLAND_RX = 400.0
const ISLAND_RY = 240.0

# ── Couleurs ──────────────────────────────────────────────────────────────────
const C_OCEAN      = Color(0.08, 0.35, 0.72)
const C_OCEAN_DARK = Color(0.05, 0.22, 0.55)
const C_SAND       = Color(0.85, 0.75, 0.50)
const C_SAND_WET   = Color(0.70, 0.60, 0.35)
const C_GRASS      = Color(0.20, 0.42, 0.12)
const C_GRASS_DARK = Color(0.14, 0.30, 0.08)
const C_GRASS_LITE = Color(0.28, 0.52, 0.16)

# ── Positions arbres ──────────────────────────────────────────────────────────
const TREE_POS = [
	Vector2(400, 180), Vector2(520, 140), Vector2(650, 160), Vector2(780, 180),
	Vector2(370, 310), Vector2(500, 270), Vector2(620, 250), Vector2(750, 270),
	Vector2(850, 310), Vector2(420, 440), Vector2(560, 470), Vector2(700, 450),
	Vector2(800, 440),
]

var _tex_plant : Texture2D = null


func _ready() -> void:
	_tex_plant = load("res://assets/tilesets/cainos/TX Plant.png")
	_spawn_trees()
	_spawn_waves_node()


# ─────────────────────────────────────────────────────────────────────────────
#  DESSIN PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────
func _draw() -> void:
	var t = Time.get_ticks_msec() / 1000.0

	# 1. Fond océan
	_draw_ocean(t)

	# 2. Plage (anneau sable)
	_draw_beach()

	# 3. Île (herbe irrégulière)
	_draw_island()

	# 4. Texture herbe (petits détails)
	_draw_grass_details(t)

	# 5. Ports
	_draw_ports(t)


func _process(_delta: float) -> void:
	queue_redraw()


# ─────────────────────────────────────────────────────────────────────────────
#  OCEAN
# ─────────────────────────────────────────────────────────────────────────────
func _draw_ocean(t: float) -> void:
	# Fond bleu
	draw_rect(Rect2(0, 0, MAP_W, MAP_H), C_OCEAN)

	# Bords plus sombres
	draw_rect(Rect2(0, 0, MAP_W, 25), C_OCEAN_DARK)
	draw_rect(Rect2(0, MAP_H - 25, MAP_W, 25), C_OCEAN_DARK)
	draw_rect(Rect2(0, 0, 25, MAP_H), C_OCEAN_DARK)
	draw_rect(Rect2(MAP_W - 25, 0, 25, MAP_H), C_OCEAN_DARK)

	# Vagues animées
	for i in range(14):
		var wy  = 22.0 + float(i) * 44.0
		var alpha = 0.10 + sin(t * 0.9 + float(i) * 0.55) * 0.04
		var col = Color(0.55, 0.80, 1.0, alpha)
		var x = 0
		while x < MAP_W:
			var y1 = wy + sin(float(x) * 0.013 + t * 0.85 + float(i) * 0.5) * 7.0
			var y2 = wy + sin(float(x + 48) * 0.013 + t * 0.85 + float(i) * 0.5) * 7.0
			draw_line(Vector2(x, y1), Vector2(x + 48, y2), col, 1.6)
			x += 48


# ─────────────────────────────────────────────────────────────────────────────
#  PLAGE
# ─────────────────────────────────────────────────────────────────────────────
func _draw_beach() -> void:
	var pts_wet  = PackedVector2Array()
	var pts_sand = PackedVector2Array()
	var steps    = 120

	for i in range(steps + 1):
		var angle = float(i) / float(steps) * TAU
		var noise = _island_noise(angle)

		# Sable humide (juste au bord de l'île)
		var rw = (ISLAND_RX + 30.0) * (1.0 + noise * 0.6)
		var rh = (ISLAND_RY + 30.0) * (1.0 + noise * 0.6)
		pts_wet.append(Vector2(ISLAND_CX + cos(angle) * rw,
							   ISLAND_CY + sin(angle) * rh))

		# Sable sec (plus loin)
		var rs = (ISLAND_RX + 18.0) * (1.0 + noise * 0.7)
		var rss = (ISLAND_RY + 18.0) * (1.0 + noise * 0.7)
		pts_sand.append(Vector2(ISLAND_CX + cos(angle) * rs,
								ISLAND_CY + sin(angle) * rss))

	draw_colored_polygon(pts_wet, C_SAND_WET)
	draw_colored_polygon(pts_sand, C_SAND)


# ─────────────────────────────────────────────────────────────────────────────
#  ÎLE (herbe)
# ─────────────────────────────────────────────────────────────────────────────
func _draw_island() -> void:
	var pts       = PackedVector2Array()
	var pts_dark  = PackedVector2Array()
	var pts_lite  = PackedVector2Array()
	var steps     = 120

	for i in range(steps + 1):
		var angle = float(i) / float(steps) * TAU
		var noise = _island_noise(angle)
		var rx    = ISLAND_RX * (1.0 + noise)
		var ry    = ISLAND_RY * (1.0 + noise)
		pts.append(Vector2(ISLAND_CX + cos(angle) * rx,
						   ISLAND_CY + sin(angle) * ry))

		# Zone sombre (bords intérieurs)
		var rxd = ISLAND_RX * (1.0 + noise) * 0.92
		var ryd = ISLAND_RY * (1.0 + noise) * 0.92
		pts_dark.append(Vector2(ISLAND_CX + cos(angle) * rxd,
								ISLAND_CY + sin(angle) * ryd))

		# Zone claire (centre)
		var rxl = ISLAND_RX * 0.55
		var ryl = ISLAND_RY * 0.55
		pts_lite.append(Vector2(ISLAND_CX + cos(angle) * rxl,
								ISLAND_CY + sin(angle) * ryl))

	draw_colored_polygon(pts, C_GRASS)
	draw_colored_polygon(pts_dark, C_GRASS_DARK)
	draw_colored_polygon(pts_lite, C_GRASS_LITE)
	# Centre très clair
	draw_circle(Vector2(ISLAND_CX, ISLAND_CY), 80.0,
		Color(C_GRASS_LITE.r, C_GRASS_LITE.g, C_GRASS_LITE.b, 0.4))


# ─────────────────────────────────────────────────────────────────────────────
#  DÉTAILS HERBE (petits points/taches)
# ─────────────────────────────────────────────────────────────────────────────
func _draw_grass_details(_t: float) -> void:
	var detail_pos = [
		Vector2(480, 200), Vector2(580, 180), Vector2(680, 220),
		Vector2(450, 340), Vector2(600, 300), Vector2(730, 350),
		Vector2(500, 430), Vector2(650, 410), Vector2(750, 390),
	]
	for pos in detail_pos:
		if _is_island(pos.x, pos.y, -30.0):
			draw_circle(pos, 12.0, Color(0.24, 0.48, 0.14, 0.35))
			draw_circle(pos + Vector2(8, 4), 8.0, Color(0.18, 0.38, 0.10, 0.25))


# ─────────────────────────────────────────────────────────────────────────────
#  PORTS
# ─────────────────────────────────────────────────────────────────────────────
func _draw_ports(t: float) -> void:
	# Port gauche — bord ouest de l'île
	var port_l = Vector2(ISLAND_CX - ISLAND_RX - 5, ISLAND_CY)
	# Port droit — bord est de l'île
	var port_r = Vector2(ISLAND_CX + ISLAND_RX + 5, ISLAND_CY)

	for port in [port_l, port_r]:
		# Quai bois
		draw_rect(Rect2(port.x - 14, port.y - 22, 28, 44),
			Color(0.42, 0.30, 0.16))
		# Planches
		for j in range(4):
			draw_rect(Rect2(port.x - 14, port.y - 20 + j * 10, 28, 2),
				Color(0.30, 0.20, 0.10))
		# Anneau port pulsant
		var pulse = sin(t * 2.2) * 0.15
		draw_arc(port, 18.0, 0, TAU, 32,
			Color(0.25, 0.72, 1.0, 0.80 + pulse), 3.5)
		draw_arc(port, 26.0, 0, TAU, 32,
			Color(0.25, 0.72, 1.0, 0.25 + pulse * 0.5), 1.5)


# ─────────────────────────────────────────────────────────────────────────────
#  ARBRES (Sprite2D)
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_trees() -> void:
	if _tex_plant == null:
		push_warning("TX Plant.png introuvable")
		return

	for i in range(TREE_POS.size()):
		var pos = TREE_POS[i]
		if not _is_island(pos.x, pos.y, -25.0):
			continue

		# Ombre
		var shadow      = ColorRect.new()
		shadow.color    = Color(0, 0, 0, 0.20)
		shadow.size     = Vector2(44, 12)
		shadow.position = pos + Vector2(-22, 24)
		add_child(shadow)

		# Arbre
		var sprite             = Sprite2D.new()
		sprite.texture         = _tex_plant
		sprite.region_enabled  = true
		sprite.region_rect     = Rect2((i % 3) * 160, 0, 140, 160)
		sprite.scale           = Vector2(0.42, 0.42)
		sprite.position        = pos
		sprite.centered        = true
		sprite.modulate        = Color(0.88, 1.0, 0.68)
		add_child(sprite)


# ─────────────────────────────────────────────────────────────────────────────
#  VAGUES (nœud séparé pour éviter z-order issues)
# ─────────────────────────────────────────────────────────────────────────────
func _spawn_waves_node() -> void:
	pass  # Les vagues sont dans _draw() directement


# ─────────────────────────────────────────────────────────────────────────────
#  HELPERS
# ─────────────────────────────────────────────────────────────────────────────
func _island_noise(angle: float) -> float:
	return (sin(angle * 5.0) * 0.06 +
			sin(angle * 9.0) * 0.04 +
			sin(angle * 13.0) * 0.03 +
			cos(angle * 7.0) * 0.05)


func _is_island(px: float, py: float, margin: float) -> bool:
	var dx    = (px - ISLAND_CX) / (ISLAND_RX + margin)
	var dy    = (py - ISLAND_CY) / (ISLAND_RY + margin)
	var dist  = dx * dx + dy * dy
	var angle = atan2(py - ISLAND_CY, px - ISLAND_CX)
	var noise = _island_noise(angle)
	return dist < (1.0 + noise)
