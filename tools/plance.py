#!/usr/bin/env python3
"""Traduce in italiano le plance dei giocatori lasciando la grafica originale: cancella ogni scritta
inglese ricostruendo lo sfondo e riscrive il testo italiano nello stesso punto.
Le coordinate sono nella scala 1650 x 1275 (PDF reso a 150 dpi)."""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter
QUI = os.path.dirname(os.path.abspath(__file__))
def F(nome, dim):
    return ImageFont.truetype(os.path.join(QUI, 'font', nome), dim)
SC, MED, GR, TIT = 'Chorus.otf', 'Poppins-Medium.ttf', 'Poppins-Bold.ttf', 'Besley.ttf'
INCH = (38, 28, 18)
BIANCO = (255, 250, 240)

# (x0, y0, x1, y1, testo, stile)   stili: e = etichetta grassa, n = nota, b = bianco su scuro,
# s = corsivo ornato bianco, m = corsivo ornato nero, t = titolo, nl/bl = allineati a sinistra
def regioni(lato):
    r = [
        (172, 26, 530, 100, 'GRAN BRETAGNA' if lato == 'BR' else 'FRANCIA', 't'),
        (552, 22, 832, 106, "GLI ACQUISTI IN PIÙ DI UNA REGIONE CON PUNTI DIPLOMATICI O ECONOMICI, NELLO STESSO ROUND, COSTANO 1 PUNTO IN PIÙ PER OGNI REGIONE OLTRE LA PRIMA", 'n'),
        (588, 148, 802, 258, 'Tessere\nGuerra Bonus', 's'),
        (70, 468, 380, 520, 'Squadre navali', 's'),
        (478, 468, 790, 520, 'Tessere Guerra Base', 's'),
        (686, 524, 780, 562, 'RIFIUTO DI UN\nTERRITORIO', 'b'),
        (686, 598, 780, 652, '2 PER GUERRA\nCOSTA 3 PV\nPOI 5 PV', 'b'),
        (90, 716, 356, 790, 'Ministero 1', 'm'),
        (500, 716, 770, 790, 'Ministero 2', 'm'),
        (52, 1180, 398, 1226, "PUOI RIVELARE UN MINISTERO SOLO\nIN UN TUO ROUND D'AZIONE", 'n'),
        (464, 1180, 810, 1226, "PUOI RIVELARE UN MINISTERO SOLO\nIN UN TUO ROUND D'AZIONE", 'n'),
        # colonna diplomatica
        (845, 274, 1036, 322, 'PESCA UNA\nCARTA EVENTO', 'e'),
        (955, 330, 1042, 350, 'CONFLITTO', 'n'),
        (845, 458, 1036, 504, 'SPOSTA UNO\nSPAZIO POLITICO', 'e'),
        (838, 520, 1044, 558, '', 'x'),
        (838, 522, 1042, 560, "I PUNTI DI UN'AZIONE MINORE VALGONO PER UN SOLO ACQUISTO", 'nl'),
        (838, 558, 978, 578, '', 'x'),
        (838, 580, 978, 603, 'AZIONI MINORI', 'nl_'),
        (838, 620, 1042, 700, "LE AZIONI MINORI NON TOLGONO BANDIERE NÉ SQUADRE NEMICHE, SALVO DOVE C'È UN CONFLITTO", 'nl'),
        (870, 720, 1012, 746, 'ICONE DI GUERRA', 'bg'),
        (848, 784, 1040, 806, '+1 DEBITO AL NEMICO', 'bl'),
        (848, 848, 1040, 886, 'DANNEGGIA UN FORTE O\nSQUADRA IN MARINA', 'bl'),
        (848, 927, 1042, 962, 'TOGLI UNA BANDIERA\n(MERCATO / POLITICO)', 'bl'),
        (858, 983, 1040, 1001, 'SCEGLIE CHI HA LA TESSERA', 'bl'),
        (858, 1003, 1040, 1056, 'UN MERCATO SCELTO NON DEVE ISOLARNE ALTRI, SE POSSIBILE', 'bl'),
        (858, 1060, 1040, 1128, 'LO SPAZIO SCELTO DEVE ESSERE NELLA REGIONE DEL TEATRO', 'bl'),
        # colonna economica
        (1070, 186, 1156, 205, 'ISOLATO', 'n'),
        (1066, 247, 1152, 266, 'CONFLITTO', 'n'),
        (1098, 267, 1286, 297, 'SPOSTA UN MERCATO', 'e'),
        (1062, 300, 1318, 528, "DEVE ESSERE COLLEGATO A UN TERRITORIO, FORTE O SPAZIO NAVALE CHE CONTROLLI\n \nOPPURE\n \nA UN ALTRO TUO MERCATO CHE\n- NON HA CONFLITTI\n- NON È ISOLATO\n- NON HA CAMBIATO CONTROLLO IN QUESTO ROUND D'AZIONE", 'n'),
        (1142, 532, 1252, 566, 'PASSA', 'e'),
        (1110, 569, 1280, 605, 'RIDUCI IL DEBITO\nFINO A -2', 'n'),
        (1064, 612, 1322, 700, "I CONFLITTI SI TOLGONO DALLA MAPPA ALLA FINE DELLE GUERRE IN CUI HANNO DATO FORZA, O QUANDO IL LORO SPAZIO CAMBIA CONTROLLO", 'n'),
        (1146, 724, 1240, 745, 'ISOLATO', 'e2'),
        (1066, 746, 1320, 882, "UN MERCATO È ISOLATO SE HA UNA BANDIERA MA NON UNA CATENA DI MERCATI AMICI SENZA CONFLITTI FINO A UN TERRITORIO, FORTE O SPAZIO NAVALE DEL PROPRIETARIO, ALL'INIZIO DI UN ROUND D'AZIONE", 'n'),
        (1100, 907, 1282, 927, 'SPAZIO PROTETTO', 'e2'),
        (1066, 927, 1318, 1002, "SPAZIO CON BANDIERA COLLEGATO A UNA SQUADRA O A UN FORTE INTEGRO DELLA STESSA PARTE", 'n'),
        (1104, 1014, 1318, 1060, 'SERVE UNA SQUADRA O UN MERCATO COLLEGATO: PRENDI IL CONTROLLO', 'nl'),
        (1104, 1063, 1320, 1095, 'SE TOGLI UNA BANDIERA A UN MERCATO PROTETTO', 'nl'),
        (1104, 1101, 1318, 1133, 'SCONTO SE RIPARI UN TUO FORTE', 'nl'),
        (848, 1132, 1300, 1150, '', 'x'),
        (846, 1142, 1468, 1250, "GLI SPAZI CON UN CONFLITTO NON VALGONO PER:\n  • COLLEGARE I MERCATI      • I VANTAGGI\n  • PREMI, PRESTIGIO E DOMANDA GLOBALE\n  • CONDIZIONI ED EFFETTI DI MINISTERI ED EVENTI\n  • PUNTEGGIO FINALE      • VALORE DELLE ALLEANZE", 'nl'),
        # colonna militare
        (1348, 148, 1410, 183, 'MAX\n2 / ROUND', 'n'),
        (1400, 251, 1568, 297, 'TESSERA\nGUERRA BONUS', 'e'),
        (1342, 305, 1403, 338, 'IN\nMARINA', 'n'),
        (1400, 394, 1568, 440, 'COSTRUISCI\nUNA SQUADRA', 'e'),
        (1338, 460, 1408, 507, 'IN UNO\nSPAZIO\nVUOTO', 'n'),
        (1338, 521, 1410, 555, 'DALLA\nMAPPA', 'n'),
        (1560, 514, 1622, 560, 'DALLA\nMARINA', 'n'),
        (1400, 561, 1568, 605, 'SCHIERA\nUNA SQUADRA', 'e'),
        (1338, 617, 1444, 637, 'RIMUOVERE', 'n'),
        (1510, 617, 1616, 637, 'PROTETTO', 'n'),
        (1370, 704, 1600, 752, 'RIMUOVI\nUN CONFLITTO', 'e'),
        (1340, 768, 1440, 801, 'RIPARA\nIL TUO', 'nl'),
        (1340, 825, 1418, 857, 'PRENDI\nIL NEMICO', 'nl'),
        (1358, 861, 1612, 911, 'COSTRUISCI /\nRIPARA UN FORTE', 'e'),
        (1356, 922, 1614, 1014, "PER COSTRUIRE UN FORTE DEVI CONTROLLARE, DALL'INIZIO DEL ROUND D'AZIONE, ALMENO UN MERCATO, SPAZIO NAVALE O TERRITORIO COLLEGATO", 'n'),
        (1360, 1040, 1612, 1076, '', 'x'),
        (1398, 1044, 1606, 1092, "I FORTI DANNEGGIATI RESTANO CONTROLLATI E IMPEDISCONO L'ISOLAMENTO", 'n'),
        (1486, 1105, 1612, 1147, 'TESSERE\nINVESTIMENTO', 'e2'),
    ]
    for riga in range(2):
        for col in range(3):
            x0 = 52 + col * 163
            y0 = 118 + riga * 163
            r.append((x0 + 6, y0 + 12, x0 + 146, y0 + 110, 'Tessera\nVantaggio', 's2'))
    return r

def scuro(im, box):
    """Vero se lo sfondo del riquadro e' scuro (testo chiaro)."""
    g = sorted(im.crop(box).convert('L').getdata())
    return g[len(g) // 2] < 120

def pulisci(im, box, chiaro, raggio):
    """Toglie il testo: massimo (testo scuro) o minimo (testo chiaro) locale, poi sfumatura."""
    e = 5
    x0, y0, x1, y1 = box[0] - e, box[1] - e, box[2] + e, box[3] + e
    m = 24
    pezzo = im.crop((x0 - m, y0 - m, x1 + m, y1 + m))
    filt = ImageFilter.MaxFilter(raggio) if chiaro else ImageFilter.MinFilter(raggio)
    pezzo = pezzo.filter(filt).filter(ImageFilter.GaussianBlur(4))
    maschera = Image.new('L', (x1 - x0, y1 - y0), 0)
    ImageDraw.Draw(maschera).rectangle((4, 4, x1 - x0 - 5, y1 - y0 - 5), fill=255)
    maschera = maschera.filter(ImageFilter.GaussianBlur(3))
    im.paste(pezzo.crop((m, m, m + x1 - x0, m + y1 - y0)), (x0, y0), maschera)

def righe_di(dr, testo, font, largh):
    out = []
    for par in testo.split('\n'):
        riga = ''
        for p in par.split(' '):
            prova = (riga + ' ' + p) if riga else p
            if dr.textlength(prova, font=font) <= largh or not riga:
                riga = prova
            else:
                out.append(riga); riga = p
        out.append(riga)
    return out

def scrivi(im, box, testo, nome_font, dim_max, colore, centro=True, ombra=None, sottolinea=False, inter=1.12, dim_min=9):
    dr = ImageDraw.Draw(im)
    x0, y0, x1, y1 = box
    for dim in range(dim_max, dim_min - 1, -1):
        f = F(nome_font, dim)
        rr = righe_di(dr, testo, f, x1 - x0)
        alt = dim * inter
        if len(rr) * alt <= (y1 - y0) + 2 and all(dr.textlength(r, font=f) <= x1 - x0 for r in rr):
            break
    y = y0 + ((y1 - y0) - len(rr) * alt) / 2 - dim * 0.12
    for r in rr:
        w = dr.textlength(r, font=f)
        x = (x0 + x1) / 2 - w / 2 if centro else x0
        if ombra:
            dr.text((x + 2, y + 2), r, font=f, fill=ombra)
        dr.text((x, y), r, font=f, fill=colore)
        if sottolinea:
            dr.line((x, y + dim * 1.25, x + w, y + dim * 1.25), fill=colore, width=2)
        y += alt

def traduci(im, lato):
    im = im.convert('RGB')
    for (x0, y0, x1, y1, testo, st) in regioni(lato):
        box = (x0, y0, x1, y1)
        if st == 'x':
            pulisci(im, box, True, 11)
        elif st == 't':
            pulisci(im, box, True, 41)
            scrivi(im, box, testo, TIT, 78, (18, 14, 10), ombra=(120, 110, 95))
        elif st in ('s', 's2'):
            sc = scuro(im, box)
            pulisci(im, box, not sc, 15)
            scrivi(im, box, testo, SC, 50 if st == 's' else 36, BIANCO if sc else (14, 10, 8), ombra=(30, 15, 10) if sc else (240, 240, 235), inter=0.98)
        elif st == 'm':
            pulisci(im, box, True, 19)
            scrivi(im, box, testo, SC, 66, (14, 10, 8), ombra=(235, 225, 205))
        elif st in ('b', 'bl', 'bg'):
            sc = scuro(im, box)
            pulisci(im, box, not sc, 11)
            scrivi(im, box, testo, GR if st == 'bg' else MED, 22 if st == 'bg' else 14, BIANCO if sc else (14, 10, 8), centro=st != 'bl')
        elif st in ('e', 'e2'):
            pulisci(im, box, True, 15)
            scrivi(im, box, testo, GR, 22 if st == 'e' else 17, (20, 14, 10))
        else:
            pulisci(im, box, True, 11)
            scrivi(im, box, testo, MED, 15, INCH, centro=st == 'n', sottolinea=st == 'nl_')
    return im

if __name__ == '__main__':
    import sys
    for lato in ('BR', 'FR'):
        traduci(Image.open(sys.argv[1] % lato), lato).save(sys.argv[2] % lato, quality=90)
