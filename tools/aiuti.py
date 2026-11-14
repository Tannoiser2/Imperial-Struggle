#!/usr/bin/env python3
"""Prepara le plance dei giocatori e il player aid italiano dai PDF della cartella del gioco.
Uso: python3 -I tools/aiuti.py <cartella con i PDF> <cartella del progetto>   (serve pdftoppm)"""
import os, subprocess, sys, tempfile
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import plance
SRC, PRJ = sys.argv[1], sys.argv[2]
os.makedirs(PRJ + '/assets/aiuti', exist_ok=True)
tmp = tempfile.mkdtemp()
def pagine(pdf, dpi):
    base = os.path.join(tmp, 'p')
    for f in os.listdir(tmp):
        os.remove(os.path.join(tmp, f))
    subprocess.run(['pdftoppm', '-r', str(dpi), '-png', os.path.join(SRC, pdf), base], check=True)
    return [Image.open(os.path.join(tmp, f)).convert('RGB') for f in sorted(os.listdir(tmp))]
for lato, pdf in (('BR', 'Imperial_Struggle_-_British_Player_Mat.pdf'), ('FR', 'Imperial_Struggle_-_French_Player_Mat.pdf')):
    im = pagine(pdf, 150)[0]          # 1650 x 1275: le coordinate in scripts/plancia_giocatore.gd sono in questa scala
    plance.traduci(im, lato).save(PRJ + '/assets/aiuti/plancia_%s.jpg' % lato, quality=90)
for i, im in enumerate(pagine('ImperialStruggleItalianPlayerAid.pdf', 140)):
    im.save(PRJ + '/assets/aiuti/aiuto_%d.jpg' % (i + 1), quality=88)
print(sorted(os.listdir(PRJ + '/assets/aiuti')))
