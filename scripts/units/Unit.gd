class_name Unit
extends CharacterBody2D

# ─────────────────────────────────────────────────────────────────────────────
# SIGNAUX
# ─────────────────────────────────────────────────────────────────────────────
signal unit_died(unit)          # émis quand l'unité meurt → P1 écoute pour la capture
signal unit_damaged(unit, amount) # émis à chaque dégât → utile pour la barre de vie (P3)

# ─────────────────────────────────────────────────────────────────────────────
# ENUM — types d'unités (correspond au diagramme de classes)
# ─────────────────────────────────────────────────────────────────────────────
enum UnitType {
	FANTASSIN,
	TIR_DISTANCE,
	LOURD,
	ANTI_BLINDAGE,
	MORTIER,
	SOUTIEN,
	SOIGNEUR,
	TRANSPORT,
	FREGATE,
	DESTROYER
}

# ─────────────────────────────────────────────────────────────────────────────
# STATS — à surcharger dans chaque sous-classe
# ─────────────────────────────────────────────────────────────────────────────
@export var unit_type: UnitType = UnitType.FANTASSIN
@export var max_hp: float       = 100.0
@export var damage: float       = 15.0
@export var attack_range: float = 0.0     # 0 = corps à corps
@export var speed: float        = 120.0   # pixels par seconde
@export var hit_speed: float    = 1.0     # secondes entre chaque attaque
@export var build_time: float   = 3.0     # secondes pour produire cette unité
@export var price: int          = 50      # coût en or (compatible avec le système gold de Main.gd)

# ─────────────────────────────────────────────────────────────────────────────
# ÉTAT — géré en cours de jeu
# ─────────────────────────────────────────────────────────────────────────────
var hp: float = max_hp
var owner_id: int = -1       # -1 = neutre, 0 = Joueur 1, 1 = Joueur 2 (cohérent avec Main.gd)
var current_target: Unit = null
var is_alive: bool = true

# ─────────────────────────────────────────────────────────────────────────────
# MODIFICATEURS DE TYPE
# Clé : [attaquant, cible] → multiplicateur de dégâts
# ─────────────────────────────────────────────────────────────────────────────
const DAMAGE_MODIFIERS := {
	[UnitType.ANTI_BLINDAGE, UnitType.LOURD]:        3.0,  # AntiBlindage × 3 vs Lourd
	[UnitType.MORTIER,        UnitType.FANTASSIN]:   1.5,  # Mortier efficace vs infanterie groupée
	[UnitType.TIR_DISTANCE,   UnitType.FANTASSIN]:   1.2,  # Avantage portée vs corps à corps
	[UnitType.LOURD,          UnitType.TIR_DISTANCE]:1.5,  # Tank résiste bien aux tireurs
	[UnitType.FREGATE,        UnitType.TRANSPORT]:   2.0,  # Frégate détruit les transports
	[UnitType.DESTROYER,      UnitType.FREGATE]:     1.8,  # Destroyer domine en mer
}

# ─────────────────────────────────────────────────────────────────────────────
# NŒUDS GODOT — à ajouter dans la scène .tscn
# ─────────────────────────────────────────────────────────────────────────────
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var attack_timer: Timer          = $AttackTimer
@onready var range_area: Area2D           = $RangeArea

# ─────────────────────────────────────────────────────────────────────────────
# INITIALISATION
# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	hp = max_hp
	attack_timer.wait_time = hit_speed
	attack_timer.one_shot  = false

	# Connecter les signaux de la zone de portée
	range_area.body_entered.connect(_on_range_entered)
	range_area.body_exited.connect(_on_range_exited)
	attack_timer.timeout.connect(_on_attack_timer)

	# Ajuster le rayon de la zone de portée selon attack_range
	var shape = CircleShape2D.new()
	shape.radius = attack_range if attack_range > 0 else 40.0
	var collision = range_area.get_child(0) if range_area.get_child_count() > 0 else CollisionShape2D.new()
	if collision is CollisionShape2D:
		collision.shape = shape

# ─────────────────────────────────────────────────────────────────────────────
# DÉPLACEMENT — utilise NavigationAgent2D pour le pathfinding
# ─────────────────────────────────────────────────────────────────────────────
func move_to(target_pos: Vector2) -> void:
	if not is_alive:
		return
	nav_agent.target_position = target_pos

func _physics_process(_delta: float) -> void:
	if not is_alive:
		return
	if nav_agent.is_navigation_finished():
		return
	var next_pos: Vector2 = nav_agent.get_next_path_position()
	var direction: Vector2 = global_position.direction_to(next_pos)
	velocity = direction * speed
	move_and_slide()

# ─────────────────────────────────────────────────────────────────────────────
# COMBAT — détection automatique + attaque
# ─────────────────────────────────────────────────────────────────────────────
func _on_range_entered(body: Node) -> void:
	if body is Unit and body.owner_id != owner_id and body.is_alive:
		if current_target == null:
			current_target = body
			attack_timer.start()

func _on_range_exited(body: Node) -> void:
	if body == current_target:
		current_target = null
		attack_timer.stop()
		# Chercher une autre cible dans la zone
		for b in range_area.get_overlapping_bodies():
			if b is Unit and b.owner_id != owner_id and b.is_alive:
				current_target = b
				attack_timer.start()
				break

func _on_attack_timer() -> void:
	if current_target != null and current_target.is_alive:
		attack(current_target)
	else:
		current_target = null
		attack_timer.stop()

func attack(target: Unit) -> void:
	if not is_alive or target == null:
		return
	var final_damage := _calculate_damage(target)
	target.take_damage(final_damage, unit_type)

# ─────────────────────────────────────────────────────────────────────────────
# CALCUL DES DÉGÂTS avec modificateurs de type
# ─────────────────────────────────────────────────────────────────────────────
func _calculate_damage(target: Unit) -> float:
	var multiplier := 1.0
	var key := [unit_type, target.unit_type]
	if DAMAGE_MODIFIERS.has(key):
		multiplier = DAMAGE_MODIFIERS[key]
	return damage * multiplier

# ─────────────────────────────────────────────────────────────────────────────
# RECEVOIR DES DÉGÂTS
# ─────────────────────────────────────────────────────────────────────────────
func take_damage(amount: float, _attacker_type: UnitType = UnitType.FANTASSIN) -> void:
	if not is_alive:
		return
	hp -= amount
	emit_signal("unit_damaged", self, amount)
	if hp <= 0:
		hp = 0
		die()

# ─────────────────────────────────────────────────────────────────────────────
# MORT
# ─────────────────────────────────────────────────────────────────────────────
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	attack_timer.stop()
	emit_signal("unit_died", self)  # P1 écoute ce signal pour gérer la capture du camp
	queue_free()

# ─────────────────────────────────────────────────────────────────────────────
# UTILITAIRES
# ─────────────────────────────────────────────────────────────────────────────

# Retourne les PV sous forme de ratio 0.0 → 1.0 (utile pour la barre de vie de P3)
func get_hp_ratio() -> float:
	return hp / max_hp

# Vérifie si cette unité appartient au même joueur qu'un camp (Dictionary de Main.gd)
func belongs_to_camp(camp: Dictionary) -> bool:
	return camp.has("owner") and camp["owner"] == owner_id

# Initialise l'unité depuis un camp Dictionary (compatible avec Main.gd de P1)
func setup(p_owner_id: int) -> void:
	owner_id = p_owner_id
	hp = max_hp
	is_alive = true
