extends Node
class_name GameManager

const PlayerScript = preload("res://scripts/Player.gd")
const CampScript = preload("res://scripts/Camp.gd")

var players = []
var camps = []

var player_count = 2
var map_index : int = 0

# Régions : region_id -> player_id qui la possède (-1 = personne)
var _owned_regions : Dictionary = {}

var available_teams = [
	{
		"name": "Neon Squad",
		"color": Color.CYAN
	},
	{
		"name": "Crimson Squad",
		"color": Color.RED
	},
	{
		"name": "Shadow Squad",
		"color": Color.PURPLE
	},
	{
		"name": "Cyber Squad",
		"color": Color.GREEN
	},
	{
		"name": "Phantom Squad",
		"color": Color.GRAY
	},
	{
		"name": "Eclipse Squad",
		"color": Color.BLACK
	},
	{
		"name": "Nova Squad",
		"color": Color.ORANGE
	},
	{
		"name": "Ghost Squad",
		"color": Color.WHITE
	}
]

var income_timer = 0.0
var income_interval = 10.0

func _ready():
	start_game()

func _process(delta):
	income_timer += delta
	
	if income_timer >= income_interval:
		give_income()
		income_timer = 0.0

func start_game():
	create_players()
	load_camps()
	assign_starting_camps()
	
	print("Mission launched. Spy teams are entering the field to expand their territory.")

func create_players():
	players.clear()
	
	if player_count > available_teams.size():
		print("Too many players selected. Maximum is ", available_teams.size())
		player_count = available_teams.size()
	
	for i in range(player_count):
		var team_data = available_teams[i]
		
		var player = PlayerScript.new(team_data["name"])
		if player.has_method("setup"):
			player.setup(i + 1, team_data["name"], team_data["color"])
		
		players.append(player)

func load_camps():
	camps.clear()
	
	for camp in get_tree().get_nodes_in_group("camps"):
		camps.append(camp)

func assign_starting_camps():
	if camps.size() < players.size():
		print("Not enough spy bases for all teams.")
		return
	
	for i in range(players.size()):
		var player = players[i]
		var camp = camps[i]
		
		camp.change_owner(player.id)
		player.add_camp(camp)

func give_income():
	Sound.play("income_chime")
	for player in players:
		var total_income = calculate_player_income(player)
		player.add_gold(total_income)
		print(player.player_name, " gains ", total_income, " gold from controlled territory. Total gold: ", player.gold)

func calculate_player_income(player):
	var total = 0
	
	for camp in camps:
		if camp.owner_id == player.id:
			total += camp.get_income()
	
	return total

func capture_camp(camp, new_owner_id):
	var old_owner = find_player_by_id(camp.owner_id)
	var new_owner = find_player_by_id(new_owner_id)

	if old_owner != null:
		old_owner.remove_camp(camp)

	camp.change_owner(new_owner_id)

	if new_owner != null:
		new_owner.add_camp(camp)

	check_regions()
	check_end_game()

func find_player_by_id(player_id):
	for player in players:
		if player.id == player_id:
			return player
	
	return null

func check_end_game():
	var alive_players = []
	
	for player in players:
		if not player.is_defeated():
			alive_players.append(player)
	
	if alive_players.size() == 1:
		print(alive_players[0].player_name, " wins the operation and controls the territory!")

# =============================================================================
#  RÉGIONS
# =============================================================================

func check_regions() -> void:
	var RegionDefs = load("res://scripts/RegionDefs.gd")
	var regions : Array = RegionDefs.get_regions(map_index)

	for region in regions:
		var rid : int = region["id"]
		var camp_ids : Array = region["camp_ids"]

		# Trouve quel joueur possède tous les camps de cette région
		var owner_id : int = _get_region_owner(camp_ids)

		var prev_owner : int = _owned_regions.get(rid, -1)

		if owner_id != prev_owner:
			# Un joueur vient de perdre la région
			if prev_owner != -1:
				print("Region ", region["name"], " lost by player ", prev_owner)

			# Un joueur vient de conquérir la région
			if owner_id != -1:
				var player = find_player_by_id(owner_id)
				if player:
					player.add_gold(region["bonus_gold"])
					print("Region ", region["name"], " captured by ", player.player_name,
						" ! Bonus: +", region["bonus_gold"], " gold")

			_owned_regions[rid] = owner_id


func _get_region_owner(camp_ids: Array) -> int:
	if camp_ids.is_empty():
		return -1

	var first_owner : int = -2  # valeur sentinelle

	for camp in camps:
		if camp.camp_id in camp_ids:
			if first_owner == -2:
				first_owner = camp.owner_id
			elif camp.owner_id != first_owner:
				return -1  # pas tous au même joueur

	if first_owner == -2 or first_owner == -1:
		return -1

	return first_owner