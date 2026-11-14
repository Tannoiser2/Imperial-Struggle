## Le regole di Imperial Struggle. Tutto lo stato della partita sta in un dizionario (s);
## il motore chiede una decisione alla volta (s.att) con un elenco di opzioni numerate:
## la stessa sequenza di scelte dà sempre la stessa partita (serve per online, salvataggi e IA).
class_name Motore
extends RefCounted

const S := DatiGen.SPAZI
var adiac := {}
var conq := {}
var paesi := {}

func _init() -> void:
	for id in S:
		adiac[id] = []
		conq[id] = []
		if S[id].has("paese"):
			if not paesi.has(S[id].paese):
				paesi[S[id].paese] = []
			paesi[S[id].paese].append(id)
	for c in DatiGen.COLLEG:
		adiac[c[0]].append(c[1])
		adiac[c[1]].append(c[0])
	for c in DatiGen.CONQ:
		conq[c[0]].append(c[1])
		conq[c[1]].append(c[0])

static func avv(p: String) -> String:
	return "BR" if p == "FR" else "FR"

# ---------------------------------------------------------------- caso
func rnd(s: Dictionary, n: int) -> int:
	s.rng = (s.rng * 1103515245 + 12345) & 0x7fffffff
	return (s.rng >> 8) % max(1, n)

func mescola(s: Dictionary, a: Array) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rnd(s, i + 1)
		var t = a[i]
		a[i] = a[j]
		a[j] = t

func nota(s: Dictionary, t: String) -> void:
	s.log.append(t)
	if s.log.size() > 400:
		s.log = s.log.slice(s.log.size() - 300)

# ---------------------------------------------------------------- nuova partita
func nuova(seme: int) -> Dictionary:
	var s := {"v": 1, "rng": (seme & 0x7fffffff) | 1, "turno": 1, "era": 1, "pv": 15, "iniz": "FR", "primo": "FR",
		"band": {}, "confl": {}, "danno": {}, "ugo": {}, "vant": {}, "mazzo": [], "scarti": [], "rimossi": [],
		"inv_pila": [], "inv_disp": [], "inv_usate": [], "inv_prese": {"FR": [], "BR": []},
		"premi_pila": [], "premi": {}, "premi_vinti": {}, "domanda": [], "dom_vinta": {}, "guerra": {}, "ar": {"FR": 0, "BR": 0}, "ar_st": {},
		"pila": [], "att": null, "fine": null, "log": [], "jac_vitt": 0, "jac_fine": false, "jac_extra": false, "usa": false,
		"sq_rit": {"FR": 0, "BR": 0}, "gratis7": {"FR": 0, "BR": 0}, "townshend": "", "nd": 0, "ult_guerra": [], "fase": "",
		"g": {}}
	for p in ["FR", "BR"]:
		var b := []
		for i in 16:
			b.append(i)
		mescola(s, b)
		s.g[p] = {"deb": 0, "lim": 6, "trp": 0, "mano": [], "min": [], "mu": {}, "sq_box": 1 if p == "FR" else 2, "sq_non": 7 if p == "FR" else 6,
			"base": b, "bonus": [], "pref_trp": true, "m17": 0, "rif": 0}
	for id in S:
		if S[id].has("iniz"):
			s.band[id] = S[id].iniz
	for v in Dati.VANTAGGI:
		s.vant[v] = {"di": "", "es": false, "nuovo": false}
	agg_vantaggi(s)
	for v in s.vant:
		s.vant[v].nuovo = false
	for n in Dati.EVENTI:
		if Dati.EVENTI[n].era == 1:
			s.mazzo.append(n)
	mescola(s, s.mazzo)
	for i in DatiGen.INVEST.size():
		s.inv_pila.append(i)
	mescola(s, s.inv_pila)
	_prepara_guerra(s, "WSS")
	# la Francia comincia con una tessera Bonus in Europa centrale
	s.guerra.teatri[0].FR.bonus.append(_pesca_bonus(s, "FR"))
	nota(s, "Comincia la partita: 1697, l'Europa aspetta l'erede di Spagna.")
	s.pila.append({"f": "turno", "passo": 0})
	avanza(s)
	return s

func _prepara_guerra(s: Dictionary, gid: String) -> void:
	var g := {"id": gid, "teatri": []}
	for p in ["FR", "BR"]:
		var b := []
		for i in 12:
			b.append(i)
		mescola(s, b)
		s.g[p].bonus = b
		s.g[p].rif = 0
	var nt: int = Dati.GUERRE[gid].teatri.size()
	for i in nt:
		var t := {"byng": ""}
		for p in ["FR", "BR"]:
			var pool: Array = s.g[p].base
			var b: int = pool.pop_back() if not pool.is_empty() else -1
			t[p] = {"base": b, "bonus": [], "extra": 0}
		g.teatri.append(t)
	s.guerra = g

func _pesca_bonus(s: Dictionary, p: String) -> int:
	var pool: Array = s.g[p].bonus
	return pool.pop_back() if not pool.is_empty() else -1

# ---------------------------------------------------------------- consultazione
func ctrl(s: Dictionary, id: String) -> String:
	return s.band.get(id, "")

func attivo(s: Dictionary, id: String) -> bool:
	var d: Dictionary = S[id]
	if d.has("usa"):
		return s.usa
	return int(d.get("era", 1)) <= s.era

func protetto(s: Dictionary, id: String) -> bool:
	var o := ctrl(s, id)
	if o != "FR" and o != "BR":
		return false
	for n in adiac[id]:
		if ctrl(s, n) == o and (S[n].tipo == "N" or (S[n].tipo == "F" and not s.danno.has(n))):
			return true
	return false

## Mercati isolati (di entrambi): con bandiera, senza catena di Mercati amici liberi da Conflitti
## fino a un Territorio, Forte o spazio Navale del proprietario.
func isolati(s: Dictionary) -> Array:
	var out := []
	for p in ["FR", "BR"]:
		var ok := {}
		var coda := []
		for id in S:
			if S[id].tipo == "M" and ctrl(s, id) == p:
				for n in adiac[id]:
					if S[n].tipo != "M" and ctrl(s, n) == p:
						ok[id] = true
						coda.append(id)
						break
		while not coda.is_empty():
			var c: String = coda.pop_back()
			if s.confl.has(c):
				continue
			for n in adiac[c]:
				if S[n].tipo == "M" and ctrl(s, n) == p and not ok.has(n):
					ok[n] = true
					coda.append(n)
		for id in S:
			if S[id].tipo == "M" and ctrl(s, id) == p and not ok.has(id):
				out.append(id)
	return out

func deb_disp(s: Dictionary, p: String) -> int:
	return s.g[p].lim - s.g[p].deb

func ha_min(s: Dictionary, p: String, id: int) -> bool:
	for m in s.g[p].min:
		if m.id == id:
			return true
	return false

func rivela(s: Dictionary, p: String, id: int) -> void:
	for m in s.g[p].min:
		if m.id == id and not m.riv:
			m.riv = true
			nota(s, "%s rivela il Ministero «%s»." % [Dati.NOMI[p], Dati.MINISTERI[id].nome])
			if id == 20:
				_fine_giacobiti(s, "i Negoziati Papato-Hannover")

func ha_parola(s: Dictionary, p: String, k: String, anche_coperta := false) -> bool:
	for m in s.g[p].min:
		if (m.riv or anche_coperta) and k in Dati.MINISTERI[m.id].kw:
			return true
	return false

func _fine_giacobiti(s: Dictionary, perche: String) -> void:
	if s.jac_fine:
		return
	s.jac_fine = true
	s.jac_extra = false
	var m: Array = s.g.FR.min
	for i in range(m.size() - 1, -1, -1):
		if m[i].id == 4:
			m.remove_at(i)
	nota(s, "Le Insurrezioni giacobite sono rimosse dal gioco (%s)." % perche)

func usato(s: Dictionary, p: String, k: String) -> bool:
	return s.g[p].mu.has(k)

func conta_bonus_guerra(s: Dictionary, p: String) -> int:
	var n := 0
	for t in s.guerra.get("teatri", []):
		n += t[p].bonus.size()
	return n

func cond_ok(s: Dictionary, p: String, c: String) -> bool:
	var a := avv(p)
	if c == "":
		return false
	if c.begins_with("K:"):
		return ha_parola(s, p, c.substr(2), true)
	if c.begins_with("V:"):
		return s.vant[c.substr(2)].di == p
	match c:
		"DEB": return deb_disp(s, p) > deb_disp(s, a)
		"DEB3": return deb_disp(s, p) >= deb_disp(s, a) + 3
		"BONUS_G": return conta_bonus_guerra(s, p) > conta_bonus_guerra(s, a)
		"PRES_SCOIRL":
			var d := 0
			for id in ["p_sco2", "p_irl2"]:
				if not s.confl.has(id):
					d += (1 if ctrl(s, id) == p else 0) - (1 if ctrl(s, id) == a else 0)
			return d > 0
	return false

func conta_spazi(s: Dictionary, p: String, f: String) -> int:
	var n := 0
	for id in S:
		if ctrl(s, id) == p and filtro_ok(s, p, id, f):
			n += 1
	return n

## Filtro sugli spazi: condizioni separate da ";" (vedi dati.gd).
func filtro_ok(s: Dictionary, p: String, id: String, f: String) -> bool:
	if f == "":
		return true
	var d: Dictionary = S[id]
	for c in f.split(";"):
		var kv := c.split("=")
		var k := kv[0]
		var v := kv[1] if kv.size() > 1 else ""
		match k:
			"tipo":
				if d.tipo != v: return false
			"reg":
				if d.reg != v: return false
			"sub":
				if d.sub != v: return false
			"merce":
				if d.get("merce", "") != v: return false
			"paese":
				if not (d.get("paese", "") in v.split(",")): return false
			"nopaese":
				if d.get("paese", "") in v.split(","): return false
			"loc":
				if not d.has("loc"): return false
			"all":
				if not d.has("all"): return false
			"pres":
				if not d.has("pres"): return false
			"nopres":
				if d.has("pres") or d.tipo != "P": return false
			"noprot":
				if protetto(s, id): return false
			"nemico":
				if ctrl(s, id) != avv(p): return false
			"noisola":
				if _isolerebbe(s, id): return false
			"adiac_mio":
				var ok := false
				for n in adiac[id]:
					if S[n].tipo == "M" and ctrl(s, n) == p:
						ok = true
				if not ok: return false
	return true

func _isolerebbe(s: Dictionary, id: String) -> bool:
	var prima := isolati(s)
	var o: String = s.band.get(id, "")
	if o == "":
		return false
	s.band.erase(id)
	var dopo := isolati(s)
	s.band[id] = o
	for x in dopo:
		if x != id and not (x in prima):
			return true
	return false

# ---------------------------------------------------------------- modifiche di base
func pv(s: Dictionary, p: String, n: int, perche := "") -> void:
	if n == 0:
		return
	s.pv += n if p == "FR" else -n
	nota(s, "%s segna %d PV%s (totale %d)." % [Dati.NOMI[p], n, (" - " + perche) if perche != "" else "", s.pv])

func trp(s: Dictionary, p: String, n: int) -> void:
	if n == 0:
		return
	s.g[p].trp = max(0, s.g[p].trp + n)
	nota(s, "%s %s %d PT (ora %d)." % [Dati.NOMI[p], "guadagna" if n > 0 else "perde", abs(n), s.g[p].trp])

## Variazione di Debito imposta dal gioco. Il Debito oltre il Limite diventa PV per l'avversario.
func debito(s: Dictionary, p: String, n: int) -> int:
	var g: Dictionary = s.g[p]
	if n < 0:
		var r: int = min(-n, g.deb)
		g.deb -= r
		if r > 0:
			nota(s, "%s riduce il Debito di %d (ora %d)." % [Dati.NOMI[p], r, g.deb])
		return -n - r
	var spazio: int = max(0, g.lim - g.deb)
	var preso: int = min(n, spazio)
	g.deb += preso
	if preso > 0:
		nota(s, "%s prende %d Debito (ora %d su %d)." % [Dati.NOMI[p], preso, g.deb, g.lim])
	if n > preso:
		if p == "BR" and ha_min(s, "BR", 19):
			rivela(s, "BR", 19)
		else:
			pv(s, avv(p), n - preso, "Debito oltre il Limite")
	return 0

func metti(s: Dictionary, id: String, p: String) -> void:
	if ctrl(s, id) == "US":
		return
	var prima := ctrl(s, id)
	s.band[id] = p
	if prima != p:
		s.confl.erase(id)
		if s.ar_st.has("nuovi"):
			s.ar_st.nuovi.append(id)
	if p == "BR" and s.ugo.has(id):
		s.ugo.erase(id)
	agg_vantaggi(s)

func togli(s: Dictionary, id: String) -> void:
	if ctrl(s, id) == "US" or ctrl(s, id) == "":
		return
	s.band.erase(id)
	s.confl.erase(id)
	agg_vantaggi(s)

func agg_vantaggi(s: Dictionary) -> void:
	for v in Dati.VANTAGGI:
		var d: Dictionary = Dati.VANTAGGI[v]
		var di := ""
		for p in ["FR", "BR"]:
			var tutti := true
			for id in d.sp:
				if ctrl(s, id) != p or not attivo(s, id):
					tutti = false
			if tutti:
				di = p
		if s.vant[v].di != di:
			s.vant[v].di = di
			s.vant[v].nuovo = di != ""

func nome_sp(id: String) -> String:
	var d: Dictionary = S[id]
	if d.has("paese") and not d.has("loc"):
		return "%s (%s%d)" % [d.paese, "Alleanza " if d.has("all") else "Prestigio ", d.costo]
	return d.nome

func squadra_via(s: Dictionary, id: String, perche := "") -> void:
	var o := ctrl(s, id)
	if o != "FR" and o != "BR":
		return
	s.band.erase(id)
	s.g[o].sq_box += 1
	nota(s, "La Squadra %s lascia %s e torna nel Riquadro della Marina%s." % [Dati.AGG[o], S[id].nome, perche])
	agg_vantaggi(s)

func squadre_mappa(s: Dictionary, p: String, regs := []) -> Array:
	var out := []
	for id in S:
		if S[id].tipo == "N" and ctrl(s, id) == p and (regs.is_empty() or S[id].reg in regs):
			out.append(id)
	return out

# ---------------------------------------------------------------- ciclo principale
func avanza(s: Dictionary) -> void:
	var guardia := 0
	while s.att == null and s.fine == null and not s.pila.is_empty():
		guardia += 1
		if guardia > 5000:
			push_error("Motore: ciclo senza fine in " + str(s.pila.back()))
			return
		var fr: Dictionary = s.pila.back()
		call("_f_" + fr.f, s, fr)

func opzioni(s: Dictionary) -> Array:
	return s.att.opz if s.att != null else []

## Per l'IA: nelle copie di prova (s._ia) l'elenco delle azioni si calcola solo quando serve.
func materializza(s: Dictionary) -> void:
	if s.att != null and s.att.get("pigro", false):
		s.att.erase("pigro")
		s.att.opz = opz_azioni(s, s.att.chi)

func applica(s: Dictionary, i: int) -> void:
	materializza(s)
	if s.att == null or i < 0 or i >= s.att.opz.size():
		return
	var a: Dictionary = s.att
	s.att = null
	s.nd += 1
	call("_r_" + a.tipo, s, a, a.opz[i])
	avanza(s)

func chiedi(s: Dictionary, chi: String, tipo: String, tit: String, opz: Array, extra := {}) -> void:
	var a := {"chi": chi, "tipo": tipo, "tit": tit, "opz": opz}
	a.merge(extra)
	s.att = a

func vittoria(s: Dictionary, p: String, perche: String) -> void:
	s.fine = {"vince": p, "motivo": perche}
	nota(s, "FINE: vince la %s. %s" % [Dati.NOMI[p], perche])

func _controllo_pv(s: Dictionary) -> bool:
	if s.pv >= 30:
		vittoria(s, "FR", "I Punti Vittoria hanno raggiunto 30.")
		return true
	if s.pv <= 0:
		vittoria(s, "BR", "I Punti Vittoria sono scesi a 0.")
		return true
	return false

# ---------------------------------------------------------------- turno di pace
func _f_turno(s: Dictionary, fr: Dictionary) -> void:
	match int(fr.passo):
		0:
			_inizio_turno(s)
			fr.passo = 1
			for p in ["BR", "FR"]:
				s.pila.append({"f": "scarta", "p": p})
		1:
			fr.passo = 2
			s.fase = "Fase dei Ministeri"
			var primo_era: bool = s.turno in [1, 3, 5]
			for p in ["BR", "FR"]:
				s.pila.append({"f": "ministri", "p": p, "primo": primo_era, "k": 0})
		2:
			fr.passo = 3
			if s.pv < 15:
				s.iniz = "FR"
			elif s.pv > 15:
				s.iniz = "BR"
			s.fase = "Fase dell'Iniziativa"
			chiedi(s, s.iniz, "primo", "Hai l'Iniziativa: chi fa il primo Round d'Azione?",
				[{"p": "FR", "et": "Comincia la Francia"}, {"p": "BR", "et": "Comincia la Gran Bretagna"}])
		3:
			s.fase = "Fase delle Azioni"
			var r: int = s.ar.FR + s.ar.BR
			if r >= 8:
				fr.passo = 4
			else:
				var p: String = s.primo if r % 2 == 0 else avv(s.primo)
				s.pila.append({"f": "round", "p": p, "passo": 0})
		4:
			fr.passo = 5
			_fine_turno(s)
		5:
			if s.turno == 6:
				_punteggio_finale(s)
				return
			fr.passo = 6
			if Dati.GUERRA_DOPO.has(s.turno):
				s.pila.append({"f": "guerra", "passo": 0, "i": 0})
		6:
			s.turno += 1
			fr.passo = 0

func _inizio_turno(s: Dictionary) -> void:
	s.era = 1 if s.turno <= 2 else (2 if s.turno <= 4 else 3)
	s.ar = {"FR": 0, "BR": 0}
	s.ar_st = {}
	s.townshend = ""
	nota(s, "=== Turno %d di Pace (%s), era %s ===" % [s.turno, Dati.ANNI[s.turno], Dati.ERE[s.era]])
	s.fase = "Preparazione del turno"
	if s.turno == 3 or s.turno == 5:
		for n in Dati.EVENTI:
			if Dati.EVENTI[n].era == s.era:
				s.mazzo.append(n)
		mescola(s, s.mazzo)
		nota(s, "Entrano nel mazzo gli Eventi dell'era %s. I Limiti di Debito salgono di 4." % Dati.ERE[s.era])
		for p in ["FR", "BR"]:
			s.g[p].lim += 4
			if s.turno == 5:
				var m: Array = s.g[p].mano
				for i in range(m.size() - 1, -1, -1):
					if Dati.EVENTI[m[i]].era == 1:
						s.rimossi.append(m[i])
						m.remove_at(i)
		agg_vantaggi(s)
	# Premi
	if s.turno % 2 == 1:
		s.premi_pila = [0, 1, 2, 3, 4, 5, 6, 7]
		mescola(s, s.premi_pila)
	s.premi = {}
	s.premi_vinti = {}
	s.dom_vinta = {}
	for r in Dati.REG_ORD:
		s.premi[r] = s.premi_pila.pop_back()
	# Domanda globale
	var m2: Array = Dati.MERCI.duplicate()
	mescola(s, m2)
	s.domanda = [m2[0], m2[1], m2[2]]
	var ord := []
	for x in Dati.MERCI:
		if x in s.domanda:
			ord.append(x)
	s.domanda = ord
	var nomi := []
	for x in s.domanda:
		nomi.append(Dati.MERCI_NOME[x])
	nota(s, "Domanda Globale: %s." % ", ".join(nomi))
	# Riassetto
	for v in s.vant:
		s.vant[v].es = false
	for p in ["FR", "BR"]:
		s.g[p].mu = {}
		s.g[p].m17 = 0
		if s.sq_rit[p] > 0:
			s.g[p].sq_box += s.sq_rit[p]
			nota(s, "%d Squadra %s torna nel Riquadro della Marina." % [s.sq_rit[p], Dati.AGG[p]])
			s.sq_rit[p] = 0
	s.inv_usate.append_array(s.inv_disp)
	s.inv_usate.append_array(s.inv_prese.FR)
	s.inv_usate.append_array(s.inv_prese.BR)
	s.inv_disp = []
	s.inv_prese = {"FR": [], "BR": []}
	while s.inv_disp.size() < 9:
		if s.inv_pila.is_empty():
			s.inv_pila = s.inv_usate
			s.inv_usate = []
			mescola(s, s.inv_pila)
		s.inv_disp.append(s.inv_pila.pop_back())
	# Eventi
	for p in ["FR", "BR"]:
		for i in 3:
			_pesca_evento(s, p)

func _pesca_evento(s: Dictionary, p: String) -> bool:
	for tent in 60:
		if s.mazzo.is_empty():
			if s.scarti.is_empty():
				return false
			s.mazzo = s.scarti
			s.scarti = []
			mescola(s, s.mazzo)
		var n: int = s.mazzo.pop_back()
		if s.era == 3 and Dati.EVENTI[n].era == 1:
			s.rimossi.append(n)
			continue
		s.g[p].mano.append(n)
		return true
	return false

func _f_scarta(s: Dictionary, fr: Dictionary) -> void:
	var m: Array = s.g[fr.p].mano
	var lim: int = fr.get("lim", 3)
	if m.size() <= lim:
		s.pila.pop_back()
		return
	var opz := []
	for n in m:
		opz.append({"ev": n, "et": Dati.EVENTI[n].nome})
	chiedi(s, fr.p, "scarta", "Scarta una carta Evento (ne tieni %d)" % lim, opz, {"segreto": true})

func _r_scarta(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	s.g[a.chi].mano.erase(o.ev)
	s.scarti.append(o.ev)
	nota(s, "%s scarta un Evento." % Dati.NOMI[a.chi])

func min_ammessi(s: Dictionary, p: String) -> Array:
	var out := []
	for id in Dati.MINISTERI:
		var d: Dictionary = Dati.MINISTERI[id]
		if d.l == p and s.era in d.ere and not (id == 4 and s.jac_fine):
			out.append(id)
	out.sort()
	return out

func _f_ministri(s: Dictionary, fr: Dictionary) -> void:
	var p: String = fr.p
	var g: Dictionary = s.g[p]
	if fr.primo:
		if fr.k == 0:
			g.min = []
		var normali := 0
		for m in g.min:
			if not m.has("extra"):
				normali += 1
		if normali >= 2:
			_extra_giacobita(s, p)
			s.pila.pop_back()
			return
		var opz := []
		for id in min_ammessi(s, p):
			if not ha_min(s, p, id):
				opz.append({"m": id, "et": Dati.MINISTERI[id].nome})
		fr.k += 1
		chiedi(s, p, "ministro", "Scegli un Ministero (%d di 2)" % (normali + 1), opz, {"segreto": true})
	else:
		# si possono sostituire i Ministeri ancora coperti
		var idx := -1
		var visti := 0
		for i in g.min.size():
			if not g.min[i].riv and not g.min[i].has("extra"):
				if visti == fr.k:
					idx = i
				visti += 1
		if idx < 0:
			_extra_giacobita(s, p)
			s.pila.pop_back()
			return
		fr.k += 1
		var opz2 := [{"m": 0, "i": idx, "et": "Tieni «%s»" % Dati.MINISTERI[g.min[idx].id].nome}]
		for id in min_ammessi(s, p):
			if not ha_min(s, p, id):
				opz2.append({"m": id, "i": idx, "et": "Sostituisci con «%s»" % Dati.MINISTERI[id].nome})
		chiedi(s, p, "ministro", "Ministero coperto «%s»: vuoi sostituirlo?" % Dati.MINISTERI[g.min[idx].id].nome, opz2, {"segreto": true})

func _extra_giacobita(s: Dictionary, p: String) -> void:
	if p == "FR" and s.jac_extra and not s.jac_fine and not ha_min(s, "FR", 4):
		s.g.FR.min.append({"id": 4, "riv": true, "extra": true})

func _r_ministro(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var g: Dictionary = s.g[a.chi]
	if o.m == 0:
		return
	if o.has("i"):
		g.min[o.i] = {"id": o.m, "riv": false}
	else:
		g.min.append({"id": o.m, "riv": false})

func _r_primo(s: Dictionary, _a: Dictionary, o: Dictionary) -> void:
	s.primo = o.p
	nota(s, "Iniziativa alla %s: comincia la %s." % [Dati.NOMI[s.iniz], Dati.NOMI[o.p]])

# ---------------------------------------------------------------- fine turno e punteggio
func conta_regione(s: Dictionary, p: String, reg: String) -> int:
	var n := 0
	for id in S:
		if S[id].reg == reg and ctrl(s, id) == p and not s.confl.has(id) and not S[id].has("usa"):
			n += 1
	return n

func conta_prestigio(s: Dictionary, p: String) -> int:
	var n := 0
	for id in S:
		if S[id].has("pres") and attivo(s, id) and ctrl(s, id) == p and not s.confl.has(id):
			n += 1
	return n

func conta_merce(s: Dictionary, p: String, m: String) -> int:
	var n := 0
	for id in S:
		if S[id].get("merce", "") == m and ctrl(s, id) == p and not s.confl.has(id):
			n += 1
	return n

func _vince(a: int, b: int, margine := 1) -> String:
	if a - b >= margine:
		return "FR"
	if b - a >= margine:
		return "BR"
	return ""

func _fine_turno(s: Dictionary) -> void:
	s.fase = "Punteggio"
	s.ar_st = {}
	for p in ["FR", "BR"]:
		if s.g[p].trp > 4:
			nota(s, "%s perde i PT oltre 4." % Dati.NOMI[p])
			s.g[p].trp = 4
	# poteri di fine turno
	if ha_min(s, "FR", 2):
		rivela(s, "FR", 2)
		var sc := ctrl(s, "p_sco1") == "FR" or ctrl(s, "p_sco2") == "FR"
		debito(s, "FR", -2 if sc else -1)
	nota(s, "--- Punteggio del turno %d ---" % s.turno)
	var vinti := {"FR": 0, "BR": 0}
	for reg in Dati.REG_ORD:
		var pr: Array = Dati.PREMI[s.premi[reg]]
		var w := _vince(conta_regione(s, "FR", reg), conta_regione(s, "BR", reg), pr[2])
		s.premi_vinti[reg] = w
		if w == "":
			nota(s, "%s: nessun Premio (%d a %d)." % [Dati.REGIONI[reg], conta_regione(s, "FR", reg), conta_regione(s, "BR", reg)])
			continue
		vinti[w] += 1
		var punti: int = pr[0]
		var pt: int = pr[1]
		if reg == "EU":
			if w == "FR" and _min_riv(s, "FR", 3):
				punti += 1
			if w == "BR" and _min_riv(s, "BR", 18):
				punti += 1
			if w == "FR" and _min_riv(s, "BR", 18):
				punti = max(0, punti - 1)
			if _min_riv(s, "FR", 14):
				var k := 0
				for paese in paesi:
					if paesi[paese].size() > 1:
						for id in paesi[paese]:
							if S[id].has("pres") and ctrl(s, id) == "FR" and not s.confl.has(id):
								k += 1
								break
				trp(s, "FR", min(3, k))
		if reg == "IN" and w == "FR" and _min_riv(s, "FR", 12):
			pt += 1
		nota(s, "%s: Premio alla %s (%d a %d)." % [Dati.REGIONI[reg], Dati.NOMI[w], conta_regione(s, "FR", reg), conta_regione(s, "BR", reg)])
		pv(s, w, punti, "Premio " + Dati.REGIONI[reg])
		trp(s, w, pt)
	var wp := _vince(conta_prestigio(s, "FR"), conta_prestigio(s, "BR"))
	if wp != "":
		pv(s, wp, 2, "Prestigio in Europa")
	for m in s.domanda:
		var w2 := _assegna_merce(s, m)
		if w2 != "":
			vinti[w2] += 1
	if _min_riv(s, "BR", 7):
		var k2 := 0
		for v in ["Textiles", "Silk", "Fruit", "Fur Trade", "Rum"]:
			if s.vant[v].di == "BR" and not s.vant[v].es:
				k2 += 1
		pv(s, "BR", min(3, k2), "Compagnia delle Indie Orientali")
	for p in ["FR", "BR"]:
		if vinti[p] == 7:
			vittoria(s, p, "Ha vinto tutti i Premi regionali e tutta la Domanda Globale.")
			return
	_controllo_pv(s)

func _min_riv(s: Dictionary, p: String, id: int) -> bool:
	for m in s.g[p].min:
		if m.id == id and m.riv:
			return true
	return false

func _assegna_merce(s: Dictionary, m: String) -> String:
	var w := _vince(conta_merce(s, "FR", m), conta_merce(s, "BR", m))
	s.dom_vinta[m] = w
	if w == "":
		return ""
	var r: Array = Dati.DOMANDA[m][s.era - 1]
	var pt: int = r[1]
	if w == "FR" and (m == "cotone" or m == "spezie") and _min_riv(s, "FR", 12):
		pt += 1
	pv(s, w, r[0], "Domanda di " + Dati.MERCI_NOME[m])
	trp(s, w, pt)
	if r[2] != 0:
		debito(s, w, r[2])
	return w

func _punteggio_finale(s: Dictionary) -> void:
	nota(s, "--- Punteggio finale ---")
	var wp := _vince(conta_prestigio(s, "FR"), conta_prestigio(s, "BR"))
	if wp != "":
		pv(s, wp, 2, "più spazi Prestigio")
	var d := deb_disp(s, "FR") - deb_disp(s, "BR")
	if abs(d) >= 2:
		pv(s, "FR" if d > 0 else "BR", min(4, abs(d) / 2), "Debito Disponibile")
	for m in Dati.MERCI:
		var w := _vince(conta_merce(s, "FR", m), conta_merce(s, "BR", m))
		if w != "":
			pv(s, w, 1, "più Mercati di " + Dati.MERCI_NOME[m])
	for id in S:
		if S[id].tipo == "T" and S[id].has("iniz"):
			var c := ctrl(s, id)
			if S[id].iniz == "BR" and (c == "FR" or c == "US"):
				pv(s, "FR", 2, "bandiera in " + S[id].nome)
			elif S[id].iniz == "FR" and c == "BR":
				pv(s, "BR", 2, "bandiera in " + S[id].nome)
	if s.pv >= 16:
		vittoria(s, "FR", "La partita finisce con %d PV." % s.pv)
	elif s.pv <= 14:
		vittoria(s, "BR", "La partita finisce con %d PV." % s.pv)
	elif deb_disp(s, "FR") > deb_disp(s, "BR"):
		vittoria(s, "FR", "Pareggio a 15 PV: la Francia ha più Debito Disponibile.")
	else:
		vittoria(s, "BR", "Pareggio a 15 PV: la Gran Bretagna prevale.")

# ---------------------------------------------------------------- Round d'Azione
func _f_round(s: Dictionary, fr: Dictionary) -> void:
	var p: String = fr.p
	match int(fr.passo):
		0:
			for v in s.vant:
				s.vant[v].nuovo = false
			s.ar_st = {"p": p, "tess": -1, "mag": {"t": "", "n": 0}, "min": {"t": "", "n": 0, "us": true}, "ex": [],
				"reg": {"E": [], "D": [], "M": []}, "nuovi": [], "isol": isolati(s), "vu": 0, "vreg": [], "bc": 0, "sqm": [],
				"sconti": [], "sq2": false, "sq_meno": 0, "usato": false, "ev": 0, "up": false, "deb1": false, "pomp": false,
				"watt": false, "conv": "", "jac": false, "patto": false, "hanb": false, "ugo_sc": "", "bonus_ev": false}
			nota(s, "-- Round d'Azione %d della %s --" % [s.ar[p] + 1, Dati.NOMI[p]])
			if p == "BR" and ha_min(s, "BR", 8) and not usato(s, "BR", "m8a"):
				s.g.BR.mu["m8a"] = true
				rivela(s, "BR", 8)
				s.g.BR.lim += 1
				nota(s, "Banca d'Inghilterra: il Limite di Debito britannico sale a %d." % s.g.BR.lim)
			if p == "FR" and ha_min(s, "FR", 24):
				for k in s.ugo:
					s.ugo[k] = false
			fr.passo = 1
			if s.turno == 4 and s.gratis7[p] > 0:
				for i in s.gratis7[p]:
					var t := _pesca_bonus(s, p)
					if t >= 0:
						s.pila.append({"f": "bonus_guerra", "p": p, "t": t})
				s.gratis7[p] = 0
		1:
			var opz := []
			for i in s.inv_disp:
				var d: Dictionary = DatiGen.INVEST[i]
				opz.append({"t": i, "et": "%s %d + %s 2%s%s" % [Dati.SIGLA_PA[d.mag], d.n, Dati.SIGLA_PA[d.min], ", Evento" if d.ev else "", ", Miglioria militare" if d.up else ""]})
			if p == "BR" and ha_min(s, "BR", 5) and not usato(s, "BR", "m5") and (not s.mazzo.is_empty() or not s.scarti.is_empty()):
				opz.append({"x": "walpole", "et": "Walpole: pesca un Evento, poi scartane uno"})
			if p == "BR" and ha_min(s, "BR", 21) and not usato(s, "BR", "m21"):
				for m in Dati.MERCI:
					opz.append({"x": "townshend", "m": m, "et": "Leggi Townshend su " + Dati.MERCI_NOME[m]})
			chiedi(s, p, "tessera", "Scegli una tessera Investimento", opz)
		2:
			fr.passo = 3
			var gioc := eventi_giocabili(s, p)
			if gioc.is_empty():
				return
			var opz2 := []
			for n in gioc:
				opz2.append({"ev": n, "et": "Gioca «%s»" % Dati.EVENTI[n].nome})
			opz2.append({"ev": 0, "et": "Non giocare Eventi"})
			chiedi(s, p, "evento", "Vuoi giocare un Evento?", opz2)
		3:
			if s.has("_ia"):
				chiedi(s, p, "azione", "", [], {"pigro": true})
			else:
				chiedi(s, p, "azione", "Spendi i tuoi Punti Azione", opz_azioni(s, p))
		4:
			_fine_round(s, p)
			s.pila.pop_back()

func _fine_round(s: Dictionary, p: String) -> void:
	s.inv_prese[p].append(s.ar_st.tess)
	s.ar[p] += 1
	if s.ar[p] >= 4:
		# all'ultimo Round si rivelano i Ministeri che servono a punteggio e guerra
		var prossima: String = Dati.GUERRA_DOPO.get(s.turno, "")
		for m in s.g[p].min:
			if m.riv:
				continue
			var utile: bool = m.id in [2, 3, 7, 12, 14, 18]
			if prossima != "":
				for t in Dati.GUERRE[prossima].teatri:
					for k in Dati.MINISTERI[m.id].kw:
						if ("K:" + k) in t.bonus:
							utile = true
			if utile:
				rivela(s, p, m.id)
	s.ar_st = {}

func eventi_giocabili(s: Dictionary, p: String) -> Array:
	var ar: Dictionary = s.ar_st
	var d: Dictionary = DatiGen.INVEST[ar.tess]
	var condorcet: bool = p == "FR" and ha_min(s, "FR", 25) and not usato(s, "FR", "m25")
	if not d.ev and not condorcet:
		return []
	var out := []
	for n in s.g[p].mano:
		var e: Dictionary = Dati.EVENTI[n]
		var ok: bool = e.tipo == "" or e.tipo == d.mag
		if not ok and d.ev and e.tipo == "E" and p == "BR" and ha_min(s, "BR", 8) and not usato(s, "BR", "m8b"):
			ok = true
		if ok:
			out.append(n)
	return out

func _r_tessera(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var p: String = a.chi
	var ar: Dictionary = s.ar_st
	if o.has("x"):
		if o.x == "walpole":
			s.g.BR.mu["m5"] = true
			rivela(s, "BR", 5)
			_pesca_evento(s, "BR")
			nota(s, "Walpole: la Gran Bretagna pesca un Evento e ne scarta uno.")
			s.pila.append({"f": "scarta", "p": "BR", "lim": s.g.BR.mano.size() - 1})
		elif o.x == "townshend":
			s.g.BR.mu["m21"] = true
			rivela(s, "BR", 21)
			s.townshend = o.m
			nota(s, "Leggi Townshend: le Azioni Minori britanniche possono togliere bandiere dai Mercati di %s." % Dati.MERCI_NOME[o.m])
		return
	var d: Dictionary = DatiGen.INVEST[o.t]
	s.inv_disp.erase(o.t)
	ar.tess = o.t
	ar.mag = {"t": d.mag, "n": d.n}
	ar.min = {"t": d.min, "n": 2, "us": false}
	nota(s, "%s prende la tessera %s." % [Dati.NOMI[p], o.et])
	var ha_d: bool = d.mag == "D" or d.min == "D"
	var ha_m: bool = d.mag == "M" or d.min == "M"
	if p == "FR":
		if ha_d and ha_min(s, "FR", 1) and not usato(s, "FR", "m1"):
			var k := 0
			for id in ["p_sav", "p_sar", "p_spa3", "p_spa4", "p_aus3", "p_aus4"]:
				if ctrl(s, id) == "FR" and not s.confl.has(id):
					k += 1
			k = min(3, k)
			if k > 0:
				s.g.FR.mu["m1"] = true
				rivela(s, "FR", 1)
				(ar.mag if d.mag == "D" else ar.min).n += k
				nota(s, "I cardinali ministri: +%d PD." % k)
		if ha_m and ha_min(s, "FR", 11) and not usato(s, "FR", "m11a"):
			s.g.FR.mu["m11a"] = true
			rivela(s, "FR", 11)
			ar.ex.append({"t": "M", "n": 1, "lim": "@bonus_schiera", "et": "Choiseul"})
		if ha_min(s, "FR", 24) and (d.mag == "E" or d.min == "E"):
			var mio := conta_merce(s, "FR", "pelli") + conta_merce(s, "FR", "pesce")
			var suo := conta_merce(s, "BR", "pelli") + conta_merce(s, "BR", "pesce")
			if mio > suo:
				rivela(s, "FR", 24)
				(ar.mag if d.mag == "E" else ar.min).n += 1
				nota(s, "Commercio nordamericano: +1 PE.")
	else:
		if ha_d and ha_min(s, "BR", 15) and not usato(s, "BR", "m15a"):
			s.g.BR.mu["m15a"] = true
			rivela(s, "BR", 15)
			ar.ex.append({"t": "D", "n": 1, "lim": "@nopres", "et": "Pitt"})
		if ha_d and ha_min(s, "BR", 20) and not usato(s, "BR", "m20"):
			s.g.BR.mu["m20"] = true
			rivela(s, "BR", 20)
			ar.ex.append({"t": "D", "n": 2, "lim": "paese=Scozia,Irlanda", "et": "Papato-Hannover"})
		if d.mag == "D" and ha_min(s, "BR", 22):
			var k2 := 0
			for id in ["p_irl1", "p_irl2"]:
				if ctrl(s, id) == "BR":
					k2 += 1
			if k2 > 0:
				rivela(s, "BR", 22)
				ar.ex.append({"t": "D", "n": k2, "lim": "reg=EU", "et": "Burke"})
	s.pila.back().passo = 2

func _r_evento(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	if o.ev == 0:
		return
	var p: String = a.chi
	var ar: Dictionary = s.ar_st
	var d: Dictionary = DatiGen.INVEST[ar.tess]
	var e: Dictionary = Dati.EVENTI[o.ev]
	if not d.ev:
		s.g.FR.mu["m25"] = true
		rivela(s, "FR", 25)
	elif e.tipo != "" and e.tipo != d.mag:
		s.g.BR.mu["m8b"] = true
		rivela(s, "BR", 8)
	gioca_evento(s, p, o.ev)

func gioca_evento(s: Dictionary, p: String, n: int) -> void:
	var e: Dictionary = Dati.EVENTI[n]
	var v: Dictionary = e.get("TT", e.get(p, {}))
	s.g[p].mano.erase(n)
	s.rimossi.append(n)
	s.ar_st.ev = n
	s.ar_st.usato = true
	var bon := cond_ok(s, p, e.cond)
	if bon and e.cond.begins_with("K:"):
		for m in s.g[p].min:
			if e.cond.substr(2) in Dati.MINISTERI[m.id].kw:
				rivela(s, p, m.id)
				break
	nota(s, "%s gioca l'Evento «%s»%s: %s" % [Dati.NOMI[p], e.nome, " con il Bonus" if bon and not v.bonus.is_empty() else "", v.t])
	if bon and not v.bonus.is_empty():
		s.ar_st.bonus_ev = true
		for i in range(v.bonus.size() - 1, -1, -1):
			s.pila.append({"f": "passo", "chi": p, "st": v.bonus[i], "bon": true})
		if p == "FR" and ha_min(s, "FR", 26):
			rivela(s, "FR", 26)
			s.ar_st.mag.n += 1
			s.ar_st.min.n += 1
			nota(s, "Lavoisier: +1 Punto Azione alle Azioni Maggiore e Minore.")
	for i in range(v.base.size() - 1, -1, -1):
		s.pila.append({"f": "passo", "chi": p, "st": v.base[i], "bon": bon})

func _f_passo(s: Dictionary, fr: Dictionary) -> void:
	s.pila.pop_back()
	var st: Dictionary = fr.st
	var p: String = fr.chi
	match st.k:
		"pa":
			s.ar_st.ex.append({"t": st.t, "n": st.n, "lim": st.get("lim", ""), "solo": st.get("solo", ""), "ev": true, "et": "Evento"})
			nota(s, "%s riceve %d %s%s." % [Dati.NOMI[p], st.n, Dati.SIGLA_PA[st.t], " (con vincoli)" if st.get("lim", "") != "" or st.get("solo", "") != "" else ""])
		"deb":
			debito(s, p if st.chi == "io" else avv(p), st.n)
		"pv":
			pv(s, p, st.n)
		"trp":
			trp(s, p, st.n)
		"sp":
			s.pila.append({"f": "spazi", "chi": p, "az": st.az, "flt": st.f, "n": st.get("n", 1), "fatto": 0})
		"scelta":
			var opz := []
			for o in st.opz:
				opz.append({"et": o.et, "p": o.p})
			chiedi(s, p, "scelta", "Scegli l'effetto", opz, {"bon": fr.bon})
		"x":
			call("_x_" + st.f, s, fr)

func _r_scelta(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	for i in range(o.p.size() - 1, -1, -1):
		s.pila.append({"f": "passo", "chi": a.chi, "st": o.p[i], "bon": a.get("bon", false)})

const TIT_AZ := {"via": "Togli una bandiera nemica", "via_mia": "Togli una tua bandiera", "metti": "Metti una bandiera", "sposta": "Sposta uno spazio",
	"prendi": "Prendi il controllo di uno spazio", "confl": "Metti un segnalino Conflitto", "confl+": "Metti un segnalino Conflitto (+1)",
	"danno": "Danneggia un Forte nemico", "via_sq": "Rimanda una Squadra nemica nel Riquadro della Marina", "dan_o_sq": "Danneggia un Forte o rimuovi una Squadra del nemico",
	"via_guerra": "Togli una bandiera nemica nella regione del teatro"}

func candidati(s: Dictionary, p: String, az: String, f: String, regs := []) -> Array:
	var a := avv(p)
	var out := []
	for id in S:
		var d: Dictionary = S[id]
		if not attivo(s, id) or not filtro_ok(s, p, id, f):
			continue
		if not regs.is_empty() and not (d.reg in regs):
			continue
		var o := ctrl(s, id)
		var mp: bool = d.tipo == "M" or d.tipo == "P"
		var ok := false
		match az:
			"via": ok = mp and o == a
			"via_mia": ok = d.tipo == "M" and o == p
			"metti": ok = mp and o == ""
			"sposta": ok = mp and (o == a or o == "")
			"prendi": ok = mp and (o == a or o == "")
			"confl", "confl+": ok = mp and not s.confl.has(id)
			"danno": ok = d.tipo == "F" and o == a and not s.danno.has(id)
			"via_sq": ok = d.tipo == "N" and o == a
			"dan_o_sq": ok = (d.tipo == "F" and o == a and not s.danno.has(id)) or (d.tipo == "N" and o == a)
			"via_guerra": ok = mp and o == a and not s.confl.has(id)
		if ok:
			out.append(id)
	if az == "via_guerra":
		# un Mercato che non isoli altri Mercati, se possibile
		var buoni := []
		for id in out:
			if S[id].tipo == "P" or not _isolerebbe(s, id):
				buoni.append(id)
		if not buoni.is_empty():
			return buoni
	return out

func _f_spazi(s: Dictionary, fr: Dictionary) -> void:
	if fr.fatto >= fr.n:
		s.pila.pop_back()
		return
	var c := candidati(s, fr.chi, fr.az, fr.flt, fr.get("regs", []))
	if c.is_empty():
		s.pila.pop_back()
		return
	var opz := []
	for id in c:
		opz.append({"sp": id, "et": nome_sp(id)})
	if fr.get("fac", false):
		opz.append({"salta": true, "et": "Basta così"})
	chiedi(s, fr.chi, "spazi", TIT_AZ.get(fr.az, "Scegli uno spazio") + (" (%d di %d)" % [fr.fatto + 1, fr.n] if fr.n > 1 else ""), opz)

func _r_spazi(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var fr: Dictionary = s.pila.back()
	if o.has("salta"):
		s.pila.pop_back()
		return
	fr.fatto += 1
	fai(s, a.chi, fr.az, o.sp)

func fai(s: Dictionary, p: String, az: String, id: String) -> void:
	var o := ctrl(s, id)
	match az:
		"via", "via_mia", "via_guerra":
			togli(s, id)
			nota(s, "%s: tolta la bandiera %s." % [nome_sp(id), Dati.AGG.get(o, "")])
		"metti":
			metti(s, id, p)
			nota(s, "%s: bandiera %s." % [nome_sp(id), Dati.AGG[p]])
		"sposta":
			if o == avv(p):
				fai(s, p, "via", id)
			else:
				fai(s, p, "metti", id)
		"prendi":
			togli(s, id)
			metti(s, id, p)
			nota(s, "%s prende il controllo di %s." % [Dati.NOMI[p], nome_sp(id)])
		"confl", "confl+":
			s.confl[id] = 2 if az == "confl+" else 1
			nota(s, "Conflitto in %s." % nome_sp(id))
		"danno":
			s.danno[id] = true
			nota(s, "Il Forte di %s è danneggiato." % S[id].nome)
		"via_sq":
			squadra_via(s, id)
		"dan_o_sq":
			if S[id].tipo == "F":
				fai(s, p, "danno", id)
			else:
				squadra_via(s, id)

# ---------------------------------------------------------------- costi e pagamenti
func collegato(s: Dictionary, p: String, id: String) -> bool:
	var ar: Dictionary = s.ar_st
	for n in adiac[id]:
		if ctrl(s, n) != p:
			continue
		if S[n].tipo != "M":
			return true
		if not s.confl.has(n) and not (n in ar.isol) and not (n in ar.nuovi):
			return true
	return false

func _sconto(s: Dictionary, p: String, id: String) -> int:
	var ar: Dictionary = s.ar_st
	for i in ar.sconti.size():
		if filtro_ok(s, p, id, ar.sconti[i].f):
			return i
	return -1

## Costo per spostare un Mercato o uno spazio Politico: {c, sc (indice sconto usato), ugo, hanb}
func costo_spazio(s: Dictionary, p: String, id: String) -> Dictionary:
	var ar: Dictionary = s.ar_st
	var d: Dictionary = S[id]
	var o := ctrl(s, id)
	var via: bool = o == avv(p)
	var base: int = d.costo
	var r := {"c": 0, "sc": -1, "ugo": false, "hanb": false}
	if s.confl.has(id) or (d.tipo == "M" and o != "" and id in ar.isol):
		base = 1
	if via:
		r.sc = _sconto(s, p, id)
		if r.sc >= 0:
			if ar.sconti[r.sc].k == "tot1":
				r.c = 1
				return r
			base -= 1
	if d.tipo == "M":
		if ar.ugo_sc == d.reg:
			base -= 1
			r.ugo = true
		if via and protetto(s, id):
			base = max(base, 0) + 1
	else:
		var paese: String = d.get("paese", "")
		if p == "BR":
			if not via and paese in ["Irlanda", "Scozia"] and ha_min(s, "BR", 6):
				base -= 1
			if (id == "p_sol" or d.has("usa")) and ha_min(s, "BR", 22):
				base -= 1
			if via and paese in ["Prussia", "Stati tedeschi", "Russia"] and ha_min(s, "BR", 16) and (ar.hanb or not usato(s, "BR", "m16")):
				base -= 1
				r.hanb = true
			if via and ar.patto and paese in ["Spagna", "Austria"]:
				base -= 1
	r.c = max(1, base)
	return r

func _sovr(ar: Dictionary, t: String, reg: String) -> int:
	return 1 if not ar.reg[t].is_empty() and not (reg in ar.reg[t]) else 0

func _pool_ok(s: Dictionary, p: String, e: Dictionary, ctx: Dictionary) -> bool:
	var solo: String = e.get("solo", "")
	if solo != "":
		if not (ctx.gen in ["merc", "pol"]) or ctx.get("az", "") != solo:
			return false
	var lim: String = e.get("lim", "")
	if lim == "":
		return true
	if lim == "@bonus_schiera":
		return ctx.gen in ["bonus", "schiera"]
	if lim == "@nopres":
		return ctx.gen == "pol" and not S[ctx.sp].has("pres")
	var sp: String = ctx.get("sp", "")
	return sp != "" and filtro_ok(s, p, sp, lim)

func _minore_ok(s: Dictionary, p: String, ctx: Dictionary) -> bool:
	if ctx.get("az", "") != "via":
		return true
	var sp: String = ctx.get("sp", "")
	if sp == "":
		return false
	if s.confl.has(sp):
		return true
	if p == "BR" and ctx.gen == "pol" and S[sp].reg == "EU" and ha_min(s, "BR", 6) and (ctrl(s, "p_irl1") == "BR" or ctrl(s, "p_irl2") == "BR"):
		return true
	if p == "BR" and ctx.gen == "merc" and s.townshend != "" and S[sp].get("merce", "") == s.townshend:
		return true
	return false

## Come si paga un acquisto di tipo t: riserve vincolate, Azione Maggiore o Minore, poi PT e Debito.
func piano(s: Dictionary, p: String, t: String, costo: int, ctx: Dictionary) -> Dictionary:
	var ar: Dictionary = s.ar_st
	var g: Dictionary = s.g[p]
	var rem := costo
	var usi := []
	var maggiore := false
	for i in ar.ex.size():
		var e: Dictionary = ar.ex[i]
		if e.t != t or e.n <= 0 or rem <= 0 or not _pool_ok(s, p, e, ctx):
			continue
		var k: int = min(rem, e.n)
		usi.append([i, k])
		rem -= k
		if e.get("ev", false):
			maggiore = true
	var dal_mag := 0
	var dal_min := 0
	var base := ""
	if ar.mag.t == t:
		base = "mag"
		dal_mag = min(rem, ar.mag.n)
		rem -= dal_mag
	elif maggiore:
		base = "ev"
	elif ar.min.t == t and not ar.min.us:
		if not _minore_ok(s, p, ctx):
			return {"ok": false}
		base = "min"
		dal_min = min(rem, ar.min.n)
		rem -= dal_min
	elif rem > 0 or usi.is_empty():
		return {"ok": false}
	var gratis := 0
	var pt := 0
	var deb := 0
	var turgot := false
	if rem > 0:
		if p == "BR" and t == "E" and g.m17 < 2 and ha_min(s, "BR", 17):
			gratis = min(rem, 2 - g.m17)
			rem -= gratis
		var spazio: int = max(0, g.lim - g.deb)
		if g.pref_trp:
			pt = min(rem, g.trp)
			deb = rem - pt
		else:
			deb = min(rem, spazio)
			pt = rem - deb
		if deb > 0 and p == "FR" and not ar.deb1 and ha_min(s, "FR", 23) and deb_disp(s, "FR") > deb_disp(s, "BR") and deb >= 2:
			deb -= 1
			turgot = true
		if deb > spazio:
			pt += deb - spazio
			deb = spazio
		if pt > g.trp:
			return {"ok": false}
	return {"ok": true, "c": costo, "usi": usi, "mag": dal_mag, "min": dal_min, "base": base, "gratis": gratis, "pt": pt, "deb": deb, "turgot": turgot, "t": t}

func paga(s: Dictionary, p: String, pl: Dictionary) -> void:
	var ar: Dictionary = s.ar_st
	var g: Dictionary = s.g[p]
	for u in pl.usi:
		ar.ex[u[0]].n -= u[1]
	ar.mag.n -= pl.mag
	if pl.base == "min":
		ar.min.n = 0
		ar.min.us = true
	if pl.gratis > 0:
		g.m17 += pl.gratis
		rivela(s, p, 17)
	if pl.pt > 0:
		g.trp -= pl.pt
	if pl.deb > 0:
		g.deb += pl.deb
		ar.deb1 = true
		if pl.turgot:
			rivela(s, "FR", 23)
	ar.usato = true

func _testo_pag(pl: Dictionary) -> String:
	var parti := []
	if pl.pt > 0:
		parti.append("%d PT" % pl.pt)
	if pl.deb > 0:
		parti.append("%d Debito" % pl.deb)
	if pl.gratis > 0:
		parti.append("%d gratis" % pl.gratis)
	var x := " + ".join(parti)
	return "%d %s%s%s" % [pl.c, Dati.SIGLA_PA[pl.t], " (Minore)" if pl.base == "min" else "", (", di cui " + x) if x != "" else ""]

func _costo_squadra(s: Dictionary, p: String) -> Dictionary:
	var ar: Dictionary = s.ar_st
	var c := 4
	var uso := ""
	if ar.sq2:
		c = 2
		uso = "sq2"
	elif p == "BR" and ha_min(s, "BR", 10) and not usato(s, "BR", "m10a"):
		c = 2
		uso = "m10a"
	elif p == "BR" and ha_min(s, "BR", 15) and not usato(s, "BR", "m15b"):
		c = 2
		uso = "m15b"
	elif p == "FR" and ha_min(s, "FR", 11) and not usato(s, "FR", "m11b") and not squadre_mappa(s, "FR", ["NA"]).is_empty():
		c = 2
		uso = "m11b"
	return {"c": max(0, c - ar.sq_meno), "uso": uso}

# ---------------------------------------------------------------- elenco delle azioni possibili
func opz_azioni(s: Dictionary, p: String) -> Array:
	var ar: Dictionary = s.ar_st
	var a := avv(p)
	var g: Dictionary = s.g[p]
	var out := []
	var jac_ok: bool = p == "FR" and ha_min(s, "FR", 4) and (ar.jac or not usato(s, "FR", "jac_m")) and int(g.mu.get("jac_pv_ar", -1)) != s.ar.FR
	for id in S:
		var d: Dictionary = S[id]
		if not attivo(s, id):
			continue
		var o := ctrl(s, id)
		if d.tipo == "M" and o != p:
			if not collegato(s, p, id):
				continue
			var az := "via" if o == a else "metti"
			var cs := costo_spazio(s, p, id)
			var pl := piano(s, p, "E", cs.c + _sovr(ar, "E", d.reg), {"az": az, "sp": id, "gen": "merc"})
			if pl.ok:
				out.append({"a": "merc", "sp": id, "pl": pl, "cs": cs, "et": "%s %s: %s" % ["Togli la bandiera da" if az == "via" else "Bandiera in", d.nome, _testo_pag(pl)]})
		elif d.tipo == "P" and o != p and o != "US":
			var az2 := "via" if o == a else "metti"
			var cs2 := costo_spazio(s, p, id)
			var pl2 := piano(s, p, "D", cs2.c + _sovr(ar, "D", d.reg), {"az": az2, "sp": id, "gen": "pol"})
			if pl2.ok:
				out.append({"a": "pol", "sp": id, "pl": pl2, "cs": cs2, "et": "%s %s: %s" % ["Togli la bandiera da" if az2 == "via" else "Bandiera in", nome_sp(id), _testo_pag(pl2)]})
			if jac_ok and d.get("paese", "") in ["Scozia", "Irlanda"]:
				var pl3 := piano(s, p, "M", cs2.c, {"az": az2, "sp": id, "gen": "jac"})
				if pl3.ok:
					out.append({"a": "pol", "sp": id, "pl": pl3, "cs": cs2, "jac": true, "et": "Giacobiti: %s %s: %s" % ["togli la bandiera da" if az2 == "via" else "bandiera in", nome_sp(id), _testo_pag(pl3)]})
		elif d.tipo == "F":
			if o == "":
				var ok := false
				for n in adiac[id]:
					if ctrl(s, n) == p and S[n].tipo in ["M", "N", "T"] and not (n in ar.nuovi):
						ok = true
				if ok:
					var pl4 := piano(s, p, "M", d.costo, {"sp": id, "gen": "forte"})
					if pl4.ok:
						out.append({"a": "forte", "sp": id, "pl": pl4, "et": "Costruisci il Forte di %s: %s" % [d.nome, _testo_pag(pl4)]})
			elif s.danno.has(id):
				if o == p:
					var pl5 := piano(s, p, "M", max(1, d.costo - 1), {"sp": id, "gen": "ripara"})
					if pl5.ok:
						out.append({"a": "ripara", "sp": id, "pl": pl5, "et": "Ripara il Forte di %s: %s" % [d.nome, _testo_pag(pl5)]})
				elif o == a:
					var ok2 := false
					for n in adiac[id]:
						if ctrl(s, n) == p and S[n].tipo in ["M", "N"]:
							ok2 = true
					if ok2:
						var pl6 := piano(s, p, "M", d.costo + 1, {"az": "via", "sp": id, "gen": "ripara"})
						if pl6.ok and pl6.base != "min":
							out.append({"a": "ripara", "sp": id, "pl": pl6, "prendi": true, "et": "Occupa e ripara il Forte di %s: %s" % [d.nome, _testo_pag(pl6)]})
		elif d.tipo == "N" and o != p:
			var az3 := "via" if o == a else ""
			if g.sq_box > 0:
				var pl7 := piano(s, p, "M", 3 if o == a else 1, {"az": az3, "sp": id, "gen": "schiera"})
				if pl7.ok and not (pl7.base == "min" and o == a):
					out.append({"a": "schiera", "sp": id, "da": "", "pl": pl7, "et": "Schiera una Squadra in %s%s: %s" % [d.nome, " (scaccia il nemico)" if o == a else "", _testo_pag(pl7)]})
			if g.sq_box == 0 or o == a:
				for src in squadre_mappa(s, p):
					if src in ar.sqm:
						continue
					var pl8 := piano(s, p, "M", 2 if o == a else 1, {"az": az3, "sp": id, "gen": "schiera"})
					if pl8.ok and not (pl8.base == "min" and o == a):
						out.append({"a": "schiera", "sp": id, "da": src, "pl": pl8, "et": "Sposta la Squadra da %s a %s: %s" % [S[src].nome, d.nome, _testo_pag(pl8)]})
	for id in s.confl:
		var c: int = (1 if protetto(s, id) else 2) + (1 if s.confl[id] == 2 else 0)
		var pl9 := piano(s, p, "M", c, {"sp": id, "gen": "pace"})
		if pl9.ok:
			out.append({"a": "pace", "sp": id, "pl": pl9, "et": "Rimuovi il Conflitto da %s: %s" % [nome_sp(id), _testo_pag(pl9)]})
	if (not s.mazzo.is_empty() or not s.scarti.is_empty()):
		var pl10 := piano(s, p, "D", 3, {"gen": "pesca"})
		if pl10.ok:
			out.append({"a": "pesca", "pl": pl10, "et": "Pesca una carta Evento: %s" % _testo_pag(pl10)})
	if s.turno < 6 and ar.bc < 2 and not g.bonus.is_empty() and not _teatri_liberi(s, p).is_empty():
		var pl11 := piano(s, p, "M", 2, {"gen": "bonus"})
		if pl11.ok:
			out.append({"a": "bonus", "pl": pl11, "et": "Compra una tessera Guerra Bonus: %s" % _testo_pag(pl11)})
	if g.sq_non > 0:
		var csq := _costo_squadra(s, p)
		var pl12 := piano(s, p, "M", csq.c, {"gen": "sq"})
		if csq.c == 0:
			pl12 = {"ok": true, "c": 0, "usi": [], "mag": 0, "min": 0, "base": "", "gratis": 0, "pt": 0, "deb": 0, "turgot": false, "t": "M"}
		if pl12.ok:
			out.append({"a": "sq", "pl": pl12, "uso": csq.uso, "et": "Costruisci una Squadra: %s" % _testo_pag(pl12)})
	if s.turno == 6:
		for t in ["E", "D"]:
			if ar.conv == "" or ar.conv == t:
				var pl13 := piano(s, p, "M", 2, {"gen": "conv"})
				if pl13.ok:
					out.append({"a": "conv", "t": t, "pl": pl13, "et": "Converti 2 PM in 1 %s: %s" % [Dati.SIGLA_PA[t], _testo_pag(pl13)]})
	if p == "FR" and ha_min(s, "FR", 4) and not usato(s, "FR", "jac_pv") and not ar.jac and int(g.mu.get("jac_m_ar", -1)) != s.ar.FR:
		var n: int = s.jac_vitt
		for id in ["p_sco1", "p_sco2", "p_irl1", "p_irl2"]:
			if ctrl(s, id) == "FR":
				n += 1
		n = min(4, n)
		var pl14 := piano(s, p, "M", 3, {"gen": "jacpv"})
		if n > 0 and pl14.ok:
			out.append({"a": "jacpv", "n": n, "pl": pl14, "et": "Insurrezioni giacobite: segna %d PV: %s" % [n, _testo_pag(pl14)]})
	# azioni gratuite
	if ar.vu < 2:
		for v in s.vant:
			var st: Dictionary = s.vant[v]
			var dv: Dictionary = Dati.VANTAGGI[v]
			if st.di != p or st.es or st.nuovo or dv.reg in ar.vreg:
				continue
			if not vant_usabile(s, p, v):
				continue
			out.append({"a": "vant", "v": v, "et": "Vantaggio «%s»: %s" % [dv.it, dv.d]})
	var di: Dictionary = DatiGen.INVEST[ar.tess]
	if di.up and not ar.up:
		if s.turno == 6:
			out.append({"a": "up", "i": -1, "et": "Miglioria militare: guadagna 1 PT"})
		else:
			for i in s.guerra.teatri.size():
				if s.guerra.teatri[i][p].base >= 0 and not g.base.is_empty():
					out.append({"a": "up", "i": i, "et": "Miglioria militare nel teatro «%s»" % Dati.GUERRE[s.guerra.id].teatri[i].nome})
	for m in g.min:
		if not m.riv:
			out.append({"a": "rivela", "m": m.id, "et": "Rivela il Ministero «%s»" % Dati.MINISTERI[m.id].nome})
	if p == "BR" and ha_min(s, "BR", 10) and not usato(s, "BR", "m10b") and not squadre_mappa(s, "BR", ["EU"]).is_empty():
		for n2 in g.mano:
			out.append({"a": "halley", "ev": n2, "et": "Halley: scarta «%s» e prendi 1 PT" % Dati.EVENTI[n2].nome})
	if p == "FR" and ha_min(s, "FR", 9):
		if not usato(s, "FR", "m9"):
			for id in S:
				if S[id].tipo == "T" and S[id].reg in ["NA", "CA"] and ctrl(s, id) == "FR" and not s.ugo.has(id):
					out.append({"a": "ugo", "sp": id, "et": "Metti gli Ugonotti in %s" % S[id].nome})
		if ar.ugo_sc == "":
			for id in s.ugo:
				if not s.ugo[id]:
					out.append({"a": "ugo_gira", "sp": id, "et": "Gira gli Ugonotti di %s: -1 PE al prossimo Mercato in %s" % [S[id].nome, Dati.REGIONI[S[id].reg]]})
	out.append({"a": "pref", "et": "Paga i supplementi prima con %s" % ("il Debito" if g.pref_trp else "i Punti Trattato")})
	if not ar.usato:
		out.append({"a": "passa", "et": "Passa: riduci il Debito fino a 2"})
	out.append({"a": "fine", "et": "Fine del Round d'Azione"})
	return out

func _teatri_liberi(s: Dictionary, p: String) -> Array:
	var out := []
	for i in s.guerra.get("teatri", []).size():
		if s.guerra.teatri[i][p].bonus.size() < 2:
			out.append(i)
	return out

func vant_usabile(s: Dictionary, p: String, v: String) -> bool:
	var dv: Dictionary = Dati.VANTAGGI[v]
	for id in dv.sp:
		if s.confl.has(id):
			return false
	match dv.ef:
		"confl":
			return not candidati(s, p, "confl", dv.f).is_empty()
		"debito2":
			return s.g[p].deb > 0
		"bastione":
			return not squadre_mappa(s, avv(p)).is_empty() and piano(s, p, "M", 1, {"gen": "bastione"}).ok
		"squadra2":
			return s.g[p].sq_non > 0 and not s.ar_st.sq2
	return true

func attiva_vant(s: Dictionary, p: String, v: String, gratis: bool) -> void:
	var ar: Dictionary = s.ar_st
	var dv: Dictionary = Dati.VANTAGGI[v]
	nota(s, "%s usa il Vantaggio «%s»." % [Dati.NOMI[p], dv.it])
	if not gratis:
		s.vant[v].es = true
		ar.vu += 1
		ar.vreg.append(dv.reg)
		ar.usato = true
		if p == "FR" and dv.reg == "EU" and ha_min(s, "FR", 13) and not ar.pomp:
			ar.pomp = true
			rivela(s, "FR", 13)
			trp(s, "FR", 1)
		if p == "FR" and ha_min(s, "BR", 19) and not ar.watt:
			ar.watt = true
			rivela(s, "BR", 19)
			trp(s, "BR", 1)
	match dv.ef:
		"confl":
			s.pila.append({"f": "spazi", "chi": p, "az": "confl", "flt": dv.f, "n": 1, "fatto": 0})
		"meno1", "tot1":
			ar.sconti.append({"f": dv.f, "k": dv.ef})
		"squadra2":
			ar.sq2 = true
		"debito2":
			debito(s, p, -2)
		"bastione":
			var pl := piano(s, p, "M", 1, {"gen": "bastione"})
			if pl.ok:
				paga(s, p, pl)
				s.pila.append({"f": "spazi", "chi": p, "az": "via_sq", "flt": "tipo=N", "n": 1, "fatto": 0})

func _r_azione(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var p: String = a.chi
	var ar: Dictionary = s.ar_st
	var g: Dictionary = s.g[p]
	var fr: Dictionary = s.pila.back()
	match o.a:
		"merc", "pol":
			var d: Dictionary = S[o.sp]
			paga(s, p, o.pl)
			if o.cs.sc >= 0:
				ar.sconti.remove_at(o.cs.sc)
			if o.cs.ugo:
				ar.ugo_sc = "-"
			if o.cs.hanb and not ar.hanb:
				ar.hanb = true
				s.g.BR.mu["m16"] = true
				rivela(s, "BR", 16)
			if o.get("jac", false):
				ar.jac = true
				g.mu["jac_m"] = true
				g.mu["jac_m_ar"] = s.ar.FR
				rivela(s, "FR", 4)
			else:
				var t: String = "E" if o.a == "merc" else "D"
				if not (d.reg in ar.reg[t]):
					ar.reg[t].append(d.reg)
			if p == "BR" and o.a == "pol" and ha_min(s, "BR", 6) and d.get("paese", "") in ["Irlanda", "Scozia"]:
				rivela(s, "BR", 6)
			fai(s, p, "sposta", o.sp)
		"forte":
			paga(s, p, o.pl)
			metti(s, o.sp, p)
			nota(s, "%s costruisce il Forte di %s." % [Dati.NOMI[p], S[o.sp].nome])
		"ripara":
			paga(s, p, o.pl)
			s.danno.erase(o.sp)
			if o.get("prendi", false):
				togli(s, o.sp)
				metti(s, o.sp, p)
				nota(s, "%s occupa e ripara il Forte di %s." % [Dati.NOMI[p], S[o.sp].nome])
			else:
				nota(s, "%s ripara il Forte di %s." % [Dati.NOMI[p], S[o.sp].nome])
		"schiera":
			paga(s, p, o.pl)
			if ctrl(s, o.sp) == avv(p):
				squadra_via(s, o.sp, ", scacciata")
			if o.da == "":
				g.sq_box -= 1
			else:
				s.band.erase(o.da)
			s.band[o.sp] = p
			ar.sqm.append(o.sp)
			ar.nuovi.append(o.sp)
			nota(s, "Una Squadra %s prende posizione in %s." % [Dati.AGG[p], S[o.sp].nome])
			agg_vantaggi(s)
		"pace":
			paga(s, p, o.pl)
			s.confl.erase(o.sp)
			nota(s, "%s rimuove il Conflitto da %s." % [Dati.NOMI[p], nome_sp(o.sp)])
		"pesca":
			paga(s, p, o.pl)
			_pesca_evento(s, p)
			nota(s, "%s pesca una carta Evento." % Dati.NOMI[p])
		"bonus":
			paga(s, p, o.pl)
			ar.bc += 1
			var t2 := _pesca_bonus(s, p)
			nota(s, "%s compra una tessera Guerra Bonus." % Dati.NOMI[p])
			if t2 >= 0:
				s.pila.append({"f": "bonus_guerra", "p": p, "t": t2})
		"sq":
			paga(s, p, o.pl)
			ar.usato = true
			if o.uso == "sq2":
				ar.sq2 = false
			elif o.uso != "":
				g.mu[o.uso] = true
				rivela(s, p, int(o.uso.substr(1, 2)))
			ar.sq_meno = 0
			g.sq_non -= 1
			g.sq_box += 1
			nota(s, "%s costruisce una Squadra (nel Riquadro della Marina)." % Dati.NOMI[p])
		"conv":
			paga(s, p, o.pl)
			ar.conv = o.t
			ar.ex.append({"t": o.t, "n": 1, "lim": "", "solo": "", "ev": true, "et": "Conversione"})
			nota(s, "%s converte 2 PM in 1 %s." % [Dati.NOMI[p], Dati.SIGLA_PA[o.t]])
		"jacpv":
			paga(s, p, o.pl)
			g.mu["jac_pv"] = true
			g.mu["jac_pv_ar"] = s.ar.FR
			rivela(s, "FR", 4)
			pv(s, "FR", o.n, "Insurrezioni giacobite")
			_controllo_pv(s)
		"vant":
			attiva_vant(s, p, o.v, false)
		"up":
			ar.up = true
			ar.usato = true
			if o.i < 0:
				trp(s, p, 1)
			else:
				var nuova_t: int = g.base.pop_back()
				var vecchia: int = s.guerra.teatri[o.i][p].base
				var bn: Dictionary = DatiGen.G_BASE[p][nuova_t]
				var bv: Dictionary = DatiGen.G_BASE[p][vecchia]
				chiedi(s, p, "up", "Miglioria militare in «%s»: quale tessera Base tieni in gioco?" % Dati.GUERRE[s.guerra.id].teatri[o.i].nome,
					[{"t": vecchia, "altra": nuova_t, "i": o.i, "et": "Tieni la tessera attuale (%s)" % testo_tessera(bv)},
					{"t": nuova_t, "altra": vecchia, "i": o.i, "et": "Metti la nuova tessera (%s)" % testo_tessera(bn)}], {"segreto": true})
		"rivela":
			rivela(s, p, o.m)
		"halley":
			g.mu["m10b"] = true
			rivela(s, "BR", 10)
			g.mano.erase(o.ev)
			s.scarti.append(o.ev)
			nota(s, "Halley: la Gran Bretagna scarta un Evento.")
			trp(s, "BR", 1)
			ar.usato = true
		"ugo":
			g.mu["m9"] = true
			rivela(s, "FR", 9)
			s.ugo[o.sp] = false
			nota(s, "Ugonotti del Nuovo Mondo in %s." % S[o.sp].nome)
		"ugo_gira":
			s.ugo[o.sp] = true
			ar.ugo_sc = S[o.sp].reg
		"pref":
			g.pref_trp = not g.pref_trp
		"passa":
			debito(s, p, -2)
			nota(s, "%s passa." % Dati.NOMI[p])
			fr.passo = 4
		"fine":
			fr.passo = 4

static func testo_tessera(b: Dictionary) -> String:
	var e := ""
	match b.e:
		"deb": e = ", +1 Debito al nemico"
		"dan": e = ", danneggia un Forte o rimuove una Squadra"
		"via": e = ", toglie una bandiera"
	return "%s%d%s" % ["+" if b.v > 0 else "", b.v, e]

func _r_up(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var p: String = a.chi
	var g: Dictionary = s.g[p]
	s.guerra.teatri[o.i][p].base = o.t
	var totale: int = g.base.size() + s.guerra.teatri.size()
	if DatiGen.G_BASE[p][o.altra].v <= 0 and totale >= 5:
		nota(s, "%s fa una Miglioria militare e scarta una tessera Base dal gioco." % Dati.NOMI[p])
	else:
		g.base.append(o.altra)
		mescola(s, g.base)
		nota(s, "%s fa una Miglioria militare." % Dati.NOMI[p])

func _f_bonus_guerra(s: Dictionary, fr: Dictionary) -> void:
	var lib := _teatri_liberi(s, fr.p)
	if fr.has("jac"):
		lib = [fr.jac]
	if lib.is_empty() or s.guerra.is_empty():
		s.g[fr.p].bonus.append(fr.t)
		s.pila.pop_back()
		return
	var b: Dictionary = DatiGen.G_BONUS[s.guerra.id + "_" + fr.p][fr.t]
	var opz := []
	for i in lib:
		opz.append({"i": i, "et": Dati.GUERRE[s.guerra.id].teatri[i].nome})
	chiedi(s, fr.p, "bonus_guerra", "Tessera Bonus «%s» (%s): in quale teatro?" % [b.nome, testo_tessera(b)], opz, {"segreto": true, "tb": fr.t})

func _r_bonus_guerra(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var fr: Dictionary = s.pila.pop_back()
	s.guerra.teatri[o.i][a.chi].bonus.append(fr.t)
	nota(s, "%s mette una tessera Bonus nel teatro «%s»." % [Dati.NOMI[a.chi], Dati.GUERRE[s.guerra.id].teatri[o.i].nome])

# ---------------------------------------------------------------- effetti speciali degli Eventi
func _pa(s: Dictionary, p: String, t: String, n: int, lim := "", solo := "") -> void:
	if n <= 0:
		return
	s.ar_st.ex.append({"t": t, "n": n, "lim": lim, "solo": solo, "ev": true, "et": "Evento"})
	nota(s, "%s riceve %d %s." % [Dati.NOMI[p], n, Dati.SIGLA_PA[t]])

func _x_carnatico(s: Dictionary, fr: Dictionary) -> void:
	var n := conta_spazi(s, fr.chi, "loc;reg=IN")
	if n > 0:
		s.pila.append({"f": "spazi", "chi": fr.chi, "az": "confl", "flt": "reg=IN", "n": n, "fatto": 0})

func _x_sq_meno2(s: Dictionary, _fr: Dictionary) -> void:
	s.ar_st.sq_meno = 2

func _x_vant_NA(s: Dictionary, fr: Dictionary) -> void:
	s.pila.append({"f": "scegli_vant", "chi": fr.chi, "reg": "NA"})

func _x_vant_fuori(s: Dictionary, fr: Dictionary) -> void:
	s.pila.append({"f": "scegli_vant", "chi": fr.chi, "reg": "-EU"})

func _f_scegli_vant(s: Dictionary, fr: Dictionary) -> void:
	s.pila.pop_back()
	var opz := []
	for v in s.vant:
		var dv: Dictionary = Dati.VANTAGGI[v]
		var okreg: bool = (dv.reg == fr.reg) or (fr.reg == "-EU" and dv.reg != "EU")
		if s.vant[v].di == fr.chi and okreg and (dv.ef in ["meno1", "tot1"] or vant_usabile(s, fr.chi, v)):
			opz.append({"v": v, "et": "%s: %s" % [dv.it, dv.d]})
	if not opz.is_empty():
		chiedi(s, fr.chi, "scegli_vant", "Attiva un Vantaggio", opz)

func _r_scegli_vant(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	attiva_vant(s, a.chi, o.v, true)

func _x_togli_bonus_avv(s: Dictionary, fr: Dictionary) -> void:
	var a := avv(fr.chi)
	var opz := []
	for i in s.guerra.get("teatri", []).size():
		if not s.guerra.teatri[i][a].bonus.is_empty():
			opz.append({"i": i, "vitt": a, "et": "Teatro «%s»" % Dati.GUERRE[s.guerra.id].teatri[i].nome})
	if not opz.is_empty():
		chiedi(s, fr.chi, "togli_bonus", "Da quale teatro togli una tessera Bonus nemica?", opz)

func _r_togli_bonus(s: Dictionary, _a: Dictionary, o: Dictionary) -> void:
	var b: Array = s.guerra.teatri[o.i][o.vitt].bonus
	var k := rnd(s, b.size())
	s.g[o.vitt].bonus.append(b[k])
	b.remove_at(k)
	mescola(s, s.g[o.vitt].bonus)
	nota(s, "Una tessera Bonus %s lascia il teatro «%s» e torna nella riserva." % [Dati.AGG[o.vitt], Dati.GUERRE[s.guerra.id].teatri[o.i].nome])

func _x_riforma(s: Dictionary, fr: Dictionary) -> void:
	var r := debito(s, fr.chi, -int(fr.st.n))
	_pa(s, fr.chi, "E", r)

func _x_gnw_br(s: Dictionary, fr: Dictionary) -> void:
	if ctrl(s, "p_ger1") == "BR" and ctrl(s, "p_ger2") == "BR":
		pv(s, fr.chi, 2, "Stati tedeschi")

func _x_gnw_fr(s: Dictionary, fr: Dictionary) -> void:
	if ctrl(s, "p_rus") == "FR":
		pv(s, "FR", 2, "Russia")
	else:
		s.pila.append({"f": "spazi", "chi": fr.chi, "az": "sposta", "flt": "paese=Russia", "n": 1, "fatto": 0})

func _bandiere_paese(s: Dictionary, p: String, paese: String) -> int:
	var n := 0
	for id in paesi[paese]:
		if ctrl(s, id) == p:
			n += 1
	return n

func _x_vaticano_fr(s: Dictionary, _fr: Dictionary) -> void:
	if _bandiere_paese(s, "BR", "Spagna") + _bandiere_paese(s, "BR", "Austria") == 0:
		pv(s, "FR", 2, "unità cattolica")

func _x_punteggio_cotone(s: Dictionary, fr: Dictionary) -> void:
	if conta_merce(s, fr.chi, "cotone") > conta_merce(s, avv(fr.chi), "cotone"):
		_assegna_merce(s, "cotone")

func _x_sforamento(s: Dictionary, fr: Dictionary) -> void:
	var a := avv(fr.chi)
	var opz := []
	for id in S:
		if S[id].tipo == "F" and ctrl(s, id) == a and not s.danno.has(id):
			opz.append({"k": "forte", "sp": id, "et": "Danneggia il tuo Forte di " + S[id].nome})
		if S[id].tipo == "N" and ctrl(s, id) == a:
			opz.append({"k": "sq", "sp": id, "et": "Ritira la tua Squadra da " + S[id].nome})
	for i in s.guerra.get("teatri", []).size():
		if not s.guerra.teatri[i][a].bonus.is_empty():
			opz.append({"k": "bonus", "i": i, "vitt": a, "et": "Togli una tua tessera Bonus dal teatro «%s»" % Dati.GUERRE[s.guerra.id].teatri[i].nome})
	if not opz.is_empty():
		chiedi(s, a, "sforamento", "Sforamento delle spese militari: che cosa sacrifichi?", opz)

func _r_sforamento(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	match o.k:
		"forte":
			s.danno[o.sp] = true
			nota(s, "Il Forte di %s è danneggiato." % S[o.sp].nome)
		"sq":
			squadra_via(s, o.sp)
		"bonus":
			_r_togli_bonus(s, a, o)

func _x_alberoni_fr(s: Dictionary, _fr: Dictionary) -> void:
	if ctrl(s, "p_sav") == "FR" and ctrl(s, "p_sar") == "FR":
		pv(s, "FR", 3, "Savoia e Sardegna")

func _teatro_jac(s: Dictionary) -> int:
	if s.guerra.is_empty():
		return -1
	var tt: Array = Dati.GUERRE[s.guerra.id].teatri
	for i in tt.size():
		if tt[i].has("jac"):
			return i
	return -1

func _x_carestia_fr(s: Dictionary, _fr: Dictionary) -> void:
	var j := _teatro_jac(s)
	if j < 0:
		return
	for id in ["p_irl1", "p_irl2"]:
		if ctrl(s, id) == "FR":
			var t := _pesca_bonus(s, "FR")
			if t >= 0:
				s.guerra.teatri[j].FR.bonus.append(t)
				nota(s, "La Francia aggiunge una tessera Bonus alla Rivolta giacobita.")

func _x_interessi(s: Dictionary, fr: Dictionary) -> void:
	var a := avv(fr.chi)
	var g: Dictionary = s.g[a]
	var al_limite: bool = g.deb >= g.lim
	g.lim = max(0, g.lim - 1)
	nota(s, "Il Limite di Debito della %s scende a %d." % [Dati.NOMI[a], g.lim])
	if al_limite:
		g.deb = max(0, g.deb - 1)
		pv(s, fr.chi, 1, "pagamento degli interessi")

func _x_patto_br(s: Dictionary, _fr: Dictionary) -> void:
	s.ar_st.patto = true

func _x_patto_fr(s: Dictionary, _fr: Dictionary) -> void:
	var n := 0
	for v in s.vant:
		if n < 2 and s.vant[v].di == "FR" and s.vant[v].es and Dati.VANTAGGI[v].reg == "EU":
			s.vant[v].es = false
			n += 1
			nota(s, "Il Vantaggio «%s» è di nuovo disponibile." % Dati.VANTAGGI[v].it)

func _x_byng_br(s: Dictionary, fr: Dictionary) -> void:
	if s.guerra.is_empty():
		return
	var opz := []
	var tt: Array = Dati.GUERRE[s.guerra.id].teatri
	for i in tt.size():
		for b in tt[i].bonus:
			if b.begins_with("SQ:"):
				opz.append({"i": i, "et": "Teatro «%s»" % tt[i].nome})
	if not opz.is_empty():
		chiedi(s, fr.chi, "byng", "In quale teatro metti il segnalino Byng (+2)?", opz)

func _r_byng(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	s.guerra.teatri[o.i][a.chi].extra += 2
	nota(s, "Segnalino Byng (+2) nel teatro «%s»." % Dati.GUERRE[s.guerra.id].teatri[o.i].nome)

## Scelta di una Squadra da togliere (dalla mappa o dal Riquadro): esito "rit" (torna al prossimo turno),
## "non" (torna fra le non costruite), "via" (rimossa dal gioco).
func _chiedi_squadra(s: Dictionary, chi: String, vitt: String, esito: String, tit: String, punti := 0) -> void:
	var opz := []
	if s.g[vitt].sq_box > 0:
		opz.append({"sp": "", "vitt": vitt, "esito": esito, "pv": punti, "et": "Dal Riquadro della Marina"})
	for id in squadre_mappa(s, vitt):
		opz.append({"sp": id, "vitt": vitt, "esito": esito, "pv": punti, "et": "Da " + S[id].nome})
	if opz.is_empty():
		if esito == "via" and s.g[vitt].sq_non > 0:
			s.g[vitt].sq_non -= 1
			nota(s, "Una Squadra %s non costruita è rimossa dal gioco." % Dati.AGG[vitt])
		return
	chiedi(s, chi, "squadra", tit, opz)

func _r_squadra(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var v: String = o.vitt
	if o.sp == "":
		s.g[v].sq_box -= 1
	else:
		s.band.erase(o.sp)
		agg_vantaggi(s)
	match o.esito:
		"rit":
			s.sq_rit[v] += 1
			nota(s, "Una Squadra %s è fuori gioco fino al prossimo turno di Pace." % Dati.AGG[v])
		"non":
			s.g[v].sq_non += 1
			nota(s, "Una Squadra %s torna fra le non costruite." % Dati.AGG[v])
		"via":
			nota(s, "Una Squadra %s è rimossa dal gioco." % Dati.AGG[v])
	if o.pv > 0:
		pv(s, a.chi, o.pv)

func _x_byng_fr(s: Dictionary, fr: Dictionary) -> void:
	_chiedi_squadra(s, fr.chi, "BR", "rit", "Quale Squadra britannica togli fino al prossimo turno?")

func _x_beau_br(s: Dictionary, fr: Dictionary) -> void:
	var opz := []
	for m in ["pelli", "cotone"]:
		if not (m in s.domanda):
			opz.append({"m": m, "et": "Metti %s nella Domanda Globale" % Dati.MERCI_NOME[m]})
	if opz.is_empty():
		return
	opz.append({"m": "", "et": "Lascia la Domanda Globale com'è"})
	chiedi(s, fr.chi, "domanda", "Le beau monde", opz)

func _r_domanda(s: Dictionary, _a: Dictionary, o: Dictionary) -> void:
	if o.m == "":
		return
	if o.has("via"):
		s.domanda.erase(o.via)
	s.domanda.append(o.m)
	nota(s, "%s entra nella Domanda Globale%s." % [Dati.MERCI_NOME[o.m], (" al posto di " + Dati.MERCI_NOME[o.via]) if o.has("via") else ""])

func _x_cohong(s: Dictionary, fr: Dictionary) -> void:
	var fuori := []
	for m in Dati.MERCI:
		if not (m in s.domanda):
			fuori.append(m)
	if fuori.is_empty():
		return
	var nuova: String = fuori[rnd(s, fuori.size())]
	var opz := []
	for m in s.domanda:
		opz.append({"m": nuova, "via": m, "et": "%s al posto di %s" % [Dati.MERCI_NOME[nuova], Dati.MERCI_NOME[m]]})
	chiedi(s, fr.chi, "domanda", "Nuova tessera Domanda Globale: %s. Quale sostituisce?" % Dati.MERCI_NOME[nuova], opz)

func _x_corsica_br(s: Dictionary, _fr: Dictionary) -> void:
	if squadre_mappa(s, "FR", ["EU"]).is_empty():
		pv(s, "BR", 1, "nessuna Squadra francese in Europa")

func _x_corsica_fr(s: Dictionary, _fr: Dictionary) -> void:
	if _bandiere_paese(s, "BR", "Spagna") == 0:
		pv(s, "FR", 1, "nessuna bandiera britannica in Spagna")

func _x_panico(s: Dictionary, fr: Dictionary) -> void:
	pv(s, fr.chi, clampi(s.g[avv(fr.chi)].deb - s.g[fr.chi].deb, 0, 4), "panico europeo")

func _x_quadruplice_br(s: Dictionary, fr: Dictionary) -> void:
	_chiedi_squadra(s, fr.chi, "BR", "rit", "Quale tua Squadra impegni per segnare 2 PV?", 2)

func _x_costruisci_sq(s: Dictionary, fr: Dictionary) -> void:
	var g: Dictionary = s.g[fr.chi]
	if g.sq_non > 0:
		g.sq_non -= 1
		g.sq_box += 1
		nota(s, "%s aggiunge una Squadra al Riquadro della Marina." % Dati.NOMI[fr.chi])

func _x_quadruplice_bonus(s: Dictionary, fr: Dictionary) -> void:
	_x_costruisci_sq(s, fr)
	if s.g[fr.chi].trp > 0:
		trp(s, fr.chi, -1)
	else:
		debito(s, fr.chi, 1)

func _x_nootka_br(s: Dictionary, _fr: Dictionary) -> void:
	for id in ["p_spa1", "p_spa2"]:
		if ctrl(s, id) == "BR":
			pv(s, "BR", 2, "incidente di Nootka")
			togli(s, id)

func _x_loggia_br(s: Dictionary, _fr: Dictionary) -> void:
	if conta_spazi(s, "BR", "reg=NA") > conta_spazi(s, "FR", "reg=NA"):
		pv(s, "BR", 3, "più bandiere in Nord America")

func _x_gabella_br(s: Dictionary, fr: Dictionary) -> void:
	s.pila.append({"f": "esaurisci", "chi": fr.chi, "n": 2})

func _f_esaurisci(s: Dictionary, fr: Dictionary) -> void:
	var opz := []
	for v in s.vant:
		if s.vant[v].di == avv(fr.chi) and not s.vant[v].es:
			opz.append({"v": v, "et": "Esaurisci «%s»" % Dati.VANTAGGI[v].it})
	if fr.n <= 0 or opz.is_empty():
		s.pila.pop_back()
		return
	opz.append({"v": "", "et": "Basta così"})
	chiedi(s, fr.chi, "esaurisci", "La gabella: esaurisci un Vantaggio nemico", opz)

func _r_esaurisci(s: Dictionary, _a: Dictionary, o: Dictionary) -> void:
	var fr: Dictionary = s.pila.back()
	if o.v == "":
		s.pila.pop_back()
		return
	fr.n -= 1
	s.vant[o.v].es = true
	nota(s, "Il Vantaggio «%s» è esaurito." % Dati.VANTAGGI[o.v].it)

func _x_gabella_fr(s: Dictionary, _fr: Dictionary) -> void:
	pv(s, "FR", 3 if ha_parola(s, "FR", "GOV", true) else 2, "la gabella riformata")

func _x_crisi_debito(s: Dictionary, fr: Dictionary) -> void:
	if deb_disp(s, fr.chi) > deb_disp(s, avv(fr.chi)):
		_pa(s, fr.chi, "E", 3, "", "via")

func _x_pirateria(s: Dictionary, fr: Dictionary) -> void:
	var n := {"FR": 0, "BR": 0}
	for id in S:
		var d: Dictionary = S[id]
		if d.reg == "IN" and (d.tipo in ["N", "F"] or d.has("loc")) and n.has(ctrl(s, id)):
			n[ctrl(s, id)] += 1
	if n[fr.chi] > n[avv(fr.chi)]:
		pv(s, fr.chi, 3, "pirateria in Asia orientale")

func _x_bollo_fr(s: Dictionary, fr: Dictionary) -> void:
	s.pila.append({"f": "spazi", "chi": fr.chi, "az": "confl", "flt": "sub=COL", "n": 3 if fr.bon else 1, "fatto": 0})

func _x_falkland_br(s: Dictionary, _fr: Dictionary) -> void:
	if _bandiere_paese(s, "BR", "Spagna") > 0:
		pv(s, "BR", 1, "la Spagna cede Egmont")

func _x_falkland_fr(s: Dictionary, _fr: Dictionary) -> void:
	_pa(s, "FR", "M", _bandiere_paese(s, "FR", "Spagna"))

func _x_elimina_sq_avv(s: Dictionary, fr: Dictionary) -> void:
	_chiedi_squadra(s, fr.chi, avv(fr.chi), "via", "Quale Squadra nemica rimuovi dal gioco?")

func _x_cook_br(s: Dictionary, fr: Dictionary) -> void:
	_pa(s, fr.chi, "E", (squadre_mappa(s, fr.chi).size() + s.g[fr.chi].sq_box) / 2)

func _x_pesca_bonus(s: Dictionary, fr: Dictionary) -> void:
	if s.turno >= 6 or s.guerra.is_empty():
		return
	var t := _pesca_bonus(s, fr.chi)
	if t >= 0:
		s.pila.append({"f": "bonus_guerra", "p": fr.chi, "t": t})

# ---------------------------------------------------------------- guerre
func forza_teatro(s: Dictionary, p: String, i: int, solo_note := false) -> Dictionary:
	var gid: String = s.guerra.id
	var th: Dictionary = Dati.GUERRE[gid].teatri[i]
	var st: Dictionary = s.guerra.teatri[i][p]
	var a := avv(p)
	var voci := []
	var tot := 0
	if not solo_note:
		if st.base >= 0:
			var b: Dictionary = DatiGen.G_BASE[p][st.base]
			tot += b.v
			voci.append(["Tessera Base", b.v])
		for t in st.bonus:
			var bb: Dictionary = DatiGen.G_BONUS[gid + "_" + p][t]
			tot += bb.v
			voci.append([bb.nome, bb.v])
		if st.extra > 0:
			tot += st.extra
			voci.append(["Segnalini", st.extra])
	var paesi_teatro := []
	for b2 in th.bonus:
		if paesi.has(b2):
			paesi_teatro.append(b2)
	for b3 in th.bonus:
		var n := 0
		var et: String = b3
		if paesi.has(b3):
			for id in paesi[b3]:
				if S[id].has("all") and ctrl(s, id) == p and not s.confl.has(id) and attivo(s, id):
					n += 1
		elif b3 == "Sons of Liberty":
			n = 1 if ctrl(s, "p_sol") == p and not s.confl.has("p_sol") else 0
		elif b3.begins_with("K:"):
			n = 1 if ha_parola(s, p, b3.substr(2)) else 0
			et = "Parola chiave " + Dati.PAROLE[b3.substr(2)]
		elif b3 == "CONF":
			et = "Conflitti negli spazi nemici"
			for id in s.confl:
				if ctrl(s, id) != a:
					continue
				if th.has("jac"):
					if S[id].get("paese", "") in paesi_teatro:
						n += 1
				elif S[id].reg in th.reg:
					n += 1
		elif b3 == "FORTI":
			et = "Forti"
			for id in S:
				if S[id].tipo == "F" and S[id].reg in th.reg and ctrl(s, id) == p and not s.danno.has(id):
					n += 1
		elif b3.begins_with("SQ:"):
			et = "Squadre"
			n = squadre_mappa(s, p, Array(b3.substr(3).split(","))).size()
		if n > 0:
			tot += n
			voci.append([et, n])
	return {"tot": tot, "voci": voci}

func _f_guerra(s: Dictionary, fr: Dictionary) -> void:
	var gid: String = s.guerra.id
	var tt: Array = Dati.GUERRE[gid].teatri
	match int(fr.passo):
		0:
			s.fase = "Guerra"
			s.ar_st = {}
			s.ult_guerra = []
			nota(s, "=== %s (%s) ===" % [Dati.GUERRE[gid].nome, Dati.GUERRE[gid].anni])
			fr.passo = 1
			fr.i = 0
		1:
			if fr.i >= tt.size():
				fr.passo = 2
				return
			s.pila.append({"f": "teatro", "i": fr.i, "passo": 0})
			fr.i += 1
		2:
			# vittoria automatica: tutti i teatri vinti dallo stesso giocatore con il margine massimo
			for p in ["FR", "BR"]:
				var tutti := true
				for i in tt.size():
					var r: Dictionary = s.ult_guerra[i]
					var righe: Array = tt[i].get("bott", tt[i].get("bott_" + p, []))
					if r.vince != p or r.margine < righe[righe.size() - 1][0]:
						tutti = false
				if tutti:
					vittoria(s, p, "Ha vinto tutti i teatri della %s con il margine massimo." % Dati.GUERRE[gid].nome)
					return
			if _controllo_pv(s):
				return
			_dopo_guerra(s)
			s.pila.pop_back()

func _dopo_guerra(s: Dictionary) -> void:
	var gid: String = s.guerra.id
	var tt: Array = Dati.GUERRE[gid].teatri
	# i Conflitti che hanno dato forza vengono rimossi
	for id in s.confl.keys():
		if ctrl(s, id) == "":
			continue
		for th in tt:
			if "CONF" in th.bonus and (S[id].reg in th.reg):
				s.confl.erase(id)
				break
	var n_bonus := {"FR": 0, "BR": 0}
	for p in ["FR", "BR"]:
		for t in s.guerra.teatri:
			if t[p].base >= 0:
				s.g[p].base.append(t[p].base)
			n_bonus[p] += t[p].bonus.size()
		mescola(s, s.g[p].base)
	var prossima := ""
	match gid:
		"WSS": prossima = "WAS"
		"WAS": prossima = "7YW"
		"7YW": prossima = "AWI"
	if prossima == "":
		s.guerra = {}
		for p in ["FR", "BR"]:
			s.g[p].bonus = []
	else:
		_prepara_guerra(s, prossima)
		if prossima == "7YW":
			for p in ["FR", "BR"]:
				s.gratis7[p] = min(3, n_bonus[p])
	nota(s, "La guerra è finita. Torna la pace.")

func _riga_bottino(righe: Array, margine: int) -> Array:
	var r := []
	for x in righe:
		if margine >= x[0]:
			r = x
	return r

func _f_teatro(s: Dictionary, fr: Dictionary) -> void:
	var gid: String = s.guerra.id
	var i: int = fr.i
	var th: Dictionary = Dati.GUERRE[gid].teatri[i]
	match int(fr.passo):
		0:
			fr.passo = 1
			nota(s, "-- Teatro %d: %s --" % [i + 1, th.nome])
			var primo: String = "FR" if s.pv > 15 else ("BR" if s.pv < 15 else s.primo)
			var ordine := [avv(primo), primo]
			for p in ordine:
				var st: Dictionary = s.guerra.teatri[i][p]
				var effetti := []
				if st.base >= 0:
					effetti.append(DatiGen.G_BASE[p][st.base].e)
				for t in st.bonus:
					effetti.append(DatiGen.G_BONUS[gid + "_" + p][t].e)
				for e in effetti:
					if e != "":
						s.pila.append({"f": "eff_tessera", "p": p, "e": e, "reg": th.reg})
		1:
			fr.passo = 2
			var f := {"FR": forza_teatro(s, "FR", i), "BR": forza_teatro(s, "BR", i)}
			var w := _vince(f.FR.tot, f.BR.tot)
			var margine: int = abs(f.FR.tot - f.BR.tot)
			var tess := {}
			for p in ["FR", "BR"]:
				var stp: Dictionary = s.guerra.teatri[i][p]
				tess[p] = {"base": stp.base, "bonus": stp.bonus.duplicate(), "extra": stp.extra}
			s.ult_guerra.append({"nome": th.nome, "FR": f.FR, "BR": f.BR, "vince": w, "margine": margine, "gid": gid, "tess": tess})
			nota(s, "Forza: Francia %d, Gran Bretagna %d." % [f.FR.tot, f.BR.tot])
			if w == "":
				nota(s, "Pareggio: nessun bottino.")
				return
			var l := avv(w)
			var riga := _riga_bottino(th.get("bott", th.get("bott_" + w, [])), margine)
			nota(s, "Vince la %s con margine %d." % [Dati.NOMI[w], margine])
			if riga.is_empty():
				return
			# gli effetti si mettono in pila in ordine inverso
			var extra: Array = Array(String(riga[4]).split(";", false))
			if th.get("spec", "") == "jac_wss" and w == "FR" and margine >= 3:
				s.jac_vitt += 1
				nota(s, "La Francia ottiene un segnalino Vittoria giacobita.")
			if th.get("spec", "") == "jac_was":
				if w == "BR" and margine >= 2:
					_fine_giacobiti(s, "Sconfitta giacobita")
				elif w == "FR":
					s.jac_vitt += 1
					s.jac_extra = true
					nota(s, "Vittoria giacobita: la Francia potrà tenere le Insurrezioni giacobite oltre ai suoi due Ministeri.")
			for e in extra:
				if e.begins_with("via:"):
					s.pila.append({"f": "spazi", "chi": w, "az": "via", "flt": "tipo=M;reg=" + e.substr(4), "n": 1, "fatto": 0})
				elif e == "viapol":
					s.pila.append({"f": "spazi", "chi": w, "az": "via", "flt": "tipo=P;reg=EU", "n": 1, "fatto": 0})
				elif e == "atl":
					s.guerra.teatri[2][w].extra += 2
					nota(s, "Dominio dell'Atlantico: +2 alla %s nella Guerra franco-indiana." % Dati.NOMI[w])
				elif e == "sq1" or e == "sq2":
					for k in int(e.substr(2)):
						s.pila.append({"f": "perdi_sq", "chi": l, "esito": "non"})
				elif e == "ant":
					for k in min(2, margine):
						s.pila.append({"f": "perdi_sq", "chi": l, "esito": "via"})
				elif e == "usa":
					_usa(s, false)
				elif e == "canada":
					_usa(s, true)
			if riga[2] > 0 and not th.get("nocp", false):
				s.pila.append({"f": "pc", "p": w, "n": riga[2], "i": i, "rif": []})
			pv(s, w, riga[1], th.nome)
			trp(s, l, riga[3])
		2:
			s.pila.pop_back()

func _f_perdi_sq(s: Dictionary, fr: Dictionary) -> void:
	s.pila.pop_back()
	_chiedi_squadra(s, fr.chi, fr.chi, fr.esito, "Devi rinunciare a una Squadra: quale?")

func _f_eff_tessera(s: Dictionary, fr: Dictionary) -> void:
	s.pila.pop_back()
	var p: String = fr.p
	match fr.e:
		"deb":
			nota(s, "Una tessera Guerra %s impone 1 Debito al nemico." % Dati.AGG[p])
			debito(s, avv(p), 1)
		"dan":
			s.pila.append({"f": "spazi", "chi": p, "az": "dan_o_sq", "flt": "", "regs": fr.reg, "n": 1, "fatto": 0})
		"via":
			s.pila.append({"f": "spazi", "chi": p, "az": "via_guerra", "flt": "", "regs": fr.reg, "n": 1, "fatto": 0})

func _usa(s: Dictionary, canada: bool) -> void:
	s.usa = true
	var lista := ["t_que"] if canada else ["t_nco", "t_car", "t_sag"]
	for id in lista:
		if ctrl(s, id) != "FR":
			s.band[id] = "US"
			s.confl.erase(id)
			nota(s, "Bandiera degli Stati Uniti in %s." % S[id].nome)
	if not canada:
		for id in ["f_cha", "f_ohi"]:
			if ctrl(s, id) == "BR":
				s.band.erase(id)
				nota(s, "I britannici perdono il Forte di %s." % S[id].nome)
	for id in isolati(s):
		if S[id].reg in ["NA", "CA"]:
			nota(s, "%s resta isolato e perde la bandiera." % S[id].nome)
			s.band.erase(id)
			s.confl.erase(id)
	agg_vantaggi(s)

func _costo_pc(s: Dictionary, id: String) -> int:
	return S[id].costo + (1 if s.ugo.has(id) and ctrl(s, id) == "FR" else 0)

func bersagli_pc(s: Dictionary, p: String, i: int, n: int, rif: Array) -> Array:
	var th: Dictionary = Dati.GUERRE[s.guerra.id].teatri[i]
	var out := []
	for id in S:
		var d: Dictionary = S[id]
		var o := ctrl(s, id)
		if o == p or o == "US" or not attivo(s, id) or id in rif:
			continue
		if d.tipo in ["F", "M"] and d.reg in th.reg:
			if n >= 1:
				out.append({"sp": id, "c": 1})
		elif d.tipo == "N" and d.reg in th.reg:
			if n >= 1 and (s.g[p].sq_box > 0 or not squadre_mappa(s, p, th.reg).is_empty()):
				out.append({"sp": id, "c": 1})
		elif d.tipo == "T" and (d.reg in th.reg or id in th.terr):
			var c := _costo_pc(s, id)
			if c > n:
				continue
			var ok: bool = conq[id].is_empty()
			for x in conq[id]:
				if ctrl(s, x) == p:
					ok = true
			if ok:
				out.append({"sp": id, "c": c})
	return out

func _f_pc(s: Dictionary, fr: Dictionary) -> void:
	var b := bersagli_pc(s, fr.p, fr.i, fr.n, fr.rif)
	if fr.n <= 0 or b.is_empty():
		s.pila.pop_back()
		return
	var opz := []
	for x in b:
		opz.append({"sp": x.sp, "c": x.c, "et": "%s (%d PC)" % [nome_sp(x.sp), x.c]})
	opz.append({"sp": "", "c": 0, "et": "Non spendere altri Punti Conquista"})
	chiedi(s, fr.p, "pc", "Spendi i Punti Conquista (%d)" % fr.n, opz)

func _r_pc(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	var fr: Dictionary = s.pila.back()
	var p: String = a.chi
	if o.sp == "":
		s.pila.pop_back()
		return
	fr.n -= o.c
	var d: Dictionary = S[o.sp]
	var l := avv(p)
	if d.tipo == "T" and ctrl(s, o.sp) == l and s.g[l].rif < 2:
		var costo := 3 if s.g[l].rif == 0 else 5
		chiedi(s, l, "rifiuto", "La %s vuole %s. Rifiuti di cederlo? (costa %d PV)" % [Dati.NOMI[p], d.nome, costo],
			[{"si": false, "sp": o.sp, "p": p, "et": "Cedi " + d.nome}, {"si": true, "sp": o.sp, "p": p, "c": costo, "et": "Rifiuta: la %s segna %d PV" % [Dati.NOMI[p], costo]}])
		return
	_conquista(s, p, o.sp)

func _r_rifiuto(s: Dictionary, a: Dictionary, o: Dictionary) -> void:
	if o.si:
		s.g[a.chi].rif += 1
		nota(s, "%s rifiuta di cedere %s." % [Dati.NOMI[a.chi], S[o.sp].nome])
		pv(s, o.p, o.c, "cessione rifiutata")
		for fr in s.pila:
			if fr.f == "pc":
				fr.rif.append(o.sp)
	else:
		_conquista(s, o.p, o.sp)

func _conquista(s: Dictionary, p: String, id: String) -> void:
	var d: Dictionary = S[id]
	if d.tipo == "N":
		if ctrl(s, id) == avv(p):
			squadra_via(s, id, ", scacciata")
		if s.g[p].sq_box > 0:
			s.g[p].sq_box -= 1
		else:
			var m := squadre_mappa(s, p, [d.reg])
			if m.is_empty():
				return
			s.band.erase(m[0])
		s.band[id] = p
		agg_vantaggi(s)
	else:
		togli(s, id)
		metti(s, id, p)
	nota(s, "%s conquista %s." % [Dati.NOMI[p], nome_sp(id)])
