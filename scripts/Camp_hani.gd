extends Node2D

@export var camp_id        : int    = 0
@export var camp_name      : String = "Spy Base"
@export var region_id      : int    = 0
@export var max_hp         : int    = 100
@export var income_value   : int    = 10
@export var is_port        : bool   = false
@export var is_special_base: bool   = false

# Champs utilisés par le game loop (Main.gd) et le HUD
var current_hp        : int    = 0
var owner_id          : int    = -1   # -1 = neutre
var units             : int    = 3    # nombre d'unités présentes
var unit_type         : String = "infantry"
var production_queue  : Array  = []   # Array[{unit_type, remaining}]

func _ready() -> void:
	current_hp = max_hp
	add_to_group("camps")

# ── Propriété income (compat Renderer.gd qui lit camp.income) ─────────────────
var income : int :
	get: return income_value

# ── Propriété pos (compat Renderer.gd qui lit camp.pos) ──────────────────────
var pos : Vector2 :
	get: return global_position

# ── Propriété type (compat Renderer.gd) ──────────────────────────────────────
var type : String :
	get: return "port" if is_port else "normal"

# ── Alias queue (compat Renderer.gd qui lit camp.queue) ───────────────────────
var queue : Array :
	get: return production_queue
	set(v): production_queue = v

func change_owner(new_owner_id: int) -> void:
	owner_id  = new_owner_id
	current_hp = max_hp
	Sound.play("capture")
	print(camp_name, " secured by team ", owner_id)

func is_neutral() -> bool:
	return owner_id == -1

func take_damage(damage: int, attacker_id: int) -> void:
	current_hp -= damage
	if current_hp <= 0:
		change_owner(attacker_id)

func heal(amount: int) -> void:
	current_hp = mini(current_hp + amount, max_hp)

func get_income() -> int:
	return income_value
