#!/usr/bin/env python3
"""Dessine en code le jeu de tuiles HD provisoire de la carte (placeholder).

    python3 tools/generer_tuiles_hd.py

Produit :
    assets/tilesets/placeholder_tuiles_hd.png   atlas de tuiles 64 x 64 (4x)
    assets/tilesets/placeholder_tuiles_hd.tres  TileSet Godot (tile_size 64)

Les couches de la carte affichent ces tuiles a scale 0.25 : elles font 16 px dans
le monde, comme les tuiles de l'equipe, avec 4x plus de detail (rendu canvas_items).
C'est un PLACEHOLDER au sens de CLAUDE.MD : les tuiles definitives restent a faire
par l'equipe. La table de correspondance caractere -> tuile est dans zones.gd.

Dependances : Pillow, numpy.
"""
import os

import numpy as np
from PIL import Image

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
T = 64                 # cote d'une tuile, en pixels de texture
COLONNES = 8
SORTIE_PNG = "assets/tilesets/placeholder_tuiles_hd.png"
SORTIE_TRES = "assets/tilesets/placeholder_tuiles_hd.tres"

rng = np.random.default_rng(20261118)


# =============================================================================
# Outils de dessin (images RGBA en float 0..255)
# =============================================================================
def vide(h=T, w=T):
    return np.zeros((h, w, 4), float)


def couleur(hexa, a=255):
    hexa = hexa.lstrip("#")
    return np.array([int(hexa[i:i + 2], 16) for i in (0, 2, 4)] + [a], float)


def aplat(c, h=T, w=T):
    im = vide(h, w)
    im[:] = couleur(c)
    return im


def bruit(h, w, echelle=1, amplitude=10.0):
    """Bruit de valeur lisse et raccordable (se repete sur la tuile)."""
    gh, gw = max(1, h // echelle), max(1, w // echelle)
    g = rng.normal(0, 1, (gh, gw))
    ys = np.arange(h) / echelle
    xs = np.arange(w) / echelle
    y0 = np.floor(ys).astype(int) % gh
    x0 = np.floor(xs).astype(int) % gw
    y1, x1 = (y0 + 1) % gh, (x0 + 1) % gw
    fy = (ys - np.floor(ys))[:, None]
    fx = (xs - np.floor(xs))[None, :]
    fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
    v = (g[y0][:, x0] * (1 - fx) + g[y0][:, x1] * fx) * (1 - fy) + \
        (g[y1][:, x0] * (1 - fx) + g[y1][:, x1] * fx) * fy
    return v * amplitude


def texture(im, *couches):
    """Ajoute des bruits (echelle, amplitude) a la luminosite."""
    h, w = im.shape[:2]
    total = sum(bruit(h, w, e, a) for e, a in couches)
    im[..., :3] = np.clip(im[..., :3] + total[..., None], 0, 255)
    return im


def rect(im, x, y, w, h, c, enrouler=False):
    c = couleur(c) if isinstance(c, str) else c
    H, W = im.shape[:2]
    if enrouler:
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                im[yy % H, xx % W] = c
    else:
        im[max(0, y):min(H, y + h), max(0, x):min(W, x + w)] = c


def ombrer(im, x, y, w, h, clair, fonce, enrouler=False):
    """Bord haut/gauche eclaire, bas/droite assombri (lumiere d'en haut a gauche)."""
    H, W = im.shape[:2]

    def px(xx, yy, d):
        if enrouler:
            xx, yy = xx % W, yy % H
        elif not (0 <= xx < W and 0 <= yy < H):
            return
        im[yy, xx, :3] = np.clip(im[yy, xx, :3] + d, 0, 255)
    for xx in range(x, x + w):
        px(xx, y, clair)
        px(xx, y + h - 1, -fonce)
    for yy in range(y, y + h):
        px(x, yy, clair * 0.6)
        px(x + w - 1, yy, -fonce * 0.8)


def disque(im, cx, cy, rx, ry, c, lumiere=0.0):
    """Ellipse pleine, eclairee d'en haut a gauche si lumiere > 0."""
    c = couleur(c) if isinstance(c, str) else c
    H, W = im.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    dx, dy = (xx - cx) / rx, (yy - cy) / ry
    m = dx * dx + dy * dy <= 1
    im[m] = c
    if lumiere:
        eclair = np.clip(-(dx + dy) * 0.5, -1, 1) * lumiere
        im[..., :3] = np.where(m[..., None], np.clip(im[..., :3] + eclair[..., None], 0, 255), im[..., :3])
    return m


def poser(fond, dessus):
    """Composite alpha de 'dessus' sur 'fond'."""
    a = dessus[..., 3:4] / 255
    fond[..., :3] = dessus[..., :3] * a + fond[..., :3] * (1 - a)
    fond[..., 3:4] = np.maximum(fond[..., 3:4], dessus[..., 3:4])
    return fond


def ombre_portee(im, cx, cy, rx, ry, force=90):
    H, W = im.shape[:2]
    yy, xx = np.mgrid[0:H, 0:W]
    d = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2
    m = d <= 1
    a = np.where(m, force * (1 - d * 0.5), 0)
    ombre = vide(H, W)
    ombre[..., 3] = a
    return poser(im, ombre)


# =============================================================================
# Sols
# =============================================================================
def paves(base, joint, l=16, h=16, decalage=8, usure=0.0, mousse=0.0):
    im = aplat(joint)
    texture(im, (2, 6))
    for r in range(T // h):
        dx = (r % 2) * decalage
        for k in range(T // l):
            x, y = k * l + dx + 1, r * h + 1
            c = couleur(base) + np.r_[rng.normal(0, 9, 1).repeat(3), 0]
            rect(im, x, y, l - 2, h - 2, c, enrouler=True)
            ombrer(im, x, y, l - 2, h - 2, 26, 30, enrouler=True)
            # coins arrondis
            # coins arrondis : pave bombe, pas brique
            for cx_, cy_ in [(x, y), (x + l - 3, y), (x, y + h - 3), (x + l - 3, y + h - 3),
                             (x + 1, y), (x, y + 1), (x + l - 4, y), (x + l - 3, y + 1),
                             (x, y + h - 4), (x + 1, y + h - 3), (x + l - 3, y + h - 4), (x + l - 4, y + h - 3)]:
                im[cy_ % T, cx_ % T, :3] = couleur(joint)[:3]
            # bombe : centre plus clair
            for yy in range(y + 3, y + h - 5):
                for xx in range(x + 3, x + l - 5):
                    im[yy % T, xx % T, :3] += 6
    texture(im, (1, 5 + usure * 8), (4, 4))
    if mousse:
        verts = bruit(T, T, 4, 1.0) > 0.6 - mousse
        joints = np.all(np.abs(im[..., :3] - couleur(joint)[:3]) < 40, axis=-1)
        m = verts & joints
        im[m, :3] = couleur("#5f7a34")[:3] + rng.normal(0, 12, (m.sum(), 1))
    return im


def dalles(base, joint, n=2, fissures=3):
    im = aplat(joint)
    s = T // n
    for r in range(n):
        for k in range(n):
            c = couleur(base) + np.r_[rng.normal(0, 7, 1).repeat(3), 0]
            rect(im, k * s + 1, r * s + 1, s - 2, s - 2, c)
            ombrer(im, k * s + 1, r * s + 1, s - 2, s - 2, 20, 26)
    texture(im, (1, 5), (6, 6))
    for _ in range(fissures):
        x, y = rng.integers(4, T - 4, 2)
        for _ in range(rng.integers(5, 12)):
            im[y % T, x % T, :3] -= 35
            x += rng.integers(-1, 2)
            y += 1
    return im


def terre(base="#8a6a45"):
    im = aplat(base)
    texture(im, (1, 8), (5, 10), (12, 8))
    for _ in range(18):
        x, y = rng.integers(0, T, 2)
        r = rng.integers(1, 3)
        disque(im, x, y, r + 0.5, r * 0.7 + 0.5, couleur("#a8987e") + np.r_[rng.normal(0, 15, 3), 0], 25)
    return im


def herbe(base="#5d9a3c", brins=260, longueur=(2, 5), sombre="#3f7428", clair="#8fc45a"):
    im = aplat(base)
    texture(im, (1, 6), (6, 10))
    for _ in range(brins):
        x, y = rng.integers(0, T, 2)
        lg = rng.integers(*longueur)
        c = couleur(sombre if rng.random() < 0.55 else clair)
        for i in range(lg):
            im[(y - i) % T, (x + (i // 3) * rng.integers(-1, 2)) % T, :3] = c[:3] + rng.normal(0, 6, 3)
    return im


def eau(variante=0):
    im = aplat("#2f6f9f")
    texture(im, (1, 4), (8, 14), (16, 10))
    yy = np.arange(T)[:, None]
    im[..., 2] = np.clip(im[..., 2] + 10 * np.sin(yy / T * 2 * np.pi), 0, 255)
    for _ in range(9):
        x, y = rng.integers(0, T, 2)
        lg = rng.integers(6, 14)
        for i in range(lg):
            im[(y + variante * 3) % T, (x + i) % T, :3] = couleur("#9fd0ee")[:3] if i not in (0, lg - 1) else couleur("#5f9ccb")[:3]
            im[(y + variante * 3 + 1) % T, (x + i) % T, :3] -= 18
    return im


def sable():
    im = aplat("#d8c48e")
    texture(im, (1, 7), (6, 8))
    for _ in range(120):
        x, y = rng.integers(0, T, 2)
        im[y, x, :3] += rng.choice([-40, 30])
    return np.clip(im, 0, 255)


def ponton():
    im = aplat("#3d2a1a")
    for r in range(T // 8):
        c = couleur("#9a6b3e") + np.r_[rng.normal(0, 10, 1).repeat(3), 0]
        rect(im, 0, r * 8 + 1, T, 6, c)
        for _ in range(4):
            x = rng.integers(0, T)
            lg = rng.integers(8, 24)
            for i in range(lg):
                im[r * 8 + 1 + rng.integers(1, 5), (x + i) % T, :3] -= 18
        ombrer(im, 0, r * 8 + 1, T, 6, 20, 24)
        for x in (4, T - 5):
            im[r * 8 + 3, x, :3] = couleur("#c8c8c8")[:3]
    return im


def ballast():
    im = aplat("#6b6660")
    texture(im, (1, 10))
    for _ in range(110):
        x, y = rng.integers(0, T, 2)
        c = couleur("#8a857d") + np.r_[rng.normal(0, 18, 1).repeat(3), 0]
        disque(im, x, y, 1.6, 1.2, c, 30)
    return im


def rails(fond=None):
    im = ballast() if fond is None else fond
    for k in range(4):
        y = k * 16 + 4
        rect(im, 6, y, T - 12, 7, couleur("#6e4a2c"))
        ombrer(im, 6, y, T - 12, 7, 22, 28)
        texture_rangee = bruit(7, T - 12, 2, 8)
        im[y:y + 7, 6:T - 6, :3] += texture_rangee[..., None]
    for x in (18, 42):
        rect(im, x, 0, 4, T, couleur("#7c7f86"))
        rect(im, x, 0, 1, T, couleur("#d6d9de"))
        rect(im, x + 3, 0, 1, T, couleur("#45474c"))
    return np.clip(im, 0, 255)


def passage_niveau():
    im = aplat("#4a4a4e")
    texture(im, (1, 6), (5, 6))
    for k in range(T // 16):
        rect(im, 0, k * 16, T, 1, couleur("#3a3a3e"))
    for x in (18, 42):
        rect(im, x - 1, 0, 6, T, couleur("#2c2c30"))
        rect(im, x, 0, 4, T, couleur("#9a9da4"))
        rect(im, x, 0, 1, T, couleur("#e0e2e6"))
    for y in (2, T - 6):
        for k in range(0, T, 12):
            rect(im, k, y, 7, 4, couleur("#e8e2cf"))
    return im


def sortie():
    im = dalles("#bdb6a6", "#7d776b", n=1, fissures=0)
    for i in range(10):
        for d in (-1, 0, 1):
            for j in range(2):
                y = 18 + i + j * 14
                im[y, 32 - 10 + i + d, :3] = couleur("#e9c56a")[:3]
                im[y, 32 + 10 - i + d, :3] = couleur("#e9c56a")[:3]
    return im


def rails_tram(horizontal=False):
    """Rails de tram noyes dans le pave : on marche dessus."""
    im = paves("#9b9182", "#5c564d")
    for x in (18, 42):
        rect(im, x - 1, 0, 6, T, couleur("#4b4740"))      # gorge du rail
        rect(im, x, 0, 4, T, couleur("#8d9097"))
        rect(im, x, 0, 1, T, couleur("#dfe2e7"))
        rect(im, x + 3, 0, 1, T, couleur("#3b3d42"))
    return np.rot90(im).copy() if horizontal else im


def tramway():
    """Rame vue de dessus en 3/4, orientee vers le bas : 1 case de large, 3 de long."""
    L, W = T * 3, T
    im = vide(L, W)
    ombre_portee(im, W / 2, L / 2 + 6, W / 2 - 2, L / 2 - 4, 70)
    rect(im, 4, 6, W - 8, L - 12, couleur("#f2f2ef"))          # caisse blanche
    ombrer(im, 4, 6, W - 8, L - 12, 12, 40)
    rect(im, 14, 10, W - 28, L - 20, couleur("#c9ccd1"))       # toit gris
    for k in range(3):                                          # equipements de toit
        rect(im, 22, 30 + k * 56, W - 44, 18, couleur("#9aa0a8"))
    for y in range(16, L - 24, 14):                             # vitres sur les flancs
        rect(im, 5, y, 6, 10, couleur("#2e3d4f"))
        rect(im, W - 11, y, 6, 10, couleur("#2e3d4f"))
    rect(im, 8, L - 16, W - 16, 8, couleur("#2e3d4f"))         # pare-brise avant
    rect(im, 8, 8, W - 16, 6, couleur("#2e3d4f"))              # vitre arriere
    for x in (10, W - 14):                                      # phares
        rect(im, x, L - 8, 4, 2, couleur("#fff3c4"))
    rect(im, 4, L // 3, W - 8, 2, couleur("#b5121b"))          # liseres d'intercirculation
    rect(im, 4, 2 * L // 3, W - 8, 2, couleur("#b5121b"))
    return np.clip(im, 0, 255)


# =============================================================================
# Batiments (facade : rang du bas ; toit : le reste ; haut : bord superieur)
# =============================================================================
OCRE = "#d4a24c"


def mur(base=OCRE):
    im = aplat(base)
    texture(im, (1, 5), (4, 7), (12, 6))
    rect(im, 0, T - 8, T, 8, couleur("#8c8476"))        # soubassement en pierre
    texture_bas = bruit(8, T, 2, 9)
    im[T - 8:, :, :3] += texture_bas[..., None]
    rect(im, 0, T - 9, T, 1, couleur("#6b6458"))
    rect(im, 0, 0, T, 3, couleur("#e8c98a"))              # corniche
    rect(im, 0, 3, T, 1, couleur("#9a7434"))
    return np.clip(im, 0, 255)


def fenetre(im, x, y, w=14, h=26, volets="#4f6b5a"):
    rect(im, x - 2, y - 2, w + 4, h + 4, couleur("#ece0c4"))   # encadrement
    rect(im, x, y, w, h, couleur("#2e3d4f"))
    for k in range(h):                                          # reflet
        g = int(40 * (1 - k / h))
        im[y + k, x + 1:x + 4, :3] += g
    rect(im, x + w // 2, y, 1, h, couleur("#d9d2c2"))
    rect(im, x, y + h // 2, w, 1, couleur("#d9d2c2"))
    rect(im, x - 7, y, 5, h, couleur(volets))
    rect(im, x + w + 2, y, 5, h, couleur(volets))
    for k in range(y + 2, y + h, 3):
        im[k, x - 7:x - 2, :3] -= 20
        im[k, x + w + 2:x + w + 7, :3] -= 20
    rect(im, x - 3, y + h + 2, w + 6, 2, couleur("#b9ad95"))   # appui


def facade(genre, cote=None):
    im = mur()
    if genre == "fenetres":
        fenetre(im, 12, 14)
        fenetre(im, 40, 14)
    elif genre == "fenetre":
        fenetre(im, 25, 14)
    elif genre == "porte":
        rect(im, 20, 16, 24, T - 24, couleur("#cfc4ad"))
        rect(im, 23, 19, 18, T - 27, couleur("#5a3520"))
        for k in range(23, 41, 6):
            rect(im, k, 22, 1, T - 33, couleur("#43261a"))
        rect(im, 37, 38, 2, 2, couleur("#d8b65a"))
    elif genre == "vitrine":
        rect(im, 6, 26, 52, 28, couleur("#cfc4ad"))
        rect(im, 9, 29, 46, 24, couleur("#34485e"))
        for k in range(24):
            im[29 + k, 10:14, :3] += 30 * (1 - k / 24)
        for k in range(0, 52, 8):                              # store raye
            rect(im, 6 + k, 14, 4, 10, couleur("#c0392b"))
            rect(im, 10 + k, 14, 4, 10, couleur("#f1e9da"))
        rect(im, 6, 24, 52, 2, couleur("#7d2a20"))
    if cote == "gauche":
        rect(im, 0, 0, 4, T, couleur("#e3c287"))
        for k in range(0, T - 8, 8):
            rect(im, 0, k, 6 if (k // 8) % 2 else 4, 7, couleur("#efd8a8"))
        im[:, 0, :3] -= 30
    if cote == "droite":
        rect(im, T - 4, 0, 4, T, couleur("#b3863a"))
        im[:, T - 1, :3] -= 40
    return np.clip(im, 0, 255)


def toit(cote=None, haut=False):
    """Tuiles canal en terre cuite, vues de dessus en 3/4."""
    im = aplat("#7a2e1d")
    for r in range(T // 8):
        for k in range(T // 8):
            x, y = k * 8 + (r % 2) * 4, r * 8
            c = couleur("#b5482b") + np.r_[rng.normal(0, 10, 1).repeat(3), 0]
            for dx in range(8):
                prof = np.sin((dx + 0.5) / 8 * np.pi)          # tuile bombee
                col = c[:3] + (prof - 0.6) * 60
                for dy in range(7):
                    im[(y + dy) % T, (x + dx) % T, :3] = col - dy * 3
    texture(im, (1, 4))
    if haut:                     # faitage : le haut de la case est vide
        im[:T // 2, :, 3] = 0
        rect(im, 0, T // 2, T, 5, couleur("#8a3a24"))
        rect(im, 0, T // 2, T, 1, couleur("#d97a55"))
    if cote == "gauche":
        rect(im, 0, T // 2 if haut else 0, 3, T, couleur("#5e2416"))
    if cote == "droite":
        rect(im, T - 3, T // 2 if haut else 0, 3, T, couleur("#4e1d12"))
    return np.clip(im, 0, 255)


# =============================================================================
# Objets (certains font deux cases de haut : on les coupe en bas / haut)
# =============================================================================
def arbre():
    im = vide(T * 2, T)
    ombre_portee(im, 32, T * 2 - 8, 22, 7)
    rect(im, 27, T + 14, 10, T - 22, couleur("#6a4a2e"))      # tronc
    im[T + 14:T * 2 - 8, 27:30, :3] += 25
    im[T + 14:T * 2 - 8, 34:37, :3] -= 25
    for cx, cy, r, c in [(32, 62, 30, "#2f6b2a"), (20, 52, 18, "#3c7f33"), (44, 50, 18, "#3c7f33"),
                         (30, 38, 20, "#4b9440"), (36, 70, 22, "#336f2d")]:
        disque(im, cx, cy, r, r * 0.9, c, 40)
    for _ in range(140):                                       # feuilles
        x, y = rng.integers(4, 60), rng.integers(14, 88)
        if im[y, x, 3] > 0:
            im[y, x, :3] += rng.choice([-35, 30])
    return np.clip(im, 0, 255)


def buisson():
    im = vide()
    ombre_portee(im, 32, 52, 22, 6)
    for cx, cy, r in [(32, 40, 20), (20, 44, 13), (44, 44, 13), (32, 30, 13)]:
        disque(im, cx, cy, r, r * 0.85, "#3b7d31", 45)
    for _ in range(70):
        x, y = rng.integers(8, 56), rng.integers(16, 58)
        if im[y, x, 3] > 0:
            im[y, x, :3] += rng.choice([-30, 28])
    return np.clip(im, 0, 255)


def lampadaire():
    im = vide(T * 2, T)
    ombre_portee(im, 32, T * 2 - 7, 9, 3)
    rect(im, 28, T * 2 - 12, 8, 6, couleur("#2d3238"))
    rect(im, 30, 30, 4, T * 2 - 42, couleur("#3a4048"))
    rect(im, 30, 30, 1, T * 2 - 42, couleur("#6a7480"))
    rect(im, 24, 14, 16, 18, couleur("#2d3238"))               # lanterne
    rect(im, 26, 16, 12, 14, couleur("#f4d27a"))
    rect(im, 27, 17, 4, 12, couleur("#fff3c4"))
    rect(im, 22, 10, 20, 4, couleur("#22262b"))
    return im


def banc():
    im = vide()
    ombre_portee(im, 32, 50, 24, 5)
    rect(im, 10, 22, 44, 5, couleur("#8c5a32"))
    rect(im, 10, 29, 44, 5, couleur("#8c5a32"))
    rect(im, 10, 36, 44, 6, couleur("#a06a3c"))
    for x in (13, 47):
        rect(im, x, 26, 4, 22, couleur("#2b2e33"))
    for y in (22, 29, 36):
        rect(im, 10, y, 44, 1, couleur("#c08a5a"))
    return im


def soin():
    im = vide()
    ombre_portee(im, 32, 54, 18, 5)
    rect(im, 30, 30, 4, 24, couleur("#3a4048"))
    rect(im, 14, 6, 36, 28, couleur("#f2f2f2"))
    ombrer(im, 14, 6, 36, 28, 10, 40)
    rect(im, 28, 10, 8, 20, couleur("#2fa84f"))
    rect(im, 22, 16, 20, 8, couleur("#2fa84f"))
    return im


def boutique():
    im = vide()
    ombre_portee(im, 32, 56, 26, 5)
    rect(im, 8, 30, 48, 22, couleur("#8a5a34"))
    ombrer(im, 8, 30, 48, 22, 20, 30)
    for k, c in [(14, "#e8c06a"), (24, "#c0392b"), (34, "#7fb35a"), (44, "#e8c06a")]:
        disque(im, k + 3, 31, 4, 3, c, 30)
    for k in range(0, 52, 8):
        rect(im, 6 + k, 12, 4, 12, couleur("#2e86c1"))
        rect(im, 10 + k, 12, 4, 12, couleur("#f4f1ea"))
    for x in (8, 54):
        rect(im, x, 12, 2, 40, couleur("#5a3a22"))
    return im


def borne():
    im = vide()
    ombre_portee(im, 32, 56, 16, 5)
    rect(im, 18, 12, 28, 42, couleur("#3b3f6e"))
    ombrer(im, 18, 12, 28, 42, 30, 40)
    rect(im, 22, 16, 20, 14, couleur("#61e0a8"))
    rect(im, 23, 17, 6, 12, couleur("#b8f5d8"))
    for k, c in [(24, "#e74c3c"), (32, "#f1c40f"), (40, "#3498db")]:
        disque(im, k, 38, 2.5, 2.5, c, 20)
    return im


def passage_sous_voies():
    im = vide()
    rect(im, 8, 12, 48, 46, couleur("#9a9184"))
    ombrer(im, 8, 12, 48, 46, 25, 40)
    rect(im, 14, 18, 36, 36, couleur("#16181c"))
    for k in range(5):
        rect(im, 14, 20 + k * 7, 36, 2, couleur("#5a5650"))
    for x in (12, 50):
        rect(im, x, 8, 2, 46, couleur("#3a3f45"))
    rect(im, 12, 8, 40, 2, couleur("#3a3f45"))
    return im


def gardien():
    im = vide()
    ombre_portee(im, 32, 56, 22, 6)
    rect(im, 12, 34, 40, 20, couleur("#8f8a80"))
    ombrer(im, 12, 34, 40, 20, 25, 40)
    disque(im, 32, 24, 13, 13, "#c9a227", 50)
    disque(im, 32, 24, 7, 7, "#7a5c10", 0)
    return im


def ressource(genre):
    im = vide()
    ombre_portee(im, 32, 46, 14, 4)
    if genre == "praline":
        for cx, cy in [(26, 40), (36, 41), (31, 34), (40, 35), (22, 34)]:
            disque(im, cx, cy, 6, 5, "#d64f8a", 60)
    elif genre == "cocon":
        disque(im, 32, 36, 10, 14, "#f3eee2", 50)
        for k in range(-10, 12, 4):
            im[36 + k // 2, 24:40, :3] -= 18
    else:
        rect(im, 16, 40, 32, 5, couleur("#f4f4f4"))
        disque(im, 32, 36, 12, 6, "#e3c58f", 50)
    return np.clip(im, 0, 255)


# =============================================================================
# Assemblage de l'atlas
# =============================================================================
def haut_et_bas(grand):
    return grand[:T], grand[T:]


def construire():
    t_arbre_h, t_arbre_b = haut_et_bas(arbre())
    t_lamp_h, t_lamp_b = haut_et_bas(lampadaire())
    tuiles = [
        # nom, image, origine du tri en profondeur (None = sol)
        ("pave_0", paves("#a39a8b", "#5c564d"), None),
        ("pave_1", paves("#a39a8b", "#5c564d"), None),
        ("pave_2", paves("#9b9182", "#5c564d"), None),
        ("pave_use_0", paves("#b5ad9f", "#77705f", l=16, h=16, decalage=0, usure=1), None),
        ("pave_use_1", paves("#b5ad9f", "#77705f", l=16, h=16, decalage=0, usure=1), None),
        ("pave_mousse", paves("#9a9384", "#5c564d", mousse=0.5), None),
        ("quai_0", dalles("#c9c1ae", "#8a8272"), None),
        ("quai_1", dalles("#c4bba7", "#8a8272", fissures=6), None),
        ("terre_0", terre(), None),
        ("terre_1", terre("#80613f"), None),
        ("herbe_0", herbe(), None),
        ("herbe_1", herbe(base="#619e3f"), None),
        ("herbe_haute", herbe(base="#3f7a2b", brins=520, longueur=(5, 11), sombre="#2a5a1d", clair="#7cb84c"), None),
        ("eau_0", eau(0), None),
        ("eau_1", eau(1), None),
        ("eau_2", eau(2), None),
        ("sable", sable(), None),
        ("ponton", ponton(), None),
        ("ballast_0", ballast(), None),
        ("ballast_1", ballast(), None),
        ("rails", rails(), None),
        ("passage_niveau", passage_niveau(), None),
        ("sortie", sortie(), None),
        ("dalle_place", dalles("#bdb6a6", "#7d776b", n=4, fissures=1), None),
        # --- batiments (decor, tries en profondeur au pied de la case)
        ("facade_fenetres", facade("fenetres"), T),
        ("facade_fenetre", facade("fenetre"), T),
        ("facade_porte", facade("porte"), T),
        ("facade_vitrine", facade("vitrine"), T),
        ("facade_gauche", facade("fenetre", "gauche"), T),
        ("facade_droite", facade("fenetre", "droite"), T),
        ("mur_plein", mur(), T),
        ("vide_0", vide(), None),
        ("toit", toit(), T),
        ("toit_gauche", toit("gauche"), T),
        ("toit_droite", toit("droite"), T),
        ("toit_haut", toit(haut=True), T * 2),
        ("toit_haut_gauche", toit("gauche", haut=True), T * 2),
        ("toit_haut_droite", toit("droite", haut=True), T * 2),
        ("vide_1", vide(), None),
        ("vide_2", vide(), None),
        # --- objets
        ("arbre_bas", t_arbre_b, T),
        ("arbre_haut", t_arbre_h, T * 2),
        ("buisson", buisson(), T),
        ("lampadaire_bas", t_lamp_b, T),
        ("lampadaire_haut", t_lamp_h, T * 2),
        ("banc", banc(), T),
        ("soin", soin(), T),
        ("boutique", boutique(), T),
        ("borne", borne(), T),
        ("passage_sous_voies", passage_sous_voies(), T),
        ("gardien", gardien(), T),
        ("praline", ressource("praline"), T),
        ("cocon", ressource("cocon"), T),
        ("quenelle", ressource("quenelle"), T),
        ("tram_v", rails_tram(), None),
        ("tram_h", rails_tram(horizontal=True), None),
        ("rails_h", np.rot90(rails()).copy(), None),
        ("passage_niveau_h", np.rot90(passage_niveau()).copy(), None),
    ]
    lignes = (len(tuiles) + COLONNES - 1) // COLONNES
    atlas = np.zeros((lignes * T, COLONNES * T, 4), float)
    index = {}
    for i, (nom, im, origine) in enumerate(tuiles):
        c, r = i % COLONNES, i // COLONNES
        atlas[r * T:(r + 1) * T, c * T:(c + 1) * T] = np.clip(im, 0, 255)
        index[nom] = (c, r, origine)
    return atlas.astype(np.uint8), index


def ecrire_tres(index):
    l = ['[gd_resource type="TileSet" load_steps=3 format=3]', "",
         '[ext_resource type="Texture2D" path="res://%s" id="1_tex"]' % SORTIE_PNG, "",
         '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_hd"]',
         'texture = ExtResource("1_tex")',
         "texture_region_size = Vector2i(%d, %d)" % (T, T)]
    for nom, (c, r, origine) in index.items():
        if nom.startswith("vide"):
            continue
        l.append("%d:%d/0 = 0" % (c, r))
        if origine is not None:
            # Origine du tri : le pied de l'objet, au bas de la case (ou de la case
            # du dessous pour les parties hautes). Valeur en pixels de texture.
            l.append("%d:%d/0/y_sort_origin = %d" % (c, r, origine))
    l += ["", "[resource]", "tile_size = Vector2i(%d, %d)" % (T, T),
          'sources/0 = SubResource("TileSetAtlasSource_hd")', ""]
    with open(os.path.join(RACINE, SORTIE_TRES), "w") as f:
        f.write("\n".join(l))


def main():
    atlas, index = construire()
    Image.fromarray(atlas).save(os.path.join(RACINE, SORTIE_PNG))
    # Le tramway n'est pas une tuile : c'est l'image du vehicule (scenes/world/tram.tscn).
    Image.fromarray(tramway().astype(np.uint8)).save(os.path.join(RACINE, "assets/sprites/placeholder_tram.png"))
    ecrire_tres(index)
    print("Atlas %dx%d, %d tuiles" % (atlas.shape[1], atlas.shape[0], len(index)))
    for nom, (c, r, _) in index.items():
        print("  %-20s Vector2i(%d, %d)" % (nom, c, r))


if __name__ == "__main__":
    main()
