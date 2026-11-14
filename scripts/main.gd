## Imperial Struggle - versione digitale (uso personale).
## Menu, partita contro l'IA, due giocatori, online (Firebase), salvataggi e interfaccia.
extends Control

const F_TITOLO := preload("res://assets/font/IMFellSC.ttf")
const F_SOTTO := preload("res://assets/font/IMFell.ttf")
const F_CORSIVO := preload("res://assets/font/IMFellCorsivo.ttf")
const F_BASE := preload("res://assets/font/EBGaramond.ttf")

const C_CARTA := Color(0.94, 0.89, 0.76)
const C_CARTA2 := Color(0.86, 0.79, 0.63)
const C_INCH := Color(0.17, 0.11, 0.07)
const C_NOTTE := Color(0.13, 0.07, 0.15)
const C_VIOLA := Color(0.3, 0.14, 0.3)
const C_ORO := Color(0.83, 0.66, 0.27)
const C_FR := Color(0.11, 0.3, 0.62)
const C_BR := Color(0.72, 0.13, 0.11)
const C_TIPO := {"E": Color(0.9, 0.7, 0.15), "D": Color(0.3, 0.6, 1.0), "M": Color(0.95, 0.25, 0.2)}
const COL_LATO := {"FR": C_FR, "BR": C_BR}
const SALVA_LOCALE := "user://imperial_struggle.sav"
const S := DatiGen.SPAZI

var F_TESTO: FontVariation
var F_GRASSO: FontVariation
var mo: Motore
var ia: IA
var net: Rete
var s: Dictionary = {}
var modo := ""
var umani := {"FR": true, "BR": false}
var mio_lato := "FR"
var codice := ""
var in_partita := false
var veloce := false
var attesa_ia := 0.0
var occupato := false
var attesa_rete := 0.0
var spazio_scelto := ""
var guerra_vista := ""
var ult_salv := -1
var popup: Control = null
var popup_tipo := ""

var radice: Control
var plancia: Plancia
var barra_alto: PanelContainer
var lbl_turno: Label
var lbl_pv: Label
var pan_sx: PanelContainer
var box_sx: VBoxContainer
var pan_dx: PanelContainer
var box_dec: VBoxContainer
var lbl_dec: Label
var diario: RichTextLabel
var lbl_info: Label
var barra_basso: PanelContainer
var box_tessere: HBoxContainer
var box_mano: HBoxContainer
var on_nome: LineEdit
var on_codice: LineEdit
var on_stato: Label
var on_lato: OptionButton
var lobby_attiva := false

func _ready() -> void:
	F_TESTO = FontVariation.new()
	F_TESTO.base_font = F_BASE
	F_TESTO.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 500}
	F_GRASSO = FontVariation.new()
	F_GRASSO.base_font = F_BASE
	F_GRASSO.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 720}
	theme = _tema()
	mo = Motore.new()
	ia = IA.new(mo)
	net = Rete.new()
	add_child(net)
	radice = Control.new()
	radice.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(radice)
	get_viewport().size_changed.connect(_disponi)
	mostra_menu()
	_prova_automatica()

# ============================================================ stile
func stile(bg: Color, bordo := Color(0, 0, 0, 0), spess := 0, raggio := 6, marg := 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = bordo
	sb.set_border_width_all(spess)
	sb.set_corner_radius_all(raggio)
	sb.set_content_margin_all(marg)
	return sb

func _tema() -> Theme:
	var t := Theme.new()
	t.default_font = F_TESTO
	t.default_font_size = 21
	var bn := stile(C_CARTA, C_INCH, 2, 5)
	var bh := stile(Color(1.0, 0.96, 0.84), C_ORO, 3, 5)
	var bp := stile(C_CARTA2, C_VIOLA, 3, 5)
	var bd := stile(Color(0.7, 0.66, 0.58, 0.7), Color(0.4, 0.35, 0.3), 1, 5)
	for k in [["normal", bn], ["hover", bh], ["pressed", bp], ["disabled", bd], ["focus", stile(Color(0, 0, 0, 0), C_ORO, 2, 5)]]:
		t.set_stylebox(k[0], "Button", k[1])
		t.set_stylebox(k[0], "OptionButton", k[1])
	for c in ["Button", "OptionButton", "Label", "LineEdit", "PopupMenu"]:
		t.set_color("font_color", c, C_INCH)
	t.set_color("font_hover_color", "Button", C_VIOLA)
	t.set_color("font_pressed_color", "Button", C_INCH)
	t.set_color("font_focus_color", "Button", C_INCH)
	t.set_color("font_disabled_color", "Button", Color(0.36, 0.31, 0.26))
	t.set_stylebox("normal", "LineEdit", stile(Color(1, 0.98, 0.9), C_INCH, 2, 4))
	t.set_stylebox("panel", "PanelContainer", stile(C_CARTA, C_INCH, 2, 6))
	t.set_color("default_color", "RichTextLabel", C_INCH)
	t.set_font("normal_font", "RichTextLabel", F_TESTO)
	t.set_font("bold_font", "RichTextLabel", F_GRASSO)
	t.set_font("italics_font", "RichTextLabel", F_CORSIVO)
	t.set_stylebox("panel", "PopupMenu", stile(C_CARTA, C_INCH, 2, 4))
	t.set_color("font_hover_color", "PopupMenu", C_VIOLA)
	return t

func etichetta(testo: String, dim := 21, f: Font = null, col := C_INCH, largh := 0.0) -> Label:
	var l := Label.new()
	l.text = testo
	l.add_theme_font_size_override("font_size", dim)
	if f != null:
		l.add_theme_font_override("font", f)
	l.add_theme_color_override("font_color", col)
	if largh > 0.0:
		# testo a capo solo con una larghezza minima certa (mai colonne di una lettera)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = largh
	return l

func bottone(testo: String, azione: Callable, largh := 0.0, dim := 20) -> Button:
	var b := Button.new()
	b.text = testo
	b.add_theme_font_size_override("font_size", dim)
	b.custom_minimum_size = Vector2(max(largh, 60.0), 46.0)
	if largh > 0.0:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.pressed.connect(azione)
	return b

func svuota(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

func dim_schermo() -> Vector2:
	return get_viewport_rect().size

# ============================================================ menu
func mostra_menu() -> void:
	in_partita = false
	lobby_attiva = false
	chiudi_popup()
	svuota(radice)
	var sfondo := TextureRect.new()
	sfondo.texture = load("res://assets/mappa/mappa.jpg")
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	sfondo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sfondo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	sfondo.modulate = Color(0.5, 0.42, 0.5)
	radice.add_child(sfondo)
	var centro := CenterContainer.new()
	centro.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.add_child(centro)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", stile(Color(C_CARTA.r, C_CARTA.g, C_CARTA.b, 0.96), C_VIOLA, 5, 10, 26))
	centro.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pan.add_child(v)
	var t := etichetta("Imperial Struggle", 76, F_TITOLO, C_VIOLA)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st := etichetta("La rivalità globale tra Francia e Gran Bretagna, 1697-1789", 26, F_CORSIVO, C_INCH)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	v.add_child(HSeparator.new())
	var L := 620.0
	v.add_child(bottone("Gioca con la Francia contro l'IA", func(): nuova_partita("ia", "FR"), L, 24))
	v.add_child(bottone("Gioca con la Gran Bretagna contro l'IA", func(): nuova_partita("ia", "BR"), L, 24))
	v.add_child(bottone("Due giocatori su questo dispositivo", func(): nuova_partita("due", "FR"), L, 24))
	v.add_child(bottone("Gioca online con un amico", menu_online, L, 24))
	v.add_child(bottone("Continua la partita salvata", continua, L, 24))
	v.add_child(bottone("Guarda una partita fra due IA", func(): nuova_partita("demo", "FR"), L, 22))
	v.add_child(bottone("Come si gioca", mostra_regole, L, 22))
	var nota := etichetta("Adattamento digitale per uso personale del gioco di Ananda Gupta e Jason Matthews (GMT Games).", 17, F_CORSIVO, Color(0.35, 0.25, 0.2), L)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)

func nuova_partita(m: String, lato: String, seme := -1) -> void:
	modo = m
	umani = {"FR": m == "due" or (m == "ia" and lato == "FR"), "BR": m == "due" or (m == "ia" and lato == "BR")}
	mio_lato = lato
	if seme < 0:
		seme = int(Time.get_unix_time_from_system()) % 1000000007 + randi() % 9973
	s = mo.nuova(seme)
	avvia_partita()

func continua() -> void:
	var dati := {}
	if FileAccess.file_exists(SALVA_LOCALE):
		var f := FileAccess.open(SALVA_LOCALE, FileAccess.READ)
		var x = str_to_var(f.get_as_text())
		if x is Dictionary:
			dati = x
	if dati.is_empty():
		avviso("Cerco il salvataggio in rete...")
		var r := await net.carica_partita()
		chiudi_popup()
		if r.has("t"):
			var y = str_to_var(str(r["t"]))
			if y is Dictionary:
				dati = y
	if dati.is_empty() or not dati.has("s"):
		avviso("Non c'è nessuna partita salvata.", true)
		return
	s = dati.s
	modo = dati.modo
	umani = dati.umani
	mio_lato = dati.lato
	avvia_partita()

func salva() -> void:
	if modo == "online" or modo == "demo" or s.is_empty() or s.nd == ult_salv:
		return
	ult_salv = s.nd
	var testo := var_to_str({"s": s, "modo": modo, "umani": umani, "lato": mio_lato})
	var f := FileAccess.open(SALVA_LOCALE, FileAccess.WRITE)
	if f != null:
		f.store_string(testo)
		f.close()
	if not OS.has_environment("IS_PROVA"):
		net.salva_partita({"t": testo})

# ============================================================ schermata di gioco
func avvia_partita() -> void:
	in_partita = true
	lobby_attiva = false
	chiudi_popup()
	svuota(radice)
	spazio_scelto = ""
	guerra_vista = s.guerra.get("id", "") if not s.guerra.is_empty() else ""
	plancia = Plancia.new()
	plancia.set_anchors_preset(Control.PRESET_FULL_RECT)
	plancia.font = F_GRASSO
	plancia.spazio_cliccato.connect(_clic_spazio)
	plancia.spazio_indicato.connect(_info_spazio)
	radice.add_child(plancia)
	# barra in alto
	barra_alto = PanelContainer.new()
	barra_alto.add_theme_stylebox_override("panel", stile(C_NOTTE, C_ORO, 2, 0, 6))
	radice.add_child(barra_alto)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	barra_alto.add_child(h)
	h.add_child(etichetta("Imperial Struggle", 30, F_TITOLO, C_ORO))
	lbl_turno = etichetta("", 22, F_SOTTO, C_CARTA)
	lbl_turno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_turno.clip_text = true
	h.add_child(lbl_turno)
	lbl_pv = etichetta("", 26, F_TITOLO, C_ORO)
	h.add_child(lbl_pv)
	h.add_child(bottone("Guerra", mostra_guerra, 0, 19))
	h.add_child(bottone("Ministeri", mostra_ministeri, 0, 19))
	h.add_child(bottone("Diario", mostra_diario, 0, 19))
	h.add_child(bottone("Regole", mostra_regole, 0, 19))
	h.add_child(bottone("Mappa intera", func(): plancia.adatta(), 0, 19))
	h.add_child(bottone("Menu", _chiedi_menu, 0, 19))
	# pannello sinistro: le due potenze
	pan_sx = PanelContainer.new()
	pan_sx.add_theme_stylebox_override("panel", stile(Color(C_CARTA.r, C_CARTA.g, C_CARTA.b, 0.95), C_INCH, 2, 0, 8))
	radice.add_child(pan_sx)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pan_sx.add_child(sc)
	box_sx = VBoxContainer.new()
	box_sx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(box_sx)
	# pannello destro: decisione e diario
	pan_dx = PanelContainer.new()
	pan_dx.add_theme_stylebox_override("panel", stile(Color(C_CARTA.r, C_CARTA.g, C_CARTA.b, 0.96), C_INCH, 2, 0, 8))
	radice.add_child(pan_dx)
	var vd := VBoxContainer.new()
	pan_dx.add_child(vd)
	lbl_dec = etichetta("", 23, F_SOTTO, C_VIOLA, 360)
	vd.add_child(lbl_dec)
	var sc2 := ScrollContainer.new()
	sc2.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc2.size_flags_stretch_ratio = 1.7
	vd.add_child(sc2)
	box_dec = VBoxContainer.new()
	box_dec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc2.add_child(box_dec)
	lbl_info = etichetta("", 18, F_CORSIVO, Color(0.3, 0.2, 0.15), 360)
	lbl_info.custom_minimum_size.y = 74
	vd.add_child(lbl_info)
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.size_flags_vertical = Control.SIZE_EXPAND_FILL
	diario.custom_minimum_size = Vector2(360, 150)
	diario.add_theme_font_size_override("normal_font_size", 17)
	diario.add_theme_font_size_override("bold_font_size", 17)
	vd.add_child(diario)
	# barra in basso: tessere Investimento e mano
	barra_basso = PanelContainer.new()
	barra_basso.add_theme_stylebox_override("panel", stile(Color(C_NOTTE.r, C_NOTTE.g, C_NOTTE.b, 0.93), C_ORO, 2, 0, 6))
	radice.add_child(barra_basso)
	var sb := ScrollContainer.new()
	sb.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	barra_basso.add_child(sb)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 18)
	sb.add_child(hb)
	box_tessere = HBoxContainer.new()
	box_tessere.add_theme_constant_override("separation", 6)
	hb.add_child(box_tessere)
	hb.add_child(VSeparator.new())
	box_mano = HBoxContainer.new()
	box_mano.add_theme_constant_override("separation", 8)
	hb.add_child(box_mano)
	_disponi()
	aggiorna()

func _disponi() -> void:
	if not in_partita or barra_alto == null or not is_instance_valid(barra_alto):
		return
	# sugli schermi 4:3 (iPad) l'interfaccia si ingrandisce
	var fin := get_window().size
	var fatt := 1.3 if float(fin.x) / max(1.0, float(fin.y)) < 1.5 else 1.0
	if absf(get_window().content_scale_factor - fatt) > 0.01:
		get_window().content_scale_factor = fatt
		return
	var d := dim_schermo()
	var alto := 62.0
	var basso := 160.0
	var sx := 292.0 if d.x >= 1500 else 250.0
	var dx := 400.0 if d.x >= 1500 else 380.0
	barra_alto.position = Vector2.ZERO
	barra_alto.size = Vector2(d.x, alto)
	pan_sx.position = Vector2(0, alto)
	pan_sx.size = Vector2(sx, d.y - alto - basso)
	pan_dx.position = Vector2(d.x - dx, alto)
	pan_dx.size = Vector2(dx, d.y - alto)
	barra_basso.position = Vector2(0, d.y - basso)
	barra_basso.size = Vector2(d.x - dx, basso)
	plancia.area = Rect2(sx, alto, d.x - sx - dx, d.y - alto - basso)
	plancia.adatta()

func vedo() -> String:
	if modo == "online" or modo == "ia":
		return mio_lato
	if modo == "due" and s.att != null:
		return s.att.chi
	return "FR"

func tocca_a_me() -> bool:
	if s.att == null or s.fine != null:
		return false
	if modo == "online":
		return s.att.chi == mio_lato
	return umani[s.att.chi]

# ============================================================ aggiornamento
func aggiorna() -> void:
	if not in_partita:
		return
	plancia.s = s
	plancia.queue_redraw()
	var prossima: String = Dati.PROSSIMA_GUERRA.get(s.turno, "")
	lbl_turno.text = "Turno %d di 6 (%s) - Era %s - %s%s" % [s.turno, Dati.ANNI[s.turno], Dati.ERE[s.era], s.fase,
		(" - Prossima guerra: " + Dati.GUERRE[prossima].nome) if prossima != "" and not s.guerra.is_empty() else ""]
	lbl_pv.text = "PV %d" % s.pv
	lbl_pv.tooltip_text = "A 30 vince la Francia, a 0 la Gran Bretagna"
	_agg_sinistra()
	_agg_basso()
	_agg_diario()
	_agg_decisione()
	if not s.guerra.is_empty() and s.guerra.id != guerra_vista or (s.guerra.is_empty() and guerra_vista != "" and guerra_vista != "fine"):
		guerra_vista = s.guerra.id if not s.guerra.is_empty() else "fine"
		if not s.ult_guerra.is_empty():
			mostra_esito_guerra()
	if s.fine != null and popup_tipo != "fine":
		mostra_fine()

func _agg_sinistra() -> void:
	svuota(box_sx)
	var L := pan_sx.size.x - 26.0
	for p in ["FR", "BR"]:
		var g: Dictionary = s.g[p]
		var pc := PanelContainer.new()
		var attivo: bool = s.att != null and s.att.chi == p
		pc.add_theme_stylebox_override("panel", stile(Color(1, 0.98, 0.9), COL_LATO[p], 5 if attivo else 2, 6, 7))
		box_sx.add_child(pc)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 1)
		pc.add_child(v)
		var chi := ""
		if modo == "ia":
			chi = " (tu)" if umani[p] else " (IA)"
		elif modo == "online":
			chi = " (tu)" if p == mio_lato else " (avversario)"
		v.add_child(etichetta(Dati.NOMI[p] + chi, 26, F_TITOLO, COL_LATO[p]))
		v.add_child(etichetta("Debito %d su %d, Trattati %d" % [g.deb, g.lim, g.trp], 19, F_GRASSO, C_INCH, L - 16))
		v.add_child(etichetta("Squadre: %d in mare, %d pronte, %d da costruire" % [mo.squadre_mappa(s, p).size(), g.sq_box, g.sq_non], 17, null, C_INCH, L - 16))
		v.add_child(etichetta("Round %d di 4, Eventi in mano %d" % [min(4, s.ar[p] + (1 if s.ar_st.get("p", "") == p else 0)), g.mano.size()], 17, null, C_INCH, L - 16))
		var mm := []
		for m in g.min:
			if m.riv or p == vedo() or modo == "demo":
				mm.append(Dati.MINISTERI[m.id].nome + ("" if m.riv else " (coperto)"))
			else:
				mm.append("Ministero coperto")
		if not mm.is_empty():
			v.add_child(etichetta("Ministeri: " + "; ".join(mm), 17, F_CORSIVO, C_INCH, L - 16))
		var vv := []
		for vn in s.vant:
			if s.vant[vn].di == p:
				vv.append(Dati.VANTAGGI[vn].it + (" (esaurito)" if s.vant[vn].es else ""))
		if not vv.is_empty():
			v.add_child(etichetta("Vantaggi: " + ", ".join(vv), 16, null, Color(0.3, 0.22, 0.16), L - 16))
		if s.ar_st.get("p", "") == p and s.ar_st.tess >= 0:
			var ar: Dictionary = s.ar_st
			var parti := ["Maggiore %s %d" % [Dati.SIGLA_PA[ar.mag.t], ar.mag.n]]
			if not ar.min.us:
				parti.append("Minore %s %d" % [Dati.SIGLA_PA[ar.min.t], ar.min.n])
			for e in ar.ex:
				if e.n > 0:
					parti.append("%s %s %d" % [e.get("et", "Extra"), Dati.SIGLA_PA[e.t], e.n])
			v.add_child(etichetta("Punti Azione: " + ", ".join(parti), 18, F_GRASSO, C_VIOLA, L - 16))
	# premi e domanda
	var pc2 := PanelContainer.new()
	pc2.add_theme_stylebox_override("panel", stile(Color(1, 0.98, 0.9), C_ORO, 2, 6, 7))
	box_sx.add_child(pc2)
	var v2 := VBoxContainer.new()
	v2.add_theme_constant_override("separation", 1)
	pc2.add_child(v2)
	v2.add_child(etichetta("Premi del turno", 22, F_TITOLO, C_VIOLA))
	for r in Dati.REG_ORD:
		if not s.premi.has(r):
			continue
		var pr: Array = Dati.PREMI[s.premi[r]]
		var t := "%s: %d PV%s%s  (%d a %d)" % [Dati.REGIONI[r], pr[0], " +1 PT" if pr[1] > 0 else "", ", margine 2" if pr[2] == 2 else "", mo.conta_regione(s, "FR", r), mo.conta_regione(s, "BR", r)]
		v2.add_child(etichetta(t, 17, null, C_INCH, L - 16))
	v2.add_child(etichetta("Prestigio: 2 PV  (%d a %d)" % [mo.conta_prestigio(s, "FR"), mo.conta_prestigio(s, "BR")], 17, null, C_INCH, L - 16))
	v2.add_child(etichetta("Domanda Globale", 22, F_TITOLO, C_VIOLA))
	for m in s.domanda:
		var rr: Array = Dati.DOMANDA[m][s.era - 1]
		var t2 := "%s: %d PV%s%s  (%d a %d)" % [Dati.MERCI_NOME[m], rr[0], " +1 PT" if rr[1] > 0 else "", (" %+d Debito" % rr[2]) if rr[2] != 0 else "", mo.conta_merce(s, "FR", m), mo.conta_merce(s, "BR", m)]
		v2.add_child(etichetta(t2, 17, null, C_INCH, L - 16))
	v2.add_child(etichetta("Fra parentesi: Francia a Gran Bretagna", 15, F_CORSIVO, Color(0.4, 0.3, 0.25), L - 16))

func _tessera_btn(i: int, attiva: bool, indice_opz: int) -> Control:
	var d: Dictionary = DatiGen.INVEST[i]
	var b := TextureButton.new()
	b.texture_normal = load("res://assets/pezzi/%s.png" % d.img)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(104, 104)
	b.tooltip_text = "Azione Maggiore: %d Punti %s\nAzione Minore: 2 Punti %s%s%s" % [d.n, Dati.TIPI_PA[d.mag], Dati.TIPI_PA[d.min], "\nPermette di giocare un Evento" if d.ev else "", "\nMiglioria militare" if d.up else ""]
	if attiva:
		b.pressed.connect(func(): scegli(indice_opz))
	else:
		b.modulate = Color(0.75, 0.75, 0.75)
		b.disabled = true
	return b

func _agg_basso() -> void:
	svuota(box_tessere)
	svuota(box_mano)
	var scelta_t: bool = tocca_a_me() and s.att.tipo == "tessera"
	var tit := etichetta("Tessere\nInvestimento", 18, F_SOTTO, C_ORO)
	box_tessere.add_child(tit)
	for i in s.inv_disp:
		var idx := -1
		if scelta_t:
			for k in s.att.opz.size():
				if s.att.opz[k].get("t", -1) == i:
					idx = k
		box_tessere.add_child(_tessera_btn(i, idx >= 0, idx))
	var io := vedo()
	box_mano.add_child(etichetta("Eventi\n" + ("della " + Dati.NOMI[io] if modo != "ia" else "in mano"), 18, F_SOTTO, C_ORO))
	for n in s.g[io].mano:
		box_mano.add_child(_mini_carta(n))

func _mini_carta(n: int) -> Control:
	var e: Dictionary = Dati.EVENTI[n]
	var b := Button.new()
	b.custom_minimum_size = Vector2(200, 108)
	b.add_theme_stylebox_override("normal", stile(C_CARTA, [C_INCH, Color(0.25, 0.5, 0.25), C_VIOLA][e.era - 1], 4, 6, 4))
	b.pressed.connect(func(): mostra_carta_evento(n))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_theme_constant_override("separation", 0)
	b.add_child(v)
	var im := TextureRect.new()
	im.texture = load("res://assets/carte/ev_%02d.webp" % n)
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	im.custom_minimum_size = Vector2(190, 52)
	im.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(im)
	var l := etichetta(e.nome, 16, F_GRASSO, C_INCH, 186)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.max_lines_visible = 2
	v.add_child(l)
	return b

func _agg_diario() -> void:
	var righe: Array = s.log.slice(max(0, s.log.size() - 40))
	var t := ""
	for r in righe:
		var x: String = r
		if x.begins_with("===") or x.begins_with("--"):
			t += "[b]%s[/b]\n" % x
		else:
			t += x + "\n"
	diario.text = t

func _agg_decisione() -> void:
	svuota(box_dec)
	plancia.evidenziati = {}
	if s.fine != null:
		lbl_dec.text = "Partita finita: vince la %s." % Dati.NOMI[s.fine.vince]
		box_dec.add_child(bottone("Torna al menu", mostra_menu, 360))
		return
	if s.att == null:
		lbl_dec.text = ""
		return
	var a: Dictionary = s.att
	if not tocca_a_me():
		lbl_dec.text = "%s sta decidendo..." % Dati.NOMI[a.chi]
		if modo == "demo" or modo == "ia":
			box_dec.add_child(bottone("IA veloce: " + ("sì" if veloce else "no"), func(): veloce = not veloce; _agg_decisione(), 360))
		return
	lbl_dec.text = "%s: %s" % [Dati.NOMI[a.chi], a.tit]
	if a.tipo in ["ministro", "scarta", "evento"]:
		if popup == null:
			mostra_scelta_carte()
		box_dec.add_child(bottone("Mostra le carte", mostra_scelta_carte, 360))
		if a.tipo != "evento":
			return
	if a.tipo == "tessera":
		box_dec.add_child(etichetta("Tocca una delle tessere Investimento in basso.", 19, F_CORSIVO, C_INCH, 360))
	# opzioni legate a uno spazio della mappa: si scelgono toccando la mappa
	var per_spazio := {}
	for i in a.opz.size():
		var o: Dictionary = a.opz[i]
		if o.has("sp") and str(o.sp) != "" and S.has(o.sp) and a.tipo != "rifiuto":
			if not per_spazio.has(o.sp):
				per_spazio[o.sp] = []
			per_spazio[o.sp].append(i)
	for sp in per_spazio:
		var col := Color(1, 1, 1)
		if a.tipo == "azione":
			var o1: Dictionary = a.opz[per_spazio[sp][0]]
			if o1.has("pl"):
				col = C_TIPO[o1.pl.t]
		plancia.evidenziati[sp] = col
	if spazio_scelto != "" and per_spazio.has(spazio_scelto):
		box_dec.add_child(etichetta(mo.nome_sp(spazio_scelto), 22, F_TITOLO, C_VIOLA))
		for i in per_spazio[spazio_scelto]:
			box_dec.add_child(_bottone_opz(i))
		box_dec.add_child(bottone("Indietro", func(): spazio_scelto = ""; _agg_decisione(), 360))
		return
	spazio_scelto = ""
	if not per_spazio.is_empty():
		var hint := "Tocca uno spazio evidenziato sulla mappa."
		if a.tipo == "azione":
			hint = "Tocca uno spazio evidenziato sulla mappa (oro: Economia, azzurro: Diplomazia, rosso: Militare), oppure scegli qui sotto."
		box_dec.add_child(etichetta(hint, 18, F_CORSIVO, C_INCH, 360))
	for i in a.opz.size():
		var o2: Dictionary = a.opz[i]
		if o2.has("sp") and str(o2.sp) != "" and S.has(o2.sp) and a.tipo != "rifiuto" and per_spazio.size() > 6:
			continue
		if a.tipo == "tessera" and o2.has("t"):
			continue
		if a.tipo == "azione" and o2.a == "pref":
			continue
		box_dec.add_child(_bottone_opz(i))
	if a.tipo == "azione":
		for i in a.opz.size():
			if a.opz[i].a == "pref":
				var bp := _bottone_opz(i)
				bp.add_theme_font_size_override("font_size", 16)
				box_dec.add_child(bp)

func _bottone_opz(i: int) -> Button:
	var o: Dictionary = s.att.opz[i]
	var b := bottone(str(o.get("et", "Opzione %d" % (i + 1))), func(): scegli(i), 360, 19)
	if s.att.tipo == "azione" and o.a == "fine":
		b.add_theme_stylebox_override("normal", stile(C_CARTA2, C_VIOLA, 3, 5))
	if s.att.tipo == "evento" and o.ev > 0:
		b.tooltip_text = _testo_evento_semplice(o.ev)
	return b

func _clic_spazio(id: String) -> void:
	_info_spazio(id)
	if not tocca_a_me() or popup != null:
		return
	var a: Dictionary = s.att
	var trovate := []
	for i in a.opz.size():
		if a.opz[i].has("sp") and str(a.opz[i].sp) == id:
			trovate.append(i)
	if trovate.is_empty():
		return
	if trovate.size() == 1:
		scegli(trovate[0])
	else:
		spazio_scelto = id
		_agg_decisione()

func _info_spazio(id: String) -> void:
	if id == "" or lbl_info == null or s.is_empty():
		return
	var d: Dictionary = S[id]
	var o: String = s.band.get(id, "")
	var t := "%s - %s in %s" % [mo.nome_sp(id), Dati.TIPI_SP[d.tipo], Dati.REGIONI[d.reg]]
	if d.tipo != "N":
		t += ", costo %d" % d.costo
	if d.has("merce"):
		t += ", " + Dati.MERCI_NOME[d.merce]
	if d.has("pres"):
		t += ", Prestigio"
	t += ". " + {"FR": "Bandiera francese", "BR": "Bandiera britannica", "US": "Stati Uniti", "": "Senza bandiera"}[o]
	if mo.protetto(s, id):
		t += ", protetto"
	if s.confl.has(id):
		t += ", in Conflitto"
	if s.danno.has(id):
		t += ", danneggiato"
	if not mo.attivo(s, id):
		t += " (non ancora disponibile)"
	for v in Dati.VANTAGGI:
		if id in Dati.VANTAGGI[v].sp:
			t += "\nVantaggio «%s»: %s" % [Dati.VANTAGGI[v].it, Dati.VANTAGGI[v].d]
	lbl_info.text = t

# ============================================================ decisioni
func scegli(i: int) -> void:
	if occupato or s.att == null or i < 0 or i >= s.att.opz.size():
		return
	if modo == "online":
		occupato = true
		var n: int = s.nd
		var ok := await net.post_decision(codice, n, {"i": i, "t": s.att.tipo})
		occupato = false
		if not ok:
			avviso("Non riesco a mandare la mossa: " + net.last_error, true)
			return
	_applica(i)

func _applica(i: int) -> void:
	var prima: Dictionary = s.band.duplicate()
	var confl_prima: Dictionary = s.confl.duplicate()
	if popup_tipo == "carte":
		chiudi_popup()
	spazio_scelto = spazio_scelto if s.att.tipo == "azione" else ""
	mo.applica(s, i)
	for id in S:
		if s.band.get(id, "") != prima.get(id, "") or s.confl.has(id) != confl_prima.has(id):
			plancia.lampeggi[id] = 2.2
	if s.att != null and s.att.tipo == "tessera":
		salva()
	attesa_ia = 0.12 if veloce else 0.7
	aggiorna()

func _process(dt: float) -> void:
	if not in_partita or s.is_empty() or s.fine != null or s.att == null or occupato:
		return
	if modo == "online":
		if s.att.chi != mio_lato:
			attesa_rete -= dt
			if attesa_rete <= 0.0:
				attesa_rete = 1.3
				_leggi_rete()
		return
	if not umani[s.att.chi]:
		if popup != null and popup_tipo in ["guerra_esito", "fine"]:
			return
		attesa_ia -= dt
		if attesa_ia <= 0.0:
			occupato = true
			var i := ia.decidi(s)
			var racconto := ia.racconta(s, i)
			if racconto != "":
				mo.nota(s, "Dispaccio: la %s %s." % [Dati.NOMI[s.att.chi], racconto])
			occupato = false
			_applica(i)

func _leggi_rete() -> void:
	occupato = true
	var n: int = s.nd
	var d = await net.get_decision(codice, n)
	occupato = false
	if d is Dictionary and d.has("i") and s.nd == n and s.att != null:
		_applica(int(d["i"]))
		attesa_rete = 0.2

# ============================================================ popup
func apri_popup(contenuto: Control, tipo: String, chiudibile := true) -> void:
	chiudi_popup()
	popup_tipo = tipo
	popup = Control.new()
	popup.set_anchors_preset(Control.PRESET_FULL_RECT)
	var velo := ColorRect.new()
	velo.color = Color(0.05, 0.02, 0.06, 0.72)
	velo.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(velo)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup.add_child(c)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", stile(C_CARTA, C_VIOLA, 4, 10, 18))
	c.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pan.add_child(v)
	v.add_child(contenuto)
	if chiudibile:
		var b := bottone("Chiudi", chiudi_popup, 220)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(b)
	add_child(popup)

func chiudi_popup() -> void:
	if popup != null and is_instance_valid(popup):
		popup.queue_free()
	popup = null
	popup_tipo = ""

func avviso(testo: String, chiudibile := false) -> void:
	apri_popup(etichetta(testo, 24, F_SOTTO, C_INCH, 560), "avviso", chiudibile)

func _chiedi_menu() -> void:
	var v := VBoxContainer.new()
	v.add_child(etichetta("Vuoi tornare al menu?", 28, F_TITOLO, C_VIOLA))
	if modo == "ia" or modo == "due":
		v.add_child(etichetta("La partita resta salvata: potrai riprenderla con «Continua la partita salvata».", 20, null, C_INCH, 520))
	v.add_child(bottone("Sì, torna al menu", func(): salva(); mostra_menu(), 520))
	apri_popup(v, "menu")

func _scorri(contenuto: Control, largh: float, alt: float) -> ScrollContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.custom_minimum_size = Vector2(largh, min(alt, dim_schermo().y - 220.0))
	contenuto.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(contenuto)
	return sc

func _testo_versione(v: Dictionary) -> String:
	var t := ""
	if v.has("tit"):
		t += "[i]%s[/i]\n" % v.tit
	t += v.t
	if v.tb != "":
		t += "\n[b]Bonus:[/b] " + v.tb
	return t

func _testo_evento_semplice(n: int) -> String:
	var e: Dictionary = Dati.EVENTI[n]
	var v: Dictionary = e.get("TT", e.get(vedo(), {}))
	return "%s\n%s%s" % [e.nome, v.t, ("\nBonus (%s): %s" % [Dati.cond_testo(e.cond), v.tb]) if v.tb != "" else ""]

## Le carte sono immagini intere: grafica originale con il testo italiano (fatte da tools/carte.py).
func _carta_img(percorso: String, largh: float, descr: String) -> Control:
	var im := TextureRect.new()
	im.texture = load(percorso)
	im.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	im.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	im.custom_minimum_size = Vector2(largh, largh * 1.4)
	im.tooltip_text = descr
	return im

func carta_evento(n: int, largh := 430.0) -> Control:
	return _carta_img("res://assets/carte/evc_%02d.webp" % n, largh, _testo_evento_semplice(n))

func carta_ministro(id: int, largh := 400.0) -> Control:
	return _carta_img("res://assets/carte/mic_%02d.webp" % id, largh, Dati.MINISTERI[id].nome)

func mostra_carta_evento(n: int) -> void:
	apri_popup(carta_evento(n, min(560.0, (dim_schermo().y - 190.0) / 1.4)), "carta")

## Scelta fra carte (Ministeri da prendere, Eventi da scartare): le carte intere, in italiano.
func mostra_scelta_carte() -> void:
	if s.att == null or not tocca_a_me():
		return
	var a: Dictionary = s.att
	var v := VBoxContainer.new()
	v.add_child(etichetta("%s: %s" % [Dati.NOMI[a.chi], a.tit], 28, F_TITOLO, C_VIOLA))
	var griglia := HFlowContainer.new()
	griglia.add_theme_constant_override("h_separation", 12)
	griglia.add_theme_constant_override("v_separation", 12)
	var larg_tot: float = min(dim_schermo().x - 120.0, 1680.0)
	for i in a.opz.size():
		var o: Dictionary = a.opz[i]
		var col := VBoxContainer.new()
		var testo_b := "Scegli"
		if a.tipo == "ministro":
			if o.m == 0:
				col.add_child(etichetta("Nessun cambio", 22, F_SOTTO, C_INCH, 300))
			else:
				col.add_child(carta_ministro(o.m, 390))
			if o.m == 0 or o.has("i"):
				testo_b = str(o.et)
		elif o.ev == 0:
			col.add_child(etichetta("Tieni le carte per un altro Round.", 22, F_SOTTO, C_INCH, 380))
			testo_b = "Non giocare Eventi"
		else:
			col.add_child(carta_evento(o.ev, 390))
			testo_b = "Gioca questo Evento" if a.tipo == "evento" else "Scarta questa"
			if a.tipo == "evento":
				var e: Dictionary = Dati.EVENTI[o.ev]
				var si: bool = mo.cond_ok(s, a.chi, e.cond)
				if e.cond != "":
					col.add_child(etichetta("Bonus: " + ("sì, la condizione è soddisfatta" if si else "no, la condizione non è soddisfatta"), 18, F_GRASSO, Color(0.15, 0.45, 0.15) if si else C_BR, 380))
		var b := bottone(testo_b, func(): scegli(i), 390)
		col.add_child(b)
		griglia.add_child(col)
	v.add_child(_scorri(griglia, larg_tot, 800))
	apri_popup(v, "carte", true)

func mostra_ministeri() -> void:
	var v := VBoxContainer.new()
	v.add_child(etichetta("Ministeri in gioco", 30, F_TITOLO, C_VIOLA))
	var griglia := HFlowContainer.new()
	griglia.add_theme_constant_override("h_separation", 12)
	griglia.add_theme_constant_override("v_separation", 12)
	for p in ["FR", "BR"]:
		for m in s.g[p].min:
			if m.riv or p == vedo() or modo == "demo":
				var col := VBoxContainer.new()
				col.add_child(carta_ministro(m.id, 380))
				col.add_child(etichetta("Rivelato" if m.riv else "Coperto (lo vedi solo tu)", 17, F_CORSIVO, C_INCH))
				griglia.add_child(col)
			else:
				griglia.add_child(etichetta("%s: un Ministero coperto" % Dati.NOMI[p], 20, F_CORSIVO, C_INCH, 300))
	v.add_child(_scorri(griglia, min(dim_schermo().x - 120.0, 1640.0), 800))
	apri_popup(v, "ministeri")

func mostra_diario() -> void:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.custom_minimum_size = Vector2(min(900.0, dim_schermo().x - 160.0), dim_schermo().y - 260.0)
	r.add_theme_font_size_override("normal_font_size", 19)
	r.add_theme_font_size_override("bold_font_size", 19)
	var t := ""
	for x in s.log:
		t += ("[b]%s[/b]\n" % x) if (str(x).begins_with("===") or str(x).begins_with("--")) else (str(x) + "\n")
	r.text = t
	r.scroll_following = true
	apri_popup(r, "diario")

func _riga_bottino(x: Array) -> String:
	var parti := []
	if x[1] > 0:
		parti.append("%d PV" % x[1])
	if x[2] > 0:
		parti.append("%d Punti Conquista" % x[2])
	for e in String(x[4]).split(";", false):
		if e.begins_with("via:"):
			parti.append("toglie una bandiera a un Mercato (%s)" % Dati.REGIONI[e.substr(4)])
		elif e == "viapol":
			parti.append("toglie una bandiera a uno spazio Politico d'Europa")
		elif e == "atl":
			parti.append("+2 nella Guerra franco-indiana")
		elif e == "sq1":
			parti.append("il perdente rinuncia a 1 Squadra")
		elif e == "sq2":
			parti.append("il perdente rinuncia a 2 Squadre")
		elif e == "usa":
			parti.append("nascono gli Stati Uniti")
		elif e == "canada":
			parti.append("anche il Canada")
		elif e == "ant":
			parti.append("il perdente perde Squadre")
	var t := "margine %d o più: %s" % [x[0], ", ".join(parti) if not parti.is_empty() else "nulla"]
	if x[3] > 0:
		t += "; al perdente %d PT" % x[3]
	return t

func _etichetta_bonus(b: String) -> String:
	if b.begins_with("K:"):
		return "parola chiave " + Dati.PAROLE[b.substr(2)]
	if b == "CONF":
		return "Conflitti negli spazi nemici"
	if b == "FORTI":
		return "Forti"
	if b.begins_with("SQ:"):
		var rg := []
		for x in b.substr(3).split(","):
			rg.append(Dati.REGIONI[x])
		return "Squadre (%s)" % ", ".join(rg)
	return b

## Popup con la scheda originale della guerra e, accanto, il dettaglio in italiano.
func _popup_scheda(titolo: String, gid: String, dati_teatri: Array, righe_testo: Array, tipo: String) -> void:
	var d := dim_schermo()
	var stretto := d.x < 1500.0
	var col_testo := 400.0 if not stretto else 330.0
	var largh: float = min(1129.0, d.x - col_testo - 110.0, (d.y - 230.0) * 1129.0 / 884.0)
	var v := VBoxContainer.new()
	v.add_child(etichetta(titolo, 30, F_TITOLO, C_VIOLA))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	var scheda := SchedaGuerra.new()
	scheda.imposta(gid, dati_teatri, F_GRASSO, largh)
	h.add_child(scheda)
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 6)
	for r in righe_testo:
		corpo.add_child(etichetta(r[0], r[1], F_GRASSO if r[2] else null, r[3], col_testo - 30.0))
	h.add_child(_scorri(corpo, col_testo, largh * 884.0 / 1129.0))
	v.add_child(h)
	apri_popup(v, tipo)

func mostra_guerra() -> void:
	if s.guerra.is_empty():
		var v := VBoxContainer.new()
		v.add_child(etichetta("Non ci sono altre guerre in arrivo.", 26, F_TITOLO, C_VIOLA))
		apri_popup(v, "guerra")
		return
	var gid: String = s.guerra.id
	var io := vedo()
	var tt: Array = Dati.GUERRE[gid].teatri
	var dati := []
	var righe := [["Le tue tessere sono scoperte, quelle dell'avversario coperte. La forza Bonus (Alleanze, Forti, Squadre, Conflitti, parole chiave) è pubblica per entrambi.", 17, false, Color(0.35, 0.25, 0.2)]]
	for i in tt.size():
		var th: Dictionary = tt[i]
		var voce := {}
		righe.append(["%d. %s" % [i + 1, th.nome], 22, true, C_INCH])
		var bonus := []
		for b in th.bonus:
			bonus.append(_etichetta_bonus(b))
		righe.append(["Forza Bonus: " + ", ".join(bonus), 16, false, C_INCH])
		for p in ["FR", "BR"]:
			var st: Dictionary = s.guerra.teatri[i][p]
			var vedi: bool = p == io or modo == "demo" or modo == "due"
			var forza := ""
			var t: String = Dati.NOMI[p] + ": "
			if vedi:
				var f := mo.forza_teatro(s, p, i)
				var voci := []
				for x in f.voci:
					voci.append("%s %+d" % [x[0], x[1]])
				forza = "Forza %d" % f.tot
				t += "forza %d (%s)" % [f.tot, ", ".join(voci) if not voci.is_empty() else "nulla"]
			else:
				# la forza Bonus viene dalla mappa ed è pubblica: si mostra per esteso, coperte restano solo le tessere
				var f2 := mo.forza_teatro(s, p, i, true)
				var voci2 := []
				for x in f2.voci:
					voci2.append("%s %+d" % [x[0], x[1]])
				if st.extra > 0:
					voci2.append("Segnalini %+d" % st.extra)
				var nt: int = (1 if st.base >= 0 else 0) + st.bonus.size()
				var tot2: int = f2.tot + st.extra
				forza = "Bonus %d + %d %s" % [tot2, nt, "tessera" if nt == 1 else "tessere"]
				t += "forza Bonus %d (%s), più %d %s" % [tot2, ", ".join(voci2) if not voci2.is_empty() else "nulla", nt, "tessera coperta" if nt == 1 else "tessere coperte"]
			voce[p] = {"base": st.base, "bonus": st.bonus, "extra": st.extra, "vedi": vedi, "forza": forza}
			righe.append([t, 17, true, COL_LATO[p]])
		dati.append(voce)
	_popup_scheda("Prossima guerra: %s (%s)" % [Dati.GUERRE[gid].nome, Dati.GUERRE[gid].anni], gid, dati, righe, "guerra")

func mostra_esito_guerra() -> void:
	if s.ult_guerra.is_empty() or not s.ult_guerra[0].has("gid"):
		return
	var gid: String = s.ult_guerra[0].gid
	var dati := []
	var righe := [["Tutte le tessere sono state rivelate. Conquiste e trattati sono nel Diario.", 17, false, Color(0.35, 0.25, 0.2)]]
	var n := 0
	for r in s.ult_guerra:
		n += 1
		var voce := {"vince": r.vince}
		righe.append(["%d. %s" % [n, r.nome], 22, true, C_INCH])
		for p in ["FR", "BR"]:
			var voci := []
			for x in r[p].voci:
				voci.append("%s %+d" % [x[0], x[1]])
			voce[p] = {"base": r.tess[p].base, "bonus": r.tess[p].bonus, "extra": r.tess[p].extra, "vedi": true, "forza": "Forza %d" % r[p].tot}
			righe.append(["%s: forza %d (%s)" % [Dati.NOMI[p], r[p].tot, ", ".join(voci) if not voci.is_empty() else "nulla"], 17, false, COL_LATO[p]])
		righe.append(["Pareggio: nessun bottino." if r.vince == "" else "Vince la %s con margine %d." % [Dati.NOMI[r.vince], r.margine], 19, true, COL_LATO.get(r.vince, C_INCH)])
		dati.append(voce)
	_popup_scheda("Esito: %s" % Dati.GUERRE[gid].nome, gid, dati, righe, "guerra_esito")

func mostra_fine() -> void:
	var v := VBoxContainer.new()
	var w: String = s.fine.vince
	var t := etichetta("Vince la %s" % Dati.NOMI[w], 54, F_TITOLO, COL_LATO[w])
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	v.add_child(etichetta(s.fine.motivo, 24, F_SOTTO, C_INCH, 620))
	v.add_child(etichetta("Punti Vittoria finali: %d" % s.pv, 22, null, C_INCH))
	v.add_child(bottone("Torna al menu", mostra_menu, 620))
	apri_popup(v, "fine")
	if FileAccess.file_exists(SALVA_LOCALE) and modo != "online" and modo != "demo":
		DirAccess.remove_absolute(SALVA_LOCALE)

const REGOLE := """[b]Lo scopo.[/b] C'è un solo totale di Punti Vittoria: parte da 15, sale quando segna la Francia e scende quando segna la Gran Bretagna. A 30 vince subito la Francia, a 0 la Gran Bretagna. Altrimenti, dopo il sesto turno, vince la Francia con 16 o più e la Gran Bretagna con 14 o meno.

[b]Il turno di Pace.[/b] Ogni potenza fa quattro Round d'Azione. Nel tuo Round prendi una tessera Investimento: dà un'Azione Maggiore (2-4 punti) e un'Azione Minore (2 punti) di tipi diversi. Se la tessera ha il simbolo Evento puoi prima giocare una carta Evento.

[b]Punti Economici (oro).[/b] Mettono o tolgono bandiere nei Mercati. Il Mercato deve essere collegato a un tuo Territorio, Forte o spazio Navale, o a un tuo Mercato.
[b]Punti Diplomatici (azzurro).[/b] Mettono o tolgono bandiere negli spazi Politici: Alleanze (forza in guerra), Prestigio (2 PV a turno a chi ne ha di più), Alleanze Locali (Vantaggi). Con 3 PD peschi un Evento.
[b]Punti Militari (rosso).[/b] Comprano tessere Guerra Bonus (2), costruiscono Squadre (4) e le schierano (1, oppure 2-3 per scacciare il nemico), costruiscono e riparano Forti, tolgono i Conflitti.

Per togliere una bandiera nemica e mettere la tua devi pagare due volte. L'Azione Minore vale per un solo acquisto e non può togliere bandiere nemiche (salvo dove c'è un Conflitto). Agire in una seconda Regione con lo stesso tipo di punti costa 1 in più.

[b]Debito e Punti Trattato.[/b] Sono punti «jolly»: aggiungono punti del tipo delle tue Azioni. Il Debito non può superare il Limite; i Punti Trattato oltre 4 si perdono a fine turno. Passando un Round riduci il Debito di 2.

[b]Fine turno.[/b] In ogni Regione chi ha più bandiere e Squadre vince il Premio; chi ha più Mercati di una merce nella Domanda Globale ne incassa il premio.

[b]Le guerre.[/b] Dopo i turni 1, 3, 4 e 5 scoppia una guerra, teatro per teatro: si sommano le tessere Guerra e la forza Bonus (Alleanze, Forti, Squadre, Conflitti in casa del nemico). Chi vince prende PV e Punti Conquista, con cui strappa Territori, Forti e Mercati. Il pulsante «Guerra» mostra sempre la situazione.

[b]Ministeri e Vantaggi.[/b] A ogni era scegli due Ministeri: restano coperti finché non li usi. I Vantaggi si ottengono controllando gli spazi collegati e si usano una volta per turno."""

func mostra_regole() -> void:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.custom_minimum_size.x = min(960.0, dim_schermo().x - 200.0)
	r.add_theme_font_size_override("normal_font_size", 20)
	r.add_theme_font_size_override("bold_font_size", 20)
	r.text = REGOLE
	var v := VBoxContainer.new()
	v.add_child(etichetta("Come si gioca", 32, F_TITOLO, C_VIOLA))
	v.add_child(_scorri(r, min(980.0, dim_schermo().x - 180.0), 760))
	apri_popup(v, "regole")

# ============================================================ online
func menu_online() -> void:
	svuota(radice)
	lobby_attiva = false
	var sfondo := ColorRect.new()
	sfondo.color = C_NOTTE
	sfondo.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.add_child(sfondo)
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	radice.add_child(c)
	var pan := PanelContainer.new()
	pan.add_theme_stylebox_override("panel", stile(C_CARTA, C_VIOLA, 5, 10, 24))
	c.add_child(pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pan.add_child(v)
	v.add_child(etichetta("Gioca online", 46, F_TITOLO, C_VIOLA))
	v.add_child(etichetta("Il tuo nome", 20))
	on_nome = LineEdit.new()
	on_nome.text = str(net.load_session().get("name", ""))
	on_nome.max_length = 20
	on_nome.custom_minimum_size = Vector2(560, 48)
	v.add_child(on_nome)
	v.add_child(etichetta("Se crei la stanza, con chi giochi?", 20))
	on_lato = OptionButton.new()
	on_lato.add_item("Francia")
	on_lato.add_item("Gran Bretagna")
	on_lato.custom_minimum_size = Vector2(560, 48)
	v.add_child(on_lato)
	v.add_child(bottone("Crea una stanza", _crea_stanza, 560, 22))
	v.add_child(HSeparator.new())
	v.add_child(etichetta("Oppure entra con il codice di 4 lettere", 20))
	on_codice = LineEdit.new()
	on_codice.max_length = 4
	on_codice.placeholder_text = "CODICE"
	on_codice.custom_minimum_size = Vector2(560, 48)
	v.add_child(on_codice)
	v.add_child(bottone("Entra nella stanza", _entra_stanza, 560, 22))
	on_stato = etichetta("", 20, F_CORSIVO, C_BR, 560)
	v.add_child(on_stato)
	v.add_child(bottone("Indietro", mostra_menu, 560))
	var ses := net.load_session()
	if str(ses.get("room", "")) != "":
		on_codice.text = str(ses["room"])

func _nome_online() -> String:
	var n := on_nome.text.strip_edges()
	if n == "":
		n = "Giocatore"
	net._save({"name": n})
	return n

func _crea_stanza() -> void:
	on_stato.text = "Creo la stanza..."
	var lato := "FR" if on_lato.selected == 0 else "BR"
	var c := await net.create_room(_nome_online(), {"lato_host": lato})
	if c == "":
		on_stato.text = "Non riesco a creare la stanza. " + net.last_error
		return
	codice = c
	mio_lato = lato
	net.remember_room(c, 0)
	lobby_attiva = true
	on_stato.text = "Stanza %s creata. Dai il codice al tuo avversario: la partita comincia appena entra." % c
	while lobby_attiva and codice == c:
		await get_tree().create_timer(1.5).timeout
		if not lobby_attiva:
			return
		var room := await net.room(c)
		var seats := Rete._as_dict(room.get("seats", {}))
		if seats.has("1"):
			var seme := int(Time.get_unix_time_from_system()) % 1000000007
			if await net.start_room(c, {"seme": seme}):
				lobby_attiva = false
				_avvia_online(seme, [])
				return

func _entra_stanza() -> void:
	var c := on_codice.text.strip_edges().to_upper()
	if c.length() != 4:
		on_stato.text = "Il codice ha 4 lettere."
		return
	on_stato.text = "Entro nella stanza..."
	var posto := await net.join_room(c, _nome_online(), 2)
	if posto < 0:
		on_stato.text = "Stanza piena o inesistente. " + net.last_error
		return
	codice = c
	net.remember_room(c, posto)
	var room: Dictionary = net.last_room
	var cfg = JSON.parse_string(str(room.get("cfg", "{}")))
	var lato_host: String = str(cfg.get("lato_host", "FR")) if cfg is Dictionary else "FR"
	mio_lato = lato_host if posto == 0 else Motore.avv(lato_host)
	lobby_attiva = true
	on_stato.text = "Sei nella stanza %s: aspetto che cominci la partita..." % c
	while lobby_attiva and codice == c:
		var r2 := await net.room(c)
		if str(r2.get("status", "")) == "playing":
			var g = JSON.parse_string(str(r2.get("game", "{}")))
			if g is Dictionary and g.has("seme"):
				lobby_attiva = false
				var mosse := await net.get_decisions(c, 0)
				var lista := []
				var k := 0
				while mosse.has(k):
					lista.append(int(mosse[k]["i"]))
					k += 1
				_avvia_online(int(g["seme"]), lista)
				return
		await get_tree().create_timer(1.5).timeout

func _avvia_online(seme: int, mosse: Array) -> void:
	modo = "online"
	umani = {"FR": mio_lato == "FR", "BR": mio_lato == "BR"}
	s = mo.nuova(seme)
	for i in mosse:
		if s.att == null:
			break
		mo.applica(s, i)
	attesa_rete = 0.5
	avvia_partita()

# ============================================================ prove automatiche (screenshot)
func _prova_automatica() -> void:
	var prova := OS.get_environment("IS_PROVA")
	if prova == "":
		return
	var parti := prova.split(",")
	await get_tree().create_timer(0.6).timeout
	if parti[0] == "caos":
		# una partita intera passando dall'interfaccia: scelte a caso per l'umano, IA per l'altro lato
		veloce = true
		nuova_partita("ia", "FR" if parti.size() < 3 else parti[2], 99 + int(parti[1]))
		var r := RandomNumberGenerator.new()
		r.seed = int(parti[1])
		var fatte := 0
		while s.fine == null and fatte < 1500:
			await get_tree().process_frame
			if s.att == null:
				break
			if popup != null and popup_tipo in ["guerra_esito", "guerra", "carta", "regole", "ministeri", "diario"]:
				chiudi_popup()
			if tocca_a_me():
				var k := r.randi_range(0, s.att.opz.size() - 1)
				if r.randf() < 0.75:
					k = ia.decidi(s)
				var o: Dictionary = s.att.opz[k]
				if o.has("sp") and str(o.sp) != "" and r.randf() < 0.5:
					_clic_spazio(str(o.sp))
					if spazio_scelto != "":
						scegli(k)
				else:
					scegli(k)
				fatte += 1
				if fatte % 37 == 0:
					[mostra_guerra, mostra_ministeri, mostra_diario, mostra_regole][r.randi_range(0, 3)].call()
		print("CAOS: %d scelte, turno %d, PV %d, fine %s" % [fatte, s.turno, s.pv, str(s.fine)])
		await get_tree().create_timer(0.5).timeout
		get_viewport().get_texture().get_image().save_png(OS.get_environment("IS_FOTO") if OS.has_environment("IS_FOTO") else "/tmp/foto.png")
		get_tree().quit()
		return
	if parti[0] != "menu":
		veloce = true
		nuova_partita("ia" if parti[0] != "demo" else "demo", "FR", 4242)
		var passi := int(parti[1]) if parti.size() > 1 else 0
		for k in passi:
			if s.att == null or s.fine != null:
				break
			mo.applica(s, ia.decidi(s))
		if parti.size() > 2 and parti[2].begins_with("fino:"):
			var cerco := parti[2].substr(5)
			var g := 0
			while s.fine == null and g < 600 and not (s.att.tipo == cerco and s.att.chi == "FR"):
				mo.applica(s, ia.decidi(s))
				g += 1
		chiudi_popup()
		aggiorna()
		if parti.size() > 2:
			match parti[2]:
				"guerra": mostra_guerra()
				"carta": mostra_carta_evento(s.g.FR.mano[0] if not s.g.FR.mano.is_empty() else 1)
				"regole": mostra_regole()
				"fino:pc": mostra_esito_guerra()
				"ministeri": mostra_ministeri()
				"zoom":
					plancia._zoom_su(plancia.area.get_center(), 2.2)
	await get_tree().create_timer(1.2).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("IS_FOTO") if OS.has_environment("IS_FOTO") else "/tmp/foto.png")
	get_tree().quit()
