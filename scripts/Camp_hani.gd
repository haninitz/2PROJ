extends Node2D
class_name Camp

@export var camp_id = 0
@export var camp_name = "Spy Base"

@export var region_id = 0

@export var max_hp = 100
@export var income_value = 10

@export var is_port = false
@export var is_special_base = false

var current_hp = 0

# -1 = neutral base
var owner_id = -1

func _ready():
	current_hp = max_hp
	
	add_to_group("camps")

func change_owner(new_owner_id):
	owner_id = new_owner_id
	
	current_hp = max_hp
	
	print(camp_name, " has been secured by team ", owner_id)

func is_neutral():
	return owner_id == -1

func take_damage(damage, attacker_id):
	current_hp -= damage
	
	print(camp_name, " takes ", damage, " damage. Remaining HP: ", current_hp)
	
	if current_hp <= 0:
		change_owner(attacker_id)

func heal(amount):
	current_hp += amount
	
	if current_hp > max_hp:
		current_hp = max_hp

func get_income():
	return income_value
