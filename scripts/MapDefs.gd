extends Node

const MAPS = [

	# ── Carte 1 : La Vie de Clover — Beverly Hills ────────────────────────────
	# Glamour, shopping, mode, palmiers — Sunset Boulevard coupe la ville
	{
		"name": "Beverly Hills (Clover)",
		"has_water": false,
		"land_zones": [],
		"camps": [
			{"name": "Villa Clover",       "pos": Vector2(150, 200),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Boutique WOOHP",     "pos": Vector2(150, 430),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Beverly Hills High", "pos": Vector2(440, 310),  "owner": -1, "units": 2, "income": 15},
			{"name": "Sunset Mall",        "pos": Vector2(710, 310),  "owner": -1, "units": 2, "income": 15},
			{"name": "QG de Mandy",        "pos": Vector2(1000, 200), "owner": 1,  "units": 5, "income": 10},
			{"name": "Repaire LAMOS",      "pos": Vector2(1000, 430), "owner": 1,  "units": 5, "income": 10},
		],
		"forests": [
			Vector2(275, 148), Vector2(335, 292), Vector2(270, 442),
			Vector2(802, 148), Vector2(762, 418), Vector2(828, 452)
		],
		"river_x": 576,
		"bridge_y": 258,
		"bridge_h": 92
	},

	# ── Carte 2 : La Jungle Techno de Sam ────────────────────────────────────
	# Intelligente, nature + high-tech — labos cachés dans une forêt dense
	{
		"name": "Jungle Techno (Sam)",
		"has_water": false,
		"land_zones": [],
		"camps": [
			{"name": "Labo de Sam",         "pos": Vector2(150, 310),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Bibliothèque Secrète", "pos": Vector2(310, 150),  "owner": -1, "units": 3, "income": 20},
			{"name": "Terminal Vert",        "pos": Vector2(310, 470),  "owner": -1, "units": 3, "income": 20},
			{"name": "Nexus Techno",         "pos": Vector2(576, 310),  "owner": -1, "units": 4, "income": 25},
			{"name": "Base de Données",      "pos": Vector2(840, 150),  "owner": -1, "units": 3, "income": 20},
			{"name": "Relais WOOHP",         "pos": Vector2(840, 470),  "owner": -1, "units": 3, "income": 20},
			{"name": "Base Ennemie",         "pos": Vector2(1000, 310), "owner": 1,  "units": 5, "income": 10},
		],
		"forests": [
			Vector2(80,  120), Vector2(200, 200), Vector2(80,  320),
			Vector2(200, 450), Vector2(80,  530),
			Vector2(350, 80),  Vector2(350, 220), Vector2(350, 390),
			Vector2(350, 530), Vector2(430, 180), Vector2(430, 460),
			Vector2(490, 310), Vector2(576, 80),  Vector2(576, 520),
			Vector2(660, 310), Vector2(720, 80),  Vector2(720, 180),
			Vector2(720, 460), Vector2(720, 540), Vector2(800, 220),
			Vector2(800, 410), Vector2(900, 100), Vector2(900, 320),
			Vector2(900, 530), Vector2(960, 200), Vector2(960, 450),
			Vector2(1060, 120), Vector2(1060, 530)
		],
		"river_x": -1,
		"bridge_y": -1,
		"bridge_h": 0
	},

	# ── Carte 3 : L'Île d'Alex ────────────────────────────────────────────────
	# Sport, tropical, animaux, plage — archipel entouré d'océan
	{
		"name": "Île Tropicale (Alex)",
		"has_water": true,
		"land_zones": [
			{"x": 20,  "y": 50,  "w": 280, "h": 520},
			{"x": 420, "y": 30,  "w": 310, "h": 200},
			{"x": 440, "y": 300, "w": 270, "h": 200},
			{"x": 850, "y": 50,  "w": 280, "h": 520},
		],
		"camps": [
			{"name": "Plage d'Alex",      "pos": Vector2(130, 180),  "owner": 0,  "units": 5, "income": 10, "type": "normal"},
			{"name": "Port Aventure",     "pos": Vector2(200, 480),  "owner": 0,  "units": 3, "income": 10, "type": "port"},
			{"name": "Arène Tropicale",   "pos": Vector2(575, 130),  "owner": -1, "units": 3, "income": 20, "type": "normal"},
			{"name": "Île aux Animaux",   "pos": Vector2(575, 400),  "owner": -1, "units": 2, "income": 25, "type": "normal"},
			{"name": "Fort Adverse",      "pos": Vector2(1020, 180), "owner": 1,  "units": 5, "income": 10, "type": "normal"},
			{"name": "Dock Ennemi",       "pos": Vector2(950, 480),  "owner": 1,  "units": 3, "income": 10, "type": "port"},
		],
		"forests": [],
		"river_x": -1,
		"bridge_y": -1,
		"bridge_h": 0
	},

	# ── Carte 4 : Opération WOOHP — Le QG de Jerry ───────────────────────────
	# Espionnage, base souterraine, couloirs secrets — QG infiltré par LAMOS
	{
		"name": "QG WOOHP (Jerry)",
		"has_water": false,
		"land_zones": [],
		"camps": [
			{"name": "Bureau de Jerry",    "pos": Vector2(150, 310),  "owner": 0,  "units": 5, "income": 10},
			{"name": "Salle des Gadgets",  "pos": Vector2(310, 150),  "owner": -1, "units": 3, "income": 20},
			{"name": "Armurerie WOOHP",    "pos": Vector2(310, 470),  "owner": -1, "units": 3, "income": 20},
			{"name": "Centre de Contrôle", "pos": Vector2(576, 310),  "owner": -1, "units": 4, "income": 25},
			{"name": "Salle d'Entraîn.",   "pos": Vector2(840, 150),  "owner": -1, "units": 3, "income": 20},
			{"name": "Archives WOOHP",     "pos": Vector2(840, 470),  "owner": -1, "units": 3, "income": 20},
			{"name": "Secteur LAMOS",      "pos": Vector2(1000, 310), "owner": 1,  "units": 5, "income": 10},
		],
		"forests": [
			Vector2(80,  120), Vector2(200, 200), Vector2(80,  320),
			Vector2(200, 450), Vector2(80,  530),
			Vector2(350, 80),  Vector2(350, 220), Vector2(350, 390),
			Vector2(350, 530), Vector2(430, 180), Vector2(430, 460),
			Vector2(490, 310), Vector2(576, 80),  Vector2(576, 520),
			Vector2(660, 310), Vector2(720, 80),  Vector2(720, 180),
			Vector2(720, 460), Vector2(720, 540), Vector2(800, 220),
			Vector2(800, 410), Vector2(900, 100), Vector2(900, 320),
			Vector2(900, 530), Vector2(960, 200), Vector2(960, 450),
			Vector2(1060, 120), Vector2(1060, 530)
		],
		"river_x": -1,
		"bridge_y": -1,
		"bridge_h": 0
	}
]
