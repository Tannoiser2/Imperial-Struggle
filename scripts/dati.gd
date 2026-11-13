## Dati fissi del gioco: carte Evento e Ministero (tradotte in italiano), guerre, premi, domanda globale.
## Gli spazi della mappa e le tessere stanno in dati_gen.gd (generato dal modulo).
class_name Dati
extends RefCounted

const NOMI := {"FR": "Francia", "BR": "Gran Bretagna"}
const AGG := {"FR": "francese", "BR": "britannico"}
const REGIONI := {"EU": "Europa", "NA": "Nord America", "CA": "Caraibi", "IN": "India"}
const REG_ORD := ["EU", "NA", "CA", "IN"]
const SOTTO := {"CAN": "Canada", "COL": "Colonie del Nord", "CAR": "Costa del Carnatico", "HOO": "Fiume Hooghly"}
const TIPI_PA := {"E": "Economici", "D": "Diplomatici", "M": "Militari"}
const SIGLA_PA := {"E": "PE", "D": "PD", "M": "PM"}
const TIPI_SP := {"M": "Mercato", "P": "Spazio politico", "T": "Territorio", "N": "Spazio navale", "F": "Forte"}
const MERCI := ["pelli", "spezie", "pesce", "tabacco", "zucchero", "cotone"]
const MERCI_NOME := {"pelli": "Pelli", "spezie": "Spezie", "pesce": "Pesce", "tabacco": "Tabacco", "zucchero": "Zucchero", "cotone": "Cotone"}
const ERE := ["", "Successione", "Impero", "Rivoluzione"]
const PAROLE := {"FIN": "Finanza", "MER": "Mercantilismo", "GOV": "Governo", "STI": "Stile", "ERU": "Erudizione"}
const ANNI := ["", "1697-1701", "1714-1721", "1722-1739", "1749-1755", "1764-1774", "1784-1789"]

## Domanda globale: per merce e per era [PV, PT, variazione del Debito]
const DOMANDA := {
	"pelli": [[2, 1, 0], [2, 1, 0], [1, 0, 0]],
	"spezie": [[1, 0, -1], [2, 0, -1], [3, 0, -1]],
	"pesce": [[2, 0, 1], [2, 0, 0], [2, 0, 0]],
	"tabacco": [[3, 0, 1], [2, 0, 1], [1, 0, 1]],
	"zucchero": [[2, 0, 0], [3, 1, 0], [3, 0, 0]],
	"cotone": [[2, 1, 0], [2, 1, 0], [3, 0, 0]],
}

## Tessere Premio: [PV, PT, margine richiesto]
const PREMI := [[1, 1, 1], [1, 1, 1], [0, 1, 1], [0, 1, 1], [1, 0, 1], [1, 0, 1], [2, 0, 2], [3, 0, 2]]

## Vantaggi: spazi richiesti, regione, effetto
const VANTAGGI := {
	"Algonquin Raids": {"it": "Incursioni algonchine", "sp": ["p_alg"], "reg": "NA", "ef": "confl", "f": "tipo=M;reg=NA;merce=pelli", "d": "Metti 1 Conflitto in un Mercato delle Pelli del Nord America."},
	"Fur Trade": {"it": "Commercio delle pelli", "sp": ["t_hud"], "reg": "NA", "ef": "tot1", "f": "tipo=M;reg=NA", "d": "Togliere la bandiera a un Mercato del Nord America costa in tutto 1 PE."},
	"Patriot Agitation": {"it": "Agitazione patriottica", "sp": ["p_sol"], "reg": "NA", "ef": "confl", "f": "reg=NA", "d": "Metti 1 Conflitto in Nord America."},
	"Iroquois Raids": {"it": "Incursioni irochesi", "sp": ["p_iro"], "reg": "NA", "ef": "confl", "f": "reg=NA", "d": "Metti 1 Conflitto in Nord America."},
	"Wheat": {"it": "Grano", "sp": ["che"], "reg": "NA", "ef": "meno1", "f": "tipo=M;reg=NA", "d": "-1 PE per togliere una bandiera in Nord America."},
	"Fruit": {"it": "Frutta", "sp": ["t_sag"], "reg": "CA", "ef": "meno1", "f": "tipo=M;reg=CA", "d": "-1 PE per togliere una bandiera nei Caraibi."},
	"Slaving Contracts": {"it": "Contratti dell'Asiento", "sp": ["t_asi"], "reg": "CA", "ef": "squadra2", "f": "", "d": "Costruire una Squadra costa 2 PM."},
	"Letters of Marque": {"it": "Lettere di corsa", "sp": ["p_prv"], "reg": "CA", "ef": "confl", "f": "tipo=M;reg=CA;noprot", "d": "Metti 1 Conflitto in un Mercato non protetto dei Caraibi."},
	"Rum": {"it": "Rum", "sp": ["pri"], "reg": "CA", "ef": "meno1", "f": "tipo=M;reg=CA", "d": "-1 PE per togliere una bandiera nei Caraibi."},
	"Pirate Havens": {"it": "Covi di pirati", "sp": ["p_buc"], "reg": "CA", "ef": "confl", "f": "tipo=M;reg=CA;noprot", "d": "Metti 1 Conflitto in un Mercato non protetto dei Caraibi."},
	"Separatist Wars": {"it": "Guerre separatiste", "sp": ["p_niz"], "reg": "IN", "ef": "confl", "f": "tipo=M;merce=cotone", "d": "Metti 1 Conflitto in un Mercato del Cotone."},
	"Power Struggle": {"it": "Lotta di potere", "sp": ["p_mys"], "reg": "IN", "ef": "confl", "f": "tipo=M;sub=CAR", "d": "Metti 1 Conflitto in un Mercato della Costa del Carnatico."},
	"Textiles": {"it": "Tessuti", "sp": ["tir"], "reg": "IN", "ef": "meno1", "f": "tipo=M;reg=IN", "d": "-1 PE per togliere una bandiera in India."},
	"Raids & Incursions": {"it": "Razzie e incursioni", "sp": ["p_mrt"], "reg": "IN", "ef": "confl", "f": "tipo=M;reg=IN", "d": "Metti 1 Conflitto in un Mercato dell'India."},
	"Silk": {"it": "Seta", "sp": ["wbe"], "reg": "IN", "ef": "meno1", "f": "tipo=M;reg=IN", "d": "-1 PE per togliere una bandiera in India."},
	"Naval Bastion": {"it": "Bastione navale", "sp": ["t_gib"], "reg": "EU", "ef": "bastione", "f": "", "d": "Spendi 1 PM per rimandare una Squadra nemica nel Riquadro della Marina."},
	"Mediterranean Intrigue": {"it": "Intrigo mediterraneo", "sp": ["p_spa4", "p_sav"], "reg": "EU", "ef": "confl", "f": "tipo=P;paese=Spagna,Austria,Sardegna", "d": "Metti 1 Conflitto in Spagna, Austria o Sardegna."},
	"Italy Influence": {"it": "Influenza in Italia", "sp": ["p_aus2", "p_sar"], "reg": "EU", "ef": "tot1", "f": "tipo=P;paese=Spagna,Austria", "d": "Togliere una bandiera in Spagna o Austria costa in tutto 1 PD."},
	"German Diplomacy": {"it": "Diplomazia tedesca", "sp": ["p_pru4"], "reg": "EU", "ef": "tot1", "f": "tipo=P;paese=Russia,Svezia,Baviera", "d": "Togliere una bandiera in Russia, Svezia o Baviera costa in tutto 1 PD."},
	"Central Europe Conflict": {"it": "Conflitto in Europa centrale", "sp": ["p_bav", "p_ger2"], "reg": "EU", "ef": "confl", "f": "tipo=P;reg=EU;all", "d": "Metti 1 Conflitto in uno spazio Alleanza d'Europa."},
	"Baltic Trade": {"it": "Commercio baltico", "sp": ["p_dan", "p_pru1"], "reg": "EU", "ef": "debito2", "f": "", "d": "Riduci il tuo Debito di 2."},
	"Silesia Negotiations": {"it": "Negoziati di Slesia", "sp": ["p_aus3"], "reg": "EU", "ef": "tot1", "f": "tipo=P;paese=Prussia,Stati tedeschi", "d": "Togliere una bandiera in Prussia o negli Stati tedeschi costa in tutto 1 PD."},
}

## Guerre. bonus: paesi (Alleanze), "K:<parola>", "CONF", "FORTI", "SQ:<regioni>". bottino: righe [margine minimo, PV, PC, PT al perdente, extra]
const GUERRE := {
	"WSS": {"nome": "Guerra di Successione Spagnola", "anni": "1702-1713", "teatri": [
		{"nome": "Europa centrale", "reg": ["EU"], "bonus": ["Austria", "Baviera", "Danimarca-Norvegia", "Province Unite", "Stati tedeschi", "Savoia"],
			"bott": [[1, 2, 0, 1, ""], [3, 2, 1, 2, ""], [5, 3, 2, 3, ""]], "terr": ["t_sag", "t_asi", "t_hud", "t_aca"]},
		{"nome": "Spagna", "reg": ["EU"], "bonus": ["K:GOV", "Sardegna", "Spagna", "SQ:EU"],
			"bott": [[1, 1, 0, 1, ""], [2, 1, 1, 2, ""], [4, 1, 2, 2, ""]], "terr": ["t_sag", "t_asi"]},
		{"nome": "Guerra della regina Anna", "reg": ["NA"], "bonus": ["CONF", "FORTI", "SQ:NA"],
			"bott": [[1, 1, 0, 0, ""], [3, 1, 1, 1, ""], [4, 1, 1, 2, "via:NA"]], "terr": []},
		{"nome": "Rivolta giacobita", "reg": ["EU"], "bonus": ["K:STI", "Province Unite", "Irlanda", "Scozia", "CONF"], "jac": true,
			"bott": [[1, 1, 0, 0, ""], [3, 2, 0, 1, ""], [5, 4, 0, 2, ""]], "terr": [], "spec": "jac_wss"},
	]},
	"WAS": {"nome": "Guerra di Successione Austriaca", "anni": "1740-1748", "teatri": [
		{"nome": "Europa centrale", "reg": ["EU"], "bonus": ["Austria", "Baviera", "Danimarca-Norvegia", "Province Unite", "Stati tedeschi", "Prussia", "Svezia"],
			"bott": [[1, 1, 0, 0, ""], [3, 1, 1, 1, ""]], "terr": ["t_hud", "t_sag", "t_aca", "t_asi"]},
		{"nome": "Guerra di re Giorgio", "reg": ["NA"], "bonus": ["CONF", "FORTI", "SQ:NA"],
			"bott": [[1, 0, 1, 0, ""], [3, 0, 1, 1, "via:NA"]], "terr": ["t_sag"]},
		{"nome": "Prima guerra del Carnatico", "reg": ["IN"], "bonus": ["CONF", "FORTI", "SQ:IN"],
			"bott": [[1, 0, 1, 0, ""], [3, 0, 2, 1, ""], [4, 0, 2, 2, "via:IN"]], "terr": []},
		{"nome": "Rivolta giacobita", "reg": ["EU"], "bonus": ["K:STI", "Irlanda", "Scozia", "CONF"], "jac": true,
			"bott_FR": [[1, 2, 0, 1, ""], [2, 3, 0, 2, "viapol"], [4, 5, 0, 3, "viapol"]],
			"bott_BR": [[1, 1, 0, 0, ""], [2, 2, 0, 1, "viapol"], [3, 3, 0, 2, "viapol"]], "terr": [], "spec": "jac_was"},
	]},
	"7YW": {"nome": "Guerra dei Sette Anni", "anni": "1756-1763", "teatri": [
		{"nome": "Dominio dell'Atlantico", "reg": ["EU"], "bonus": ["SQ:CA,EU,NA"],
			"bott": [[2, 0, 0, 0, "atl"], [3, 0, 0, 0, "atl;sq1"], [5, 0, 0, 0, "atl;sq2"]], "terr": [], "nocp": true},
		{"nome": "Terza guerra del Carnatico", "reg": ["IN"], "bonus": ["CONF", "FORTI", "SQ:IN"],
			"bott": [[1, 0, 1, 1, ""], [3, 0, 1, 2, "via:IN"], [5, 0, 2, 3, "via:IN"]], "terr": []},
		{"nome": "Guerra franco-indiana", "reg": ["NA", "CA"], "bonus": ["Spagna", "CONF", "FORTI", "SQ:CA,NA"],
			"bott": [[1, 0, 1, 1, "via:NA"], [3, 1, 2, 3, ""], [5, 2, 3, 4, ""]], "terr": ["t_min", "t_gib"]},
		{"nome": "Guerre di Prussia", "reg": ["EU"], "bonus": ["Austria", "Baviera", "Danimarca-Norvegia", "Province Unite", "Stati tedeschi", "Prussia", "Russia", "Svezia"],
			"bott": [[1, 2, 0, 0, ""], [3, 3, 0, 0, ""], [5, 4, 0, 1, ""]], "terr": []},
	]},
	"AWI": {"nome": "Guerra d'Indipendenza Americana", "anni": "1775-1783", "teatri": [
		{"nome": "Rivoluzione americana", "reg": ["NA"], "bonus": ["Stati tedeschi", "Sons of Liberty", "Spagna", "CONF", "FORTI", "SQ:NA"],
			"bott_FR": [[1, 2, 0, 2, "usa"], [3, 3, 0, 2, "usa"], [5, 4, 0, 3, "usa;canada"]],
			"bott_BR": [[1, 2, 0, 0, ""], [2, 3, 1, 1, ""], [4, 4, 2, 2, ""]], "terr": ["t_sag"]},
		{"nome": "Guerra del Mysore", "reg": ["IN"], "bonus": ["CONF", "FORTI", "SQ:IN"],
			"bott": [[1, 0, 1, 1, ""], [3, 0, 2, 3, ""]], "terr": []},
		{"nome": "Guerra delle Antille", "reg": ["CA"], "bonus": ["Spagna", "CONF", "SQ:CA"],
			"bott": [[1, 0, 1, 0, "ant"], [2, 0, 1, 1, "via:CA;ant"], [4, 0, 2, 2, "via:CA;ant"]], "terr": ["t_hud", "t_aca"]},
	]},
}
## Guerra che segue ogni turno di pace
const GUERRA_DOPO := {1: "WSS", 3: "WAS", 4: "7YW", 5: "AWI"}
const PROSSIMA_GUERRA := {1: "WSS", 2: "WAS", 3: "WAS", 4: "7YW", 5: "AWI", 6: ""}

## Carte Ministero. ere: quali ere; kw: parole chiave.
const MINISTERI := {
	1: {"l": "FR", "nome": "I cardinali ministri", "ere": [1], "kw": ["GOV"], "t": "Una volta per turno, all'inizio di un Round d'Azione in cui la tua tessera Investimento ha un'Azione Diplomatica, quell'Azione dà 1 PD in più per ciascuno di questi spazi che controlli (massimo 3): Savoia, Sardegna e ogni spazio Prestigio in Spagna e Austria."},
	2: {"l": "FR", "nome": "John Law", "ere": [1], "kw": ["FIN"], "t": "Alla fine di ogni turno di Pace riduci il tuo Debito di 1 (di 2 se controlli almeno uno spazio in Scozia)."},
	3: {"l": "FR", "nome": "La corte del Re Sole", "ere": [1], "kw": ["STI", "ERU"], "t": "Il Premio dell'Europa vale per te 1 PV in più."},
	4: {"l": "FR", "nome": "Insurrezioni giacobite", "ere": [1, 2, 3], "kw": [], "t": "Una volta per turno puoi usare PM per spostare spazi in Scozia e/o Irlanda. Una volta per turno, in un Round d'Azione diverso, puoi spendere 3 PM per segnare 1 PV (massimo 4) per ogni spazio di Scozia e Irlanda con bandiera francese e per ogni segnalino Vittoria giacobita. La carta è rimossa dal gioco dopo la carta britannica Negoziati Papato-Hannover o dopo una Sconfitta giacobita in guerra."},
	9: {"l": "FR", "nome": "Ugonotti del Nuovo Mondo", "ere": [1], "kw": ["MER"], "t": "Una volta per turno, in un tuo Round d'Azione, metti 1 segnalino Ugonotti in un Territorio con bandiera francese in Nord America o nei Caraibi che non ne abbia già uno. Il segnalino aumenta di 1 il costo in Punti Conquista del suo spazio. Una volta per partita può essere girato per ridurre di 1 il costo in PE di un Mercato della sua Regione. È rimosso per sempre se lo spazio prende bandiera britannica."},
	11: {"l": "FR", "nome": "Choiseul", "ere": [2], "kw": ["GOV", "FIN"], "t": "Una volta per turno, quando fai un'Azione Militare, ricevi 1 PM in più da spendere solo per tessere Guerra Bonus o per schierare Squadre. Una volta per turno, se hai una Squadra in Nord America, puoi costruire una nuova Squadra con 2 PM (invece di 4)."},
	12: {"l": "FR", "nome": "Dupleix", "ere": [2], "kw": ["MER"], "t": "I Premi per India, Cotone e Spezie valgono per te 1 PT in più."},
	13: {"l": "FR", "nome": "Pompadour e Du Barry", "ere": [2, 3], "kw": ["STI"], "t": "La prima volta in ogni Round d'Azione in cui esaurisci un Vantaggio in Europa, guadagni 1 PT."},
	14: {"l": "FR", "nome": "Voltaire", "ere": [2, 3], "kw": ["ERU"], "t": "Quando viene assegnato il Premio dell'Europa guadagni 1 PT per ogni paese con più spazi in cui controlli uno spazio Prestigio (massimo 3)."},
	23: {"l": "FR", "nome": "Turgot", "ere": [3], "kw": ["FIN", "STI"], "t": "Il primo Debito che prendi in ogni Round d'Azione vale 1 Punto Azione in più, purché tu abbia più Debito Disponibile dei britannici."},
	24: {"l": "FR", "nome": "Commercio nordamericano", "ere": [3], "kw": ["MER"], "t": "Se all'inizio del tuo Round d'Azione controlli più Mercati di Pelli e Pesce (insieme) dell'avversario, le tue Azioni Economiche Maggiore e Minore valgono 1 PE in più. Rinnova i tuoi segnalini Ugonotti sulla mappa."},
	25: {"l": "FR", "nome": "Marchese di Condorcet", "ere": [3], "kw": ["GOV"], "t": "Una volta per turno, all'inizio del tuo Round d'Azione, puoi giocare un Evento anche se la tessera Investimento scelta non ha il simbolo Evento. Il tipo dell'Evento, se c'è, deve comunque corrispondere all'Azione Maggiore della tessera."},
	26: {"l": "FR", "nome": "Lavoisier", "ere": [3], "kw": ["ERU"], "t": "In ogni Round d'Azione in cui giochi un Evento e ne ricevi l'effetto Bonus, le Azioni Maggiore e Minore della tessera Investimento valgono 1 Punto Azione in più."},
	5: {"l": "BR", "nome": "Robert Walpole", "ere": [1], "kw": ["GOV"], "t": "Una volta per turno puoi pescare una carta Evento e poi scartare una carta Evento."},
	6: {"l": "BR", "nome": "Jonathan Swift", "ere": [1], "kw": ["STI"], "t": "Mettere la bandiera negli spazi di Irlanda e Scozia ti costa 1 PD in meno. Se controlli almeno uno spazio in Irlanda, le tue Azioni Diplomatiche Minori possono togliere bandiere francesi in Europa."},
	7: {"l": "BR", "nome": "Compagnia delle Indie Orientali", "ere": [1, 2], "kw": ["MER"], "t": "Nella Fase di Punteggio segni 1 PV per ciascuno di questi Vantaggi non esauriti che controlli (massimo 3): Tessuti, Seta, Frutta, Commercio delle pelli, Rum."},
	8: {"l": "BR", "nome": "Banca d'Inghilterra", "ere": [1], "kw": ["FIN"], "t": "Una volta per turno puoi aumentare di 1 il tuo Limite di Debito. Una volta per turno puoi giocare un Evento Economico anche se la tessera Investimento scelta non ha un'Azione Maggiore Economica (deve comunque avere il simbolo Evento)."},
	10: {"l": "BR", "nome": "Edmond Halley", "ere": [1], "kw": ["ERU"], "t": "Una volta per turno puoi costruire una Squadra con 2 PM (invece di 4). Una volta per turno, se hai una Squadra in Europa, puoi scartare una carta Evento dalla mano e prendere 1 PT."},
	15: {"l": "BR", "nome": "Pitt il Vecchio", "ere": [2], "kw": ["GOV"], "t": "Una volta per turno, quando fai un'Azione Diplomatica, ricevi 1 PD in più da spendere per spostare spazi Politici non di Prestigio. Una volta per turno puoi costruire una nuova Squadra con 2 PM (invece di 4)."},
	16: {"l": "BR", "nome": "Charles Hanbury Williams", "ere": [2], "kw": ["STI"], "t": "Una volta per turno, per un Round d'Azione, togliere la bandiera francese dagli spazi di Prussia, Stati tedeschi e Russia ti costa 1 PD in meno."},
	17: {"l": "BR", "nome": "Banche mercantili", "ere": [2, 3], "kw": ["FIN"], "t": "Ignora i primi 2 Debiti che prendi come PE in ogni turno di Pace, purché tu li usi. (Se l'abilità è disponibile puoi usarla anche al Limite di Debito.)"},
	18: {"l": "BR", "nome": "Samuel Johnson", "ere": [2, 3], "kw": ["ERU"], "t": "Il Premio dell'Europa vale 1 PV in più per te e 1 PV in meno per la Francia (minimo 0)."},
	19: {"l": "BR", "nome": "James Watt", "ere": [3], "kw": ["ERU"], "t": "Se sei costretto a prendere Debito oltre il tuo Limite, l'avversario non segna PV. La prima volta in ogni Round d'Azione in cui l'avversario esaurisce un Vantaggio, guadagni 1 PT."},
	20: {"l": "BR", "nome": "Negoziati Papato-Hannover", "ere": [3], "kw": ["STI"], "t": "Rimuovi dal gioco la carta Ministero Insurrezioni giacobite. Una volta per turno, quando fai un'Azione Diplomatica, ricevi 2 PD utilizzabili solo per spostare spazi in Scozia e Irlanda."},
	21: {"l": "BR", "nome": "Leggi Townshend", "ere": [3], "kw": ["MER"], "t": "Una volta per turno, all'inizio di un Round d'Azione, metti il segnalino Leggi Townshend su una merce della Domanda Globale. In questo turno puoi usare le Azioni Minori per togliere bandiere dai Mercati di quella merce."},
	22: {"l": "BR", "nome": "Edmund Burke", "ere": [3], "kw": ["GOV"], "t": "Le Azioni Diplomatiche Maggiori spese interamente in Europa valgono fino a 2 PD in più: uno per ogni spazio dell'Irlanda che controlli. Gli spazi Sons of Liberty e Stati Uniti ti costano 1 PD in meno da spostare."},
}

## Carte Evento. era 1-3; tipo: Azione Maggiore richiesta ("" = qualsiasi); cond: condizione del Bonus.
## Versioni: "BR" e "FR", oppure "TT" (uguale per entrambi). Ogni versione: titolo, testo, base (passi), bonus (passi), tb (testo bonus).
const EVENTI := {
	1: {"nome": "Guerra del Carnatico", "era": 1, "tipo": "", "cond": "K:MER", "TT": {"t": "Metti 1 Conflitto in India per ogni Alleanza Locale che vi controlli.", "tb": "Danneggia un Forte nemico oppure sposta un Mercato del Cotone in India.",
		"base": [{"k": "x", "f": "carnatico"}], "bonus": [{"k": "scelta", "opz": [{"et": "Danneggia un Forte nemico", "p": [{"k": "sp", "az": "danno", "f": "tipo=F"}]}, {"et": "Sposta un Mercato del Cotone in India", "p": [{"k": "sp", "az": "sposta", "f": "tipo=M;merce=cotone;reg=IN"}]}]}]}},
	2: {"nome": "Atti di Unione", "era": 1, "tipo": "", "cond": "PRES_SCOIRL",
		"BR": {"tit": "Il Parlamento unificato riduce gli intrighi scozzesi in Europa", "t": "1 PD (solo per togliere bandiere in Europa).", "tb": "Segna 2 PV.", "base": [{"k": "pa", "t": "D", "n": 1, "lim": "reg=EU", "solo": "via"}], "bonus": [{"k": "pv", "n": 2}]},
		"FR": {"tit": "Gli Asburgo isolati", "t": "2 PD.", "tb": "Togli la bandiera a uno spazio Politico in Europa (non in Spagna né in Austria).", "base": [{"k": "pa", "t": "D", "n": 2}], "bonus": [{"k": "sp", "az": "via", "f": "tipo=P;reg=EU;nopaese=Spagna,Austria"}]}},
	3: {"nome": "Malattie tropicali", "era": 1, "tipo": "", "cond": "K:ERU", "TT": {"t": "Rimuovi 1 bandiera nemica, poi 1 bandiera amica, da Mercati dei Caraibi.", "tb": "Rimuovi un'altra bandiera nemica da un Mercato dei Caraibi.",
		"base": [{"k": "sp", "az": "via", "f": "tipo=M;reg=CA", "obb": true}, {"k": "sp", "az": "via_mia", "f": "tipo=M;reg=CA", "obb": true}], "bonus": [{"k": "sp", "az": "via", "f": "tipo=M;reg=CA", "obb": true}]}},
	4: {"nome": "Speculazione dei Mari del Sud", "era": 1, "tipo": "", "cond": "K:FIN", "TT": {"t": "Togli la bandiera a un Mercato la cui rimozione non isoli altri Mercati.", "tb": "In questo Round d'Azione costruire una nuova Squadra costa 2 PM in meno (può costare 0).",
		"base": [{"k": "sp", "az": "via", "f": "tipo=M;noisola"}], "bonus": [{"k": "x", "f": "sq_meno2"}]}},
	5: {"nome": "Guerra dell'orecchio di Jenkins", "era": 1, "tipo": "M", "cond": "K:MER",
		"BR": {"tit": "Anson torna con l'oro spagnolo", "t": "Riduci il tuo Debito di 2.", "tb": "Aggiungi 1 Debito alla Francia.", "base": [{"k": "deb", "chi": "io", "n": -2}], "bonus": [{"k": "deb", "chi": "avv", "n": 1}]},
		"FR": {"tit": "Disastro di Cartagena", "t": "Metti un Conflitto in un Mercato con bandiera britannica nei Caraibi.", "tb": "1 PD.", "base": [{"k": "sp", "az": "confl", "f": "tipo=M;reg=CA;nemico"}], "bonus": [{"k": "pa", "t": "D", "n": 1}]}},
	6: {"nome": "Alleanze con i nativi americani", "era": 1, "tipo": "D", "cond": "K:MER",
		"BR": {"tit": "I quattro re Mohawk", "t": "Sposta un'Alleanza Locale in Nord America.", "tb": "Attiva subito un Vantaggio che controlli in Nord America (anche se esaurito).", "base": [{"k": "sp", "az": "sposta", "f": "loc;reg=NA"}], "bonus": [{"k": "x", "f": "vant_NA"}]},
		"FR": {"tit": "Alleanza con i nativi", "t": "2 PE (solo Nord America).", "tb": "Togli la bandiera a un'Alleanza Locale in Nord America.", "base": [{"k": "pa", "t": "E", "n": 2, "lim": "reg=NA"}], "bonus": [{"k": "sp", "az": "via", "f": "loc;reg=NA"}]}},
	7: {"nome": "Rivalità austro-spagnola", "era": 1, "tipo": "", "cond": "K:GOV",
		"BR": {"tit": "La Farnese si scontra con la Francia", "t": "Metti 1 Conflitto in Spagna.", "tb": "Rimuovi una tessera Guerra Bonus francese dalla prossima Guerra (torna nella sua riserva).", "base": [{"k": "sp", "az": "confl", "f": "tipo=P;paese=Spagna"}], "bonus": [{"k": "x", "f": "togli_bonus_avv"}]},
		"FR": {"tit": "Carlo VI investe nei Paesi Bassi", "t": "Togli la bandiera a uno spazio delle Province Unite.", "tb": "2 PD oppure 2 PE in India.", "base": [{"k": "sp", "az": "via", "f": "paese=Province Unite"}], "bonus": [{"k": "scelta", "opz": [{"et": "2 PD", "p": [{"k": "pa", "t": "D", "n": 2}]}, {"et": "2 PE in India", "p": [{"k": "pa", "t": "E", "n": 2, "lim": "reg=IN"}]}]}]}},
	8: {"nome": "Riforma fiscale", "era": 1, "tipo": "E", "cond": "K:FIN", "TT": {"t": "Riduci il tuo Debito di 2. Se non puoi ridurre il Debito, prendi 1 PE per ogni riduzione non effettuata.", "tb": "Riduci il tuo Debito di 1 in più.",
		"base": [{"k": "x", "f": "riforma", "n": 2}], "bonus": [{"k": "x", "f": "riforma", "n": 1}]}},
	9: {"nome": "Grande guerra del Nord", "era": 1, "tipo": "M", "cond": "K:STI",
		"BR": {"tit": "Cresce il prestigio degli Hannover", "t": "Sposta uno spazio Politico negli Stati tedeschi. Se ora hanno entrambi la bandiera britannica, segna 2 PV.", "tb": "1 PD.", "base": [{"k": "sp", "az": "sposta", "f": "paese=Stati tedeschi"}, {"k": "x", "f": "gnw_br"}], "bonus": [{"k": "pa", "t": "D", "n": 1}]},
		"FR": {"tit": "La Francia media il trattato", "t": "Sposta la Russia. Se ha già la bandiera francese, segna invece 2 PV.", "tb": "1 PD.", "base": [{"k": "x", "f": "gnw_fr"}], "bonus": [{"k": "pa", "t": "D", "n": 1}]}},
	10: {"nome": "Politica vaticana", "era": 1, "tipo": "", "cond": "K:STI",
		"BR": {"tit": "Gli stati protestanti diffidano", "t": "2 PD (da spendere negli Stati tedeschi, in Prussia o nelle Province Unite).", "tb": "1 PD (Europa).", "base": [{"k": "pa", "t": "D", "n": 2, "lim": "paese=Stati tedeschi,Prussia,Province Unite"}], "bonus": [{"k": "pa", "t": "D", "n": 1, "lim": "reg=EU"}]},
		"FR": {"tit": "Unità cattolica", "t": "Sposta uno spazio qualsiasi di Spagna o Austria.", "tb": "Se non ci sono bandiere britanniche né in Spagna né in Austria, segna 2 PV.", "base": [{"k": "sp", "az": "sposta", "f": "paese=Spagna,Austria"}], "bonus": [{"k": "x", "f": "vaticano_fr"}]}},
	11: {"nome": "Leggi sul calicò", "era": 1, "tipo": "E", "cond": "K:MER",
		"BR": {"tit": "Le leggi sul calicò stimolano l'industria", "t": "2 PE, da usare per togliere bandiere a Mercati.", "tb": "Puoi assegnare il Cotone (come se fosse nella Domanda Globale).", "base": [{"k": "pa", "t": "E", "n": 2, "solo": "via"}], "bonus": [{"k": "x", "f": "punteggio_cotone"}]},
		"FR": {"tit": "Le leggi sul calicò arricchiscono i contrabbandieri", "t": "Togli la bandiera a un Mercato del Cotone.", "tb": "Sposta una Squadra britannica dalla mappa al Riquadro della Marina.", "base": [{"k": "sp", "az": "via", "f": "tipo=M;merce=cotone"}], "bonus": [{"k": "sp", "az": "via_sq", "f": "tipo=N"}]}},
	12: {"nome": "Sforamento delle spese militari", "era": 1, "tipo": "M", "cond": "DEB", "TT": {"t": "L'avversario deve danneggiare un suo Forte, rimuovere una sua Squadra (nel Riquadro della Marina) o rimuovere una sua tessera Guerra Bonus dalla prossima Guerra (torna nella riserva).", "tb": "L'avversario deve farlo di nuovo (non per forza la stessa scelta).",
		"base": [{"k": "x", "f": "sforamento"}], "bonus": [{"k": "x", "f": "sforamento"}]}},
	13: {"nome": "L'ambizione di Alberoni", "era": 1, "tipo": "", "cond": "K:GOV",
		"BR": {"tit": "«Nemmeno un inglese»", "t": "2 PE, da spendere per mettere bandiere in Mercati adiacenti a un Mercato con bandiera britannica.", "tb": "1 PE, con lo stesso vincolo.", "base": [{"k": "pa", "t": "E", "n": 2, "lim": "adiac_mio", "solo": "metti"}], "bonus": [{"k": "pa", "t": "E", "n": 1, "lim": "adiac_mio", "solo": "metti"}]},
		"FR": {"tit": "Il capolavoro di Fleury", "t": "Sposta uno spazio Alleanza in Austria, nelle Province Unite o in Spagna.", "tb": "Se Savoia e Sardegna hanno entrambe la bandiera francese, segna 3 PV.", "base": [{"k": "sp", "az": "sposta", "f": "all;paese=Austria,Province Unite,Spagna"}], "bonus": [{"k": "x", "f": "alberoni_fr"}]}},
	14: {"nome": "Carestia in Irlanda", "era": 1, "tipo": "E", "cond": "",
		"BR": {"tit": "La carestia indebolisce i giacobiti", "t": "Togli la bandiera a uno spazio francese in Irlanda o Scozia.", "tb": "", "base": [{"k": "sp", "az": "via", "f": "paese=Irlanda,Scozia"}], "bonus": []},
		"FR": {"tit": "Carichi di grano dall'America", "t": "Pesca una tessera Guerra Bonus per ogni spazio che controlli in Irlanda e aggiungile al teatro Rivolta giacobita della prossima Guerra.", "tb": "", "base": [{"k": "x", "f": "carestia_fr"}], "bonus": []}},
	15: {"nome": "Pagamento degli interessi", "era": 1, "tipo": "E", "cond": "DEB", "TT": {"t": "Riduci di 1 il Limite di Debito dell'avversario. Se l'avversario era al Limite, riduci di 1 anche il suo Debito e poi segna 1 PV.", "tb": "Riduci il tuo Debito di 2.",
		"base": [{"k": "x", "f": "interessi"}], "bonus": [{"k": "deb", "chi": "io", "n": -2}]}},
	16: {"nome": "Rivolte di schiavi nei Caraibi", "era": 2, "tipo": "", "cond": "BONUS_G", "TT": {"tit": "Gli schiavi abbandonano le piantagioni", "t": "Metti 1 Conflitto in un Mercato dei Caraibi.", "tb": "Metti 1 altro Conflitto allo stesso modo.",
		"base": [{"k": "sp", "az": "confl", "f": "tipo=M;reg=CA"}], "bonus": [{"k": "sp", "az": "confl", "f": "tipo=M;reg=CA"}]}},
	17: {"nome": "Patto di famiglia", "era": 2, "tipo": "", "cond": "K:STI",
		"BR": {"tit": "Tensione tra Borbone e Asburgo", "t": "In questo Round d'Azione togliere la bandiera francese dagli spazi di Spagna o Austria ti costa 1 PD in meno.", "tb": "1 PD.", "base": [{"k": "x", "f": "patto_br"}], "bonus": [{"k": "pa", "t": "D", "n": 1}]},
		"FR": {"tit": "Legami della famiglia Borbone", "t": "Rinnova fino a due Vantaggi in Europa.", "tb": "2 PD in Spagna e/o Austria.", "base": [{"k": "x", "f": "patto_fr"}], "bonus": [{"k": "pa", "t": "D", "n": 2, "lim": "paese=Spagna,Austria"}]}},
	18: {"nome": "Il processo di Byng", "era": 2, "tipo": "", "cond": "",
		"BR": {"tit": "Per incoraggiare gli altri", "t": "Metti il segnalino Byng (+2) in un teatro della prossima Guerra che conta la Forza navale.", "tb": "", "base": [{"k": "x", "f": "byng_br"}], "bonus": []},
		"FR": {"tit": "Gli altri non sono incoraggiati", "t": "Rimuovi una Squadra britannica dalla mappa o dal Riquadro della Marina: tornerà nel Riquadro nella Fase di Riassetto del prossimo turno di Pace.", "tb": "", "base": [{"k": "x", "f": "byng_fr"}], "bonus": []}},
	19: {"nome": "Le beau monde", "era": 2, "tipo": "", "cond": "K:STI",
		"BR": {"tit": "I profughi ugonotti portano i loro mestieri", "t": "Puoi mettere Pelli o Cotone nella Domanda Globale.", "tb": "1 PE.", "base": [{"k": "x", "f": "beau_br"}], "bonus": [{"k": "pa", "t": "E", "n": 1}]},
		"FR": {"tit": "Il dominio della moda", "t": "1 PD in Europa.", "tb": "Altri 2 PD in Europa.", "base": [{"k": "pa", "t": "D", "n": 1, "lim": "reg=EU"}], "bonus": [{"k": "pa", "t": "D", "n": 2, "lim": "reg=EU"}]}},
	20: {"nome": "Hyder Ali", "era": 2, "tipo": "", "cond": "K:MER", "TT": {"t": "Prendi il controllo di un'Alleanza Locale in India, oppure metti 2 Conflitti in spazi non protetti dell'India.", "tb": "2 PE in India.",
		"base": [{"k": "scelta", "opz": [{"et": "Prendi il controllo di un'Alleanza Locale in India", "p": [{"k": "sp", "az": "prendi", "f": "loc;reg=IN"}]}, {"et": "Metti 2 Conflitti in spazi non protetti dell'India", "p": [{"k": "sp", "az": "confl", "f": "reg=IN;noprot", "n": 2}]}]}], "bonus": [{"k": "pa", "t": "E", "n": 2, "lim": "reg=IN"}]}},
	21: {"nome": "Il sistema Co-Hong", "era": 2, "tipo": "D", "cond": "K:ERU", "TT": {"tit": "Accordo con i Qing", "t": "Pesca una nuova tessera Domanda Globale e sostituisci con essa una di quelle del turno.", "tb": "2 PE in India.",
		"base": [{"k": "x", "f": "cohong"}], "bonus": [{"k": "pa", "t": "E", "n": 2, "lim": "reg=IN"}]}},
	22: {"nome": "Crisi della Corsica", "era": 2, "tipo": "D", "cond": "K:GOV",
		"BR": {"tit": "I britannici intervengono", "t": "Sposta la Sardegna o la Savoia.", "tb": "Segna 1 PV se la Francia non ha Squadre in Europa.", "base": [{"k": "sp", "az": "sposta", "f": "paese=Sardegna,Savoia"}], "bonus": [{"k": "x", "f": "corsica_br"}]},
		"FR": {"tit": "I britannici tentennano", "t": "Togli la bandiera a uno spazio Politico in Europa.", "tb": "Segna 1 PV se la Gran Bretagna non ha bandiere in Spagna.", "base": [{"k": "sp", "az": "via", "f": "tipo=P;reg=EU"}], "bonus": [{"k": "x", "f": "corsica_fr"}]}},
	23: {"nome": "Panico europeo", "era": 2, "tipo": "E", "cond": "DEB3", "TT": {"t": "Per ogni Debito che l'avversario ha più di te (fino a 4), segna 1 PV.", "tb": "Togli la bandiera a uno spazio Politico avversario in Europa.",
		"base": [{"k": "x", "f": "panico"}], "bonus": [{"k": "sp", "az": "via", "f": "tipo=P;reg=EU"}]}},
	24: {"nome": "Miniere d'oro dell'Africa occidentale", "era": 2, "tipo": "", "cond": "DEB", "TT": {"t": "1 PE.", "tb": "2 PE nei Caraibi.",
		"base": [{"k": "pa", "t": "E", "n": 1}], "bonus": [{"k": "pa", "t": "E", "n": 2, "lim": "reg=CA"}]}},
	25: {"nome": "Guerra della Quadruplice Alleanza", "era": 2, "tipo": "D", "cond": "K:GOV",
		"BR": {"tit": "Prodezza navale britannica", "t": "Rimuovi una Squadra britannica dalla mappa o dal Riquadro della Marina per segnare 2 PV. Tornerà nel Riquadro al prossimo turno di Pace.", "tb": "Costruisci una Squadra, poi prendi 1 Debito oppure, se ne hai, perdi 1 PT.", "base": [{"k": "x", "f": "quadruplice_br"}], "bonus": [{"k": "x", "f": "quadruplice_bonus"}]},
		"FR": {"tit": "La Francia fa avanzare i suoi interessi nel Mediterraneo", "t": "Sposta uno spazio della Spagna.", "tb": "1 PD.", "base": [{"k": "sp", "az": "sposta", "f": "paese=Spagna"}], "bonus": [{"k": "pa", "t": "D", "n": 1}]}},
	26: {"nome": "Il Salone d'Ercole", "era": 2, "tipo": "", "cond": "K:STI",
		"BR": {"tit": "Versailles sfora i costi", "t": "Aumenta di 1 il Debito francese.", "tb": "Aumenta il Debito francese di altri 2.", "base": [{"k": "deb", "chi": "avv", "n": 1}], "bonus": [{"k": "deb", "chi": "avv", "n": 2}]},
		"FR": {"tit": "Il Salone impressiona gli ambasciatori", "t": "2 PD in Europa.", "tb": "Altri 2 PD in Europa.", "base": [{"k": "pa", "t": "D", "n": 2, "lim": "reg=EU"}], "bonus": [{"k": "pa", "t": "D", "n": 2, "lim": "reg=EU"}]}},
	27: {"nome": "Carestia del Bengala", "era": 2, "tipo": "E", "cond": "", "TT": {"t": "Metti fino a 2 Conflitti in Mercati o spazi Politici dell'India.", "tb": "",
		"base": [{"k": "sp", "az": "confl", "f": "reg=IN", "n": 2}], "bonus": []}},
	28: {"nome": "Padre Le Loutre", "era": 2, "tipo": "M", "cond": "K:GOV",
		"BR": {"tit": "Gli acadiani espulsi", "t": "Metti un Conflitto in un Mercato del Pesce.", "tb": "2 PM in Nord America.", "base": [{"k": "sp", "az": "confl", "f": "tipo=M;merce=pesce"}], "bonus": [{"k": "pa", "t": "M", "n": 2, "lim": "reg=NA"}]},
		"FR": {"tit": "Incursioni su Halifax", "t": "Metti un Conflitto in un Mercato con bandiera britannica.", "tb": "2 PE in Nord America.", "base": [{"k": "sp", "az": "confl", "f": "tipo=M;nemico"}], "bonus": [{"k": "pa", "t": "E", "n": 2, "lim": "reg=NA"}]}},
	29: {"nome": "Guerra di Successione Polacca", "era": 2, "tipo": "M", "cond": "K:FIN",
		"BR": {"tit": "I britannici rafforzano i legami con la Russia", "t": "Guadagna 2 PT.", "tb": "Sposta la Russia.", "base": [{"k": "trp", "n": 2}], "bonus": [{"k": "sp", "az": "sposta", "f": "paese=Russia"}]},
		"FR": {"tit": "La Lorena è assicurata", "t": "Segna 2 PV.", "tb": "Sposta la Russia o la Svezia.", "base": [{"k": "pv", "n": 2}], "bonus": [{"k": "sp", "az": "sposta", "f": "paese=Russia,Svezia"}]}},
	30: {"nome": "Il caffè di Jonathan", "era": 2, "tipo": "E", "cond": "K:FIN", "TT": {"t": "2 PE.", "tb": "1 PE in più e riduci il tuo Debito di 1.",
		"base": [{"k": "pa", "t": "E", "n": 2}], "bonus": [{"k": "pa", "t": "E", "n": 1}, {"k": "deb", "chi": "io", "n": -1}]}},
	31: {"nome": "Incidente di Nootka", "era": 3, "tipo": "M", "cond": "K:MER",
		"BR": {"tit": "Crisi risolta", "t": "2 PD oppure 2 PE.", "tb": "Segna 2 PV per ogni spazio Alleanza della Spagna con bandiera britannica, poi rimuovi quelle bandiere.", "base": [{"k": "scelta", "opz": [{"et": "2 PD", "p": [{"k": "pa", "t": "D", "n": 2}]}, {"et": "2 PE", "p": [{"k": "pa", "t": "E", "n": 2}]}]}], "bonus": [{"k": "x", "f": "nootka_br"}]},
		"FR": {"tit": "I britannici contendono il territorio alla Spagna", "t": "Rimanda una Squadra britannica nel Riquadro della Marina.", "tb": "Costruisci una Squadra.", "base": [{"k": "sp", "az": "via_sq", "f": "tipo=N"}], "bonus": [{"k": "x", "f": "costruisci_sq"}]}},
	32: {"nome": "Rivoluzione haitiana", "era": 3, "tipo": "", "cond": "BONUS_G", "TT": {"t": "Metti un Conflitto in un Mercato dello Zucchero dei Caraibi. I Conflitti messi da questo Evento costano 1 PM in più da rimuovere.", "tb": "Metti Conflitti in altri 2 Mercati dello stesso tipo.",
		"base": [{"k": "sp", "az": "confl+", "f": "tipo=M;reg=CA;merce=zucchero"}], "bonus": [{"k": "sp", "az": "confl+", "f": "tipo=M;reg=CA;merce=zucchero", "n": 2}]}},
	33: {"nome": "Loggia delle Nove Sorelle", "era": 3, "tipo": "", "cond": "K:STI",
		"BR": {"tit": "Le società di dibattito infiltrate", "t": "Metti 1 Conflitto nella sotto-regione Colonie del Nord.", "tb": "Se in Nord America ci sono più bandiere britanniche che francesi, segna 3 PV.", "base": [{"k": "sp", "az": "confl", "f": "sub=COL"}], "bonus": [{"k": "x", "f": "loggia_br"}]},
		"FR": {"tit": "Le logge animano la politica", "t": "Attiva un Vantaggio che controlli fuori dall'Europa (anche se esaurito).", "tb": "2 PD.", "base": [{"k": "x", "f": "vant_fuori"}], "bonus": [{"k": "pa", "t": "D", "n": 2}]}},
	34: {"nome": "La gabella", "era": 3, "tipo": "D", "cond": "DEB",
		"BR": {"tit": "Rivolte per la tassa sul sale", "t": "Esaurisci fino a 2 Vantaggi (a scelta del britannico): non hanno effetto.", "tb": "2 PE.", "base": [{"k": "x", "f": "gabella_br"}], "bonus": [{"k": "pa", "t": "E", "n": 2}]},
		"FR": {"tit": "La tassa sul sale riformata per sempre", "t": "2 PE.", "tb": "Segna 2 PV (3 PV se hai la parola chiave Governo).", "base": [{"k": "pa", "t": "E", "n": 2}], "bonus": [{"k": "x", "f": "gabella_fr"}]}},
	35: {"nome": "Soppressione dei gesuiti", "era": 3, "tipo": "", "cond": "K:GOV",
		"BR": {"tit": "Le haciendas dei gesuiti si dissolvono", "t": "Togli la bandiera a un Mercato dello Zucchero.", "tb": "3 PE (solo Caraibi).", "base": [{"k": "sp", "az": "via", "f": "tipo=M;merce=zucchero"}], "bonus": [{"k": "pa", "t": "E", "n": 3, "lim": "reg=CA"}]},
		"FR": {"tit": "I debiti dei gesuiti onorati", "t": "Riduci il tuo Debito di 2.", "tb": "Segna 2 PV.", "base": [{"k": "deb", "chi": "io", "n": -2}], "bonus": [{"k": "pv", "n": 2}]}},
	36: {"nome": "La ricchezza delle nazioni", "era": 3, "tipo": "", "cond": "K:ERU", "TT": {"t": "Riduci il tuo Debito di 2.", "tb": "3 PE.",
		"base": [{"k": "deb", "chi": "io", "n": -2}], "bonus": [{"k": "pa", "t": "E", "n": 3}]}},
	37: {"nome": "Crisi del debito", "era": 3, "tipo": "E", "cond": "DEB3", "TT": {"t": "Se hai più Debito Disponibile dell'avversario, ricevi 3 PE (da usare per togliere bandiere a Mercati).", "tb": "Segna 2 PV.",
		"base": [{"k": "x", "f": "crisi_debito"}], "bonus": [{"k": "pv", "n": 2}]}},
	38: {"nome": "Pirateria in Asia orientale", "era": 3, "tipo": "M", "cond": "", "TT": {"t": "Se in India hai più Squadre, Forti e Alleanze Locali (sommati) dell'avversario, segna 3 PV.", "tb": "",
		"base": [{"k": "x", "f": "pirateria"}], "bonus": []}},
	39: {"nome": "Legge sul bollo", "era": 3, "tipo": "", "cond": "K:MER",
		"BR": {"tit": "La legge sul bollo frena il contrabbando", "t": "Riduci il tuo Debito di 2.", "tb": "2 PE.", "base": [{"k": "deb", "chi": "io", "n": -2}], "bonus": [{"k": "pa", "t": "E", "n": 2}]},
		"FR": {"tit": "Il bollo fa infuriare i coloni", "t": "Metti 1 Conflitto nella sotto-regione Colonie del Nord.", "tb": "Mettine invece 3.", "base": [{"k": "x", "f": "bollo_fr"}], "bonus": []}},
	40: {"nome": "Crisi delle Falkland", "era": 3, "tipo": "D", "cond": "V:Mediterranean Intrigue",
		"BR": {"tit": "La Spagna cede Egmont", "t": "Se c'è uno spazio della Spagna con bandiera britannica, segna 1 PV.", "tb": "Togli la bandiera a uno spazio della Spagna.", "base": [{"k": "x", "f": "falkland_br"}], "bonus": [{"k": "sp", "az": "via", "f": "paese=Spagna"}]},
		"FR": {"tit": "La Francia sposta gli equilibri", "t": "Ricevi 1 PM per ogni bandiera francese in Spagna.", "tb": "Rimuovi dal gioco una Squadra britannica.", "base": [{"k": "x", "f": "falkland_fr"}], "bonus": [{"k": "x", "f": "elimina_sq_avv"}]}},
	41: {"nome": "Cook e Bougainville", "era": 3, "tipo": "", "cond": "K:MER",
		"BR": {"tit": "Cook mappa il Pacifico", "t": "1 PE ogni 2 Squadre che hai sulla mappa o nel Riquadro della Marina.", "tb": "Pesca una tessera Guerra Bonus.", "base": [{"k": "x", "f": "cook_br"}], "bonus": [{"k": "x", "f": "pesca_bonus"}]},
		"FR": {"tit": "La circumnavigazione di Bougainville", "t": "Aggiungi una Squadra al Riquadro della Marina.", "tb": "Riduci il tuo Debito di 2.", "base": [{"k": "x", "f": "costruisci_sq"}], "bonus": [{"k": "deb", "chi": "io", "n": -2}]}},
}

static func cond_testo(c: String) -> String:
	if c == "":
		return ""
	if c.begins_with("K:"):
		return PAROLE[c.substr(2)]
	if c.begins_with("V:"):
		return "controlli " + VANTAGGI[c.substr(2)]["it"]
	match c:
		"DEB": return "hai più Debito Disponibile dell'avversario"
		"DEB3": return "hai almeno 3 Debito Disponibile più dell'avversario"
		"PRES_SCOIRL": return "hai più spazi Prestigio in Scozia e Irlanda"
		"BONUS_G": return "hai più tessere Guerra Bonus nella prossima Guerra"
	return c
