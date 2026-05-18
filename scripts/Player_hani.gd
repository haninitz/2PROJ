class_name Player

var id = 0
var player_name = ""
var color = Color.WHITE

var gold = 0

var owned_camps = []

func setup(new_id, new_player_name, new_color):
	id = new_id
	player_name = new_player_name
	color = new_color

func add_gold(amount):
	gold += amount

func spend_gold(amount):
	if gold >= amount:
		gold -= amount
		return true
	
	return false

func add_camp(camp):
	if not owned_camps.has(camp):
		owned_camps.append(camp)

func remove_camp(camp):
	if owned_camps.has(camp):
		owned_camps.erase(camp)

func is_defeated():
	return owned_camps.size() == 0