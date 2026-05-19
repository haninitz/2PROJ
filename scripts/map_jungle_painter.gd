extends Node2D

# ─────────────────────────────────────────────────────────────────────────────
#  map_jungle_painter.gd
#  Attache ce script au nœud MapJungle de map_jungle.tscn
#  La scène doit avoir :
#    MapJungle (Node2D) ← ce script
#    └── TileMap        ← même TileSet que Beverly Hills
# ─────────────────────────────────────────────────────────────────────────────

const MAP_W = 1152
const MAP_H = 620
const COLS  = 72
const ROWS  = 39

# ── Source TileSet ────────────────────────────────────────────────────────────
const SRC_GRASS = 0

# Tuiles herbe (plus sombres pour ambiance jungle)
const T_GRASS    = Vector2i(0,  0)
const T_GRASS_V1 = Vector2i(4,  0)
const T_GRASS_V2 = Vector2i(8,  0)
const T_GRASS_V3 = Vector2i(12, 0)

# Tuiles pierre/chemin
const T_STONE    = Vector2i(0, 8)
const T_STONE_V1 = Vector2i(1, 8)

# ── Positions des arbres (depuis MapDefs.gd — Carte 2) ───────────────────────
const TREE_POS = [
	Vector2(80,  120), Vector2(200, 200), Vector2(80,  320),
	Vector2(200, 450), Vector2(80,  530), Vector2(350,  80),
	Vector2(350, 220), Vector2(350, 390), Vector2(350, 530),
	Vector2(490, 180), Vector2(490, 460), Vector2(576,  80),
	Vector2(576, 520), Vector2(660, 310), Vector2(720,  80),
	Vector2(720, 180), Vector2(720, 460), Vector2(720, 540),
	Vector2(800, 220), Vector2(800, 410), Vector2(900, 100),
	Vector2(900, 320), Vector2(900, 530), Vector2(1060, 120),
	Vector2(1060, 530),
]

# ── Buissons supplémentaires (ambiance jungle dense) ─────────────────────────
const BUSH_POS = [
	Vector2(150, 50),  Vector2(420, 300), Vector2(550, 200),
	Vector2(630, 480), Vector2(850, 160), Vector2(980, 400),
	Vector2(1100, 250),Vector2(50,  400), Vector2(300, 560),
	Vector2(750, 300), Vector2(450, 140), Vector2(820, 560),
]

# ── Couleur overlay jungle (teinte verte sombre par dessus l'herbe) ───────────
const C_JUNGLE_OVERLAY = Color(0.05, 0.18, 0.04, 0.35)

@onready var tilemap : TileMap = $TileMap


func _ready() -> void:
	_paint_grass()
	_add_jungle_overlay()
	_paint_stone_paths()
	_add_trees()
	_add_bushes()
	_add_vines()


# ── 1. Fond herbe (variantes pour casser la répétition) ──────────────────────
func _paint_grass() -> void:
	var variants = [
		T_GRASS, T_GRASS, T_GRASS,
		T_GRASS_V1, T_GRASS_V1,
		T_GRASS_V2, T_GRASS_V2,
		T_GRASS_V3
	]
	for col in range(COLS):
		for row in range(ROWS):
			var idx = (col * 11 + row * 17 + col * row * 3) % variants.size()
			tilemap.set_cell(0, Vector2i(col, row), SRC_GRASS, variants[idx])


# ── 2. Overlay vert sombre (ambiance jungle) ──────────────────────────────────
func _add_jungle_overlay() -> void:
	var overlay      = ColorRect.new()
	overlay.name     = "JungleOverlay"
	overlay.color    = C_JUNGLE_OVERLAY
	overlay.position = Vector2.ZERO
	overlay.size     = Vector2(MAP_W, MAP_H)
	add_child(overlay)


# ── 3. Chemins de pierre ──────────────────────────────────────────────────────
func _paint_stone_paths() -> void:
	# Chemin vertical gauche (x=9 = 144px = Labo de Sam)
	for row in range(ROWS):
		tilemap.set_cell(0, Vector2i(9, row), SRC_GRASS, T_STONE)

	# Chemin vertical droit (x=62 = 992px = Base Ennemie)
	for row in range(ROWS):
		tilemap.set_cell(0, Vector2i(62, row), SRC_GRASS, T_STONE)

	# Chemin horizontal haut (y=9 = 144px)
	for col in range(10, 62):
		tilemap.set_cell(0, Vector2i(col, 9), SRC_GRASS, T_STONE)

	# Chemin horizontal bas (y=29 = 464px)
	for col in range(10, 62):
		tilemap.set_cell(0, Vector2i(col, 29), SRC_GRASS, T_STONE)

	# Chemin central (x=36 = 576px = Nexus Techno)
	for row in range(ROWS):
		tilemap.set_cell(0, Vector2i(36, row), SRC_GRASS, T_STONE_V1)


# ── 4. Arbres (jungle dense — 25 arbres) ─────────────────────────────────────
func _add_trees() -> void:
	var tex : Texture2D = load("res://assets/tilesets/cainos/TX Plant.png")
	if tex == null:
		push_warning("MapJungle: TX Plant.png introuvable")
		return

	for i in range(TREE_POS.size()):
		_spawn_tree(TREE_POS[i], tex, i % 3)


func _spawn_tree(pos: Vector2, tex: Texture2D, variant: int) -> void:
	# Ombre plus grande (jungle = arbres plus grands)
	var shadow      = ColorRect.new()
	shadow.color    = Color(0.0, 0.0, 0.0, 0.28)
	shadow.size     = Vector2(52, 16)
	shadow.position = pos + Vector2(-26, 30)
	add_child(shadow)

	# Sprite arbre
	var sprite             = Sprite2D.new()
	sprite.texture         = tex
	sprite.region_enabled  = true
	sprite.region_rect     = Rect2(variant * 160, 0, 140, 160)
	# Jungle = arbres légèrement plus grands
	sprite.scale           = Vector2(0.52, 0.52)
	sprite.position        = pos
	sprite.centered        = true
	# Teinte légèrement plus verte pour ambiance jungle
	sprite.modulate        = Color(0.85, 1.0, 0.75)
	add_child(sprite)


# ── 5. Buissons ───────────────────────────────────────────────────────────────
func _add_bushes() -> void:
	var tex : Texture2D = load("res://assets/tilesets/cainos/TX Plant.png")
	if tex == null:
		return

	for i in range(BUSH_POS.size()):
		var sprite             = Sprite2D.new()
		sprite.texture         = tex
		sprite.region_enabled  = true
		sprite.region_rect     = Rect2((i % 4) * 80, 160, 64, 64)
		sprite.scale           = Vector2(0.65, 0.65)
		sprite.position        = BUSH_POS[i]
		sprite.centered        = true
		sprite.modulate        = Color(0.80, 1.0, 0.70)
		add_child(sprite)


# ── 6. Lianes verticales décoratives ─────────────────────────────────────────
func _add_vines() -> void:
	# Quelques bandes sombres verticales qui simulent des lianes/ombres
	var vine_x = [160, 460, 690, 850, 1020]
	for x in vine_x:
		var vine      = ColorRect.new()
		vine.color    = Color(0.03, 0.12, 0.02, 0.18)
		vine.position = Vector2(x, 0)
		vine.size     = Vector2(6, MAP_H)
		add_child(vine)

		# Deuxième liane décalée
		var vine2      = ColorRect.new()
		vine2.color    = Color(0.03, 0.12, 0.02, 0.12)
		vine2.position = Vector2(x + 14, 30)
		vine2.size     = Vector2(4, MAP_H - 30)
		add_child(vine2)
