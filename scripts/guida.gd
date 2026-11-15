## La guida della partita guidata: spiega ogni passo, consiglia la mossa e dice perché,
## racconta le mosse dell'avversario. Il "perché" nasce confrontando la partita prima e dopo la mossa
## (simulata su una copia): Premi regionali, Prestigio, merci della Domanda Globale, Vantaggi,
## forza nella prossima guerra, Debito, Punti Trattato e Punti Vittoria.
class_name Guida
extends RefCounted

var mo: Motore
var ia: IA
var visti := {}

const MIN_FORTI := [1, 2, 6, 8, 10]

func _init(m: Motore, i: IA) -> void:
	mo = m
	ia = i

# ------------------------------------------------------------ lezioni
## Spiegazione del passo in corso: completa la prima volta, breve le volte successive.
const LEZIONI := {
	"ministro": ["I Ministeri",
		"All'inizio di ogni era (turni 1, 3 e 5) scegli [b]due Ministeri[/b]. Restano coperti finché non li riveli e danno un potere che dura tutta l'era, più le [b]parole chiave[/b] che attivano i Bonus degli Eventi e danno forza in alcuni teatri di guerra. Conviene un Ministero che lavori [b]a ogni turno[/b] più di uno che serve una volta sola.",
		"Scegli i due Ministeri dell'era: preferisci quelli che lavorano a ogni turno."],
	"scarta": ["La mano di Eventi",
		"Si tengono al massimo 3 Eventi. Scarta quelli che non potrai giocare (servono tessere con il pugnale) o il cui Bonus non potrai attivare.",
		"Scarta gli Eventi meno utili."],
	"primo": ["L'Iniziativa",
		"Chi è in svantaggio nei PV ha l'[b]Iniziativa[/b] e decide chi gioca il primo Round. Di norma conviene far cominciare l'avversario: tu fai l'[b]ultimo Round[/b] prima del punteggio e della guerra e puoi rispondere a tutto. Si comincia per primi quando c'è una tessera molto migliore delle altre da non farsi soffiare, o al turno 1 per prendere spazi senza disturbo.",
		"Decidi chi apre il turno: di solito conviene giocare per ultimi."],
	"tessera": ["Sottofase a: la tessera Investimento",
		"Ogni Round comincia scegliendo una tessera: il [b]numero grande[/b] è l'Azione Maggiore (si divide fra più spazi), il [b]numero piccolo[/b] l'Azione Minore (un solo acquisto, non toglie bandiere salvo dove c'è un Conflitto). Il [b]pugnale[/b] permette un Evento, la [b]Miglioria[/b] di cambiare una tessera Guerra. Scegliere una tessera vuol dire anche toglierla all'avversario.",
		"Sottofase a: scegli la tessera Investimento."],
	"evento": ["Sottofase b: l'Evento",
		"La tessera ha il pugnale: puoi giocare un Evento [b]prima[/b] di spendere i punti. Se è soddisfatta la condizione del [b]Bonus[/b] (spesso una parola chiave di un tuo Ministero rivelato) l'Evento fa di più.",
		"Sottofase b: giochi un Evento?"],
	"azione": ["Sottofase c: i Punti Azione",
		"Spendi i punti dell'Azione Maggiore e di quella Minore toccando gli spazi evidenziati: [b]oro[/b] Economia (Mercati), [b]azzurro[/b] Diplomazia (spazi Politici), [b]rosso[/b] Militare (Forti, Squadre, tessere Bonus). Con Diplomazia ed Economia ogni regione oltre la prima costa 1 punto in più. Puoi aggiungere Debito e Punti Trattato. Quando hai finito tocca «Fine del Round d'Azione».",
		"Sottofase c: spendi i Punti Azione."],
	"bonus_guerra": ["Le tessere Guerra Bonus",
		"Hai comprato una tessera Bonus (coperta): mettila nel teatro della prossima guerra in cui un po' di forza in più cambia il risultato. Non serve rinforzare un teatro già vinto largo o già perso.",
		"Metti la tessera Bonus nel teatro in bilico."],
	"up": ["La Miglioria militare",
		"Hai pescato una nuova tessera Base: tieni quella che ti aiuta di più nel teatro.",
		"Tieni la tessera Base migliore."],
	"pc": ["I Punti Conquista",
		"Hai vinto un teatro e hai [b]Punti Conquista[/b]: prendi Territori, Forti, Mercati o spazi Navali della regione seguendo le direttrici di conquista. Prima i Territori liberi che danno Vantaggi o Prestigio, poi i Forti, poi i Territori nemici.",
		"Spendi i Punti Conquista."],
	"rifiuto": ["Cedere o rifiutare",
		"L'avversario vuole un tuo Territorio. Puoi rifiutare pagando [b]3 PV[/b] (la seconda volta 5). Conviene solo se il Territorio ti tiene in vita in una regione.",
		"Cedi il Territorio o paghi PV per tenerlo?"],
}

const CAP_TUTORIAL := {"ministro": [7, 1], "scarta": [7, 0], "primo": [2, 2], "tessera": [3, 0], "evento": [7, 0],
	"azione": [3, 1], "bonus_guerra": [6, 0], "up": [6, 2], "pc": [10, 3], "rifiuto": [10, 3]}

func lezione(s: Dictionary) -> String:
	if s.att == null:
		return ""
	var t: String = s.att.tipo
	if not LEZIONI.has(t):
		return "[b]%s[/b]" % s.att.tit
	var l: Array = LEZIONI[t]
	if visti.has(t):
		return "[b]%s[/b]" % l[2]
	visti[t] = true
	return "[b]%s.[/b] %s" % [l[0], l[1]]

## Riepilogo di inizio turno: dove sono i punti di questo turno.
func piano_turno(s: Dictionary, io: String) -> String:
	var t := "[b]Turno %d: dove sono i punti.[/b]\n" % s.turno
	var righe := []
	for r in Dati.REG_ORD:
		if s.premi.has(r):
			var pr: Array = Dati.PREMI[s.premi[r]]
			righe.append("Premio di %s: %d PV%s%s (tu %d, avversario %d)" % [Dati.REGIONI[r], pr[0], " +1 PT" if pr[1] > 0 else "",
				", serve un margine di 2" if pr[2] == 2 else "", mo.conta_regione(s, io, r), mo.conta_regione(s, Motore.avv(io), r)])
	righe.append("Prestigio: 2 PV (tu %d, avversario %d)" % [mo.conta_prestigio(s, io), mo.conta_prestigio(s, Motore.avv(io))])
	for m in s.domanda:
		var rr: Array = Dati.DOMANDA[m][s.era - 1]
		righe.append("%s: %d PV%s (tu %d Mercati, avversario %d)" % [Dati.MERCI_NOME[m], rr[0], " +1 PT" if rr[1] > 0 else "",
			mo.conta_merce(s, io, m), mo.conta_merce(s, Motore.avv(io), m)])
	for r2 in righe:
		t += "- " + r2 + "\n"
	var prossima: String = Dati.PROSSIMA_GUERRA.get(s.turno, "")
	if prossima != "" and Dati.GUERRA_DOPO.has(s.turno):
		t += "Alla fine del turno c'è la [b]%s[/b]: guarda la scheda (pulsante Guerra) per sapere che cosa dà forza." % Dati.GUERRE[prossima].nome
	elif s.turno == 6:
		t += "È l'ultimo turno: dopo il punteggio c'è il punteggio finale (Prestigio, Debito Disponibile, una merce a testa, Territori strappati)."
	else:
		t += "Dopo questo turno non c'è guerra: prepara con calma la prossima."
	return t

# ------------------------------------------------------------ effetti di una mossa
func _vince_premio(s: Dictionary, r: String) -> String:
	var pr: Array = Dati.PREMI[s.premi[r]]
	var fr := mo.conta_regione(s, "FR", r)
	var br := mo.conta_regione(s, "BR", r)
	return "FR" if fr - br >= pr[2] else ("BR" if br - fr >= pr[2] else "")

func _chi(c: Dictionary, f: Callable) -> String:
	var a: int = f.call(c, "FR")
	var b: int = f.call(c, "BR")
	return "FR" if a > b else ("BR" if b > a else "")

func _a_chi(p: String) -> String:
	return "alla Francia" if p == "FR" else ("alla Gran Bretagna" if p == "BR" else "a nessuno")

## Che cosa cambia fra due momenti della partita, in frasi brevi.
func effetti(prima: Dictionary, dopo: Dictionary, io: String) -> Array:
	var out := []
	var a := Motore.avv(io)
	# Premi regionali
	for r in Dati.REG_ORD:
		if not prima.premi.has(r) or not dopo.premi.has(r):
			continue
		var w0 := _vince_premio(prima, r)
		var w1 := _vince_premio(dopo, r)
		var f0 := "%d a %d" % [mo.conta_regione(prima, "FR", r), mo.conta_regione(prima, "BR", r)]
		var f1 := "%d a %d" % [mo.conta_regione(dopo, "FR", r), mo.conta_regione(dopo, "BR", r)]
		var pr: Array = Dati.PREMI[prima.premi[r]]
		if w0 != w1:
			out.append("Premio di %s (%d PV): passa %s (spazi Francia contro Gran Bretagna: prima %s, dopo %s)" % [Dati.REGIONI[r], pr[0], _a_chi(w1), f0, f1])
		elif f0 != f1:
			out.append("%s, spazi Francia contro Gran Bretagna: prima %s, dopo %s (il Premio non cambia)" % [Dati.REGIONI[r], f0, f1])
	# Prestigio
	var p0 := _chi(prima, mo.conta_prestigio)
	var p1 := _chi(dopo, mo.conta_prestigio)
	if p0 != p1:
		out.append("Prestigio (2 PV a turno): passa %s" % _a_chi(p1))
	# Domanda Globale
	for m in prima.domanda:
		var m0 := _chi(prima, func(c, p): return mo.conta_merce(c, p, m))
		var m1 := _chi(dopo, func(c, p): return mo.conta_merce(c, p, m))
		if m0 != m1:
			var rr: Array = Dati.DOMANDA[m][prima.era - 1]
			out.append("%s (%d PV nella Domanda Globale): passa %s" % [Dati.MERCI_NOME[m], rr[0], _a_chi(m1)])
	# Vantaggi
	for v in Dati.VANTAGGI:
		var d0: String = prima.vant[v].di
		var d1: String = dopo.vant[v].di
		if d0 != d1:
			out.append("Vantaggio %s: passa %s" % [Dati.VANTAGGI[v].it, _a_chi(d1)])
	# forza nella prossima guerra
	if not prima.guerra.is_empty() and not dopo.guerra.is_empty() and prima.guerra.id == dopo.guerra.id and dopo.fase != "Guerra":
		var tt: Array = Dati.GUERRE[dopo.guerra.id].teatri
		for i in tt.size():
			var b0: int = mo.forza_teatro(prima, io, i, true).tot
			var c0: int = mo.forza_teatro(prima, a, i, true).tot
			var b1: int = mo.forza_teatro(dopo, io, i, true).tot
			var c1: int = mo.forza_teatro(dopo, a, i, true).tot
			if b0 != b1 or c0 != c1:
				out.append("Guerra, teatro %s: forza bonus %s %d contro %d (prima %d contro %d)" % [tt[i].nome, Dati.NOMI[io], b1, c1, b0, c0])
		for p in ["FR", "BR"]:
			if _bonus_messi(dopo, p) > _bonus_messi(prima, p):
				out.append("%s mette %d tessera Bonus coperta nella prossima guerra (per l'avversario vale circa 2 di forza)" % [Dati.NOMI[p], _bonus_messi(dopo, p) - _bonus_messi(prima, p)])
	# Squadre, Debito, Trattati, PV
	var g0: Dictionary = prima.g[io]
	var g1: Dictionary = dopo.g[io]
	if g1.sq_non < g0.sq_non:
		out.append("Costruisce %d Squadra: forza in guerra e protezione dei Mercati vicini" % (g0.sq_non - g1.sq_non))
	if g1.deb != g0.deb:
		out.append("Debito di %s: %d su %d (%+d)" % [Dati.NOMI[io], g1.deb, g1.lim, g1.deb - g0.deb])
	if g1.trp != g0.trp:
		out.append("Punti Trattato di %s: %d (%+d)" % [Dati.NOMI[io], g1.trp, g1.trp - g0.trp])
	if dopo.pv != prima.pv:
		var verso := "FR" if dopo.pv > prima.pv else "BR"
		out.append("Punti Vittoria: %d (%d a favore della %s)" % [dopo.pv, absi(dopo.pv - prima.pv), Dati.NOMI[verso]])
	return out

func _bonus_messi(c: Dictionary, p: String) -> int:
	var n := 0
	for th in c.guerra.get("teatri", []):
		n += th[p].bonus.size()
	return n

# ------------------------------------------------------------ consiglio
## La mossa consigliata, il piano del Round che ne segue e il perché.
func consiglio(s: Dictionary) -> Dictionary:
	var a: Dictionary = s.att
	var io: String = a.chi
	mo.materializza(s)
	var i := ia.decidi(s)
	var o: Dictionary = a.opz[i]
	var res := {"i": i, "et": str(o.get("et", "")), "piano": [], "eff": [], "perche": ""}
	# simula il resto del Round con le scelte della guida
	var c := ia._copia(s)
	c.att = s.att.duplicate(true)
	var ar0: int = s.ar[io]
	mo.applica(c, i)
	var giri := 0
	while c.att != null and c.fine == null and c.att.chi == io and c.ar[io] == ar0 and c.fase == s.fase and c.turno == s.turno and giri < 10:
		mo.materializza(c)
		var j := ia.decidi(c)
		var oj: Dictionary = c.att.opz[j]
		if c.att.tipo == "azione":
			if oj.a != "fine":
				res.piano.append(str(oj.get("et", "")))
		else:
			res.piano.append("%s: %s" % [str(c.att.tit).trim_suffix(":").trim_suffix("?"), str(oj.get("et", ""))])
		mo.applica(c, j)
		giri += 1
	res.eff = effetti(s, c, io)
	res.perche = _motivo(s, o, io)
	return res

func _motivo(s: Dictionary, o: Dictionary, io: String) -> String:
	var a: Dictionary = s.att
	match a.tipo:
		"ministro":
			if o.get("m", 0) == 0:
				return ""
			var m: Dictionary = Dati.MINISTERI[o.m]
			var t := "[b]%s[/b]: %s" % [m.nome, m.t]
			var prossima: String = Dati.PROSSIMA_GUERRA.get(s.turno, "")
			if prossima != "":
				for th in Dati.GUERRE[prossima].teatri:
					for kw in m.kw:
						if ("K:" + kw) in th.bonus:
							t += " Inoltre la sua parola chiave dà forza nel teatro %s della prossima guerra." % th.nome
			if o.m in MIN_FORTI:
				t += " È fra i Ministeri che i giocatori esperti considerano più forti perché lavorano a ogni turno."
			return t
		"primo":
			# le stesse ragioni con cui decide l'IA
			var con_ev := 0
			var forti := 0
			for k in s.inv_disp:
				var dk: Dictionary = DatiGen.INVEST[k]
				if dk.ev:
					con_ev += 1
				if dk.n >= 4 and dk.up:
					forti += 1
			var pronto := ""
			for n in s.g[io].mano:
				if mo.cond_ok(s, io, Dati.EVENTI[n].cond):
					pronto = Dati.EVENTI[n].nome
			if o.p == io:
				if forti == 1:
					return "Conviene aprire: fra le tessere scoperte ce n'è una sola con Maggiore 4 e Miglioria militare, e chi apre la prende."
				return "Conviene aprire: hai un Evento con il Bonus già attivo («%s») e le tessere con il pugnale sono solo %d; se apre l'avversario potrebbe prendertele." % [pronto, con_ev]
			return "Fai cominciare l'avversario: avrai l'ultimo Round prima del punteggio e potrai rispondere alle sue mosse senza che lui possa ribattere."
		"tessera":
			if o.has("t"):
				var d: Dictionary = DatiGen.INVEST[o.t]
				var t2 := "Maggiore %s %d, Minore %s 2" % [Dati.SIGLA_PA[d.mag], d.n, Dati.SIGLA_PA[d.min]]
				if d.ev:
					t2 += ", con il pugnale per un Evento"
				if d.up:
					t2 += ", con la Miglioria militare"
				return "La tessera dà %s: è quella che rende di più con il piano qui sotto." % t2
		"evento":
			if o.get("ev", 0) > 0:
				return "[b]%s[/b]: l'effetto conviene adesso, prima di spendere i punti." % Dati.EVENTI[o.ev].nome
			return "Nessun Evento conviene in questo momento: tienili per un Round in cui il Bonus è attivo."
		"azione":
			if o.a == "fine":
				return "Non resta nulla di utile da comprare con i punti rimasti."
			if o.a == "passa":
				return "Nessuna tessera rende abbastanza: passare riduce il Debito di 2."
	return ""

# ------------------------------------------------------------ mosse dell'avversario
func commenta(s: Dictionary, i: int) -> String:
	var a: Dictionary = s.att
	var o: Dictionary = a.opz[i]
	var chi: String = a.chi
	var et := str(o.get("et", ""))
	if a.tipo == "tessera" and o.has("t"):
		var d: Dictionary = DatiGen.INVEST[o.t]
		et = "prende la tessera %s %d + %s 2" % [Dati.SIGLA_PA[d.mag], d.n, Dati.SIGLA_PA[d.min]]
	elif a.tipo == "ministro" and o.get("m", 0) > 0:
		et = "sceglie un Ministero (coperto)"
	elif a.tipo == "scarta":
		et = "scarta un Evento"
	elif a.tipo == "azione" and o.a == "fine":
		return ""
	var c := ia._copia(s)
	c.att = s.att.duplicate(true)
	mo.applica(c, i)
	var eff := effetti(s, c, chi)
	var t := "[b]%s[/b]: %s" % [Dati.NOMI[chi], et]
	if not eff.is_empty():
		t += "\n   " + "\n   ".join(eff)
	return t
