## La mappa: disegna il tabellone, le bandiere, le Squadre e i segnalini.
## Si sposta trascinando (mouse o un dito), si ingrandisce con la rotella o pizzicando con due dita.
class_name Plancia
extends Control

signal spazio_cliccato(id: String)
signal spazio_indicato(id: String)

const S := DatiGen.SPAZI
const ML := float(DatiGen.MAPPA_L)
const MH := float(DatiGen.MAPPA_H)
const K := 4096.0 / 5100.0
const RAGGIO := 46.0

var tex_mappa: Texture2D
var tex := {}
var font: Font
var s: Dictionary = {}
var zoom := 0.4
var origine := Vector2.ZERO
## area dello schermo non coperta dai pannelli (per centrare la mappa)
var area := Rect2(0, 0, 1920, 1080)
var evidenziati := {}   # id -> Color
var lampeggi := {}      # id -> secondi rimasti
var consigliato := ""   # spazio della mossa consigliata dalla guida
var tempo := 0.0
var tocchi := {}
var trascina := false
var premuto := false
var mosso := 0.0
var pizzico_dist := 0.0
var sopra := ""
var adattata := false

func _ready() -> void:
	tex_mappa = load("res://assets/mappa/mappa.jpg")
	for n in ["band_a", "band_b", "band_USA", "squadra_FR", "squadra_BR", "conflitto", "conflitto_piu", "danno", "esaurito", "pv",
			"debito_FR", "debito_BR", "limite_FR", "limite_BR", "trattati_FR", "trattati_BR", "turno", "iniz_FR", "iniz_BR",
			"ugonotti", "ugonotti_usati", "giac_vittoria", "giac_sconfitta", "townshend",
			"premio_0t", "premio_1t", "premio_1", "premio_2", "premio_3"]:
		tex[n] = load("res://assets/pezzi/%s.png" % n)
	for v in DatiGen.VANT_IMG:
		tex["v:" + v] = load("res://assets/pezzi/%s.png" % DatiGen.VANT_IMG[v])
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

func adatta() -> void:
	zoom = min(area.size.x / ML, area.size.y / MH)
	origine = area.position + (area.size - Vector2(ML, MH) * zoom) / 2.0
	adattata = true
	queue_redraw()

func centra_su(id: String) -> void:
	var p := Vector2(S[id].x, S[id].y)
	origine = area.get_center() - p * zoom
	_limita()
	queue_redraw()

func _limita() -> void:
	var zmin: float = min(area.size.x / ML, area.size.y / MH) * 0.85
	zoom = clampf(zoom, zmin, 2.4)
	var dim := Vector2(ML, MH) * zoom
	var c := area.get_center()
	origine.x = clampf(origine.x, c.x - dim.x, c.x)
	origine.y = clampf(origine.y, c.y - dim.y, c.y)

func a_mappa(p: Vector2) -> Vector2:
	return (p - origine) / zoom

func _zoom_su(p: Vector2, fattore: float) -> void:
	var prima := a_mappa(p)
	zoom *= fattore
	_limita()
	origine = p - prima * zoom
	_limita()
	queue_redraw()

func _spazio_a(p: Vector2) -> String:
	var m := a_mappa(p)
	var best := ""
	var bd := RAGGIO * RAGGIO * 1.5
	for id in S:
		var d := Vector2(S[id].x, S[id].y).distance_squared_to(m)
		if d < bd:
			bd = d
			best = id
	return best

func _gui_input(e: InputEvent) -> void:
	# Un dito (o il mouse) trascina e tocca: arriva come mouse emulato. Due dita: pizzico per lo zoom.
	if e is InputEventScreenTouch:
		if e.pressed:
			tocchi[e.index] = e.position
		else:
			tocchi.erase(e.index)
		if tocchi.size() == 2:
			var v: Array = tocchi.values()
			pizzico_dist = (v[0] as Vector2).distance_to(v[1])
			mosso = 999.0
	elif e is InputEventScreenDrag:
		tocchi[e.index] = e.position
		if tocchi.size() >= 2:
			var v2: Array = tocchi.values()
			var d: float = (v2[0] as Vector2).distance_to(v2[1])
			if pizzico_dist > 10.0 and d > 10.0:
				_zoom_su(((v2[0] as Vector2) + (v2[1] as Vector2)) / 2.0, d / pizzico_dist)
			pizzico_dist = d
			mosso = 999.0
	elif e is InputEventMagnifyGesture:
		_zoom_su(e.position, e.factor)
	elif e is InputEventPanGesture:
		origine -= e.delta * 12.0
		_limita()
		queue_redraw()
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP and e.pressed:
			_zoom_su(e.position, 1.12)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN and e.pressed:
			_zoom_su(e.position, 1.0 / 1.12)
		elif e.button_index == MOUSE_BUTTON_LEFT or e.button_index == MOUSE_BUTTON_RIGHT or e.button_index == MOUSE_BUTTON_MIDDLE:
			if e.pressed:
				premuto = true
				mosso = 0.0
			else:
				if premuto and mosso < 10.0 and e.button_index == MOUSE_BUTTON_LEFT and tocchi.size() < 2:
					var id2 := _spazio_a(e.position)
					if id2 != "":
						spazio_cliccato.emit(id2)
				premuto = false
	elif e is InputEventMouseMotion:
		if premuto:
			if tocchi.size() < 2:
				mosso += e.relative.length()
				origine += e.relative
				_limita()
				queue_redraw()
		else:
			var id3 := _spazio_a(e.position)
			if id3 != sopra:
				sopra = id3
				spazio_indicato.emit(id3)
				queue_redraw()

func _process(dt: float) -> void:
	tempo += dt
	if not adattata and size.x > 10:
		adatta()
	var ridisegna := not evidenziati.is_empty() or consigliato != ""
	for id in lampeggi.keys():
		lampeggi[id] -= dt
		if lampeggi[id] <= 0.0:
			lampeggi.erase(id)
		ridisegna = true
	if ridisegna:
		queue_redraw()

func _pezzo(nome: String, centro: Vector2, lato: float, alpha := 1.0) -> void:
	var t: Texture2D = tex[nome]
	var dim := Vector2(lato, lato * t.get_height() / t.get_width())
	draw_texture_rect(t, Rect2(centro - dim / 2.0, dim), false, Color(1, 1, 1, alpha))

func _disco(c: Vector2, r: float, col: Color, testo: String) -> void:
	draw_circle(c, r, Color(0.08, 0.06, 0.05))
	draw_circle(c, r - 3.0, col)
	if font != null:
		var fs := int(r * 1.15)
		var w := font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, c + Vector2(-w / 2.0, fs * 0.36), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1))

func _casella(v: int) -> Vector2:
	# Tracciato generale: 0-6 nella prima riga, poi sei caselle per riga
	v = clampi(v, 0, 30)
	var x0 := 4335.0 * K
	var passo := 117.6 * K
	var y0 := 2652.0 * K
	var py := 120.0 * K
	if v <= 6:
		return Vector2(x0 + (v - 1) * passo, y0)
	var r := (v - 7) / 6
	var c := (v - 7) % 6
	return Vector2(x0 + c * passo, y0 + (r + 1) * py)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.05, 0.09))
	draw_set_transform(origine, 0.0, Vector2(zoom, zoom))
	draw_texture_rect(tex_mappa, Rect2(0, 0, ML, MH), false)
	if s.is_empty():
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	var onda := 0.5 + 0.5 * sin(tempo * 5.0)
	# spazi non ancora disponibili
	for id in S:
		var d: Dictionary = S[id]
		var c := Vector2(d.x, d.y)
		var o: String = s.band.get(id, "")
		if o == "FR" or o == "BR":
			if d.tipo == "N":
				_pezzo("squadra_" + o, c, 104.0)
			else:
				_pezzo("band_b" if o == "FR" else "band_a", c, 74.0)
		elif o == "US":
			_pezzo("band_USA", c, 74.0)
		if s.danno.has(id):
			_pezzo("danno", c + Vector2(34, 30), 60.0)
		if s.confl.has(id):
			_pezzo("conflitto_piu" if s.confl[id] == 2 else "conflitto", c + Vector2(-34, 30), 62.0)
		if s.ugo.has(id):
			_pezzo("ugonotti_usati" if s.ugo[id] else "ugonotti", c + Vector2(40, -36), 50.0)
		if evidenziati.has(id):
			var col: Color = evidenziati[id]
			var sp: float = max(7.0, 3.6 / zoom)
			draw_arc(c, RAGGIO + 6.0 + sp * 0.5 + 5.0 * onda, 0, TAU, 40, Color(0, 0, 0, 0.55), sp + 4.0, true)
			draw_arc(c, RAGGIO + 6.0 + sp * 0.5 + 5.0 * onda, 0, TAU, 40, Color(col.r, col.g, col.b, 0.98), sp, true)
		if id == consigliato:
			# la mossa consigliata dalla guida: doppio anello bianco e oro che pulsa
			var rr := RAGGIO + 26.0 + 10.0 * onda
			draw_arc(c, rr, 0, TAU, 48, Color(0, 0, 0, 0.6), 14.0, true)
			draw_arc(c, rr, 0, TAU, 48, Color(1, 1, 1, 0.95), 9.0, true)
			draw_arc(c, rr + 9.0, 0, TAU, 48, Color(1, 0.8, 0.15, 0.95), 5.0, true)
		if lampeggi.has(id):
			draw_arc(c, RAGGIO + 20.0, 0, TAU, 40, Color(1, 0.95, 0.4, clampf(lampeggi[id], 0.0, 1.0)), 9.0, true)
		if id == sopra:
			draw_arc(c, RAGGIO + 2.0, 0, TAU, 40, Color(1, 1, 1, 0.8), 3.0, true)
	# Vantaggi: le tessere originali sui loro spazi, con il segnalino Esaurito quando sono usate
	for v in s.vant:
		if not DatiGen.VANT_POS.has(v):
			continue
		var st: Dictionary = s.vant[v]
		var pv: Array = DatiGen.VANT_POS[v]
		var c2 := Vector2(pv[0], pv[1])
		_pezzo("v:" + v, c2, 98.0)
		if st.di != "":
			var colv := Color(0.12, 0.3, 0.7) if st.di == "FR" else Color(0.75, 0.12, 0.1)
			draw_rect(Rect2(c2 - Vector2(52, 52), Vector2(104, 104)), colv, false, 7.0)
			_pezzo("band_b" if st.di == "FR" else "band_a", c2 + Vector2(44, -44), 38.0)
		if st.es:
			_pezzo("esaurito", c2 + Vector2(10, 10), 70.0)
	# Premi regionali: le tessere Premio originali
	for r in s.premi:
		var nomi := {"NA": "North America", "EU": "Europe", "IN": "India", "CA": "Caribbean"}
		var pp: Array = DatiGen.PREMI_POS[nomi[r]]
		var c3 := Vector2(pp[0], pp[1])
		var pr: Array = Dati.PREMI[s.premi[r]]
		var nome_p := "premio_%d%s" % [pr[0], "t" if pr[1] > 0 else ""]
		_pezzo(nome_p, c3, 96.0)
		var vinto: String = s.premi_vinti.get(r, "-")
		if vinto == "FR" or vinto == "BR":
			_pezzo("band_b" if vinto == "FR" else "band_a", c3 + Vector2(40, -40), 44.0)
	# Domanda globale: cornice sulle merci richieste nella colonna dell'era
	var righe := {"pelli": 399.0, "spezie": 440.0, "pesce": 481.0, "tabacco": 521.0, "zucchero": 562.0, "cotone": 603.0}
	var colonne := [2437.0, 2611.0, 2782.0]
	for m in s.domanda:
		var cc := Vector2(colonne[s.era - 1], righe[m]) * K
		draw_rect(Rect2(cc - Vector2(66, 15), Vector2(132, 30)), Color(0.8, 0.1, 0.1, 0.9), false, 4.0)
		draw_circle(Vector2(2275.0, righe[m]) * K, 7.0, Color(0.8, 0.1, 0.1))
	if s.townshend != "":
		_pezzo("townshend", Vector2(2215.0, righe[s.townshend]) * K, 40.0)
	# Tracciato dei turni e Iniziativa
	var y_turni := [0.0, 2520.0, 2430.0, 2305.0, 2140.0, 1985.0, 1825.0]
	var guerra_in_corso: bool = s.fase == "Guerra"
	var y_guerre := {1: 2470.0, 3: 2230.0, 4: 2075.0, 5: 1905.0}
	if guerra_in_corso and y_guerre.has(s.turno):
		_pezzo("turno", Vector2(150.0, y_guerre[s.turno]), 74.0)
	else:
		_pezzo("turno", Vector2(262.0, y_turni[clampi(s.turno, 1, 6)]), 74.0)
	_pezzo("iniz_" + s.iniz, Vector2(450.0, 2470.0), 96.0)
	for i in s.jac_vitt:
		_pezzo("giac_vittoria", Vector2(262.0 + 40.0 * i, y_turni[2] if i == 0 else y_turni[4]) + Vector2(44, 0), 50.0)
	if s.jac_fine and s.jac_vitt == 0:
		_pezzo("giac_sconfitta", Vector2(306.0, y_turni[4]), 50.0)
	# Tracciato generale: i segnalini originali di PV, Debito, Limite e Punti Trattato
	var occupate := {}
	var segn := [["pv", s.pv]]
	for p in ["FR", "BR"]:
		var g: Dictionary = s.g[p]
		segn.append(["limite_" + p, g.lim])
		segn.append(["debito_" + p, g.deb])
		segn.append(["trattati_" + p, g.trp])
	for x in segn:
		var cas: int = clampi(x[1], 0, 30)
		var k: int = occupate.get(cas, 0)
		occupate[cas] = k + 1
		var sposta: Vector2 = [Vector2(0, 0), Vector2(-20, -18), Vector2(20, 18), Vector2(20, -18), Vector2(-20, 18), Vector2(0, -26), Vector2(0, 26)][min(k, 6)]
		_pezzo(x[0], _casella(cas) + sposta, 58.0 if k == 0 else 50.0)
	# Riquadro della Marina
	var nb := Vector2(2054.0, 1835.0) * K
	for p in ["FR", "BR"]:
		for i in s.g[p].sq_box:
			_pezzo("squadra_" + p, nb + Vector2(-190 + i * 56, -24 if p == "FR" else 44), 68.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
