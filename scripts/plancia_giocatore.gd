## La plancia originale di un giocatore (tradotta), con sopra le sue tessere e le sue carte:
## Vantaggi controllati, riserva delle tessere Guerra, Squadre da costruire, Ministeri, Investimenti del turno.
class_name PlanciaGiocatore
extends Control

const L := 1650.0
const A := 1275.0
var lato := "FR"
var s: Dictionary = {}
var vedi_min := true
var font: Font
var tex_fondo: Texture2D
var cache := {}

func imposta(p: String, stato: Dictionary, vedi: bool, f: Font, largh: float) -> void:
	lato = p
	s = stato
	vedi_min = vedi
	font = f
	tex_fondo = load("res://assets/aiuti/plancia_%s.jpg" % p)
	custom_minimum_size = Vector2(largh, largh * A / L)
	queue_redraw()

func _t(nome: String) -> Texture2D:
	if not cache.has(nome):
		cache[nome] = load(nome if nome.begins_with("res://") else "res://assets/pezzi/%s.png" % nome)
	return cache[nome]

func _pezzo(nome: String, centro: Vector2, largh: float, k: float, alfa := 1.0) -> void:
	var t := _t(nome)
	if t == null:
		return
	var dim := Vector2(largh, largh * t.get_height() / float(t.get_width())) * k
	draw_texture_rect(t, Rect2(centro * k - dim / 2.0, dim), false, Color(1, 1, 1, alfa))

func _numero(testo: String, centro: Vector2, k: float, dim := 30) -> void:
	var fs := int(dim * k)
	var w := font.get_string_size(testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var r := Rect2(centro * k - Vector2(w / 2.0 + 8 * k, fs * 0.62), Vector2(w + 16 * k, fs * 1.24))
	draw_style_box(_sb, r)
	draw_string(font, Vector2(r.position.x + 8 * k, r.position.y + fs * 0.98), testo, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 0.96, 0.82))

var _sb := StyleBoxFlat.new()

func _draw() -> void:
	if tex_fondo == null or s.is_empty():
		return
	_sb.bg_color = Color(0.1, 0.06, 0.1, 0.88)
	_sb.set_corner_radius_all(6)
	var k := size.x / L
	draw_texture_rect(tex_fondo, Rect2(Vector2.ZERO, Vector2(size.x, size.x * A / L)), false)
	var g: Dictionary = s.g[lato]
	# tessere Vantaggio controllate
	var miei := []
	for v in Dati.VANTAGGI:
		if s.vant[v].di == lato:
			miei.append(v)
	var col := 3 if miei.size() <= 6 else (4 if miei.size() <= 12 else 5)
	var righe := 2 if miei.size() <= 6 else 3
	var passo_x := 489.0 / col
	var passo_y := 326.0 / righe
	var lt: float = min(passo_x, passo_y) * 0.9
	for i in miei.size():
		var c := Vector2(46 + passo_x * (i % col + 0.5), 112 + passo_y * (i / col + 0.5))
		_pezzo(DatiGen.VANT_IMG[miei[i]], c, lt, k)
		if s.vant[miei[i]].es:
			_pezzo("esaurito", c + Vector2(lt * 0.22, lt * 0.22), lt * 0.5, k)
	# riserva delle tessere Guerra Bonus (coperte)
	var gid: String = s.guerra.get("id", "")
	var nb: int = g.bonus.size()
	if gid != "" and nb > 0:
		for i in min(nb, 4):
			_pezzo("dorsox_%s_%s" % [gid, lato], Vector2(697 - i * 5, 345 - i * 5), 118, k)
		_numero("%d nella riserva" % nb, Vector2(697, 270), k, 22)
	# Squadre ancora da costruire
	var ns: int = g.sq_non
	for i in ns:
		_pezzo("squadra_" + lato, Vector2(84 + (i % 4) * 88 + (44 if i >= 4 else 0), 570 + (i / 4) * 62), 84, k)
	if ns == 0:
		_numero("tutte costruite", Vector2(222, 590), k, 22)
	# riserva delle tessere Guerra Base (coperte)
	var nbase: int = g.base.size()
	for i in min(nbase, 4):
		_pezzo("dorso_" + lato, Vector2(530 - i * 5, 596 - i * 5), 108, k)
	_numero("%d nella riserva" % nbase, Vector2(530, 540), k, 20)
	# Ministeri
	var rett := [Rect2(34, 800, 376, 372), Rect2(446, 800, 378, 372)]
	for i in min(2, g.min.size()):
		var m: Dictionary = g.min[i]
		var r: Rect2 = rett[i]
		var c := r.get_center()
		if m.riv or vedi_min:
			var t := _t("res://assets/carte/mic_%02d.webp" % int(m.id))
			var prop := float(t.get_width()) / t.get_height()
			var h := 470.0
			var dim := Vector2(h * prop, h)
			draw_texture_rect(t, Rect2((Vector2(c.x, 950) - dim / 2.0) * k, dim * k), false)
			draw_rect(Rect2(Vector2(c.x - 178, 1178) * k, Vector2(356, 56) * k), Color(0.93, 0.87, 0.74))
			_numero("Rivelato" if m.riv else "Coperto: lo vedi solo tu", Vector2(c.x, 1206), k, 22)
		else:
			draw_rect(Rect2(Vector2(c.x - 150, 730) * k, Vector2(300, 440) * k), Color(0.12, 0.07, 0.13, 0.9))
			draw_rect(Rect2(Vector2(c.x - 150, 730) * k, Vector2(300, 440) * k), Color(0.83, 0.66, 0.27), false, 3 * k)
			_numero("Ministero coperto", c, k, 26)
	# tessere Investimento prese in questo turno
	var prese: Array = s.inv_prese[lato]
	for i in prese.size():
		if int(prese[i]) >= 0:
			_pezzo("inv_%02d" % int(prese[i]), Vector2(1548 - (prese.size() - 1 - i) * 74, 1202), 92, k)
