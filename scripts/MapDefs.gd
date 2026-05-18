extends Node

# Les 3 cartes disponibles dans le jeu
# Chaque carte a : un nom, une liste de camps, des forêts, et les données de la rivière
const MAPS = [
	{
		"name": "Plaine Centrale",
		"has_water": false,
		"land_zones": [],
		"camps": [
			{"name": "Fort Bleu",       "pos": Vector2(150, 200),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Citadelle Bleue", "pos": Vector2(150, 430),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Carrefour",       "pos": Vector2(440, 310),  "owner": -1, "units": 2, "income": 15},
			{"name": "Passage",         "pos": Vector2(710, 310),  "owner": -1, "units": 2, "income": 15},
			{"name": "Fort Rouge",      "pos": Vector2(1000, 200), "owner": 1,  "units": 5, "income": 10},
			{"name": "Citadelle Rouge", "pos": Vector2(1000, 430), "owner": 1,  "units": 5, "income": 10},
		],
		"forests": [
			Vector2(275, 148), Vector2(335, 292), Vector2(270, 442),
			Vector2(802, 148), Vector2(762, 418), Vector2(828, 452)
		],
		"river_x": 576,
		"bridge_y": 258,
		"bridge_h": 92
	},
	{
		"name": "Désert Brûlant",
		"has_water": false,
		"land_zones": [],
		"camps": [
			{"name": "Base Bleue",     "pos": Vector2(150, 170),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Oasis Bleue",    "pos": Vector2(200, 470),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Dune Nord",      "pos": Vector2(400, 130),  "owner": -1, "units": 3, "income": 20},
			{"name": "Oasis Centre",   "pos": Vector2(576, 310),  "owner": -1, "units": 2, "income": 25},
			{"name": "Dune Sud",       "pos": Vector2(400, 490),  "owner": -1, "units": 3, "income": 20},
			{"name": "Dune Nord Est",  "pos": Vector2(750, 130),  "owner": -1, "units": 3, "income": 20},
			{"name": "Dune Sud Est",   "pos": Vector2(750, 490),  "owner": -1, "units": 3, "income": 20},
			{"name": "Base Rouge",     "pos": Vector2(1000, 170), "owner": 1,  "units": 5, "income": 10},
			{"name": "Oasis Rouge",    "pos": Vector2(950, 470),  "owner": 1,  "units": 5, "income": 10},
		],
		"forests": [],
		"river_x": -1,
		"bridge_y": -1,
		"bridge_h": 0
	},
	{
		"name": "Grande Forêt",
		"has_water": false,
		"land_zones": [],
		"camps": [
			{"name": "Clairière Bleue", "pos": Vector2(150, 310), "owner": 0,  "units": 5, "income": 10},
			{"name": "Ruine Nord",      "pos": Vector2(310, 150), "owner": -1, "units": 3, "income": 20},
			{"name": "Ruine Sud",       "pos": Vector2(310, 470), "owner": -1, "units": 3, "income": 20},
			{"name": "Pont Central",    "pos": Vector2(576, 310), "owner": -1, "units": 4, "income": 25},
			{"name": "Ruine Nord Est",  "pos": Vector2(840, 150), "owner": -1, "units": 3, "income": 20},
			{"name": "Ruine Sud Est",   "pos": Vector2(840, 470), "owner": -1, "units": 3, "income": 20},
			{"name": "Clairière Rouge", "pos": Vector2(1000, 310), "owner": 1, "units": 5, "income": 10},
		],
		"forests": [
			# côté gauche
			Vector2(80,  120), Vector2(200, 200), Vector2(80,  320),
			Vector2(200, 450), Vector2(80,  530),
			# centre-gauche
			Vector2(350, 80),  Vector2(350, 220), Vector2(350, 390),
			Vector2(350, 530), Vector2(430, 180), Vector2(430, 460),
			# centre
			Vector2(490, 310), Vector2(576, 80),  Vector2(576, 130),
			Vector2(576, 520), Vector2(660, 310),
			# centre-droit
			Vector2(720, 80),  Vector2(720, 180), Vector2(720, 460),
			Vector2(720, 540), Vector2(800, 220), Vector2(800, 410),
			# côté droit
			Vector2(900, 100), Vector2(900, 320), Vector2(900, 530),
			Vector2(960, 200), Vector2(960, 450), Vector2(1060, 120),
			Vector2(1060, 530)
		],
		"river_x": -1,
		"bridge_y": -1,
		"bridge_h": 0
	},
	{
		"name": "Archipel des Tempêtes",
		"has_water": true,
		"land_zones": [
			{"x": 20,  "y": 50,  "w": 280, "h": 520},  # île gauche (J1)
			{"x": 420, "y": 30,  "w": 310, "h": 200},  # îlot nord (neutre)
			{"x": 440, "y": 300, "w": 270, "h": 200},  # îlot centre (neutre)
			{"x": 850, "y": 50,  "w": 280, "h": 520},  # île droite (J2)
		],
		"camps": [
			{"name": "Fort Côtier Bleu",  "pos": Vector2(130, 180),  "owner": 0,  "units": 5, "income": 10, "type": "normal"},
			{"name": "Port Bleu",          "pos": Vector2(200, 480),  "owner": 0,  "units": 3, "income": 10, "type": "port"},
			{"name": "Îlot Nord",          "pos": Vector2(575, 130),  "owner": -1, "units": 3, "income": 20, "type": "normal"},
			{"name": "Carrefour Marin",    "pos": Vector2(575, 400),  "owner": -1, "units": 2, "income": 25, "type": "normal"},
			{"name": "Fort Côtier Rouge",  "pos": Vector2(1020, 180), "owner": 1,  "units": 5, "income": 10, "type": "normal"},
			{"name": "Port Rouge",          "pos": Vector2(950, 480),  "owner": 1,  "units": 3, "income": 10, "type": "port"},
		],
		"forests": [],
		"river_x": -1,
		"bridge_y": -1,
		"bridge_h": 0
	}
]
