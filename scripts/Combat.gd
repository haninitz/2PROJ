extends Node

func resolve(source: Camp, target: Camp) -> void:
	var att_units = source.units
	var def_units = target.units

	var att_stats = UnitDefs.TYPES[source.unit_type]
	var def_stats = UnitDefs.TYPES[target.unit_type]

	var force_att = att_units * att_stats["damage"] + randi() % (att_units * 4 + 1)
	var force_def = def_units * (def_stats["hp"] / 10) + randi() % (def_units * 3 + 1)

	if force_att >= force_def:
		var losses    = maxi(1, def_units / 2)
		target.owner     = source.owner
		target.units     = maxi(1, att_units - losses)
		target.unit_type = source.unit_type
		target.queue     = []
	else:
		var def_losses = maxi(0, att_units / 2 - 1)
		target.units = maxi(1, def_units - def_losses)

	source.units = 0
