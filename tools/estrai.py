#!/usr/bin/env python3
"""Costruisce risorse grafiche e dati generati a partire dal modulo TTS estratto.
Uso: python3 -I tools/estrai.py <cartella Mods del modulo> <cartella del progetto>"""
import json, os, re, sys, glob
from PIL import Image
Image.MAX_IMAGE_PIXELS = None
MODS, PRJ = sys.argv[1], sys.argv[2]
IMG = os.path.join(MODS, 'Images')
d = json.load(open(glob.glob(os.path.join(MODS, 'Workshop', '*.json'))[0]))
files = os.listdir(IMG)
def trova(url):
    m = re.findall(r'[0-9A-F]{40}', url)
    if not m:
        return None
    for f in files:
        if m[-1] in f:
            return os.path.join(IMG, f)
    return None
ogg = []
MANCANTI = []
def walk(o, par=''):
    o['_par'] = par
    ogg.append(o)
    for x in o.get('ContainedObjects', []) or []:
        walk(x, o.get('Nickname', ''))
for o in d['ObjectStates']:
    walk(o)
def pulisci(n):
    return re.sub(r'\[/?[a-zA-Z0-9]*\]|\[-\]', '', n)
os.makedirs(PRJ + '/assets/pezzi', exist_ok=True)
os.makedirs(PRJ + '/assets/carte', exist_ok=True)
os.makedirs(PRJ + '/assets/mappa', exist_ok=True)

# ---- mappa ----
mappa = [f for f in files if '208449462F9CE3A9B5ED5F571691F1AB7688A347FC601799' in f][0]
im = Image.open(os.path.join(IMG, mappa)).convert('RGB')
SC = 4096 / im.size[0]
im.resize((4096, round(im.size[1] * SC)), Image.LANCZOS).save(PRJ + '/assets/mappa/mappa.jpg', quality=88)
MAPPA_H = round(im.size[1] * SC)

# ---- spazi ----
chips = [o for o in ogg if o['Name'] == 'reversi_chip' and o['_par'] == '']
def pos(o):
    t = o['Transform']
    return round((91.2 * t['posX'] + 2548) * SC), round((-89.5 * t['posZ'] + 966) * SC)
spazi = {}
for riga in open(PRJ + '/tools/spazi_tabella.txt', encoding='utf-8'):
    riga = riga.rstrip('\n')
    if not riga or riga[0] == '#':
        continue
    sid, nome, gm, tipo, reg, sub, costo, extra = riga.split('|')
    c = None
    for o in chips:
        n = pulisci(o.get('Nickname', ''))
        if gm and o.get('GMNotes', '') != gm:
            continue
        if nome and not n.startswith(nome):
            continue
        if o['Transform']['posX'] < -24.5 and 'Spain' in n:
            continue
        c = o
        break
    assert c is not None, sid
    x, y = pos(c)
    s = dict(nome=(nome.rstrip(' -') or ''), tipo=tipo, reg=reg, sub=sub, costo=int(costo), x=x, y=y)
    for kv in extra.split(';'):
        if kv:
            k, v = kv.split('=')
            s[k] = int(v) if v.isdigit() else v
    if not s['nome']:
        s['nome'] = s.get('paese', sid)
    spazi[sid] = s
vant_pos = {}
for o in chips:
    n = pulisci(o.get('Nickname', ''))
    if 'Advantage' in n:
        vant_pos[n.split(' Advantage')[0]] = pos(o)
premi_pos = {}
for o in ogg:
    n = pulisci(o.get('Nickname', ''))
    if o['Name'] == 'reversi_chip' and n.startswith('Award for the') and o.get('GMNotes', '').startswith('REG'):
        premi_pos[n.split('the ')[1].split(' region')[0]] = pos(o)
coll, conq = [], []
for riga in open(PRJ + '/tools/collegamenti.txt', encoding='utf-8'):
    p = riga.split()
    if not p or p[0][0] == '#':
        continue
    if p[0] == '=':
        assert p[1] in spazi and p[2] in spazi, riga
        conq.append([p[1], p[2]])
    else:
        assert p[0] in spazi and p[1] in spazi, riga
        coll.append([p[0], p[1]])

# ---- pezzi ----
def salva(url, nome, lato=160):
    f = trova(url)
    if not f:
        MANCANTI.append(nome); return False
    im = Image.open(f).convert('RGBA')
    im.thumbnail((lato, lato), Image.LANCZOS)
    im.save(PRJ + '/assets/pezzi/' + nome + '.png')
    return True
def uno(nick):
    for o in ogg:
        if o.get('Nickname', '') == nick and o.get('CustomImage'):
            return o
    raise SystemExit('non trovo ' + nick)
b = uno('British/French Flag')['CustomImage']
salva(b['ImageURL'], 'band_a'); salva(b['ImageSecondaryURL'], 'band_b')
salva(uno('British Squadron')['CustomImage']['ImageURL'], 'squadra_BR')
salva(uno('French Squadron')['CustomImage']['ImageURL'], 'squadra_FR')
c = uno('Conflict Marker (double-sided)')['CustomImage']
salva(c['ImageURL'], 'conflitto'); salva(c['ImageSecondaryURL'], 'conflitto_piu')
salva(uno('Fort Damage')['CustomImage']['ImageURL'], 'danno')
salva(uno('USA Control Marker')['CustomImage']['ImageURL'], 'band_USA')
salva(uno('Exhausted Marker')['CustomImage']['ImageURL'], 'esaurito')
salva(uno('Victory Point Marker')['CustomImage']['ImageURL'], 'pv')
# tessere Investimento
inv = []
TIPI = {'Economic': 'E', 'Ecomonic': 'E', 'Diplomacy': 'D', 'Military': 'M'}
for o in ogg:
    if o.get('Nickname', '') == 'Investment Tile':
        ds = o['Description']
        m = re.search(r'Major Action: (\w+) (\d) AP', ds); mi = re.search(r'Minor Action: (\w+) 2 AP', ds)
        t = dict(mag=TIPI[m.group(1)], n=int(m.group(2)), min=TIPI[mi.group(1)], ev=0 if 'Not eligible' in ds else 1, up=0 if 'No Military Upgrade' in ds else 1)
        t['img'] = 'inv_%02d' % len(inv)
        salva(o['CustomImage']['ImageSecondaryURL'], t['img'], 200)
        inv.append(t)
# tessere Guerra
def effetto(n):
    n = n.lower()
    return 'deb' if 'debt' in n else ('dan' if 'damage' in n else ('via' if 'unflag' in n else ''))
base = {'FR': [], 'BR': []}
bonus = {}
viste = {}
for o in ogg:
    n = o.get('Nickname', ''); par = o['_par']
    if 'Basic War Tile' in n and 'Basic War Tiles' in par:
        lato = 'FR' if 'French' in par else 'BR'
        v = int(re.search(r'\(([+-]?\d)', n).group(1))
        url = o['CustomImage']['ImageURL']
        if url not in viste:
            viste[url] = 'gb_%s_%d' % (lato, len(viste)); salva(url, viste[url], 150)
            if 'dorso_' + lato not in viste:
                viste['dorso_' + lato] = 1; salva(o['CustomImage']['ImageSecondaryURL'], 'dorso_' + lato, 150)
        base[lato].append(dict(v=v, e=effetto(n), img=viste[url]))
    elif 'Bonus War Tile' in n and 'Bonus War Tiles' in par:
        lato = 'FR' if 'French' in par else 'BR'
        g = par.split(':')[0]
        v = int(re.search(r'\(\+(\d)', n).group(1))
        nome = n.split(' (')[0].strip()
        k = g + '_' + lato
        bonus.setdefault(k, [])
        img = 'gx_%s_%02d' % (k, len(bonus[k]))
        salva(o['CustomImage']['ImageURL'], img, 150)
        bonus[k].append(dict(v=v, e=effetto(n), nome=nome, img=img))
for k in bonus:
    assert len(bonus[k]) == 12, (k, len(bonus[k]))
assert len(base['FR']) == 16 and len(base['BR']) == 16 and len(inv) == 24, (len(base['FR']), len(inv))

# ---- illustrazioni delle carte ----
def ritaglio(im, n, nome):
    im.crop((26, 32, 349, 200)).save(PRJ + '/assets/carte/%s.webp' % nome, quality=82)
foglio = Image.open(trova([v['FaceURL'] for o in ogg for k, v in (o.get('CustomDeck') or {}).items() if k == '431'][0])).convert('RGB')
cw, ch = foglio.size[0] / 10, foglio.size[1] / 7
agg = {}
for o in ogg:
    if o['Name'] in ('Card', 'CardCustom'):
        m = re.search(r'Event card #(\d+)', o.get('Description', ''))
        for k, v in (o.get('CustomDeck') or {}).items():
            if m and v['NumWidth'] == 1:
                agg[int(m.group(1))] = v['FaceURL']
for i in range(41):
    n = i + 1
    if n in agg:
        c = Image.open(trova(agg[n])).convert('RGB').resize((375, 525))
    else:
        c = foglio.crop((round((i % 10) * cw), round((i // 10) * ch), round((i % 10 + 1) * cw), round((i // 10 + 1) * ch))).resize((375, 525))
    ritaglio(c, n, 'ev_%02d' % n)
dorsi = {}
for lato, chiave, ordine in (('FR', '4', [1, 2, 3, 4, 9, 11, 12, 13, 14, 23, 24, 25, 26]), ('BR', '412', [5, 6, 7, 8, 10, 15, 16, 17, 18, 19, 20, 21, 22])):
    v = [v for o in ogg for k, v in (o.get('CustomDeck') or {}).items() if k == chiave][0]
    f = Image.open(trova(v['FaceURL'])).convert('RGB')
    w, h = f.size[0] / 5, f.size[1] / 3
    for i, n in enumerate(ordine):
        c = f.crop((round((i % 5) * w), round((i // 5) * h), round((i % 5 + 1) * w), round((i // 5 + 1) * h))).resize((375, 525))
        ritaglio(c, n, 'mi_%02d' % n)

# ---- dati generati ----
with open(PRJ + '/scripts/dati_gen.gd', 'w', encoding='utf-8') as f:
    f.write('## File generato da tools/estrai.py: non modificare a mano.\nclass_name DatiGen\nextends RefCounted\n\n')
    f.write('const MAPPA_L := 4096\nconst MAPPA_H := %d\n' % MAPPA_H)
    def js(v):
        return json.dumps(v, ensure_ascii=False)
    f.write('const SPAZI := {\n' + ',\n'.join('\t%s: %s' % (js(k), js(v)) for k, v in spazi.items()) + '\n}\n')
    f.write('const COLLEG := ' + js(coll) + '\n')
    f.write('const CONQ := ' + js(conq) + '\n')
    f.write('const VANT_POS := ' + js(vant_pos) + '\n')
    f.write('const PREMI_POS := ' + js(premi_pos) + '\n')
    f.write('const INVEST := [\n' + ',\n'.join('\t' + js(t) for t in inv) + '\n]\n')
    f.write('const G_BASE := ' + js(base) + '\n')
    f.write('const G_BONUS := {\n' + ',\n'.join('\t%s: %s' % (js(k), js(v)) for k, v in bonus.items()) + '\n}\n')
print('spazi', len(spazi), 'colleg', len(coll), 'conq', len(conq), 'vant', len(vant_pos), premi_pos)
print('mancanti', len(MANCANTI), MANCANTI[:8])
