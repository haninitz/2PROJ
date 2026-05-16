class_name Player

var id = 0
var team_name = ""
var color = Color.WHITE

var coins = 100

var owned_camps = []

func setup(new_id, new_team_name, new_color):
	id = new_id
	team_name = new_team_name
	color = new_color

func add_coins(amount):
	coins += amount

func spend_coins(amount):
	if coins >= amount:
		coins -= amount
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