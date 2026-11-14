## La scheda originale di una guerra, con le tessere Guerra originali nei riquadri «War Tiles»
## (blu per la Francia, rosso per la Gran Bretagna). Le tessere che non puoi vedere sono coperte.
class_name SchedaGuerra
extends Control

const L := 1129.0
const A := 884.0
## centri dei riquadri [Francia, Gran Bretagna] di ogni teatro, in pixel della scheda
const RIQUADRI := {
	"WSS": [[Vector2(156, 223), Vector2(320, 223)], [Vector2(667, 223), Vector2(831, 223)], [Vector2(157, 586), Vector2(321, 586)], [Vector2(668, 586), Vector2(831, 586)]],
	"WAS": [[Vector2(156, 207), Vector2(320, 207)], [Vector2(667, 207), Vector2(831, 207)], [Vector2(156, 530), Vector2(321, 530)], [Vector2(667, 521), Vector2(831, 521)]],
	"7YW": [[Vector2(156, 223), Vector2(320, 223)], [Vector2(667, 223), Vector2(831, 223)], [Vector2(156, 585), Vector2(321, 585)], [Vector2(668, 586), Vector2(831, 585)]],
	"AWI": [[Vector2(157, 223), Vector2(320, 223)], [Vector2(668, 223), Vector2(831, 223)], [Vector2(668, 527), Vector2(831, 527)]],
}

## altezza (in pixel della scheda) delle righe della tabella «Margin of Victory» di ogni teatro;
## dove la tabella è doppia, una per chi vince
const RIGHE := {
	"WSS": [[335, 354, 371], [338, 356, 374], [703, 721, 739], [705, 723, 740]],
	"WAS": [[315, 332], [315, 332], [639, 657, 675], {"FR": [616, 636, 652], "BR": [693, 709, 729]}],
	"7YW": [[336, 370, 401], [338, 356, 373], [695, 713, 730], [732, 750, 767]],
	"AWI": [{"FR": [338, 357, 374], "BR": [430, 447, 465]}, [338, 356], [645, 663, 681]],
}
## mostra tutte le righe (solo per controllare le posizioni)
var prova_righe := false

var gid := ""
## per ogni teatro: {"FR": {...}, "BR": {...}} con base, bonus, extra, vedi (scoperte), forza (testo), vince
var teatri: Array = []
var font: Font
var tex_scheda: Texture2D
var cache := {}

func imposta(g: String, tt: Array, f: Font, largh: float) -> void:
	gid = g
	teatri = tt
	font = f
	tex_scheda = load("res://assets/mappa/guerra_%s.jpg" % g)
	custom_minimum_size = Vector2(largh, largh * A / L)
	queue_redraw()

func _t(nome: String) -> Texture2D:
	if not cache.has(nome):
		cache[nome] = load("res://assets/pezzi/%s.png" % nome)
	return cache[nome]

func _tessera(nome: String, centro: Vector2, largh: float) -> void:
	var t := _t(nome)
	var dim := Vector2(largh, largh * t.get_height() / t.get_width())
	draw_texture_rect(t, Rect2(centro - dim / 2.0, dim), false)

func _draw() -> void:
	if tex_scheda == null:
		return
	var k := size.x / L
	draw_texture_rect(tex_scheda, Rect2(Vector2.ZERO, Vector2(size.x, size.x * A / L)), false)
	var rq: Array = RIQUADRI[gid]
	for i in min(teatri.size(), rq.size()):
		var lati := ["FR", "BR"]
		for j in 2:
			var p: String = lati[j]
			var st: Dictionary = teatri[i][p]
			var c: Vector2 = rq[i][j] * k
			var nomi := []
			if int(st.base) >= 0:
				nomi.append(DatiGen.G_BASE[p][int(st.base)].img if st.vedi else "dorso_" + p)
			for b in st.bonus:
				nomi.append(DatiGen.G_BONUS[gid + "_" + p][int(b)].img if st.vedi else "dorsox_%s_%s" % [gid, p])
			for e in int(st.extra) / 2:
				nomi.append("byng" if gid == "7YW" and i != 2 else ("atlantico_" + p))
			# le tessere si dispongono nel riquadro: una al centro, più tessere a ventaglio su due file
			var n := nomi.size()
			var lt := (76.0 if n <= 2 else (62.0 if n <= 4 else 50.0)) * k
			var per_riga := 2 if n <= 4 else 3
			var righe_n := int(ceil(float(n) / per_riga))
			for x in n:
				var r := x / per_riga
				var in_riga: int = min(per_riga, n - r * per_riga)
				var col := x % per_riga
				var px := (col - (in_riga - 1) / 2.0) * lt * 0.84
				var py := (r - (righe_n - 1) / 2.0) * lt * 0.8 + (2.0 if gid == "WAS" and i == 3 else 12.0) * k
				_tessera(nomi[x], c + Vector2(px, py), lt)
			# la forza, sotto il riquadro
			if font != null and str(st.get("forza", "")) != "":
				var testo: String = st.forza
				var fs := int(19.0 * k)
				var w := font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				# nella Rivolta giacobita del 1740 il riquadro è più basso: l'etichetta sta dentro, sopra la tabella
				var basso := 60.0 if gid == "WAS" and i == 3 else 82.0
				var pos := c + Vector2(-w / 2.0, basso * k)
				draw_rect(Rect2(pos + Vector2(-5, -fs), Vector2(w + 10, fs + 7)), Color(0.98, 0.95, 0.85, 0.94))
				draw_string(font, pos, testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.1, 0.28, 0.6) if p == "FR" else Color(0.68, 0.1, 0.1))
		# il margine di vittoria attuale: si evidenzia la riga della tabella stampata sulla scheda
		var capo: String = teatri[i].get("capo", "")
		var margine: int = int(teatri[i].get("margine", 0))
		var tab = RIGHE[gid][i]
		var soglie: Array = teatri[i].get("soglie", [])
		var elenco := []
		if prova_righe:
			for lato in (["FR", "BR"] if tab is Dictionary else [""]):
				for y in (tab[lato] if tab is Dictionary else tab):
					elenco.append([y, "FR"])
		elif capo != "" and margine > 0:
			var ys: Array = tab[capo] if tab is Dictionary else tab
			var riga := -1
			for x in min(soglie.size(), ys.size()):
				if margine >= int(soglie[x]):
					riga = x
			if riga >= 0:
				elenco.append([ys[riga], capo])
		for e in elenco:
			var colr := Color(0.1, 0.3, 0.75) if e[1] == "FR" else Color(0.78, 0.1, 0.1)
			var rr := Rect2(Vector2(rq[i][0].x - 62.0, float(e[0]) - 9.5) * k, Vector2(432.0, 19.0) * k)
			draw_rect(rr, Color(colr.r, colr.g, colr.b, 0.2))
			draw_rect(rr, colr, false, 3.0)
			if font != null and not prova_righe:
				var tm := "margine %d" % margine + ("" if not teatri[i].get("provv", false) else " per ora")
				var fsm := int(15.0 * k)
				var wm := font.get_string_size(tm, HORIZONTAL_ALIGNMENT_LEFT, -1, fsm).x
				var pm := rr.position + Vector2(rr.size.x - wm - 8.0, -5.0)
				draw_rect(Rect2(pm + Vector2(-5, -fsm), Vector2(wm + 10, fsm + 5)), colr)
				draw_string(font, pm, tm, HORIZONTAL_ALIGNMENT_LEFT, -1, fsm, Color(1, 1, 1))
		var vince: String = teatri[i].get("vince", "-")
		if vince == "FR" or vince == "BR":
			var cv: Vector2 = rq[i][0 if vince == "FR" else 1] * k
			draw_rect(Rect2(cv - Vector2(72, 67) * k, Vector2(144, 134) * k), Color(1.0, 0.85, 0.2), false, 5.0)
