#!/usr/bin/env python3
"""Ricompone le carte Evento e Ministero con la grafica originale e il testo italiano.
Prende ogni carta del modulo TTS, cancella il testo inglese ricostruendo la pergamena
(mediana fra tutte le carte) e riscrive titolo e testo con font simili agli originali.
Uso: python3 -I tools/carte.py <cartella Mods del modulo> <cartella del progetto> [numeri di prova]"""
import json, os, re, sys, glob
import numpy as np
from PIL import Image, ImageDraw, ImageFont
MODS, PRJ = sys.argv[1], sys.argv[2]
IMG = os.path.join(MODS, 'Images')
FD = os.path.join(PRJ, 'tools', 'font')
W, H = 750, 1050
files = os.listdir(IMG)
d = json.load(open(glob.glob(os.path.join(MODS, 'Workshop', '*.json'))[0]))
ogg = []
def walk(o):
    ogg.append(o)
    for x in o.get('ContainedObjects', []) or []:
        walk(x)
for o in d['ObjectStates']:
    walk(o)
def trova(url):
    m = re.findall(r'[0-9A-F]{40}', url)
    for f in files:
        if m and m[-1] in f:
            return os.path.join(IMG, f)
def mazzo(chiave):
    return [v for o in ogg for k, v in (o.get('CustomDeck') or {}).items() if k == chiave][0]

# ---------- dati dal gioco (dati.gd) ----------
def blocco(nome):
    src = open(os.path.join(PRJ, 'scripts', 'dati.gd'), encoding='utf-8').read()
    a = src.index('const %s := {' % nome) + len('const %s := ' % nome)
    b = src.index('\n}\n', a) + 2
    t = src[a:b]
    t = re.sub(r'(?m)^\t(\d+):', r'\t"\1":', t)
    t = re.sub(r',(\s*[}\]])', r'\1', t)
    t = re.sub(r'\btrue\b', 'true', t)
    return json.loads(t)
EVENTI = blocco('EVENTI')
MINISTERI = blocco('MINISTERI')
PAROLE = {"FIN": "Finanza", "MER": "Mercantilismo", "GOV": "Governo", "STI": "Stile", "ERU": "Erudizione"}
ERE = {1: 'SUCCESSIONE', 2: 'IMPERO', 3: 'RIVOLUZIONE'}
COND = {"DEB": "Più Debito Disponibile dell'avversario", "DEB3": "Almeno 3 Debito Disponibile più dell'avversario",
        "PRES_SCOIRL": "Più spazi Prestigio in Scozia e Irlanda", "BONUS_G": "Più tessere Guerra Bonus nella prossima Guerra",
        "V:Mediterranean Intrigue": "Controlli Intrigo mediterraneo"}
def cond_testo(c):
    if c.startswith('K:'):
        return PAROLE[c[2:]]
    return COND.get(c, c)

# ---------- carte originali ----------
def foglio(v, n, per_riga, righe, indice):
    f = Image.open(trova(v['FaceURL'])).convert('RGB')
    w, h = f.size[0] / per_riga, f.size[1] / righe
    return f.crop((round((indice % per_riga) * w), round((indice // per_riga) * h), round((indice % per_riga + 1) * w), round((indice // per_riga + 1) * h)))
ev_orig = {}
agg = {}
for o in ogg:
    if o['Name'] in ('Card', 'CardCustom'):
        m = re.search(r'Event card #(\d+)', o.get('Description', ''))
        for k, v in (o.get('CustomDeck') or {}).items():
            if m and v['NumWidth'] == 1:
                agg[int(m.group(1))] = v['FaceURL']
v431 = mazzo('431')
for i in range(41):
    n = i + 1
    c = Image.open(trova(agg[n])).convert('RGB') if n in agg else foglio(v431, n, 10, 7, i)
    ev_orig[n] = c.resize((W, H), Image.LANCZOS)
mi_orig = {}
for chiave, ordine in (('4', [1, 2, 3, 4, 9, 11, 12, 13, 14, 23, 24, 25, 26]), ('412', [5, 6, 7, 8, 10, 15, 16, 17, 18, 19, 20, 21, 22])):
    v = mazzo(chiave)
    for i, n in enumerate(ordine):
        mi_orig[n] = foglio(v, n, 5, 3, i).resize((W, H), Image.LANCZOS)
# le due carte Ministero aggiornate (immagine singola), se ci sono
for o in ogg:
    if o['Name'] in ('Card', 'CardCustom') and 'Ministry' in o.get('Description', ''):
        m = re.search(r'M-(\d+)', o.get('Nickname', '') + ' ' + o.get('Description', ''))
        for k, v in (o.get('CustomDeck') or {}).items():
            if m and v['NumWidth'] == 1 and trova(v['FaceURL']):
                mi_orig[int(m.group(1))] = Image.open(trova(v['FaceURL'])).convert('RGB').resize((W, H), Image.LANCZOS)

def pulito(carte):
    """Pergamena senza testo: per ogni pixel un percentile alto di luminosità fra le carte."""
    a = np.stack([np.asarray(c).astype(np.float32) for c in carte])
    lum = a.mean(axis=3)
    idx = np.argsort(lum, axis=0)
    k = idx[int(len(carte) * 0.8)]
    # nella fascia dei titoli quasi tutte le carte hanno inchiostro: lì si prende il pixel più chiaro
    k2 = idx[int(len(carte) * 0.96)]
    k[380:545] = k2[380:545]
    yy, xx = np.mgrid[0:H, 0:W]
    return a[k, yy, xx].astype(np.uint8)
PERG_EV = pulito(list(ev_orig.values()))
PERG_MI = pulito(list(mi_orig.values()))

# ---------- icone dei Punti Azione (dalle tessere Investimento) ----------
ICONE = {}
TIPI = {'Economic': 'E', 'Ecomonic': 'E', 'Diplomacy': 'D', 'Military': 'M'}
for o in ogg:
    if o.get('Nickname', '') == 'Investment Tile':
        m = re.search(r'Major Action: (\w+) (\d) AP', o['Description'])
        t = TIPI[m.group(1)]
        if t in ICONE:
            continue
        im = Image.open(trova(o['CustomImage']['ImageSecondaryURL'])).convert('RGB')
        s = im.size[0]
        c = im.crop((round(s * 0.17), round(s * 0.15), round(s * 0.62), round(s * 0.60)))
        a = np.asarray(c).astype(np.float32)
        bg = np.median(a[:6, :6].reshape(-1, 3), axis=0)
        dist = np.abs(a - bg).max(axis=2)
        alpha = np.clip((dist - 14) * 9, 0, 255).astype(np.uint8)
        rgba = np.dstack([a.astype(np.uint8), alpha])
        ic = Image.fromarray(rgba, 'RGBA')
        ICONE[t] = ic.crop(ic.getbbox())

# ---------- stemmi (filigrana) dalle carte originali ----------
def filigrana(carta, box):
    c = np.asarray(carta.crop(box)).astype(np.float32)
    p = np.asarray(Image.fromarray(PERG_EV).crop(box)).astype(np.float32)
    diff = np.clip((p.mean(axis=2) - c.mean(axis=2)) * 3.2, 0, 150).astype(np.uint8)
    out = np.zeros(diff.shape + (4,), np.uint8)
    out[..., 0:3] = (70, 62, 50)
    out[..., 3] = diff
    return Image.fromarray(out, 'RGBA')
STEMMA = {'BR': filigrana(ev_orig[2], (606, 652, 700, 728)), 'FR': filigrana(ev_orig[2], (622, 832, 688, 906))}

# ---------- testo ----------
# niente legature ornamentali (la «st» del corsivo), se il motore di testo le applica
from PIL import features as _feat
NOLEG = ['-dlig', '-hlig', '-liga', '-clig'] if _feat.check('raqm') else None
def incolla_sfumato(im, perg, box, bordo=14):
    """Incolla la pergamena pulita sfumando i bordi sinistro e alto, per non lasciare stacchi."""
    x0, y0, x1, y1 = box
    pezzo = Image.fromarray(perg).crop(box)
    m = np.full((y1 - y0, x1 - x0), 255, np.float32)
    rampa = np.linspace(0, 1, bordo)
    m[:, :bordo] *= rampa[None, :]
    m[:bordo, :] *= rampa[:, None]
    im.paste(pezzo, (x0, y0), Image.fromarray(m.astype(np.uint8), 'L'))

def font(nome, dim, peso=400):
    f = ImageFont.truetype(os.path.join(FD, nome), dim)
    try:
        f.set_variation_by_axes([peso])
    except Exception:
        pass
    return f
def fonts(dim):
    return {'n': font('Caslon.ttf', dim, 400), 'b': font('Caslon.ttf', dim, 700), 'i': font('CaslonCorsivo.ttf', dim, 400), 'bi': font('CaslonCorsivo.ttf', dim, 700)}

def spezza(testo):
    """Da testo con **grassetto**, _corsivo_, {E}{D}{M} a elenco di parole [(testo, stile, colore)]."""
    out = []
    stile = 'n'
    for pezzo in re.split(r'(\*\*|__|\{[EDM]\}|\[g\]|\[/g\]|\n)', testo):
        if pezzo == '**':
            stile = 'n' if stile == 'b' else 'b'
        elif pezzo == '__':
            stile = 'n' if stile == 'i' else 'i'
        elif pezzo == '\n':
            out.append(('\n', stile, None))
        elif pezzo in ('[g]', '[/g]'):
            out.append((pezzo, stile, None))
        elif re.fullmatch(r'\{[EDM]\}', pezzo or ''):
            out.append(('@' + pezzo[1], stile, None))
        elif pezzo:
            for i, w in enumerate(re.split(r'( +)', pezzo)):
                if w:
                    out.append((w, stile, None))
    return out

def impagina(dr, im, testo, x0, x1, y, dim, inter=1.22, colore=(28, 22, 16), misura=False, grigio=(100, 96, 88)):
    """Scrive testo centrato fra x0 e x1 a partire da y; restituisce la y finale."""
    F = fonts(dim)
    alt = round(dim * inter)
    righe = [[]]
    largh = 0.0
    col = colore
    def lw(tok):
        t, st = tok[0], tok[1]
        if t.startswith('@'):
            return dim * 1.25
        return F[st].getlength(t, features=NOLEG)
    for tok in spezza(testo):
        t = tok[0]
        if t == '\n':
            righe.append([]); largh = 0.0; continue
        if t in ('[g]', '[/g]'):
            righe[-1].append(tok); continue
        l = lw(tok)
        if largh + l > (x1 - x0) and t.strip() and righe[-1]:
            while righe[-1] and righe[-1][-1][0].strip() == '' :
                righe[-1].pop()
            righe.append([]); largh = 0.0
        if not righe[-1] and t.strip() == '':
            continue
        righe[-1].append(tok); largh += l
    for r in righe:
        while r and r[-1][0].strip() == '':
            r.pop()
        tot = sum(lw(t) for t in r if t[0] not in ('[g]', '[/g]'))
        x = (x0 + x1) / 2 - tot / 2
        for tok in r:
            t, st = tok[0], tok[1]
            if t == '[g]':
                col = grigio; continue
            if t == '[/g]':
                col = colore; continue
            if not misura:
                if t.startswith('@'):
                    ic = ICONE[t[1]]
                    hh = round(dim * 1.2)
                    ww = round(ic.size[0] * hh / ic.size[1])
                    if ww > dim * 1.25:
                        ww = round(dim * 1.25); hh = round(ic.size[1] * ww / ic.size[0])
                    ic2 = ic.resize((ww, hh), Image.LANCZOS)
                    im.paste(ic2, (round(x + (dim * 1.25 - ww) / 2), round(y + dim * 0.72 - hh / 2)), ic2)
                else:
                    dr.text((x, y), t, font=F[st], fill=col, features=NOLEG)
            x += lw(tok)
        y += alt if r else round(alt * 0.45)
    return y

def titolo(dr, testo, x0, x1, y0, colore, dim_max=50, righe_max=2):
    testo = testo.upper()
    for dim in range(dim_max, 22, -2):
        f = font('Besley.ttf', dim, 900)
        parole = testo.split(' ')
        righe = ['']
        for p in parole:
            prova = (righe[-1] + ' ' + p).strip()
            if f.getlength(prova) <= (x1 - x0) or not righe[-1]:
                righe[-1] = prova
            else:
                righe.append(p)
        if len(righe) <= righe_max and all(f.getlength(r) <= (x1 - x0) for r in righe):
            break
    alt = round(dim * 1.04)
    y = y0 if len(righe) > 1 else y0 + round(alt * 0.35)
    for r in righe:
        dr.text(((x0 + x1) / 2 - f.getlength(r) / 2, y), r, font=f, fill=colore)
        y += alt
    return y

def icone(t):
    t = re.sub(r'\bPE\b', '{E}', t)
    t = re.sub(r'\bPD\b', '{D}', t)
    t = re.sub(r'\bPM\b', '{M}', t)
    return t

def adatta(disegna, y0, y_max, dim0=37, dim_min=24):
    """Trova il corpo più grande con cui il testo sta fra y0 e y_max, poi lo disegna centrato in altezza."""
    for dim in range(dim0, dim_min - 1, -1):
        fine = disegna(dim, y0, True)
        if fine <= y_max:
            break
    disegna(dim, y0, False)

# ---------- carte Evento ----------
# carte con l'illustrazione più alta del solito
ALTE = {8, 13}
def carta_evento(n):
    e = EVENTI[str(n)]
    im = ev_orig[n].copy()
    X0, Y0 = 100, (414 if n in ALTE else 398)
    incolla_sfumato(im, PERG_EV, (X0, Y0, W, H))
    # fascia dell'era: copre la scritta inglese e la riscrive in italiano
    a = np.asarray(im).copy()
    riga = a[560:1040, 4:9].mean(axis=1).astype(np.uint8)
    scritta = np.asarray(ev_orig[n])[600:1000, 20:80].reshape(-1, 3)
    chiaro = e['era'] != 1
    col_scritta = tuple(int(v) for v in (np.percentile(scritta, 97, axis=0) if chiaro else np.percentile(scritta, 3, axis=0)))
    a[560:1040, 0:94] = riga[:, None, :]
    im = Image.fromarray(a)
    f = font('Caslon.ttf', 46, 400)
    et = ERE[e['era']]
    lung = round(f.getlength(et)) + 8
    strato = Image.new('RGBA', (lung, 64), (0, 0, 0, 0))
    ImageDraw.Draw(strato).text((4, 4), et, font=f, fill=col_scritta + (255,))
    strato = strato.rotate(90, expand=True)
    im.paste(strato, (14, 1030 - lung), strato)
    dr = ImageDraw.Draw(im)
    y = titolo(dr, e['nome'], X0 + 14, W - 22, 422, (24, 18, 12), 44)
    y = max(y + 22, 540)
    def corpo(dim, y, misura):
        if e['cond']:
            y = impagina(dr, im, '**BONUS:** [g]%s[/g]' % cond_testo(e['cond']), X0 + 22, W - 30, y, dim + 1, misura=misura)
            y += round(dim * 0.4)
        if 'TT' in e:
            v = e['TT']
            t = icone(v['t'])
            if v.get('tit'):
                t = '__%s:__ %s' % (v['tit'], t)
            if v['tb']:
                t += '\n**Bonus:** ' + icone(v['tb'])
            y = impagina(dr, im, t, X0 + 22, W - 30, y, dim, misura=misura)
        else:
            for lato in ('BR', 'FR'):
                v = e[lato]
                t = '__%s:__ %s' % (v['tit'], icone(v['t']))
                if v['tb']:
                    t += ' **Bonus:** ' + icone(v['tb'])
                ya = y
                y = impagina(dr, im, t, X0 + 20, W - 96, y, dim, misura=misura)
                if not misura:
                    st = STEMMA[lato]
                    im.paste(st, (W - 86 + (80 - st.size[0]) // 2, round((ya + y) / 2 - st.size[1] / 2)), st)
                y += round(dim * 0.45)
        return y
    adatta(corpo, y, H - 26)
    return im

# ---------- carte Ministero ----------
def carta_ministro(n):
    mdat = MINISTERI[str(n)]
    orig = mi_orig[n]
    im = orig.copy()
    X0, Y0 = 100, 414
    incolla_sfumato(im, PERG_MI, (X0, Y0, W, H))
    # la scritta in basso c'è su tutte le carte: si copre con la fascia di pergamena subito sopra
    fascia = im.crop((110, 906, 720, 976))
    mf = np.full((70, 610), 255, np.float32)
    rr = np.linspace(0, 1, 18)
    mf[:, :18] *= rr[None, :]; mf[:, -18:] *= rr[None, ::-1]; mf[:18, :] *= rr[:, None]; mf[-18:, :] *= rr[::-1, None]
    im.paste(fascia, (110, 968), Image.fromarray(mf.astype(np.uint8), 'L'))
    dr = ImageDraw.Draw(im)
    # colore del titolo: quello originale (blu francese o rosso britannico)
    col = (28, 84, 150) if mdat['l'] == 'FR' else (176, 32, 36)
    y = titolo(dr, mdat['nome'], X0 + 14, W - 30, 420, col, 46)
    y = max(y + 18, 536)
    kw = ', '.join(PAROLE[k] for k in mdat['kw'])
    def corpo(dim, y, misura):
        if kw:
            y = impagina(dr, im, '**[g]%s[/g]**' % kw, X0 + 14, W - 30, y, dim + 2, misura=misura, grigio=(104, 98, 90))
            y += round(dim * 0.25)
        y = impagina(dr, im, icone(mdat['t']), 60 if False else X0 + 10, W - 34, y, dim, inter=1.18, misura=misura)
        return y
    adatta(corpo, y, 972, 36, 21)
    f = font('Caslon.ttf', 27, 700)
    pie = 'CARTA MINISTERO'
    dr.text((W / 2 - f.getlength(pie) / 2 + 20, 986), pie, font=f, fill=(128, 122, 110))
    return im

os.makedirs(PRJ + '/assets/carte', exist_ok=True)
prova = [int(x) for x in sys.argv[3:]]
if prova:
    fila = [carta_evento(n) for n in prova if n > 0] + [carta_ministro(-n) for n in prova if n < 0]
    o = Image.new('RGB', (W * len(fila), H))
    for i, c in enumerate(fila):
        o.paste(c, (i * W, 0))
    o.save('/tmp/prova_carte.png')
else:
    tutte = []
    for n in range(1, 42):
        c = carta_evento(n); tutte.append(c)
        c.save(PRJ + '/assets/carte/evc_%02d.webp' % n, quality=84)
    for n in sorted(mi_orig):
        c = carta_ministro(n); tutte.append(c)
        c.save(PRJ + '/assets/carte/mic_%02d.webp' % n, quality=84)
    for k in range(0, len(tutte), 14):
        gr = tutte[k:k + 14]
        o = Image.new('RGB', (7 * 280, 2 * 392))
        for i, c in enumerate(gr):
            o.paste(c.resize((280, 392), Image.LANCZOS), ((i % 7) * 280, (i // 7) * 392))
        o.save('/tmp/foglio_%d.jpg' % (k // 14), quality=85)
    print('carte fatte:', 41, len(mi_orig))
