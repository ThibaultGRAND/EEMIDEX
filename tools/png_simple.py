#!/usr/bin/env python3
"""Lecture et ecriture de PNG, sans aucune dependance.

Suffisant pour ce projet : profondeur 8 bits, couleurs indexees ou non.
Sert a generer les placeholders et a importer les planches de tuiles.
"""
import os
import struct
import zlib

VIDE = (0, 0, 0, 0)


class Image:
    def __init__(self, largeur=0, hauteur=0, pixels=None):
        self.l = largeur
        self.h = hauteur
        self.px = pixels if pixels is not None else [[VIDE] * largeur for _ in range(hauteur)]

    # --- ecriture -----------------------------------------------------------
    def point(self, x, y, couleur):
        if 0 <= x < self.l and 0 <= y < self.h:
            self.px[y][x] = couleur

    def lire(self, x, y):
        if 0 <= x < self.l and 0 <= y < self.h:
            return self.px[y][x]
        return VIDE

    def rect(self, x, y, l, h, couleur):
        for j in range(y, y + h):
            for i in range(x, x + l):
                self.point(i, j, couleur)

    def coller(self, autre, ox, oy):
        for y in range(autre.h):
            for x in range(autre.l):
                self.point(ox + x, oy + y, autre.px[y][x])

    def decouper(self, x, y, l, h):
        out = Image(l, h)
        for j in range(h):
            for i in range(l):
                out.px[j][i] = self.lire(x + i, y + j)
        return out

    def ecrire(self, chemin):
        brut = b""
        for ligne in self.px:
            brut += b"\x00" + b"".join(struct.pack("BBBB", *p) for p in ligne)

        def morceau(typ, donnees):
            return (struct.pack(">I", len(donnees)) + typ + donnees
                    + struct.pack(">I", zlib.crc32(typ + donnees) & 0xffffffff))

        png = b"\x89PNG\r\n\x1a\n"
        png += morceau(b"IHDR", struct.pack(">IIBBBBB", self.l, self.h, 8, 6, 0, 0, 0))
        png += morceau(b"IDAT", zlib.compress(brut, 9))
        png += morceau(b"IEND", b"")
        dossier = os.path.dirname(chemin)
        if dossier:
            os.makedirs(dossier, exist_ok=True)
        with open(chemin, "wb") as f:
            f.write(png)


# =============================================================================
# Lecture
# =============================================================================
CANAUX = {0: 1, 2: 3, 3: 1, 4: 2, 6: 4}


def lire_png(chemin):
    with open(chemin, "rb") as f:
        donnees = f.read()
    if donnees[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("%s n'est pas un PNG" % chemin)

    pos = 8
    idat = b""
    palette = []
    transparence = []
    largeur = hauteur = profondeur = type_couleur = 0
    while pos < len(donnees):
        taille = struct.unpack(">I", donnees[pos:pos + 4])[0]
        typ = donnees[pos + 4:pos + 8]
        corps = donnees[pos + 8:pos + 8 + taille]
        pos += 12 + taille
        if typ == b"IHDR":
            largeur, hauteur, profondeur, type_couleur = struct.unpack(">IIBB", corps[:10])
        elif typ == b"PLTE":
            palette = [tuple(corps[i:i + 3]) for i in range(0, len(corps), 3)]
        elif typ == b"tRNS":
            transparence = list(corps)
        elif typ == b"IDAT":
            idat += corps
        elif typ == b"IEND":
            break

    if profondeur != 8:
        raise ValueError("%s : profondeur %d bits non geree (8 attendue)" % (chemin, profondeur))
    if type_couleur not in CANAUX:
        raise ValueError("%s : type de couleur %d non gere" % (chemin, type_couleur))

    canaux = CANAUX[type_couleur]
    brut = zlib.decompress(idat)
    par_ligne = largeur * canaux
    lignes = []
    precedente = bytearray(par_ligne)
    pos = 0
    for _ in range(hauteur):
        filtre = brut[pos]
        ligne = bytearray(brut[pos + 1:pos + 1 + par_ligne])
        pos += 1 + par_ligne
        _defiltrer(filtre, ligne, precedente, canaux)
        lignes.append(ligne)
        precedente = ligne

    img = Image(largeur, hauteur)
    for y, ligne in enumerate(lignes):
        for x in range(largeur):
            img.px[y][x] = _en_rgba(ligne, x, canaux, type_couleur, palette, transparence)
    return img


def _defiltrer(filtre, ligne, precedente, canaux):
    if filtre == 0:
        return
    for i in range(len(ligne)):
        a = ligne[i - canaux] if i >= canaux else 0
        b = precedente[i]
        c = precedente[i - canaux] if i >= canaux else 0
        if filtre == 1:
            ligne[i] = (ligne[i] + a) & 0xff
        elif filtre == 2:
            ligne[i] = (ligne[i] + b) & 0xff
        elif filtre == 3:
            ligne[i] = (ligne[i] + (a + b) // 2) & 0xff
        elif filtre == 4:
            p = a + b - c
            pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
            pred = a if (pa <= pb and pa <= pc) else (b if pb <= pc else c)
            ligne[i] = (ligne[i] + pred) & 0xff
        else:
            raise ValueError("filtre PNG inconnu : %d" % filtre)


def _en_rgba(ligne, x, canaux, type_couleur, palette, transparence):
    i = x * canaux
    if type_couleur == 0:
        g = ligne[i]
        return (g, g, g, 255)
    if type_couleur == 2:
        return (ligne[i], ligne[i + 1], ligne[i + 2], 255)
    if type_couleur == 3:
        index = ligne[i]
        r, v, b = palette[index]
        a = transparence[index] if index < len(transparence) else 255
        return (r, v, b, a)
    if type_couleur == 4:
        g = ligne[i]
        return (g, g, g, ligne[i + 1])
    return (ligne[i], ligne[i + 1], ligne[i + 2], ligne[i + 3])
