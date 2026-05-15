extends Node

# Définition des 7 types d'unités disponibles dans le jeu
# Chaque type a : un label affiché, des HP, des dégâts, une portée, une vitesse et un prix
const TYPES = {
	"Infantry":  {"label": "Infanterie",  "hp": 30, "damage": 10, "range": 1, "speed": 3, "price": 10},
	"Support":   {"label": "Support",     "hp": 20, "damage": 8,  "range": 2, "speed": 3, "price": 15},
	"Heal":      {"label": "Soigneur",    "hp": 20, "damage": 0,  "range": 2, "speed": 2, "price": 20},
	"Range":     {"label": "Tireur",      "hp": 20, "damage": 15, "range": 3, "speed": 2, "price": 20},
	"Heavy":     {"label": "Blindé",      "hp": 60, "damage": 20, "range": 1, "speed": 1, "price": 30},
	"AntiArmor": {"label": "Anti-blindé", "hp": 25, "damage": 30, "range": 2, "speed": 2, "price": 25},
	"Mortar":    {"label": "Mortier",     "hp": 20, "damage": 25, "range": 4, "speed": 1, "price": 35},
}
