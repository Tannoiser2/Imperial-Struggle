## Intelligenza artificiale: per ogni decisione prova le opzioni su una copia della partita
## e sceglie quella che lascia la posizione migliore (premi, domanda globale, alleanze per la
## prossima guerra, debito, trattati). Non guarda le tessere e le carte coperte dell'avversario.
class_name IA
extends RefCounted

const S := DatiGen.SPAZI
var mo: Motore
## Ultimo proposito dell'IA, in parole (mostrato nel diario come «dispaccio»).
var proposito := ""

const PESO_MIN := {1: 3.0, 2: 1.5, 3: 2.0, 4: 1.2, 9: 1.2, 11: 3.0, 12: 1.8, 13: 1.5, 14: 2.0, 23: 2.0, 24: 2.5, 25: 1.8, 26: 2.2,
	5: 2.2, 6: 1.2, 7: 1.5, 8: 2.5, 10: 2.0, 15: 3.0, 16: 1.2, 17: 2.8, 18: 2.0, 19: 1.5, 20: 2.0, 21: 1.4, 22: 2.0}
const SOTTO_SCELTE := ["spazi", "scelta", "bonus_guerra", "squadra", "scegli_vant", "togli_bonus", "byng", "domanda", "esaurisci", "up", "pc", "scarta"]

func _init(m: Motore) -> void:
	mo = m

func _copia(s: Dictionary) -> Dictionary:
	var lg = s.log
	var at = s.att
	s.log = []
	s.att = null
	var c: Dictionary = s.duplicate(true)
	s.log = lg
	s.att = at
	c["_ia"] = true
	return c

## Copia della partita con in attesa la sola opzione i (le altre non servono).
func _copia_con(s: Dictionary, i: int) -> Dictionary:
	var c := _copia(s)
	var a := {}
	for k in s.att:
		if k != "opz":
			a[k] = s.att[k]
	a.erase("pigro")
	a["opz"] = [s.att.opz[i].duplicate(true)]
	c.att = a
	return c

func _rumore(s: Dictionary, i: int) -> float:
	return float(((s.nd * 7919 + i * 104729 + s.rng) & 1023)) / 1023.0 * 0.04

func decidi(s: Dictionary) -> int:
	var a: Dictionary = s.att
	var io: String = a.chi
	match a.tipo:
		"ministro": return _ministro(s, a, io)
		"primo":
			for i in a.opz.size():
				if a.opz[i].p == io:
					return i
		"scarta": return _scarta(s, a, io)
		"tessera": return _tessera(s, a, io)
	return _migliore(s, io, 0)

## Valuta tutte le opzioni applicandole a una copia.
func _migliore(s: Dictionary, io: String, prof: int) -> int:
	mo.materializza(s)
	var a: Dictionary = s.att
	var best := 0
	var bv := -1e9
	for i in a.opz.size():
		var o: Dictionary = a.opz[i]
		if a.tipo == "azione" and o.a in ["pref", "rivela", "ugo_gira"]:
			continue
		var v := _valore_opzione(s, io, i, prof) + _rumore(s, i)
		if a.tipo == "azione" and o.a == "ugo":
			v += 0.2
		if v > bv:
			bv = v
			best = i
	return best

func _valore_opzione(s: Dictionary, io: String, i: int, prof: int) -> float:
	var c := _copia_con(s, i)
	var o: Dictionary = s.att.opz[i]
	var tipo: String = s.att.tipo
	mo.applica(c, 0)
	_segui(c, io, prof)
	var v := valuta(c, io)
	if tipo == "evento" and o.ev == 0:
		v += 0.3
	if tipo == "azione" and o.a == "vant" and c.att != null and c.att.tipo == "azione" and c.att.chi == io:
		# gli sconti valgono per l'acquisto che rendono possibile: guarda un passo avanti
		var ef: String = Dati.VANTAGGI[o.v].ef
		if ef in ["meno1", "tot1", "squadra2"]:
			mo.materializza(c)
			var meglio := -1e9
			for j in c.att.opz.size():
				var o2: Dictionary = c.att.opz[j]
				if (ef == "squadra2" and o2.a == "sq") or (ef != "squadra2" and o2.a in ["merc", "pol"] and o2.cs.sc >= 0):
					meglio = max(meglio, _valore_opzione(c, io, j, prof + 1))
			v = meglio - 0.05 if meglio > -1e8 else v - 0.5
	return v

## Dopo una scelta, risolve da sé le sotto-scelte che ne derivano (dove mettere, cosa togliere...).
func _segui(c: Dictionary, io: String, prof: int) -> void:
	var giri := 0
	while c.att != null and c.fine == null and c.att.chi == io and c.att.tipo in SOTTO_SCELTE and giri < 6:
		giri += 1
		if prof >= 2:
			mo.applica(c, 0)
		else:
			mo.applica(c, _scelta_veloce(c, io, prof + 1))

func _scelta_veloce(c: Dictionary, io: String, prof: int) -> int:
	if c.att.tipo == "scarta":
		return _scarta(c, c.att, io)
	return _migliore(c, io, prof)

func _ap_rimasti(s: Dictionary) -> float:
	var ar: Dictionary = s.ar_st
	if not ar.has("mag"):
		return 0.0
	var n: float = ar.mag.n + (0 if ar.min.us else ar.min.n) * 0.8
	for e in ar.ex:
		n += e.n * 0.7
	return n

# ---------------------------------------------------------------- valutazione della posizione
func valuta(s: Dictionary, io: String) -> float:
	var segno := 1.0 if io == "FR" else -1.0
	if s.fine != null:
		return 1000.0 if s.fine.vince == io else -1000.0
	var v := float(s.pv - 15) * 1.0
	var in_pace: bool = s.fase != "Guerra" and s.fase != "Punteggio"
	var fatti: int = s.ar.FR + s.ar.BR
	var k := 0.55 + 0.09 * fatti
	var restanti: float = 6 - s.turno
	# conteggi
	var reg := {"EU": 0, "NA": 0, "CA": 0, "IN": 0}
	var merci := {}
	var pres := 0
	var strutt := 0.0
	for id in S:
		var d: Dictionary = S[id]
		var o: String = s.band.get(id, "")
		if o != "FR" and o != "BR":
			if o == "US":
				strutt += 0.4
			continue
		var sg := 1 if o == "FR" else -1
		var peso := 0.22
		match d.tipo:
			"T": peso = 0.6
			"F": peso = 0.45 if not s.danno.has(id) else 0.2
			"N": peso = 0.4
			"P": peso = 0.2 + 0.05 * d.costo
			"M": peso = 0.15 + 0.06 * d.costo
		strutt += sg * peso
		if s.confl.has(id):
			strutt -= sg * 0.15
			continue
		if not d.has("usa"):
			reg[d.reg] += sg
		if d.has("pres"):
			pres += sg
		if d.has("merce"):
			merci[d.merce] = merci.get(d.merce, 0) + sg
	v += strutt * (0.35 + 0.22 * restanti)
	if in_pace and not s.premi.is_empty():
		for r in Dati.REG_ORD:
			var pr: Array = Dati.PREMI[s.premi[r]]
			var val: float = pr[0] + 0.5 * pr[1] + 0.25
			var d2: float = reg[r]
			if pr[2] == 2:
				d2 = d2 - signf(d2) * 0.8 if abs(d2) >= 1 else 0.0
			v += val * tanh(d2 * k)
		v += 2.0 * tanh(pres * k)
		for m in s.domanda:
			var rr: Array = Dati.DOMANDA[m][s.era - 1]
			var dm: float = merci.get(m, 0)
			v += rr[0] * tanh(dm * k)
			# PT e Debito vanno a chi vince
			v += (0.4 * rr[1] - 0.4 * rr[2]) * tanh(dm * k)
	else:
		v += 0.25 * (reg.EU + reg.NA + reg.CA + reg.IN) + 0.3 * pres
	if s.turno >= 5:
		for m in Dati.MERCI:
			v += 0.5 * tanh(float(merci.get(m, 0)))
		v += 1.0 * tanh(pres * 0.8)
	# guerra in arrivo
	if not s.guerra.is_empty():
		var peso_g := 1.0 if Dati.GUERRA_DOPO.has(s.turno) or s.fase == "Guerra" else 0.55
		var tt: Array = Dati.GUERRE[s.guerra.id].teatri
		for i in tt.size():
			if s.fase == "Guerra" and i < s.ult_guerra.size():
				continue
			v += peso_g * segno * _valore_teatro(s, io, i)
	# risorse
	for p in ["FR", "BR"]:
		var g: Dictionary = s.g[p]
		var sg2 := 1.0 if p == "FR" else -1.0
		var x := 0.0
		x -= 0.4 * g.deb + 1.0 * max(0, g.deb - (g.lim - 2)) + 1.2 * max(0, g.deb - (g.lim - 1))
		x += 0.12 * (g.lim - 6)
		x += 0.38 * min(g.trp, 4) + 0.1 * max(0, g.trp - 4)
		x += 0.45 * g.sq_box + 0.1 * g.sq_non
		x += 0.3 * g.mano.size()
		v += sg2 * x
	for vn in s.vant:
		var st: Dictionary = s.vant[vn]
		if st.di != "":
			v += (1.0 if st.di == "FR" else -1.0) * (0.45 + (0.0 if st.es else 0.2))
	v += 0.2 * s.ugo.size()
	v = v * segno
	if s.att != null and s.att.chi == io and s.ar_st.has("mag") and s.ar_st.p == io:
		v += 0.33 * _ap_rimasti(s)
	return v

## Valore atteso del teatro i dal punto di vista di «io».
func _valore_teatro(s: Dictionary, io: String, i: int) -> float:
	var gid: String = s.guerra.id
	var th: Dictionary = Dati.GUERRE[gid].teatri[i]
	var a := Motore.avv(io)
	var mio: float = mo.forza_teatro(s, io, i).tot
	var st: Dictionary = s.guerra.teatri[i][a]
	var suo: float = mo.forza_teatro(s, a, i, true).tot + (0.6 if st.base >= 0 else 0.0) + 1.7 * st.bonus.size() + st.extra
	var m := mio - suo
	var chi := io if m >= 0 else a
	var righe: Array = th.get("bott", th.get("bott_" + chi, []))
	var am: float = abs(m)
	var val := 0.0
	var riga := []
	for x in righe:
		if am + 0.5 >= x[0]:
			riga = x
	if riga.is_empty():
		riga = righe[0]
		val = 0.5
	else:
		val = 1.0
	var premio: float = riga[1] + 1.5 * riga[2] - 0.35 * riga[3] + (0.9 if String(riga[4]) != "" else 0.0) + 0.3
	var e := premio * val * tanh(am * 0.75)
	var per_me := e if m >= 0 else -e
	return per_me

# ---------------------------------------------------------------- scelte particolari
func _ministro(s: Dictionary, a: Dictionary, io: String) -> int:
	var best := 0
	var bv := -1e9
	var prossima: String = Dati.PROSSIMA_GUERRA.get(s.turno, "")
	for i in a.opz.size():
		var m: int = a.opz[i].m
		if m == 0:
			return i
		var v: float = PESO_MIN.get(m, 1.0) + _rumore(s, i) * 12.0
		if prossima != "":
			for t in Dati.GUERRE[prossima].teatri:
				for kw in Dati.MINISTERI[m].kw:
					if ("K:" + kw) in t.bonus:
						v += 0.5
		if m == 4:
			v += 0.5 * (mo._bandiere_paese(s, "FR", "Irlanda") + mo._bandiere_paese(s, "FR", "Scozia")) + s.jac_vitt
		if m == 20 and mo.ha_min(s, "FR", 4):
			v += 1.5
		if m == 1:
			v += 0.3 * (mo.conta_spazi(s, "FR", "paese=Spagna,Austria;pres") + mo.conta_spazi(s, "FR", "paese=Savoia,Sardegna"))
		if v > bv:
			bv = v
			best = i
	return best

func _valore_carta(s: Dictionary, io: String, n: int) -> float:
	var e: Dictionary = Dati.EVENTI[n]
	var v := 1.0
	if e.tipo == "":
		v += 0.5
	if mo.cond_ok(s, io, e.cond):
		v += 0.7
	if e.era == s.era:
		v += 0.1
	return v

func _scarta(s: Dictionary, a: Dictionary, io: String) -> int:
	var best := 0
	var bv := 1e9
	for i in a.opz.size():
		var v := _valore_carta(s, io, a.opz[i].ev) + _rumore(s, i)
		if v < bv:
			bv = v
			best = i
	return best

## Tessera Investimento: stima rapida di tutte, poi prova sul serio le tre migliori giocando il Round.
func _tessera(s: Dictionary, a: Dictionary, io: String) -> int:
	var cand := []
	var guerra_vicina: bool = Dati.GUERRA_DOPO.has(s.turno)
	for i in a.opz.size():
		var o: Dictionary = a.opz[i]
		if o.has("x"):
			if o.x == "walpole":
				return i
			if o.x == "townshend":
				if o.m in s.domanda and mo.conta_merce(s, "FR", o.m) >= 2 and mo.conta_merce(s, "FR", o.m) >= mo.conta_merce(s, "BR", o.m):
					return i
			continue
		var d: Dictionary = DatiGen.INVEST[o.t]
		var w := {"E": 1.0, "D": 1.0, "M": 0.75 if not guerra_vicina else 1.1}
		if s.turno == 6:
			w.M = 0.5
		var v: float = w[d.mag] * d.n + w[d.min] * 1.3
		if d.ev:
			var meglio := 0.0
			for n in s.g[io].mano:
				var e: Dictionary = Dati.EVENTI[n]
				if e.tipo == "" or e.tipo == d.mag:
					meglio = max(meglio, 1.2 + (0.8 if mo.cond_ok(s, io, e.cond) else 0.0))
			v += meglio
		if d.up:
			v += 0.5
		cand.append([v + _rumore(s, i), i])
	cand.sort_custom(func(x, y): return x[0] > y[0])
	var best: int = cand[0][1]
	var bv := -1e9
	for k in min(2, cand.size()):
		var i2: int = cand[k][1]
		var c := _copia_con(s, i2)
		mo.applica(c, 0)
		var passi := 0
		while c.att != null and c.fine == null and c.att.chi == io and c.att.tipo != "tessera" and passi < 9:
			passi += 1
			if c.att.tipo == "ministro" or c.att.tipo == "primo":
				break
			mo.applica(c, _migliore(c, io, 1))
		var v2: float = valuta(c, io) + cand[k][0] * 0.05
		if v2 > bv:
			bv = v2
			best = i2
	return best

## Una riga di «dispaccio» che racconta che cosa ha appena deciso l'IA (per il diario).
func racconta(s: Dictionary, i: int) -> String:
	var a: Dictionary = s.att
	var o: Dictionary = a.opz[i]
	if a.tipo == "azione":
		match o.a:
			"pol":
				var d: Dictionary = S[o.sp]
				if d.has("all"):
					return "cerca alleati per la prossima guerra: %s" % mo.nome_sp(o.sp)
				if d.has("pres"):
					return "coltiva il prestigio a %s" % mo.nome_sp(o.sp)
				return "tratta con %s" % mo.nome_sp(o.sp)
			"bonus": return "rafforza l'esercito"
			"schiera": return "manda la flotta a %s" % S[o.sp].nome
			"passa": return "risana le finanze"
	return ""
