extends SceneTree
## Controlla che una partita salvata e ricaricata prosegua identica.
## godot --headless --path . -s res://tests/salva.gd

func _init() -> void:
	var mo := Motore.new()
	var ia := IA.new(mo)
	var s := mo.nuova(777)
	for k in 90:
		mo.applica(s, ia.decidi(s))
	var testo := var_to_str({"s": s})
	var s2: Dictionary = str_to_var(testo).s
	var uguali := true
	for k in 120:
		if s.fine != null or s.att == null:
			break
		var i := ia.decidi(s)
		# dopo il ricaricamento l'ordine delle opzioni può cambiare: si confronta la scelta, non l'indice
		var j := -1
		for x in s2.att.opz.size():
			if var_to_str(s2.att.opz[x]) == var_to_str(s.att.opz[i]):
				j = x
		if j < 0 or s.att.opz.size() != s2.att.opz.size():
			uguali = false
			break
		mo.applica(s, i)
		mo.applica(s2, j)
	if uguali and s.pv == s2.pv and var_to_str(s.band) == var_to_str(s2.band) and s.log.size() == s2.log.size():
		print("SALVA OK: %d caratteri, dopo il ricaricamento la partita prosegue identica (PV %d)." % [testo.length(), s.pv])
	else:
		push_error("SALVA: la partita ricaricata diverge")
	quit()
