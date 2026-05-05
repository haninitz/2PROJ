extends Node

# Résout un combat entre deux camps.
# Le camp source attaque le camp target.
# Les stats des types d'unités influencent le résultat.
func resolve(source: Dictionary, target: Dictionary) -> void:
	var att = source["units"]
	var d = target["units"]

	# On récupère les stats du type d'unité de chaque camp
	var att_stats = UnitDefs.TYPES[source["unit_type"]]
	var def_stats = UnitDefs.TYPES[target["unit_type"]]

	# Calcul de la force de combat avec un bonus aléatoire
	var force_att = att * att_stats["damage"] + randi() % (att * 4 + 1)
	var force_def = d * (def_stats["hp"] / 10) + randi() % (d * 3 + 1)

	if force_att >= force_def:
		# L'attaquant gagne : il capture le camp
		var losses = maxi(1, d / 2)
		target["owner"] = source["owner"]
		target["units"] = maxi(1, att - losses)
		target["unit_type"] = source["unit_type"]
		target["queue"] = []  # la file de recrutement est perdue lors de la capture
	else:
		# Le défenseur gagne : il perd quelques unités
		var def_losses = maxi(0, att / 2 - 1)
		target["units"] = maxi(1, d - def_losses)

	# L'attaquant perd toutes ses unités dans les deux cas
	source["units"] = 0
