## Illustrazione di una pagina del tutorial: un ritaglio della mappa con gli spazi cerchiati,
## un'immagine (carta, scheda di guerra, plancia) oppure una fila di pezzi con didascalia.
class_name TutorialImg
extends Control

var spec: Dictionary = {}
var font: Font
var tex_mappa: Texture2D
var cache := {}

func imposta(d: Dictionary, f: Font, dim: Vector2) -> void:
	spec = d
	font = f
	# l'altezza segue le proporzioni dell'immagine, entro il massimo concesso
	var prop := 0.0
	if d.has("m"):
		prop = float(d.m[2] - d.m[0]) / float(d.m[3] - d.m[1])
	elif d.has("f"):
		var t := _t(d.f)
		if t != null:
			prop = t.get_width() / float(t.get_height())
			if d.has("r"):
				prop = float(d.r[2] - d.r[0]) / float(d.r[3] - d.r[1])
	elif d.has("p"):
		var n: int = d.p.size()
		var col := 1 if n == 1 else (2 if n <= 4 else 3)
		var righe := int(ceil(n / float(col)))
		var lato: float = min(dim.x / col - 30.0, 170.0)
		custom_minimum_size = Vector2(dim.x, min(dim.y, righe * (lato + 70.0)))
	if prop > 0.0:
		custom_minimum_size = Vector2(dim.x, min(dim.y, dim.x / prop + 8.0))
	elif not d.has("p"):
		custom_minimum_size = dim
	queue_redraw()

func _t(nome: String) -> Texture2D:
	if not cache.has(nome):
		cache[nome] = load(nome if nome.begins_with("res://") else "res://assets/pezzi/%s.png" % nome)
	return cache[nome]

## Rettangolo in cui disegnare una sorgente di dimensioni sz, centrato e in proporzione.
func _adatta(sz: Vector2, area: Rect2) -> Rect2:
	var k: float = min(area.size.x / sz.x, area.size.y / sz.y)
	var d := sz * k
	return Rect2(area.position + (area.size - d) / 2.0, d)

func _anello(c: Vector2, r: float, col: Color) -> void:
	draw_arc(c, r, 0, TAU, 48, Color(0, 0, 0, 0.75), 8.0, true)
	draw_arc(c, r, 0, TAU, 48, col, 4.5, true)

func _draw() -> void:
	var area := Rect2(Vector2.ZERO, size)
	draw_rect(area, Color(0.13, 0.08, 0.14))
	if spec.has("m"):
		if tex_mappa == null:
			tex_mappa = load("res://assets/mappa/mappa.jpg")
		var m: Array = spec.m
		var reg := Rect2(m[0], m[1], m[2] - m[0], m[3] - m[1])
		var dove := _adatta(reg.size, area.grow(-4))
		draw_texture_rect_region(tex_mappa, dove, reg)
		var k := dove.size.x / reg.size.x
		var r: float = clamp(48.0 * k, 9.0, 30.0)
		for id in spec.get("sp", []):
			var sp: Dictionary = DatiGen.SPAZI[id]
			_anello(dove.position + (Vector2(sp.x, sp.y) - reg.position) * k, r, Color(0.25, 0.95, 1.0))
		for v in spec.get("v", []):
			var pv: Array = DatiGen.VANT_POS[v]
			_anello(dove.position + (Vector2(pv[0], pv[1]) - reg.position) * k, r * 1.25, Color(0.85, 0.35, 0.95))
		if spec.has("premio"):
			var pp: Array = DatiGen.PREMI_POS[spec.premio]
			_anello(dove.position + (Vector2(pp[0], pp[1]) - reg.position) * k, r * 1.4, Color(0.25, 0.95, 1.0))
	elif spec.has("f"):
		var t := _t(spec.f)
		if t == null:
			return
		var src := Rect2(Vector2.ZERO, t.get_size())
		if spec.has("r"):
			var rr: Array = spec.r
			src = Rect2(rr[0], rr[1], rr[2] - rr[0], rr[3] - rr[1])
		draw_texture_rect_region(t, _adatta(src.size, area.grow(-6)), src)
	elif spec.has("p"):
		var pezzi: Array = spec.p
		var n := pezzi.size()
		var col := 1 if n == 1 else (2 if n <= 4 else 3)
		var righe := int(ceil(n / float(col)))
		var cw := size.x / col
		var ch := size.y / righe
		var fs := 17
		for i in n:
			var cella := Rect2((i % col) * cw, (i / col) * ch, cw, ch)
			var t2 := _t(pezzi[i][0])
			var lato: float = min(cw - 30.0, ch - 64.0, 170.0)
			if t2 != null:
				var dim := Vector2(lato, lato * t2.get_height() / float(t2.get_width()))
				if dim.y > lato:
					dim = dim * (lato / dim.y)
				var pos := Vector2(cella.position.x + (cw - dim.x) / 2.0, cella.position.y + 12.0 + (lato - dim.y) / 2.0)
				draw_texture_rect(t2, Rect2(pos, dim), false)
			var testo: String = pezzi[i][1]
			var y := cella.position.y + 12.0 + lato + 8.0
			# didascalia su una o due righe, sempre dentro la cella
			var parole := testo.split(" ")
			var riga := ""
			for p in parole:
				var prova := (riga + " " + p) if riga != "" else p
				if font.get_string_size(prova, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > cw - 12.0 and riga != "":
					draw_string(font, Vector2(cella.position.x + 6, y + fs), riga, HORIZONTAL_ALIGNMENT_CENTER, cw - 12.0, fs, Color(1, 0.95, 0.82))
					y += fs * 1.2
					riga = p
				else:
					riga = prova
			draw_string(font, Vector2(cella.position.x + 6, y + fs), riga, HORIZONTAL_ALIGNMENT_CENTER, cw - 12.0, fs, Color(1, 0.95, 0.82))
