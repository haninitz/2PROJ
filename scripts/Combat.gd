extends Node

# Résout un combat entre deux camps.
# source : camp attaquant (ses unités tombent à 0 après l'attaque)
# target : camp défenseur (change de propriétaire si l'attaquant gagne)
func resolve(source: Dictionary, target: Dictionary) -> void:
	var att: int = source["units"]
	var d: int = target["units"]

	var force_att := att * 10 + randi() % (att * 4 + 1)
	var force_def := d * 10 + randi() % (d * 3 + 1)

	if force_att >= force_def:
		var losses := maxi(1, d / 2)
		target["owner"] = source["owner"]
		target["units"] = maxi(1, att - losses)
	else:
		var def_losses := maxi(0, att / 2 - 1)
		target["units"] = maxi(1, d - def_losses)

	source["units"] = 0
