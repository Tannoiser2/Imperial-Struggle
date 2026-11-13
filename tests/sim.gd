extends SceneTree
## Partite automatiche: controlla che finiscano senza errori.
## godot --headless --path . -s res://tests/sim.gd -- [partite] [modo: caso|ia] [seme]

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var n := int(args[0]) if args.size() > 0 else 5
	var modo: String = args[1] if args.size() > 1 else "caso"
	var seme0 := int(args[2]) if args.size() > 2 else 1
	var vitt := {"FR": 0, "BR": 0}
	var motivi := {}
	var t0 := Time.get_ticks_msec()
	var mo := Motore.new()
	var ia = null
	if modo == "ia":
		ia = load("res://scripts/ia.gd").new(mo)
	var somma_pv := 0
	for k in n:
		var s := mo.nuova(seme0 + k * 7919)
		var r := RandomNumberGenerator.new()
		r.seed = seme0 + k
		var passi := 0
		var tipi := {}
		while s.fine == null and passi < 20000:
			if s.att == null:
				push_error("nessuna decisione in attesa: pila " + str(s.pila))
				break
			var opz: Array = s.att.opz
			if opz.is_empty():
				push_error("decisione senza opzioni: " + str(s.att))
				break
			tipi[s.att.tipo] = tipi.get(s.att.tipo, 0) + 1
			var i := 0
			if ia != null:
				i = ia.decidi(s)
			else:
				i = r.randi_range(0, opz.size() - 1)
				# a caso, ma senza girare all'infinito sulle azioni gratuite
				if s.att.tipo == "azione" and opz[i].a in ["pref", "rivela"] and r.randf() < 0.9:
					i = opz.size() - 1
			mo.applica(s, i)
			passi += 1
		if s.fine == null:
			push_error("partita %d non finita dopo %d passi (turno %d)" % [k, passi, s.turno])
			print(s.log.slice(-15))
			continue
		vitt[s.fine.vince] += 1
		somma_pv += s.pv
		var mot: String = s.fine.motivo.substr(0, 38)
		motivi[mot] = motivi.get(mot, 0) + 1
		print("partita %d: vince %s al turno %d, PV %d, %d decisioni. %s" % [k, s.fine.vince, s.turno, s.pv, passi, s.fine.motivo])
		if args.size() > 3 and args[3] == "log":
			for riga in s.log:
				print("   ", riga)
	print("Vittorie: Francia %d, Gran Bretagna %d. PV medi %.1f. Tempo %d ms" % [vitt.FR, vitt.BR, float(somma_pv) / max(1, n), Time.get_ticks_msec() - t0])
	print(motivi)
	quit()
