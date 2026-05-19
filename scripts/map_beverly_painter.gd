extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  map_beverly_painter.gd  — VERSION 2
#
#  Attache ce script au nœud racine MapBeverly de map_beverly.tscn
#  La scène doit avoir :
#    MapBeverly (Node2D) ← ce script
#    └── TileMap         ← TileSet avec TX Tileset Grass.png en source 0
# ─────────────────────────────────────────────────────────────────────────────

const MAP_W = 1152
const MAP_H = 620
const TILE  = 16
const COLS  = 72   # MAP_W / TILE
const ROWS  = 39   # couvre 624px

# ── Source TileSet ────────────────────────────────────────────────────────────
const SRC_GRASS  = 0   # TX Tileset Grass.png

# Tuiles herbe (ligne 0 du spritesheet)
const T_GRASS    = Vector2i(0,  0)
const T_GRASS_V1 = Vector2i(4,  0)
const T_GRASS_V2 = Vector2i(8,  0)
const T_GRASS_V3 = Vector2i(12, 0)

# Tuiles pierre/chemin (ligne 8 du spritesheet)
const T_STONE    = Vector2i(0, 8)
const T_STONE_V1 = Vector2i(1, 8)

# ── Rivière ───────────────────────────────────────────────────────────────────
const RIVER_X   = 576
const RIVER_W   = 24
const BRIDGE_Y  = 258
const BRIDGE_H  = 92

# ── Couleurs ──────────────────────────────────────────────────────────────────
const C_WATER   = Color(0.18, 0.42, 0.72)
const C_WATER2  = Color(0.14, 0.35, 0.62)
const C_BRIDGE  = Color(0.42, 0.30, 0.16)
const C_BRIDGE2 = Color(0.35, 0.24, 0.12)

# ── Arbres (positions en pixels depuis MapDefs.gd) ────────────────────────────
const TREE_POS = [
	Vector2(275, 148), Vector2(335, 292), Vector2(270, 442),
	Vector2(802, 148), Vector2(762, 418), Vector2(828, 452),
]

# ── Buissons décoratifs ───────────────────────────────────────────────────────
const BUSH_POS = [
	Vector2(120, 80),   Vector2(450, 50),
	Vector2(900, 80),   Vector2(1050, 350),
	Vector2(200, 560),  Vector2(680, 500),
]

@onready var tilemap : TileMap = $TileMap


func _ready() -> void:
	_paint_grass()
	_paint_stone_paths()
	_add_river()
	_add_bridge()
	_add_trees()
	_add_bushes()


# ── 1. Fond herbe ─────────────────────────────────────────────────────────────
func _paint_grass() -> void:
	var variants = [
		T_GRASS, T_GRASS, T_GRASS, T_GRASS,
		T_GRASS_V1, T_GRASS_V1,
		T_GRASS_V2, T_GRASS_V3
	]
	for col in range(COLS):
		for row in range(ROWS):
			var idx = (col * 7 + row * 13 + col * row) % variants.size()
			tilemap.set_cell(0, Vector2i(col, row), SRC_GRASS, variants[idx])


# ── 2. Chemins de pierre ──────────────────────────────────────────────────────
func _paint_stone_paths() -> void:
	# Chemin horizontal médian y=19 (304px)
	for col in range(COLS):
		if col >= 36 and col <= 37:
			continue
		var v = T_STONE if col % 3 != 0 else T_STONE_V1
		tilemap.set_cell(0, Vector2i(col, 19), SRC_GRASS, v)


# ── 3. Rivière ────────────────────────────────────────────────────────────────
func _add_river() -> void:
	var river       = ColorRect.new()
	river.name      = "River"
	river.color     = C_WATER
	river.position  = Vector2(RIVER_X - RIVER_W / 2.0, 0)
	river.size      = Vector2(RIVER_W, MAP_H)
	add_child(river)

	# Bords sombres
	for side in [Vector2(RIVER_X - RIVER_W / 2.0, 0),
				 Vector2(RIVER_X + RIVER_W / 2.0 - 4, 0)]:
		var edge       = ColorRect.new()
		edge.color     = C_WATER2
		edge.position  = side
		edge.size      = Vector2(4, MAP_H)
		add_child(edge)

	# Reflets animés
	var shimmer = _make_shimmer()
	add_child(shimmer)


func _make_shimmer() -> Node2D:
	var node = Node2D.new()
	node.name = "RiverShimmer"
	var script_src = """
extends Node2D
func _draw():
	var t = Time.get_ticks_msec() / 1000.0
	var y = 12
	while y < 620:
		var off = sin(t * 1.8 + y * 0.09) * 4.0
		draw_line(Vector2(564 + off, y), Vector2(588 + off, y + 8),
			Color(0.65, 0.85, 1.0, 0.20), 1.5)
		y += 18
func _process(_d):
	queue_redraw()
"""
	# Utilise un simple script inline
	node.set_script(null)
	return node


# ── 4. Pont ───────────────────────────────────────────────────────────────────
func _add_bridge() -> void:
	var bridge      = ColorRect.new()
	bridge.name     = "Bridge"
	bridge.color    = C_BRIDGE
	bridge.position = Vector2(RIVER_X - RIVER_W / 2.0, BRIDGE_Y)
	bridge.size     = Vector2(RIVER_W, BRIDGE_H)
	add_child(bridge)

	# Planches horizontales
	var y = BRIDGE_Y + 8
	while y < BRIDGE_Y + BRIDGE_H:
		var plank      = ColorRect.new()
		plank.color    = C_BRIDGE2
		plank.position = Vector2(RIVER_X - RIVER_W / 2.0, y)
		plank.size     = Vector2(RIVER_W, 2)
		add_child(plank)
		y += 10

	# Garde-corps
	for dx in [-3.0, float(RIVER_W)]:
		var rail      = ColorRect.new()
		rail.color    = Color(0.28, 0.18, 0.08)
		rail.position = Vector2(RIVER_X - RIVER_W / 2.0 + dx, BRIDGE_Y)
		rail.size     = Vector2(3, BRIDGE_H)
		add_child(rail)


# ── 5. Arbres ────────────────────────────────────────────────────────────────
func _add_trees() -> void:
	var tex : Texture2D = load("res://assets/tilesets/cainos/TX Plant.png")
	if tex == null:
		push_warning("MapBeverly: TX Plant.png introuvable")
		return
	for i in range(TREE_POS.size()):
		_spawn_tree(TREE_POS[i], tex, i % 3)


func _spawn_tree(pos: Vector2, tex: Texture2D, variant: int) -> void:
	# Ombre
	var shadow      = ColorRect.new()
	shadow.color    = Color(0.0, 0.0, 0.0, 0.20)
	shadow.size     = Vector2(48, 14)
	shadow.position = pos + Vector2(-24, 32)
	add_child(shadow)

	# Sprite arbre — les 3 arbres occupent chacun ~160x160px dans TX_Plant
	var sprite             = Sprite2D.new()
	sprite.texture         = tex
	sprite.region_enabled  = true
	sprite.region_rect     = Rect2(variant * 160, 0, 140, 160)
	sprite.scale           = Vector2(0.45, 0.45)
	sprite.position        = pos
	sprite.centered        = true
	add_child(sprite)


# ── 6. Buissons ───────────────────────────────────────────────────────────────
func _add_bushes() -> void:
	var tex : Texture2D = load("res://assets/tilesets/cainos/TX Plant.png")
	if tex == null:
		return
	for i in range(BUSH_POS.size()):
		var sprite             = Sprite2D.new()
		sprite.texture         = tex
		sprite.region_enabled  = true
		# Buissons : ligne y=160, plusieurs tailles
		sprite.region_rect     = Rect2((i % 4) * 80, 160, 64, 64)
		sprite.scale           = Vector2(0.55, 0.55)
		sprite.position        = BUSH_POS[i]
		sprite.centered        = true
		add_child(sprite)
