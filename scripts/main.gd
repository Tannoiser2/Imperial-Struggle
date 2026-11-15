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
var box_fasi: HBoxContainer
var box_sotto: HBoxContainer
var bt_veloce: Button
var lbl_da_fare: Label
var riga_fasi: HBoxContainer
var col_alto: VBoxContainer
var pan_sx: PanelContainer
var box_sx: VBoxContainer
var pan_dx: PanelContainer
var box_dec: HFlowContainer
var box_dx: VBoxContainer
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
	v.add_child(bottone("Partita guidata: impara giocando", func(): nuova_partita("ia", "FR", 1697, true), L, 24))
	v.add_child(bottone("Gioca con la Francia contro l'IA", func(): nuova_partita("ia", "FR"), L, 24))
	v.add_child(bottone("Gioca con la Gran Bretagna contro l'IA", func(): nuova_partita("ia", "BR"), L, 24))
	v.add_child(bottone("Due giocatori su questo dispositivo", func(): nuova_partita("due", "FR"), L, 24))
	v.add_child(bottone("Gioca online con un amico", menu_online, L, 24))
	v.add_child(bottone("Continua la partita salvata", continua, L, 24))
	v.add_child(bottone("Guarda una partita fra due IA", func(): nuova_partita("demo", "FR"), L, 22))
	v.add_child(bottone("Tutorial: regole e strategia", mostra_tutorial, L, 22))
	var nota := etichetta("Adattamento digitale per uso personale del gioco di Ananda Gupta e Jason Matthews (GMT Games).", 17, F_CORSIVO, Color(0.35, 0.25, 0.2), L)
	nota.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(nota)

func nuova_partita(m: String, lato: String, seme := -1, con_guida := false) -> void:
	guidata = con_guida
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
	guidata = dati.get("guidata", false)
	avvia_partita()

func salva() -> void:
	if modo == "online" or modo == "demo" or s.is_empty() or s.nd == ult_salv:
		return
	ult_salv = s.nd
	var testo := var_to_str({"s": s, "modo": modo, "umani": umani, "lato": mio_lato, "guidata": guidata})
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
	guida_pan = null
	guida_cons = {}
	guida_nd = -1
	guida_commenti = []
	guida_turno = 0
	if guidata:
		_crea_guida()
	# barra in alto
	barra_alto = PanelContainer.new()
	barra_alto.add_theme_stylebox_override("panel", stile(C_NOTTE, C_ORO, 2, 0, 6))
	radice.add_child(barra_alto)
	barra_alto.clip_contents = true
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	barra_alto.add_child(vb)
	# riga 1: titolo, turno, PV e i pulsanti (compatti)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	vb.add_child(h)
	h.add_child(etichetta("Imperial Struggle", 24, F_TITOLO, C_ORO))
	lbl_turno = etichetta("", 19, F_SOTTO, C_CARTA)
	lbl_turno.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_turno.clip_text = true
	h.add_child(lbl_turno)
	lbl_pv = etichetta("", 23, F_TITOLO, C_ORO)
	h.add_child(lbl_pv)
	h.add_child(_bott_stretto("Tessere", mostra_tessere))
	h.add_child(_bott_stretto("Carte", mostra_mano))
	h.add_child(_bott_stretto("Guerra", mostra_guerra))
	h.add_child(_bott_stretto("Ministeri", mostra_ministeri))
	h.add_child(_bott_stretto("Diario", mostra_diario))
	h.add_child(_bott_stretto("Tutorial", mostra_tutorial))
	h.add_child(_bott_stretto("Aiuto", mostra_aiuto))
	h.add_child(_bott_stretto("Mappa", func(): plancia.adatta()))
	bt_veloce = _bott_stretto("IA lenta", func(): veloce = not veloce; _agg_veloce())
	bt_veloce.tooltip_text = "Velocità delle mosse dell'IA"
	h.add_child(bt_veloce)
	h.add_child(_bott_stretto("Menu", _chiedi_menu))
	# riga 2: le 14 fasi del turno, con quella in corso in evidenza
	box_fasi = HBoxContainer.new()
	box_fasi.add_theme_constant_override("separation", 3)
	box_fasi.custom_minimum_size.y = 26
	vb.add_child(box_fasi)
	# riga 3: le sottofasi (del Round d'Azione o della guerra)
	box_sotto = HBoxContainer.new()
	box_sotto.add_theme_constant_override("separation", 3)
	box_sotto.custom_minimum_size.y = 26
	vb.add_child(box_sotto)
	# riga 4: le azioni da fare (altezza fissa: due file di pulsanti, poi si scorre)
	var sc_az := ScrollContainer.new()
	sc_az.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc_az.custom_minimum_size.y = 76
	vb.add_child(sc_az)
	box_dec = HFlowContainer.new()
	box_dec.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box_dec.add_theme_constant_override("h_separation", 5)
	box_dec.add_theme_constant_override("v_separation", 4)
	sc_az.add_child(box_dec)
	# riga 5: che cosa deve fare il giocatore
	lbl_da_fare = etichetta("", 19, F_GRASSO, Color(1.0, 0.93, 0.7))
	lbl_da_fare.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_da_fare.clip_text = true
	lbl_da_fare.custom_minimum_size.y = 24
	vb.add_child(lbl_da_fare)
	lbl_dec = etichetta("", 20)
	lbl_dec.visible = false
	vb.add_child(lbl_dec)
	# pannelli delle due potenze: Gran Bretagna a sinistra, Francia a destra
	var pannelli := []
	for k in 2:
		var pan := PanelContainer.new()
		pan.add_theme_stylebox_override("panel", stile(Color(C_CARTA.r, C_CARTA.g, C_CARTA.b, 0.95), C_INCH, 2, 0, 8))
		radice.add_child(pan)
		var sc := ScrollContainer.new()
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		pan.add_child(sc)
		var bx := VBoxContainer.new()
		bx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sc.add_child(bx)
		pannelli.append([pan, bx])
	pan_sx = pannelli[0][0]
	box_sx = pannelli[0][1]
	pan_dx = pannelli[1][0]
	box_dx = pannelli[1][1]
	# barra in basso: il diario e le informazioni sullo spazio indicato
	barra_basso = PanelContainer.new()
	barra_basso.add_theme_stylebox_override("panel", stile(Color(C_CARTA.r, C_CARTA.g, C_CARTA.b, 0.97), C_ORO, 2, 0, 6))
	radice.add_child(barra_basso)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	barra_basso.add_child(hb)
	diario = RichTextLabel.new()
	diario.bbcode_enabled = true
	diario.scroll_following = true
	diario.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diario.custom_minimum_size = Vector2(400, 60)
	diario.add_theme_font_size_override("normal_font_size", 17)
	diario.add_theme_font_size_override("bold_font_size", 17)
	hb.add_child(diario)
	hb.add_child(VSeparator.new())
	lbl_info = etichetta("Tocca uno spazio della mappa per leggerne i dati. Cerchi sulla mappa: oro Economia, azzurro Diplomazia, rosso Militare.", 17, F_CORSIVO, Color(0.3, 0.2, 0.15), 470)
	lbl_info.clip_text = true
	lbl_info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hb.add_child(lbl_info)
	_disponi()
	aggiorna()

## Altezza fissa della barra in alto: pulsanti, fasi, sottofasi, azioni da fare, indicazione.
const ALTO_BARRA := 212.0

## Pulsante compatto per la barra in alto.
func _bott_stretto(testo: String, azione: Callable, dim := 16) -> Button:
	var b := bottone(testo, azione, 0, dim)
	b.custom_minimum_size = Vector2(30, 30)
	var stili := {"normal": stile(C_CARTA, C_INCH, 2, 5), "hover": stile(Color(1.0, 0.96, 0.84), C_ORO, 2, 5),
		"pressed": stile(C_CARTA2, C_VIOLA, 2, 5), "disabled": stile(Color(0.7, 0.66, 0.58, 0.7), Color(0.4, 0.35, 0.3), 1, 5),
		"focus": stile(Color(0, 0, 0, 0), C_ORO, 2, 5)}
	for k in stili:
		var sb: StyleBoxFlat = stili[k]
		sb.content_margin_left = 7
		sb.content_margin_right = 7
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		b.add_theme_stylebox_override(k, sb)
	return b

func _agg_veloce() -> void:
	if bt_veloce == null or not is_instance_valid(bt_veloce):
		return
	bt_veloce.visible = modo == "demo" or modo == "ia"
	bt_veloce.text = "IA veloce" if veloce else "IA lenta"

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
	var largo := d.x >= 1700.0
	var alto := ALTO_BARRA
	var basso := 112.0
	var lato := 318.0 if d.x >= 1500 else 292.0
	barra_alto.position = Vector2.ZERO
	barra_alto.size = Vector2(d.x, alto)
	pan_sx.position = Vector2(0, alto)
	pan_sx.size = Vector2(lato, d.y - alto - basso)
	pan_dx.position = Vector2(d.x - lato, alto)
	pan_dx.size = Vector2(lato, d.y - alto - basso)
	barra_basso.position = Vector2(0, d.y - basso)
	barra_basso.size = Vector2(d.x, basso)
	plancia.area = Rect2(lato, alto, d.x - lato * 2.0, d.y - alto - basso)
	plancia.adatta()
	_disponi_guida()

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
	lbl_turno.text = "Turno %d di 6 (%s) - Era %s%s" % [s.turno, Dati.ANNI[s.turno], Dati.ERE[s.era],
		(" - Prossima guerra: " + Dati.GUERRE[prossima].nome) if prossima != "" and not s.guerra.is_empty() else ""]
	_agg_fasi()
	lbl_pv.text = "PV %d" % s.pv
	lbl_pv.tooltip_text = "A 30 vince la Francia, a 0 la Gran Bretagna"
	_agg_sinistra()
	_agg_basso()
	_agg_diario()
	_agg_decisione()
	_agg_guida()
	if not s.guerra.is_empty() and s.guerra.id != guerra_vista or (s.guerra.is_empty() and guerra_vista != "" and guerra_vista != "fine"):
		guerra_vista = s.guerra.id if not s.guerra.is_empty() else "fine"
		if not s.ult_guerra.is_empty():
			mostra_esito_guerra()
	if s.fine != null and popup_tipo != "fine":
		mostra_fine()

## Le 14 fasi di un turno di Pace (regola 4.1), più la guerra che segue.
const FASI14 := ["Mazzo", "Limite di Debito", "Premi", "Domanda Globale", "Riassetto", "Carte", "Ministeri", "Iniziativa",
	"Azioni", "Punti Trattato", "Poteri residui", "Punteggio", "Controllo vittoria", "Punteggio finale"]
const FASI14_BREVI := ["Mazzo", "Debito", "Premi", "Domanda", "Riassetto", "Carte", "Ministeri", "Iniziativa",
	"Azioni", "Trattati", "Poteri", "Punteggio", "Vittoria", "Finale"]
const FASI14_DESCR := ["Si aggiungono al mazzo gli Eventi della nuova era", "All'inizio di un'era i Limiti di Debito salgono di 4",
	"Si mettono le tessere Premio nelle quattro regioni", "Si estraggono le tre merci della Domanda Globale",
	"Tornano disponibili Vantaggi, tessere Investimento e Ministeri", "Si pescano 3 Eventi e si scoprono 9 tessere Investimento",
	"All'inizio di un'era si scelgono i due Ministeri", "Chi è indietro nei PV decide chi fa il primo Round",
	"Quattro Round d'Azione a testa, alternati", "I Punti Trattato oltre 4 si perdono", "Si risolvono i poteri di fine turno",
	"Si assegnano Premi, prestigio e Domanda Globale", "A 30 PV vince la Francia, a 0 la Gran Bretagna", "Solo dopo il sesto turno"]
const DA_FARE := {"scarta": "scarta gli Eventi in più (se ne tengono 3)", "ministro": "scegli i due Ministeri dell'era",
	"primo": "decidi chi fa il primo Round d'Azione", "tessera": "prendi una tessera Investimento",
	"evento": "decidi se giocare un Evento", "azione": "tocca uno spazio evidenziato sulla mappa oppure scegli un'azione qui sotto",
	"pc": "spendi i Punti Conquista sulla mappa", "bonus_guerra": "metti la tessera Bonus in un teatro",
	"up": "scegli quale tessera Base tenere", "rifiuto": "cedi il Territorio oppure rifiuta", "spazi": "scegli uno spazio sulla mappa"}

func _fase_corrente() -> int:
	if s.fine != null:
		return 99
	match s.fase:
		"Preparazione del turno": return 5
		"Fase dei Ministeri": return 6
		"Fase dell'Iniziativa": return 7
		"Fase delle Azioni": return 8
		"Punteggio": return 11
		"Guerra": return 14
	return 0

func _chip(testo: String, stato: int, dim := 17, descr := "") -> PanelContainer:
	# stato: 0 passata, 1 corrente, 2 futura, 3 corrente secondaria
	var pc := PanelContainer.new()
	var l := etichetta(testo, dim, F_GRASSO if stato == 1 or stato == 3 else F_SOTTO)
	match stato:
		1:
			pc.add_theme_stylebox_override("panel", stile(C_ORO, Color(1, 0.97, 0.8), 2, 5, 3))
			l.add_theme_color_override("font_color", C_NOTTE)
		3:
			pc.add_theme_stylebox_override("panel", stile(Color(0.95, 0.9, 0.75), C_ORO, 2, 5, 3))
			l.add_theme_color_override("font_color", C_NOTTE)
		0:
			pc.add_theme_stylebox_override("panel", stile(Color(0.24, 0.17, 0.26), Color(0.42, 0.34, 0.4), 1, 5, 3))
			l.add_theme_color_override("font_color", Color(0.72, 0.66, 0.68))
		_:
			pc.add_theme_stylebox_override("panel", stile(Color(0.2, 0.12, 0.22), C_ORO.darkened(0.35), 1, 5, 3))
			l.add_theme_color_override("font_color", C_CARTA)
	pc.add_child(l)
	if descr != "":
		pc.tooltip_text = descr
	return pc

func _agg_fasi() -> void:
	svuota(box_fasi)
	svuota(box_sotto)
	var corrente := _fase_corrente()
	var stretto := dim_schermo().x < 1700.0
	var c_guerra: bool = Dati.GUERRA_DOPO.has(s.turno)
	for i in 14:
		if i == 13 and s.turno != 6:
			continue
		var st := 1 if i == corrente else (0 if i < corrente else 2)
		var testo: String = "%d %s" % [i + 1, FASI14_BREVI[i]]
		if stretto and st != 1:
			testo = str(i + 1) if i < 6 or i > 8 else testo
		box_fasi.add_child(_chip(testo, st, 15 if not stretto else 14, "%d. %s: %s" % [i + 1, FASI14[i], FASI14_DESCR[i]]))
	var nome_g: String = Dati.GUERRE[Dati.GUERRA_DOPO[s.turno]].nome if c_guerra else "Nessuna guerra"
	if stretto and c_guerra and corrente != 14:
		nome_g = "Guerra"
	box_fasi.add_child(_chip(nome_g, 1 if corrente == 14 else (0 if corrente == 99 else 2), 15 if not stretto else 14, "Dopo i turni 1, 3, 4 e 5 si combatte una guerra"))
	# sottofasi
	if corrente == 8 and s.ar_st.has("p"):
		var ar: Dictionary = s.ar_st
		var passo := 2
		if s.att != null and s.att.tipo == "tessera":
			passo = 0
		elif int(ar.tess) < 0:
			passo = 0
		elif s.att != null and s.att.tipo == "evento":
			passo = 1
		box_sotto.add_child(_chip("Round %d di 8: %s" % [min(8, s.ar.FR + s.ar.BR + 1), Dati.NOMI[ar.p]], 3, 14))
		var nomi := ["a Investimento", "b Evento", "c Punti Azione"]
		var descr := ["Prendi una tessera Investimento (oppure usa un potere che la sostituisce)", "Se la tessera ha il simbolo, puoi giocare un Evento",
			"Spendi i punti dell'Azione Maggiore e di quella Minore; la Miglioria militare se la tessera la concede"]
		for i in 3:
			box_sotto.add_child(_chip(nomi[i], 1 if i == passo else (0 if i < passo else 2), 15, descr[i]))
		if passo == 2 and not stretto:
			if int(ar.mag.n) > 0:
				box_sotto.add_child(_chip("Maggiore: %s %d" % [Dati.SIGLA_PA.get(ar.mag.t, "?"), int(ar.mag.n)], 3, 14))
			if not ar.min.us and int(ar.min.n) > 0:
				box_sotto.add_child(_chip("Minore: %s %d" % [Dati.SIGLA_PA.get(ar.min.t, "?"), int(ar.min.n)], 3, 14))
			if ar.up:
				box_sotto.add_child(_chip("Miglioria militare", 3, 14))
	elif corrente == 14 and not s.guerra.is_empty():
		var tt: Array = Dati.GUERRE[s.guerra.id].teatri
		var fatto: int = s.ult_guerra.size()
		for i in tt.size():
			box_sotto.add_child(_chip("Teatro %d: %s" % [i + 1, tt[i].nome] if not stretto else ("T%d" % (i + 1) if i != fatto else tt[i].nome), 1 if i == fatto else (0 if i < fatto else 2), 15, tt[i].nome))
	elif corrente == 5 or corrente == 6 or corrente == 7 or corrente == 11:
		box_sotto.add_child(_chip("%d. %s" % [corrente + 1, FASI14[corrente]], 3, 15, FASI14_DESCR[corrente]))
	if s.fine != null:
		lbl_da_fare.text = "Partita finita: vince la %s." % Dati.NOMI[s.fine.vince]
	elif s.att == null:
		lbl_da_fare.text = ""
	else:
		var cosa: String = DA_FARE.get(s.att.tipo, str(s.att.tit).to_lower())
		if tocca_a_me():
			lbl_da_fare.text = "Tocca a %s: %s." % ["te" if modo != "due" else "te, " + Dati.NOMI[s.att.chi], cosa]
		else:
			lbl_da_fare.text = "Tocca alla %s: %s." % [Dati.NOMI[s.att.chi], cosa]

# ---------- pannello delle due potenze ----------
func _riga(nome: String, valore: String, col_valore := C_INCH) -> Control:
	var h := HBoxContainer.new()
	var a := etichetta(nome, 17, F_SOTTO, Color(0.42, 0.33, 0.27))
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(a)
	h.add_child(etichetta(valore, 18, F_GRASSO, col_valore))
	return h

func _titoletto(testo: String, col: Color) -> Control:
	var pc := PanelContainer.new()
	var sb := stile(Color(col.r, col.g, col.b, 0.14), Color(0, 0, 0, 0), 0, 3, 3)
	sb.content_margin_left = 6
	pc.add_theme_stylebox_override("panel", sb)
	pc.add_child(etichetta(testo, 16, F_TITOLO, col.darkened(0.25)))
	return pc

func _voce(testo: String, largh: float, col := C_INCH, dim := 17, f: Font = null) -> Control:
	return etichetta(testo, dim, f, col, largh)

## Chi sta vincendo adesso ogni Premio del turno: [testo, lato ("" = conteso)]
func _premi_attuali() -> Array:
	var out := []
	for r in Dati.REG_ORD:
		if not s.premi.has(r):
			continue
		var pr: Array = Dati.PREMI[s.premi[r]]
		var fr := mo.conta_regione(s, "FR", r)
		var br := mo.conta_regione(s, "BR", r)
		var lato := "FR" if fr - br >= pr[2] else ("BR" if br - fr >= pr[2] else "")
		var premio := "%d PV%s" % [pr[0], " +1 PT" if pr[1] > 0 else ""]
		out.append(["%s: %s" % [Dati.REGIONI[r], premio], "%d a %d%s" % [fr, br, ", serve +2" if pr[2] == 2 else ""], lato])
	var pf := mo.conta_prestigio(s, "FR")
	var pb := mo.conta_prestigio(s, "BR")
	out.append(["Prestigio: 2 PV", "%d a %d" % [pf, pb], "FR" if pf > pb else ("BR" if pb > pf else "")])
	for m in s.domanda:
		var rr: Array = Dati.DOMANDA[m][s.era - 1]
		var mf := mo.conta_merce(s, "FR", m)
		var mb := mo.conta_merce(s, "BR", m)
		var premio2 := "%d PV%s%s" % [rr[0], " +1 PT" if rr[1] > 0 else "", (" %+d Debito" % rr[2]) if rr[2] != 0 else ""]
		out.append(["%s: %s" % [Dati.MERCI_NOME[m], premio2], "%d a %d" % [mf, mb], "FR" if mf > mb else ("BR" if mb > mf else "")])
	return out

func _agg_sinistra() -> void:
	svuota(box_sx)
	svuota(box_dx)
	var dove := {"BR": box_sx, "FR": box_dx}
	box_sx.add_theme_constant_override("separation", 8)
	box_dx.add_theme_constant_override("separation", 8)
	var L := pan_sx.size.x - 44.0
	var premi := _premi_attuali()
	for p in ["BR", "FR"]:
		var g: Dictionary = s.g[p]
		var col: Color = COL_LATO[p]
		var attivo: bool = s.att != null and s.att.chi == p and s.fine == null
		var esterno := PanelContainer.new()
		var sbe := stile(Color(1, 0.985, 0.93), C_ORO if attivo else col, 4 if attivo else 2, 7, 0)
		esterno.add_theme_stylebox_override("panel", sbe)
		dove[p].add_child(esterno)
		var ve := VBoxContainer.new()
		ve.add_theme_constant_override("separation", 0)
		esterno.add_child(ve)
		# intestazione colorata
		var testa := PanelContainer.new()
		var sbt := stile(col, Color(0, 0, 0, 0), 0, 4, 6)
		sbt.corner_radius_bottom_left = 0
		sbt.corner_radius_bottom_right = 0
		testa.add_theme_stylebox_override("panel", sbt)
		ve.add_child(testa)
		var ht := HBoxContainer.new()
		testa.add_child(ht)
		var bandiera := TextureRect.new()
		bandiera.texture = load("res://assets/pezzi/%s.png" % ("band_b" if p == "FR" else "band_a"))
		bandiera.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bandiera.custom_minimum_size = Vector2(34, 34)
		ht.add_child(bandiera)
		var nome := etichetta(Dati.NOMI[p], 25, F_TITOLO, Color(1, 0.97, 0.88))
		nome.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ht.add_child(nome)
		# toccando l'intestazione si apre la plancia del giocatore
		bandiera.mouse_filter = Control.MOUSE_FILTER_IGNORE
		testa.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		testa.tooltip_text = "Tocca per vedere la plancia della %s" % Dati.NOMI[p]
		testa.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT and not ev.pressed:
				mostra_plancia(p))
		var chi := ""
		if modo == "ia":
			chi = "tu" if umani[p] else "IA"
		elif modo == "online":
			chi = "tu" if p == mio_lato else "avversario"
		elif modo == "demo":
			chi = "IA"
		if attivo:
			chi = (chi + ", di turno") if chi != "" else "di turno"
		ht.add_child(etichetta(chi, 17, F_CORSIVO, Color(1, 0.93, 0.7)))
		# corpo
		var mc := MarginContainer.new()
		for lato_m in ["left", "right", "top", "bottom"]:
			mc.add_theme_constant_override("margin_" + lato_m, 8)
		ve.add_child(mc)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 2)
		mc.add_child(v)
		var disp: int = g.lim - g.deb
		var gr := GridContainer.new()
		gr.columns = 2
		gr.add_theme_constant_override("h_separation", 14)
		gr.add_theme_constant_override("v_separation", 1)
		for cella in [["Debito", "%d su %d" % [g.deb, g.lim], C_BR if disp <= 1 else C_INCH], ["Trattati", str(g.trp), C_INCH],
				["Round fatti", "%d di 4" % min(4, s.ar[p]), C_INCH], ["Eventi", str(g.mano.size()), C_INCH]]:
			var rc := _riga(cella[0], cella[1], cella[2])
			rc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			gr.add_child(rc)
		v.add_child(gr)
		v.add_child(_riga("Squadre", "%d mare, %d pronte, %d da fare" % [mo.squadre_mappa(s, p).size(), g.sq_box, g.sq_non]))
		if s.ar_st.get("p", "") == p and s.ar_st.get("tess", -1) >= 0:
			var ar: Dictionary = s.ar_st
			v.add_child(_titoletto("Punti Azione di questo Round", C_VIOLA))
			v.add_child(_riga("Azione Maggiore", "%d %s" % [ar.mag.n, Dati.SIGLA_PA[ar.mag.t]], C_VIOLA))
			if not ar.min.us:
				v.add_child(_riga("Azione Minore", "%d %s" % [ar.min.n, Dati.SIGLA_PA[ar.min.t]], C_VIOLA))
			for e in ar.ex:
				if e.n > 0:
					v.add_child(_riga(str(e.get("et", "Extra")), "%d %s" % [e.n, Dati.SIGLA_PA[e.t]], C_VIOLA))
		v.add_child(_titoletto("Ministeri", col))
		if g.min.is_empty():
			v.add_child(_voce("Nessuno", L, Color(0.45, 0.38, 0.33), 16, F_CORSIVO))
		for m in g.min:
			if m.riv or p == vedo() or modo == "demo":
				v.add_child(_voce(Dati.MINISTERI[m.id].nome + ("" if m.riv else " (coperto)"), L, C_INCH, 17))
			else:
				v.add_child(_voce("Ministero coperto", L, Color(0.45, 0.38, 0.33), 16, F_CORSIVO))
		var vv := []
		for vn in s.vant:
			if s.vant[vn].di == p:
				vv.append(Dati.VANTAGGI[vn].it + (" (usato)" if s.vant[vn].es else ""))
		if not vv.is_empty():
			v.add_child(_titoletto("Vantaggi", col))
			v.add_child(_voce(", ".join(vv), L, C_INCH, 16))
		# i Premi del turno che in questo momento andrebbero a questa potenza
		var miei := []
		for x in premi:
			if x[2] == p:
				miei.append(x)
		v.add_child(_titoletto("Premi che sta vincendo", col))
		if miei.is_empty():
			v.add_child(_voce("Nessuno", L, Color(0.45, 0.38, 0.33), 16, F_CORSIVO))
		for x in miei:
			v.add_child(_riga(x[0], x[1], col))
	# Premi non ancora di nessuno
	var contesi := []
	for x in premi:
		if x[2] == "":
			contesi.append(x)
	if not contesi.is_empty():
		var pc2 := PanelContainer.new()
		pc2.add_theme_stylebox_override("panel", stile(Color(1, 0.985, 0.93), C_ORO, 2, 7, 8))
		box_sx.add_child(pc2)
		var v2 := VBoxContainer.new()
		v2.add_theme_constant_override("separation", 2)
		pc2.add_child(v2)
		v2.add_child(etichetta("Premi ancora contesi", 20, F_TITOLO, C_VIOLA))
		for x in contesi:
			v2.add_child(_riga(x[0], x[1]))
	box_sx.add_child(etichetta("I conteggi sono Francia a Gran Bretagna.", 15, F_CORSIVO, Color(0.4, 0.3, 0.25), L))

func _tessera_btn(i: int, attiva: bool, indice_opz: int) -> Control:
	var d: Dictionary = DatiGen.INVEST[i]
	var b := TextureButton.new()
	b.texture_normal = load("res://assets/pezzi/%s.png" % d.img)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	b.custom_minimum_size = Vector2(104, 104)
	b.tooltip_text = "Azione Maggiore: %d Punti %s\nAzione Minore: 2 Punti %s%s%s" % [d.n, Dati.TIPI_PA[d.mag], Dati.TIPI_PA[d.min], "\nPermette di giocare un Evento" if d.ev else "", "\nMiglioria militare" if d.up else ""]
	if attiva:
		if indice_opz >= 0:
			b.pressed.connect(func(): scegli(indice_opz))
	else:
		b.modulate = Color(0.75, 0.75, 0.75)
		b.disabled = true
	return b

func _agg_basso() -> void:
	pass

## Le tessere Investimento disponibili: compaiono quando c'è da sceglierne una, o con il pulsante «Tessere».
func mostra_tessere() -> void:
	var scelta_t: bool = tocca_a_me() and s.att.tipo == "tessera"
	var v := VBoxContainer.new()
	v.add_child(etichetta("Scegli una tessera Investimento" if scelta_t else "Tessere Investimento disponibili", 30, F_TITOLO, C_VIOLA))
	if scelta_t and guidata:
		v.add_child(_box_consiglio(min(dim_schermo().x - 140.0, 1500.0)))
	var fl := HFlowContainer.new()
	fl.add_theme_constant_override("h_separation", 14)
	fl.add_theme_constant_override("v_separation", 14)
	for i in s.inv_disp:
		var d: Dictionary = DatiGen.INVEST[i]
		var idx := -1
		if scelta_t:
			for k in s.att.opz.size():
				if s.att.opz[k].get("t", -1) == i:
					idx = k
		var col := VBoxContainer.new()
		col.custom_minimum_size.x = 230
		var b := _tessera_btn(i, idx >= 0 or not scelta_t, idx)
		b.custom_minimum_size = Vector2(150, 150)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		col.add_child(b)
		var t1 := etichetta("Maggiore: %d %s" % [d.n, Dati.TIPI_PA[d.mag]], 18, F_GRASSO, C_TIPO[d.mag].darkened(0.5), 226)
		t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t1)
		var t2 := etichetta("Minore: 2 %s" % Dati.TIPI_PA[d.min], 17, null, C_TIPO[d.min].darkened(0.5), 226)
		t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t2)
		var extra := []
		if d.ev:
			extra.append("Evento")
		if d.up:
			extra.append("Miglioria militare")
		var t3 := etichetta(", ".join(extra) if not extra.is_empty() else "-", 16, F_CORSIVO, C_INCH, 226)
		t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(t3)
		if idx >= 0:
			var bp := bottone("Prendi", func(): scegli(idx), 226)
			if guidata and guida_nd == s.nd and guida_cons.get("i", -1) == idx:
				bp.text = "Consigliata: prendi"
				bp.add_theme_stylebox_override("normal", stile(C_ORO, C_VIOLA, 3, 6, 6))
			col.add_child(bp)
		fl.add_child(col)
	v.add_child(_scorri(fl, min(dim_schermo().x - 140.0, 1250.0), min(720.0, dim_schermo().y - (360.0 if guidata and scelta_t else 220.0))))
	apri_popup(v, "tessere")

## Le carte Evento in mano: con il pulsante «Carte».
func mostra_mano() -> void:
	var io := vedo()
	var v := VBoxContainer.new()
	v.add_child(etichetta("Eventi in mano" + (" della " + Dati.NOMI[io] if modo != "ia" and modo != "online" else ""), 30, F_TITOLO, C_VIOLA))
	if s.g[io].mano.is_empty():
		v.add_child(etichetta("Nessuna carta in mano.", 22, F_CORSIVO, C_INCH))
	else:
		var fl := HFlowContainer.new()
		fl.add_theme_constant_override("h_separation", 12)
		fl.add_theme_constant_override("v_separation", 12)
		for n in s.g[io].mano:
			fl.add_child(carta_evento(n, 390))
		v.add_child(_scorri(fl, min(dim_schermo().x - 140.0, 1630.0), 780))
	apri_popup(v, "mano")

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
	_agg_veloce()
	plancia.evidenziati = {}
	if s.fine != null:
		lbl_dec.text = "Partita finita: vince la %s." % Dati.NOMI[s.fine.vince]
		box_dec.add_child(_bott_az("Torna al menu", mostra_menu))
		return
	if s.att == null:
		lbl_dec.text = ""
		return
	var a: Dictionary = s.att
	if not tocca_a_me():
		lbl_dec.text = "%s sta decidendo..." % Dati.NOMI[a.chi]
		return
	lbl_dec.text = "%s: %s" % [Dati.NOMI[a.chi], a.tit]
	if a.tipo in ["ministro", "scarta", "evento"]:
		if popup == null:
			mostra_scelta_carte()
		box_dec.add_child(_bott_az("Mostra le carte", mostra_scelta_carte))
		if a.tipo != "evento":
			return
	if a.tipo == "tessera":
		if popup == null:
			mostra_tessere()
		box_dec.add_child(_bott_az("Mostra le tessere", mostra_tessere))
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
		box_dec.add_child(etichetta(mo.nome_sp(spazio_scelto) + ":", 22, F_TITOLO, C_ORO))
		for i in per_spazio[spazio_scelto]:
			box_dec.add_child(_bottone_opz(i))
		box_dec.add_child(_bott_az("Indietro", func(): spazio_scelto = ""; _agg_decisione()))
		return
	spazio_scelto = ""
	if not per_spazio.is_empty():
		var hint := "Tocca uno spazio evidenziato sulla mappa."
		if a.tipo == "azione":
			hint = "Tocca uno spazio evidenziato sulla mappa (oro: Economia, azzurro: Diplomazia, rosso: Militare), oppure scegli qui sotto."
		pass
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
				bp.add_theme_font_size_override("font_size", 15)
				box_dec.add_child(bp)

func _bott_az(testo: String, azione: Callable) -> Button:
	return _bott_stretto(testo, azione, 17)

func _bottone_opz(i: int) -> Button:
	var o: Dictionary = s.att.opz[i]
	var b := _bott_az(str(o.get("et", "Opzione %d" % (i + 1))), func(): scegli(i))
	if guidata and guida_nd == s.nd and guida_cons.get("i", -1) == i:
		b.text = "Consigliato: " + b.text
		b.add_theme_stylebox_override("normal", stile(C_ORO, C_VIOLA, 3, 5, 6))
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
	if guidata and tocca_a_me():
		guida_azzera = true
	var prima: Dictionary = s.band.duplicate()
	var confl_prima: Dictionary = s.confl.duplicate()
	if popup_tipo in ["carte", "tessere", "mano"]:
		chiudi_popup()
	spazio_scelto = spazio_scelto if s.att.tipo == "azione" else ""
	mo.applica(s, i)
	for id in S:
		if s.band.get(id, "") != prima.get(id, "") or s.confl.has(id) != confl_prima.has(id):
			plancia.lampeggi[id] = 2.2
	if s.att != null and s.att.tipo == "tessera":
		salva()
	attesa_ia = 0.12 if veloce else (1.3 if guidata else 0.7)
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
			if guidata:
				var com := guida.commenta(s, i)
				if com != "":
					if guida_azzera:
						guida_commenti = []
						guida_azzera = false
					guida_commenti.append(com)
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
	if guidata:
		v.add_child(_box_consiglio(min(dim_schermo().x - 140.0, 1500.0)))
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
		if guidata and guida_nd == s.nd and guida_cons.get("i", -1) == i:
			b.text = "Consigliato: " + testo_b.to_lower()
			b.add_theme_stylebox_override("normal", stile(C_ORO, C_VIOLA, 3, 6, 6))
		col.add_child(b)
		griglia.add_child(col)
	v.add_child(_scorri(griglia, larg_tot, min(800.0, dim_schermo().y - (360.0 if guidata else 220.0))))
	apri_popup(v, "carte", true)

## La plancia originale del giocatore con sopra tessere, Squadre e Ministeri.
func mostra_plancia(p: String) -> void:
	var d := dim_schermo()
	var largh: float = min(1650.0, d.x - 90.0, (d.y - 190.0) * 1650.0 / 1275.0)
	var v := VBoxContainer.new()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var tit := etichetta("Plancia della %s" % Dati.NOMI[p], 30, F_TITOLO, C_VIOLA)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tit)
	var altro := "BR" if p == "FR" else "FR"
	h.add_child(bottone("Vedi la %s" % Dati.NOMI[altro], func(): mostra_plancia(altro), 0, 19))
	v.add_child(h)
	var pg := PlanciaGiocatore.new()
	pg.imposta(p, s, p == vedo() or modo == "demo", F_GRASSO, largh)
	v.add_child(pg)
	apri_popup(v, "plancia")

## Il riepilogo delle regole in italiano (player aid), due pagine.
func mostra_aiuto(pagina := 1) -> void:
	var d := dim_schermo()
	var largh: float = min(1500.0, d.x - 110.0)
	var v := VBoxContainer.new()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	var tit := etichetta("Aiuto di gioco, pagina %d di 2" % pagina, 30, F_TITOLO, C_VIOLA)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tit)
	h.add_child(bottone("Pagina %d" % (3 - pagina), func(): mostra_aiuto(3 - pagina), 0, 19))
	v.add_child(h)
	var img := TextureRect.new()
	img.texture = load("res://assets/aiuti/aiuto_%d.jpg" % pagina)
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.stretch_mode = TextureRect.STRETCH_SCALE
	img.custom_minimum_size = Vector2(largh - 24.0, (largh - 24.0) * img.texture.get_height() / float(img.texture.get_width()))
	v.add_child(_scorri(img, largh, d.y - 230.0))
	apri_popup(v, "aiuto")

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
	scheda.prova_righe = OS.get_environment("IS_RIGHE") != ""
	scheda.imposta(gid, dati_teatri, F_GRASSO, largh)
	h.add_child(scheda)
	var corpo := VBoxContainer.new()
	corpo.add_theme_constant_override("separation", 6)
	for r in righe_testo:
		corpo.add_child(etichetta(r[0], r[1], F_GRASSO if r[2] else null, r[3], col_testo - 30.0))
	h.add_child(_scorri(corpo, col_testo, largh * 884.0 / 1129.0))
	v.add_child(h)
	apri_popup(v, tipo)

## Aggiunge alla voce di un teatro chi è avanti, di quanto, e le soglie della tabella del bottino.
func _margine_voce(voce: Dictionary, th: Dictionary, diff: int, provv: bool) -> void:
	voce["capo"] = "FR" if diff > 0 else ("BR" if diff < 0 else "")
	voce["margine"] = abs(diff)
	voce["provv"] = provv
	var soglie := []
	if voce.capo != "":
		for x in th.get("bott", th.get("bott_" + voce.capo, [])):
			soglie.append(x[0])
	voce["soglie"] = soglie

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
		var noti := {"FR": 0, "BR": 0}
		var provv := false
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
			noti[p] = (mo.forza_teatro(s, p, i).tot) if vedi else (mo.forza_teatro(s, p, i, true).tot + st.extra)
			if not vedi:
				provv = true
		_margine_voce(voce, th, noti.FR - noti.BR, provv)
		if voce.capo == "":
			righe.append(["Per ora in parità%s." % (" (senza le tessere coperte)" if provv else ""), 17, true, C_INCH])
		else:
			righe.append(["Per ora la %s è avanti di %d%s." % [Dati.NOMI[voce.capo], voce.margine, " (senza contare le tessere coperte dell'avversario)" if provv else ""], 17, true, COL_LATO[voce.capo]])
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
		_margine_voce(voce, Dati.GUERRE[gid].teatri[n - 1], r.FR.tot - r.BR.tot, false)
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

## ------------------------------------------------------------ partita guidata
func _crea_guida() -> void:
	guida = Guida.new(mo, ia)
	guida_pan = PanelContainer.new()
	guida_pan.add_theme_stylebox_override("panel", stile(Color(1.0, 0.98, 0.92, 0.97), C_VIOLA, 3, 8, 10))
	radice.add_child(guida_pan)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	guida_pan.add_child(v)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 6)
	v.add_child(h)
	var tit := etichetta("La guida", 24, F_TITOLO, C_VIOLA)
	tit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tit)
	guida_bt_segui = _bott_stretto("Segui il consiglio", _segui_consiglio, 16)
	h.add_child(guida_bt_segui)
	h.add_child(_bott_stretto("Nel tutorial", _guida_tutorial, 16))
	guida_bt_rid = _bott_stretto("Riduci", func(): guida_ridotta = not guida_ridotta; _disponi_guida(), 16)
	h.add_child(guida_bt_rid)
	guida_corpo = ScrollContainer.new()
	guida_corpo.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guida_corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(guida_corpo)
	guida_txt = RichTextLabel.new()
	guida_txt.bbcode_enabled = true
	guida_txt.fit_content = true
	guida_txt.scroll_active = false
	guida_txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	guida_txt.add_theme_font_size_override("normal_font_size", 18)
	guida_txt.add_theme_font_size_override("bold_font_size", 18)
	guida_txt.add_theme_color_override("default_color", C_INCH)
	guida_corpo.add_child(guida_txt)

func _disponi_guida() -> void:
	if guida_pan == null or not is_instance_valid(guida_pan):
		return
	var ar := plancia.area
	var w: float = min(620.0, ar.size.x - 24.0)
	var h: float = 52.0 if guida_ridotta else min(ar.size.y * 0.58, 560.0)
	guida_pan.position = Vector2(ar.position.x + 12.0, ar.end.y - h - 12.0)
	guida_pan.size = Vector2(w, h)
	guida_pan.custom_minimum_size = Vector2(w, h)
	guida_corpo.visible = not guida_ridotta
	guida_txt.custom_minimum_size.x = w - 40.0
	guida_bt_rid.text = "Apri" if guida_ridotta else "Riduci"

func _agg_guida() -> void:
	if not guidata or guida_pan == null or not is_instance_valid(guida_pan):
		return
	plancia.consigliato = ""
	guida_bt_segui.visible = false
	if s.fine != null:
		guida_txt.text = "[b]Partita finita[/b]: vince la %s. %s\n\nPuoi rivedere il diario della partita o ricominciare dal menu." % [Dati.NOMI[s.fine.vince], s.fine.get("motivo", "")]
		return
	if s.att == null:
		return
	if not tocca_a_me():
		var t := "[b]Tocca alla %s.[/b] La guida ti racconta che cosa fa e che cosa cambia.\n\n" % Dati.NOMI[s.att.chi]
		t += "\n".join(guida_commenti.slice(max(0, guida_commenti.size() - 8)))
		guida_txt.text = t
		guida_corpo.scroll_vertical = max(0, int(guida_txt.size.y))
		return
	if guida_nd != s.nd:
		guida_txt.text = "[i]La guida sta valutando le mosse...[/i]"
		_calcola_guida.call_deferred(s.nd)
		return
	_scrivi_guida()

func _calcola_guida(nd: int) -> void:
	await get_tree().process_frame
	if not guidata or s.att == null or s.nd != nd or not tocca_a_me():
		return
	guida_cons = guida.consiglio(s)
	guida_nd = nd
	_scrivi_guida()
	_agg_decisione()
	if popup != null and popup_tipo == "tessere":
		mostra_tessere()
	elif popup != null and popup_tipo == "carte":
		mostra_scelta_carte()

func _scrivi_guida() -> void:
	var io: String = s.att.chi
	var t := guida.lezione(s) + "\n\n"
	t += _testo_consiglio()
	if not guida_commenti.is_empty():
		t += "\n\n[b]Che cosa ha appena fatto l'avversario:[/b]\n" + "\n".join(guida_commenti.slice(max(0, guida_commenti.size() - 6)))
	t += "\n\n" + guida.piano_turno(s, io)
	guida_txt.text = t
	guida_corpo.scroll_vertical = 0
	guida_bt_segui.visible = true
	var o: Dictionary = s.att.opz[guida_cons.i]
	if o.has("sp") and S.has(str(o.sp)):
		plancia.consigliato = str(o.sp)

func _testo_consiglio() -> String:
	if guida_nd != s.nd:
		return "[i]La guida sta valutando le mosse...[/i]"
	var t := "[b]Consiglio: %s[/b]" % guida_cons.et
	if guida_cons.perche != "":
		t += "\n" + guida_cons.perche
	if not guida_cons.piano.is_empty():
		t += "\n[b]Poi, nello stesso Round:[/b]\n- " + "\n- ".join(guida_cons.piano)
	if guida_cons.eff.is_empty():
		t += "\n[b]Che cosa cambia:[/b] nessun effetto immediato sui punti; è un investimento per i Round e i turni che seguono."
	else:
		t += "\n[b]Che cosa cambia:[/b]\n- " + "\n- ".join(guida_cons.eff)
	return t

## Il consiglio in poche righe, per le finestre di tessere e carte.
func _testo_breve() -> String:
	var t := "[b]%s[/b]" % guida_cons.et
	if str(guida_cons.perche).begins_with("[b]" + str(guida_cons.et)):
		t = guida_cons.perche
	elif guida_cons.perche != "":
		t += ". " + guida_cons.perche
	var eff: Array = guida_cons.eff
	if not eff.is_empty():
		t += "\n[b]Che cosa cambia:[/b] " + "; ".join(eff.slice(0, 3))
		if eff.size() > 3:
			t += "; e altro ancora (vedi il riquadro della Guida)."
	return t

func _box_consiglio(largh: float) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", stile(Color(1.0, 0.95, 0.78), C_ORO.darkened(0.2), 2, 6, 10))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	pc.add_child(h)
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size.x = largh - 260.0
	r.add_theme_font_size_override("normal_font_size", 18)
	r.add_theme_font_size_override("bold_font_size", 18)
	r.add_theme_color_override("default_color", C_INCH)
	r.text = "[b]La guida:[/b] " + (_testo_breve() if guida_nd == s.nd else "[i]sta valutando le mosse...[/i]")
	h.add_child(r)
	if guida_nd == s.nd:
		var b := bottone("Segui il consiglio", _segui_consiglio, 210, 18)
		b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		h.add_child(b)
	return pc

func _segui_consiglio() -> void:
	if guida_nd == s.nd and tocca_a_me():
		scegli(int(guida_cons.i))

func _guida_tutorial() -> void:
	var dove: Array = Guida.CAP_TUTORIAL.get(s.att.tipo if s.att != null else "", [0, 0])
	mostra_tutorial(dove[0], dove[1])

## Il tutorial passo passo: capitoli a sinistra, pagina a destra (illustrazione, regola, perché, Punti Vittoria).
var tut_cap := 0
# partita guidata
var guidata := false
var guida: Guida
var guida_pan: PanelContainer
var guida_txt: RichTextLabel
var guida_corpo: ScrollContainer
var guida_bt_segui: Button
var guida_bt_rid: Button
var guida_cons := {}
var guida_nd := -1
var guida_commenti := []
var guida_ridotta := false
var guida_azzera := false
var guida_turno := 0
var tut_pag := 0

func mostra_tutorial(cap := -1, pag := -1) -> void:
	if cap >= 0:
		tut_cap = cap
		tut_pag = max(0, pag)
	var caps: Array = Tutorial.CAPITOLI
	tut_cap = clampi(tut_cap, 0, caps.size() - 1)
	var pagine: Array = caps[tut_cap].pagine
	tut_pag = clampi(tut_pag, 0, pagine.size() - 1)
	var pg: Dictionary = pagine[tut_pag]
	var d := dim_schermo()
	var largh: float = min(1560.0, d.x - 80.0)
	var alt: float = min(900.0, d.y - 150.0)
	var stretto := largh < 1250.0
	var l_elenco := 210.0 if stretto else 270.0
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	h.custom_minimum_size = Vector2(largh, alt)
	# elenco dei capitoli
	var el := VBoxContainer.new()
	el.add_theme_constant_override("separation", 4)
	for i in caps.size():
		var titolo: String = caps[i].tit
		var b := bottone(titolo, func(): mostra_tutorial(i, 0), l_elenco - 22.0, 15 if stretto else 16)
		b.custom_minimum_size.y = 34
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if i == tut_cap:
			b.add_theme_stylebox_override("normal", stile(C_ORO, C_VIOLA, 2, 5, 6))
		el.add_child(b)
	h.add_child(_scorri(el, l_elenco, alt))
	# pagina
	var dx := VBoxContainer.new()
	dx.add_theme_constant_override("separation", 8)
	dx.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(dx)
	dx.add_child(etichetta(caps[tut_cap].tit, 18, F_SOTTO, C_INCH))
	dx.add_child(etichetta(pg.t, 30 if not stretto else 26, F_TITOLO, C_VIOLA))
	var l_pag := largh - l_elenco - 14.0
	var corpo := HBoxContainer.new()
	corpo.add_theme_constant_override("separation", 16)
	corpo.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dx.add_child(corpo)
	var l_img: float = l_pag * (0.44 if not stretto else 0.4)
	var alt_corpo := alt - 150.0
	var img := TutorialImg.new()
	img.imposta(pg.get("img", {}), F_GRASSO, Vector2(l_img, min(alt_corpo, l_img * 1.1)))
	img.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	corpo.add_child(img)
	var l_testo := l_pag - l_img - 30.0
	var testi := VBoxContainer.new()
	testi.add_theme_constant_override("separation", 12)
	testi.add_child(_tut_testo(pg.x, l_testo - 24.0, 20 if not stretto else 18))
	if pg.has("perche"):
		testi.add_child(_tut_riquadro("Perché", pg.perche, l_testo - 24.0, Color(0.93, 0.89, 1.0), C_VIOLA, stretto))
	if pg.has("pv"):
		testi.add_child(_tut_riquadro("Punti Vittoria", pg.pv, l_testo - 24.0, Color(1.0, 0.95, 0.78), C_ORO.darkened(0.25), stretto))
	corpo.add_child(_scorri(testi, l_testo, alt_corpo))
	# navigazione
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 14)
	var prima := tut_cap > 0 or tut_pag > 0
	var dopo := tut_cap < caps.size() - 1 or tut_pag < pagine.size() - 1
	var b_ind := bottone("Indietro", _tut_indietro, 180, 19)
	b_ind.disabled = not prima
	nav.add_child(b_ind)
	var dove := etichetta("Pagina %d di %d del capitolo" % [tut_pag + 1, pagine.size()], 18, F_SOTTO, C_INCH)
	dove.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dove.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nav.add_child(dove)
	var b_av := bottone("Avanti", _tut_avanti, 180, 19)
	b_av.disabled = not dopo
	nav.add_child(b_av)
	dx.add_child(nav)
	apri_popup(h, "tutorial")

func _tut_avanti() -> void:
	var pagine: Array = Tutorial.CAPITOLI[tut_cap].pagine
	if tut_pag < pagine.size() - 1:
		mostra_tutorial(tut_cap, tut_pag + 1)
	elif tut_cap < Tutorial.CAPITOLI.size() - 1:
		mostra_tutorial(tut_cap + 1, 0)

func _tut_indietro() -> void:
	if tut_pag > 0:
		mostra_tutorial(tut_cap, tut_pag - 1)
	elif tut_cap > 0:
		mostra_tutorial(tut_cap - 1, Tutorial.CAPITOLI[tut_cap - 1].pagine.size() - 1)

func _tut_testo(t: String, largh: float, dim: int) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.custom_minimum_size.x = largh
	r.add_theme_font_size_override("normal_font_size", dim)
	r.add_theme_font_size_override("bold_font_size", dim)
	r.add_theme_font_size_override("italics_font_size", dim)
	r.add_theme_color_override("default_color", C_INCH)
	r.text = t
	return r

func _tut_riquadro(titolo: String, t: String, largh: float, fondo: Color, bordo: Color, stretto: bool) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", stile(fondo, bordo, 2, 6, 10))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	v.add_child(etichetta(titolo, 20, F_TITOLO, bordo.darkened(0.2)))
	v.add_child(_tut_testo(t, largh - 24.0, 19 if not stretto else 17))
	return pc

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
	if parti[0] == "guida":
		# partita guidata: segue sempre il consiglio per N decisioni (0 = fino alla fine), poi foto
		veloce = true
		nuova_partita("ia", "FR", 1697, true)
		var quante := int(parti[1]) if parti.size() > 1 else 0
		var fatte_g := 0
		var t_max := 0
		var t_tot := 0
		while s.fine == null and (quante == 0 or fatte_g < quante) and fatte_g < 2000:
			await get_tree().process_frame
			if popup != null and popup_tipo in ["guerra_esito"]:
				chiudi_popup()
			if s.att == null:
				break
			if tocca_a_me() and guida_nd == s.nd and not occupato:
				fatte_g += 1
				_segui_consiglio()
			elif tocca_a_me() and guida_nd != s.nd:
				var t0 := Time.get_ticks_msec()
				guida_cons = guida.consiglio(s)
				var dt := Time.get_ticks_msec() - t0
				t_max = max(t_max, dt)
				t_tot += dt
				guida_nd = s.nd
		print("GUIDA: %d decisioni, tempo medio %d ms, massimo %d ms, turno %d, PV %d, fine %s" % [fatte_g, t_tot / max(1, fatte_g), t_max, s.turno, s.pv, str(s.fine)])
		veloce = false
		aggiorna()
		await get_tree().create_timer(2.5).timeout
		if OS.has_environment("IS_FOTO"):
			get_viewport().get_texture().get_image().save_png(OS.get_environment("IS_FOTO"))
		get_tree().quit()
		return
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
			if popup != null and popup_tipo in ["guerra_esito", "guerra", "carta", "regole", "ministeri", "diario", "mano", "plancia", "aiuto", "tutorial"]:
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
					[mostra_guerra, mostra_ministeri, mostra_diario, mostra_regole, mostra_mano, mostra_tessere][r.randi_range(0, 5)].call()
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
				"guerra":
					if OS.has_environment("IS_GUERRA"):
						mo._prepara_guerra(s, OS.get_environment("IS_GUERRA"))
					mostra_guerra()
				"carta": mostra_carta_evento(s.g.FR.mano[0] if not s.g.FR.mano.is_empty() else 1)
				"mano": mostra_mano()
				"fino:tessera": mostra_tessere()
				"regole": mostra_regole()
				"fino:pc": mostra_esito_guerra()
				"ministeri": mostra_ministeri()
				"plancia": mostra_plancia("FR")
				"plancia_br": mostra_plancia("BR")
				"aiuto": mostra_aiuto(1)
				"tutorial": mostra_tutorial(int(OS.get_environment("IS_TUT").split(",")[0]), int(OS.get_environment("IS_TUT").split(",")[1]))
				"zoom":
					plancia._zoom_su(plancia.area.get_center(), 2.2)
	await get_tree().create_timer(1.2).timeout
	var img := get_viewport().get_texture().get_image()
	img.save_png(OS.get_environment("IS_FOTO") if OS.has_environment("IS_FOTO") else "/tmp/foto.png")
	get_tree().quit()
