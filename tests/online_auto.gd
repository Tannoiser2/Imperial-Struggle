extends SceneTree
## Un capo di una partita online di prova (host oppure ospite) sul finto Firebase: gioca con l'IA
## le proprie mosse, legge dalla rete quelle dell'altro e alla fine stampa l'impronta della partita.
## Lo lancia tests/prova_online.sh.

func _init() -> void:
	_gioca.call_deferred()

func _gioca() -> void:
	var ruolo := OS.get_environment("IS_RUOLO")
	var file_codice := OS.get_environment("IS_CODICE")
	var net := Rete.new()
	root.add_child(net)
	var mo := Motore.new()
	var ia := IA.new(mo)
	var codice := ""
	var lato := "FR"
	var seme := 0
	if ruolo == "host":
		codice = await net.create_room("Host", {"lato_host": "FR"})
		if codice == "":
			print("IS ERRORE creazione stanza: ", net.last_error)
			quit()
			return
		var f := FileAccess.open(file_codice, FileAccess.WRITE)
		f.store_string(codice)
		f.close()
		while true:
			await create_timer(0.3).timeout
			var room := await net.room(codice)
			if Rete._as_dict(room.get("seats", {})).has("1"):
				break
		seme = 20261114
		await net.start_room(codice, {"seme": seme})
	else:
		lato = "BR"
		while not FileAccess.file_exists(file_codice):
			await create_timer(0.3).timeout
		await create_timer(0.3).timeout
		codice = FileAccess.get_file_as_string(file_codice).strip_edges()
		var posto := await net.join_room(codice, "Ospite", 2)
		if posto != 1:
			print("IS ERRORE ingresso: posto ", posto, " ", net.last_error)
			quit()
			return
		while true:
			var r2 := await net.room(codice)
			if str(r2.get("status", "")) == "playing":
				seme = int(JSON.parse_string(str(r2.get("game", "{}")))["seme"])
				break
			await create_timer(0.3).timeout
	var s := mo.nuova(seme)
	var limite := int(OS.get_environment("IS_MOSSE")) if OS.has_environment("IS_MOSSE") else 140
	while s.fine == null and s.att != null and s.nd < limite:
		if s.att.chi == lato:
			var i := ia.decidi(s)
			if not await net.post_decision(codice, s.nd, {"i": i, "t": s.att.tipo}):
				print("IS ERRORE invio mossa: ", net.last_error)
				break
			mo.applica(s, i)
		else:
			var d = await net.get_decision(codice, s.nd)
			if d is Dictionary and d.has("i"):
				mo.applica(s, int(d["i"]))
			else:
				await create_timer(0.15).timeout
	print("IS %s: %d mosse, turno %d, PV %d, impronta %d" % [ruolo, s.nd, s.turno, s.pv, var_to_str([s.band, s.confl, s.g, s.rng]).hash()])
	quit()
