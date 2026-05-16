extends Node

# Partagé avec Main.gd après init()
var players: Array = []
var camps:   Array = []
var regions: Array = []

const available_teams = [
	{"name": "Neon Squad",    "color": Color.CYAN},
	{"name": "Shadow Squad",  "color": Color.PURPLE},
	{"name": "Crimson Squad", "color": Color.RED},
	{"name": "Cyber Squad",   "color": Color.GREEN},
	{"name": "Phantom Squad", "color": Color.GRAY},
	{"name": "Eclipse Squad", "color": Color.BLACK},
	{"name": "Nova Squad",    "color": Color.ORANGE},
	{"name": "Storm Squad",   "color": Color.WHITE},
]

func init(p_players: Array, p_camps: Array, p_regions: Array) -> void:
	players = p_players
	camps   = p_camps
	regions = p_regions

func give_income(player_idx: int) -> void:
	var player = players[player_idx]
	for camp in camps:
		if camp.owner == player_idx:
			player.gold += camp.income
	for region in regions:
		if region_owner(region) == player_idx:
			player.gold += region["bonus"]

func calculate_income(player_idx: int) -> int:
	var total = 0
	for camp in camps:
		if camp.owner == player_idx:
			total += camp.income
	for region in regions:
		if region_owner(region) == player_idx:
			total += region["bonus"]
	return total

func capture_camp(camp_idx: int, new_owner: int) -> void:
	camps[camp_idx].owner      = new_owner
	camps[camp_idx].current_hp = camps[camp_idx].max_hp

func check_end_game() -> String:
	var count = [0, 0]
	for camp in camps:
		if camp.owner == 0:   count[0] += 1
		elif camp.owner == 1: count[1] += 1
	if count[0] == 0: return players[1].name
	if count[1] == 0: return players[0].name
	return ""

func region_owner(region: Dictionary) -> int:
	var owner = camps[region["camps"][0]].owner
	for idx in region["camps"]:
		if camps[idx].owner != owner:
			return -1
	return owner
