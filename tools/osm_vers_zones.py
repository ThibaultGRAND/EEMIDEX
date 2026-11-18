#!/usr/bin/env python3
"""Construit les plans des 4 zones de la Confluence depuis OpenStreetMap.

Une seule carte continue et simplifiee, de la gare de Perrache a la rue
Paul-Montrochet, de la Saone au Rhone : 16 m par case, rues principales seulement,
chaque ilot est un seul bloc plein, une seule voie ferree (les lignes principales).
La carte est tournee de 31 degres (ANGLE) pour que le quadrillage des rues tombe
droit : sinon chaque rue en biais fait des escaliers. Elle est coupee en
4 bandes horizontales collees : on passe de l'une a l'autre n'importe ou sur la
limite (Zones.ORDRE dans zones.gd), sans case de sortie.

    python3 tools/osm_vers_zones.py --apercu apercu.png     # dessine, n'ecrit rien
    python3 tools/osm_vers_zones.py --ecrire                 # met a jour zones.gd

Entree : tools/map_data/confluence_osm.json, un export Overpass (« out geom tags »)
du quartier : batiments, voirie, voies ferrees et de tram, eau, parcs, arbres.
Donnees © les contributeurs d'OpenStreetMap, licence ODbL (voir assets/maps/SOURCES.md).

Ce que fait le script :
  1. projette l'emprise, tournee de ANGLE degres (Perrache en haut, Montrochet en
     bas, la Saone a gauche, le Rhone a droite) ;
  2. dessine chaque element dans une grille de LARGEUR cases (un caractere par case,
     meme legende que zones.gd) ;
  3. relie toutes les parties praticables a la plus grande (passage a niveau, passerelle,
     passage entre deux batiments) : aucun recoin inaccessible ;
  4. coupe la grille en 4 bandes et y place les elements de jeu : soins, boutique,
     entrainement, passages sous les voies, ressources, herbe haute, et le combat
     final devant l'EEMI (au Monolithe, au nord de la darse).

Avec --ecrire, seules les cles "depart", "plan" et "sorties" de chaque zone et la
constante LARGEUR sont remplacees dans zones.gd : le reste (titres, rencontres, PNJ...)
est garde. Lancer ensuite tools/verifier_plans.py.

Dependances : Pillow, numpy.
"""
import argparse
import heapq
import json
import math
import os
import re
from collections import deque

import numpy as np
from PIL import Image, ImageDraw

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DONNEES = os.path.join(RACINE, "tools/map_data/confluence_osm.json")
## Les deux fleuves, recuperes a part : leurs contours depassent le quartier, l'export
## principal les renvoie vides. Relations OSM 7317123 (Saone) et 11696008 (Rhone).
RIVIERES = os.path.join(RACINE, "tools/map_data/confluence_rivieres.json")
ZONES_GD = os.path.join(RACINE, "scenes/world/zones.gd")

METRES = 16.0           # metres par case : carte simplifiee, pas trop grande
SUR = 4                 # sur-echantillonnage du dessin
ZONES = ["perrache", "sainte_blandine", "darse", "pointe"]

# Emprise : la presqu'ile de la gare de Perrache (cours de Verdun) a la rue
# Paul-Montrochet, de la Saone au Rhone.
LAT_NORD, LAT_SUD = 45.7512, 45.7383
LON_OUEST, LON_EST = 4.8132, 4.8285
# Les rues de la Confluence suivent un quadrillage incline de 59 degres. On tourne
# la carte de 31 degres pour l'aligner sur la grille : les ilots deviennent des
# rectangles au lieu d'escaliers. La presqu'ile se retrouve verticale (Perrache en
# haut, la Saone a gauche, le Rhone a droite).
ANGLE = 31.0
MARGE = 80.0            # metres gardes autour des quais : on voit les deux fleuves
# L'EEMI est au Monolithe, au nord de la darse. Le noeud « EEMI » d'OSM (45.7385,
# 4.8215) est une ancienne adresse : on ne s'en sert pas.
EEMI = (45.7431, 4.8182)
# La gare : le depart du jeu (le prologue commence a Perrache).
GARE = (45.7482, 4.8255)

BLOQUANTS = set("#wtvjn")

# Ce que chaque zone contenait dans la carte d'avant (a retrouver).
SPECIAUX = {
    "perrache": {"S": 1, "B": 1},
    "sainte_blandine": {"M": 1},
    "darse": {},
    "pointe": {},
}


# =============================================================================
# Projection
# =============================================================================
LAT0, LON0 = (LAT_NORD + LAT_SUD) / 2, (LON_OUEST + LON_EST) / 2
KX = math.cos(math.radians(LAT0)) * 111320.0
KY = 110540.0
_COS, _SIN = math.cos(math.radians(ANGLE)), math.sin(math.radians(ANGLE))


def tourne(lat, lon):
    """Metres dans le repere tourne : x vers la droite de l'ecran, y vers le haut."""
    x, y = (lon - LON0) * KX, (lat - LAT0) * KY
    return x * _COS - y * _SIN, x * _SIN + y * _COS


def _cadre():
    """Le cadre tourne : les quais de la Saone et du Rhone en largeur, du cours de
    Verdun a la rue Paul-Montrochet en hauteur."""
    xs, ys = [], []
    for e in json.load(open(DONNEES))["elements"]:
        nom = e.get("tags", {}).get("name", "")
        for p in e.get("geometry") or []:
            if not p or not (LAT_SUD <= p["lat"] <= LAT_NORD and LON_OUEST <= p["lon"] <= LON_EST):
                continue
            x, y = tourne(p["lat"], p["lon"])
            if nom in ("Quai Rambaud", "Quai Perrache"):
                xs.append(x)
            if nom.startswith("Cours de Verdun") or nom in ("Rue Paul Montrochet", "Passage Panama"):
                ys.append(y)
    return min(xs) - MARGE, max(xs) + MARGE, min(ys) - MARGE / 4, max(ys) + MARGE / 4


X_MIN, X_MAX, Y_MIN, Y_MAX = _cadre()
LARGEUR = int(math.ceil((X_MAX - X_MIN) / METRES))
HAUTEUR = int(math.ceil((Y_MAX - Y_MIN) / METRES))
HAUTEUR += (-HAUTEUR) % len(ZONES)


def grille(lat, lon):
    """Coordonnees (colonne, ligne) flottantes dans la grille."""
    x, y = tourne(lat, lon)
    return (x - X_MIN) / METRES, (Y_MAX - y) / METRES


# =============================================================================
# Lecture des donnees
# =============================================================================
def charger():
    elements = json.load(open(DONNEES))["elements"]
    riv = json.load(open(RIVIERES))["elements"]
    roles = {}
    for e in riv:
        if e["type"] == "relation":
            for m in e["members"]:
                roles[m["ref"]] = m["role"]
    for e in riv:
        if e["type"] == "way":
            e = dict(e)
            e["tags"] = {"natural": "water"} if roles.get(e["id"]) == "outer" else {"riviere_interieur": "yes"}
            elements.append(e)
    return elements


def points(geom):
    return [grille(g["lat"], g["lon"]) for g in geom if g]


def anneaux(e):
    """Polygones (exterieurs, interieurs) d'un way ferme ou d'une relation."""
    if e["type"] == "way":
        g = e.get("geometry")
        return ([points(g)], []) if g and len(g) > 2 else ([], [])
    ext, inte = [], []
    for m in e.get("members", []):
        g = m.get("geometry")
        if not g or len(g) < 3:
            continue
        (inte if m.get("role") == "inner" else ext).append(points(g))
    return ext, inte


class Toile:
    """Un masque booleen sur-echantillonne, ramene en cases a la fin."""

    def __init__(self):
        self.im = Image.new("L", (LARGEUR * SUR, HAUTEUR * SUR), 0)
        self.d = ImageDraw.Draw(self.im)

    def poly(self, pts, valeur=255):
        if len(pts) > 2:
            self.d.polygon([(x * SUR, y * SUR) for x, y in pts], fill=valeur)

    def ligne(self, pts, largeur_cases):
        if len(pts) > 1:
            w = max(1, int(round(largeur_cases * SUR)))
            xy = [(x * SUR, y * SUR) for x, y in pts]
            self.d.line(xy, fill=255, width=w, joint="curve")
            r = w / 2
            for x, y in xy:
                self.d.ellipse([x - r, y - r, x + r, y + r], fill=255)

    def cases(self, seuil=0.5):
        a = np.asarray(self.im, float).reshape(HAUTEUR, SUR, LARGEUR, SUR).mean(axis=(1, 3)) / 255
        return a >= seuil


# =============================================================================
# Dessin
# =============================================================================
# Carte simplifiee : seules les rues principales, en 1 case (2 pour les grands axes).
GRANDS_AXES = {"trunk", "primary", "secondary"}
RUES = GRANDS_AXES | {"tertiary", "residential", "unclassified", "living_street"}
# Un parc plus petit que ca (en cases) redevient un morceau d'ilot.
PARC_MIN = 6


def quatre_connexe(m):
    """Un trace en escalier (cases qui ne se touchent que par un coin) devient continu
    pour un deplacement en 4 directions : on bouche le coin."""
    m = m.copy()
    h, w = m.shape
    for y in range(h - 1):
        for x in range(w - 1):
            if m[y, x] and m[y + 1, x + 1] and not m[y, x + 1] and not m[y + 1, x]:
                m[y, x + 1] = True
            if m[y, x + 1] and m[y + 1, x] and not m[y, x] and not m[y + 1, x + 1]:
                m[y, x] = True
    return m


# Faisceau de Perrache : des voies paralleles, au sud de la gare seulement.
VOIES = 4               # nombre de voies
DEBUT_FAISCEAU = 9      # le faisceau commence ce nombre de lignes au-dessus de la gare
FIN_FAISCEAU = 3        # lignes laissees libres avant le bas de la premiere bande


def faisceau_perrache():
    """VOIES voies verticales paralleles, une case sur deux, centrees sur la gare :
    elles traversent le quartier de la gare et s'arretent FIN_FAISCEAU lignes avant
    le bas de la premiere bande. Nulle part ailleurs il n'y a de rails."""
    m = np.zeros((HAUTEUR, LARGEUR), bool)
    gx, gy = grille(*GARE)
    centre = int(round(gx))
    haut = max(2, int(gy) - DEBUT_FAISCEAU)
    bas = HAUTEUR // len(ZONES) - FIN_FAISCEAU
    for k in range(VOIES):
        x = centre - (VOIES - 1) + 2 * k
        m[haut:bas, x] = True
    return m


def amincir(m, epaisseur):
    """Une voie verticale garde au plus `epaisseur` cases par ligne (le milieu de
    chaque troncon) : un faisceau de voies paralleles devient une seule voie."""
    out = np.zeros_like(m)
    for y in range(m.shape[0]):
        x = 0
        while x < m.shape[1]:
            if not m[y, x]:
                x += 1
                continue
            debut = x
            while x < m.shape[1] and m[y, x]:
                x += 1
            milieu = (debut + x) // 2
            garde = max(1, min(epaisseur, x - debut))
            out[y, milieu - garde // 2: milieu - garde // 2 + garde] = True
    return quatre_connexe(out)


def dessiner(elements):
    """Une grille simple : rues principales, ilots pleins, une seule voie ferree.

    Toute la terre qui n'est ni rue, ni place, ni parc, ni eau devient du bati : chaque
    ilot entre deux rues est un seul grand batiment."""
    t = {k: Toile() for k in ["eau", "parc", "place", "grand_axe", "rue", "rail", "tram"]}
    for e in elements:
        tg = e.get("tags", {})
        if e["type"] == "node":
            continue
        sous_terre = tg.get("tunnel") in ("yes", "building_passage") or tg.get("layer", "0").startswith("-")
        ferme = e["type"] == "relation" or (e.get("geometry") and e["geometry"][0] == e["geometry"][-1])
        ext, inte = anneaux(e) if ferme else ([], [])
        geo = points(e.get("geometry", []) or [])
        if tg.get("riviere_interieur"):          # ile au milieu d'un fleuve
            for p in ext: t["eau"].poly(p, 0)
        elif tg.get("natural") == "water" or tg.get("waterway") == "riverbank" or \
                tg.get("landuse") in ("basin", "reservoir"):
            for p in ext: t["eau"].poly(p)
            for p in inte: t["eau"].poly(p, 0)
        elif tg.get("leisure") in ("park", "garden") or tg.get("landuse") in ("grass", "meadow"):
            for p in ext: t["parc"].poly(p)
        hw = tg.get("highway")
        if hw == "pedestrian" and tg.get("area") == "yes" or tg.get("place") == "square":
            for p in ext: t["place"].poly(p)
            continue
        if sous_terre or tg.get("bridge") == "yes" and hw:
            continue
        if hw in RUES:
            if hw in GRANDS_AXES:
                t["grand_axe"].ligne(geo, 3.0)
            else:
                t["rue"].ligne(geo, 1.0)
        rw = tg.get("railway")
        # Les voies ferrees ne viennent pas d'OSM : un faisceau de voies paralleles est
        # dessine a part, au sud de la gare (faisceau_perrache).
        if rw == "tram" and tg.get("usage") == "main" and not tg.get("service") and not sous_terre:
            t["tram"].ligne(geo, 1.0)
    eau = t["eau"].cases(0.5)
    rue = quatre_connexe(t["grand_axe"].cases(0.35) | t["rue"].cases(0.3)) & ~eau
    tram = amincir(quatre_connexe(t["tram"].cases(0.3)), 1) & ~eau
    # la rue du tram : une voie de chaque cote des rails
    rue |= (np.roll(tram, 1, 1) | np.roll(tram, -1, 1)) & ~eau
    rail = faisceau_perrache() & ~eau

    g = np.full((HAUTEUR, LARGEUR), "#", dtype="<U1")
    g[eau] = "w"
    parc = t["parc"].cases(0.5) & ~eau
    lab, n = composantes_masque(parc)
    tailles = np.bincount(lab[lab >= 0], minlength=n)
    g[parc & (tailles[np.maximum(lab, 0)] >= PARC_MIN)] = "h"
    g[t["place"].cases(0.5) & ~eau] = "."
    g[rue] = ","
    # ballast entre les voies du faisceau (sauf sur les rues)
    lignes = np.nonzero(rail.any(axis=1))[0]
    colonnes = np.nonzero(rail.any(axis=0))[0]
    if len(lignes):
        zone = np.zeros_like(rail)
        zone[lignes[0]:lignes[-1] + 1, colonnes[0] - 1:colonnes[-1] + 2] = True
        g[zone & ~rue] = "b"
    g[rail] = "v"
    # passage a niveau seulement la ou une rue traverse la voie (rue des deux cotes) ;
    # une rue qui longe la voie s'efface sous les rails
    for y, x in zip(*np.nonzero(rail & rue)):
        gauche = x > 0 and rue[y, x - 1] and not rail[y, x - 1]
        droite = x < LARGEUR - 1 and rue[y, x + 1] and not rail[y, x + 1]
        g[y, x] = "=" if gauche or droite else "v"
    # une case de rail prise entre deux cases de passage a niveau en devient une aussi
    for y, x in zip(*np.nonzero(g == "v")):
        if 0 < x < LARGEUR - 1 and g[y, x - 1] in "=," and g[y, x + 1] in "=," and \
                ("=" in (g[y, x - 1], g[y, x + 1])):
            g[y, x] = "="
    g[tram & (g != "v") & (g != "=")] = "r"

    # la presqu'ile seule : toute terre separee d'elle par l'eau redevient fleuve
    terre = g != "w"
    lab, n = composantes_masque(terre)
    centre = lab[HAUTEUR // 2, LARGEUR // 2]
    if centre < 0:
        centre = int(np.argmax(np.bincount(lab[lab >= 0])))
    g[terre & (lab != centre)] = "w"
    # quais : la terre au bord de l'eau devient un quai praticable
    eau = g == "w"
    bord = np.zeros_like(eau)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        bord |= np.roll(np.roll(eau, dy, 0), dx, 1)
    g[bord & ~eau & np.isin(g, ["#", ".", ",", "h"])] = "q"
    # miettes de bati (moins de 4 cases) : de la place pavee
    bati = g == "#"
    lab, n = composantes_masque(bati)
    tailles = np.bincount(lab[lab >= 0], minlength=n)
    g[bati & (tailles[np.maximum(lab, 0)] < 4)] = "."
    # quelques arbres dans les parcs, jamais colles
    for y, x in zip(*np.nonzero(g == "h")):
        if (x * 7 + y * 13) % 5 == 0 and "t" not in g[max(0, y - 1):y + 2, max(0, x - 1):x + 2]:
            g[y, x] = "t"
    return g, None


# =============================================================================
# Accessibilite : tout relier a la plus grande partie praticable
# =============================================================================
COUT = {"#": 6, "w": 10 ** 6, "v": 1, "t": 1, "j": 1, "n": 1}
REMPLACE = {"#": ".", "w": "p", "v": "=", "t": "h", "j": "h", "n": "."}


def composantes_masque(m):
    """Composantes 4-connexes d'un masque booleen (-1 hors masque)."""
    h, w = m.shape
    lab = -np.ones((h, w), int)
    n = 0
    for y, x in zip(*np.nonzero(m)):
        if lab[y, x] >= 0:
            continue
        q = deque([(y, x)])
        lab[y, x] = n
        while q:
            cy, cx = q.popleft()
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and m[ny, nx] and lab[ny, nx] < 0:
                    lab[ny, nx] = n
                    q.append((ny, nx))
        n += 1
    return lab, n


def composantes(g):
    h, w = g.shape
    lab = -np.ones((h, w), int)
    n = 0
    for y in range(h):
        for x in range(w):
            if lab[y, x] >= 0 or g[y, x] in BLOQUANTS:
                continue
            q = deque([(y, x)])
            lab[y, x] = n
            while q:
                cy, cx = q.popleft()
                for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    ny, nx = cy + dy, cx + dx
                    if 0 <= ny < h and 0 <= nx < w and lab[ny, nx] < 0 and g[ny, nx] not in BLOQUANTS:
                        lab[ny, nx] = n
                        q.append((ny, nx))
            n += 1
    return lab, n


def relier(g):
    """Creuse le chemin le moins couteux de chaque ilot vers la partie principale."""
    while True:
        lab, n = composantes(g)
        if n <= 1:
            return g
        tailles = np.bincount(lab[lab >= 0], minlength=n)
        principale = int(np.argmax(tailles))
        ilot = int(np.argmin(np.where(np.arange(n) == principale, 10 ** 9, tailles)))
        h, w = g.shape
        dist = {}
        prec = {}
        tas = []
        for y, x in zip(*np.nonzero(lab == ilot)):
            dist[(y, x)] = 0
            heapq.heappush(tas, (0, y, x))
        arrivee = None
        while tas:
            d, y, x = heapq.heappop(tas)
            if d > dist.get((y, x), 1e9):
                continue
            if lab[y, x] == principale:
                arrivee = (y, x)
                break
            for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                ny, nx = y + dy, x + dx
                if not (0 <= ny < h and 0 <= nx < w):
                    continue
                nd = d + COUT.get(g[ny, nx], 0.1)
                if nd < dist.get((ny, nx), 1e9):
                    dist[(ny, nx)] = nd
                    prec[(ny, nx)] = (y, x)
                    heapq.heappush(tas, (nd, ny, nx))
        c = arrivee
        while c in prec:
            if g[c] in REMPLACE:
                g[c] = REMPLACE[g[c]]
            c = prec[c]


# =============================================================================
# Elements de jeu
# =============================================================================
def praticable(c):
    return c not in BLOQUANTS


def placer_elements(g, eemi_bati):
    h = HAUTEUR // len(ZONES)
    zones = {nom: g[i * h:(i + 1) * h].copy() for i, nom in enumerate(ZONES)}
    rng = np.random.default_rng(20261118)
    sorties = {nom: {} for nom in ZONES}
    departs = {}

    # Pas de sortie : les bandes sont collees, on passe de l'une a l'autre sur toute
    # la limite. La grille entiere a deja ete reliee d'un seul tenant (relier).

    def libres(z, sols=".,qhd", devant_batiment=False):
        out = []
        for y in range(2, h - 2):
            for x in range(1, LARGEUR - 1):
                if z[y, x] not in sols:
                    continue
                if devant_batiment and z[y - 1, x] != "#":
                    continue
                if z[y + 1, x] in "#t":           # serait cache par un volume
                    continue
                out.append((x, y))
        return out

    def proche_du_centre(cases):
        return sorted(cases, key=lambda c: (c[0] - LARGEUR / 2) ** 2 + (c[1] - h / 2) ** 2)

    # --- combat final devant l'EEMI
    zone_eemi, x_eemi = None, None
    ex, ey = grille(*EEMI)
    i_eemi = min(int(ey) // h, len(ZONES) - 1)
    zone_eemi = ZONES[i_eemi]
    z = zones[zone_eemi]
    devant = [(x, y) for x, y in libres(z, devant_batiment=True)]
    devant.sort(key=lambda c: (c[0] - ex) ** 2 + (c[1] + i_eemi * h - ey) ** 2)
    if devant:
        x, y = devant[0]
        z[y, x] = "X"

    for nom in ZONES:
        z = zones[nom]
        # --- lieux speciaux devant des facades, pres du centre
        pris = set()
        for c, n in SPECIAUX[nom].items():
            for x, y in proche_du_centre(libres(z, devant_batiment=True)):
                if n == 0:
                    break
                if all(abs(x - a) + abs(y - b) > 4 for a, b in pris):
                    z[y, x] = c
                    pris.add((x, y))
                    n -= 1
        # --- passages sous les voies : un de chaque cote du faisceau de rails
        rails = np.argwhere(z == "v")
        if len(rails) > 8:
            cx = int(np.median(rails[:, 1]))
            ouest = [(x, y) for x, y in proche_du_centre(libres(z, ".,q")) if x < cx - 3]
            est = [(x, y) for x, y in proche_du_centre(libres(z, ".,q")) if x > cx + 3]
            if ouest and est:
                for x, y in (ouest[0], est[0]):
                    z[y, x] = "T"
        # --- herbe haute : des taches dans les parcs
        herbe = np.argwhere(z == "h")
        if len(herbe) < 12:          # pas de parc : on en cree un petit
            for x, y in proche_du_centre(libres(z, "."))[:16]:
                z[y, x] = "h"
            herbe = np.argwhere(z == "h")
        for y, x in herbe:
            if (x // 3 + y // 2 + (x * 5 + y * 3) % 2) % 3 != 0:
                z[y, x] = "g"
        # --- ressources : deux, loin l'une de l'autre
        cand = libres(z, "hg.")
        rng.shuffle(cand)
        ress = []
        for x, y in cand:
            if all(abs(x - a) + abs(y - b) > h // 2 for a, b in ress):
                ress.append((x, y))
            if len(ress) == 3:
                break
        for x, y in ress:
            z[y, x] = "R"
        # --- lampadaires le long des rues, pave mousse pres des parcs
        for y in range(1, h - 1):
            for x in range(1, LARGEUR - 1):
                if z[y, x] == "." and "," in (z[y, x - 1], z[y, x + 1]) and (x * 3 + y * 7) % 9 == 0 \
                        and z[y + 1, x] not in "#t":
                    z[y, x] = "L"
                elif z[y, x] == "." and "h" in z[y - 1:y + 2, x - 1:x + 2] and (x * 11 + y * 5) % 4 == 0:
                    z[y, x] = "m"
        # --- depart : devant la gare pour la premiere bande, pres du centre sinon
        if nom == ZONES[0]:
            gx, gy = grille(*GARE)
            departs[nom] = sorted(libres(z, ".,"), key=lambda c: (c[0] - gx) ** 2 + (c[1] - gy) ** 2)[0]
        else:
            departs[nom] = proche_du_centre(libres(z, ".,"))[0]
        x, y = departs[nom]
        if not praticable(z[y, x]) or z[y, x] in "123":
            z[y, x] = "."
    return zones, sorties, departs


# =============================================================================
# Ecriture
# =============================================================================
def ecrire_zones_gd(zones, sorties, departs):
    s = open(ZONES_GD).read()
    s = re.sub(r"const LARGEUR := \d+", "const LARGEUR := %d" % LARGEUR, s)
    for nom in ZONES:
        debut = s.index('\t&"%s": {' % nom)
        fin = s.index("\n\t},", debut)
        bloc = s[debut:fin]
        plan = "\t\t\"plan\": [\n" + "".join('\t\t\t"%s",\n' % "".join(l) for l in zones[nom]) + "\t\t],"
        bloc = re.sub(r'\t\t"plan": \[\n.*?\n\t\t\],', lambda m: plan, bloc, count=1, flags=re.S)
        x, y = departs[nom]
        bloc = re.sub(r'"depart": Vector2i\([^)]*\)', '"depart": Vector2i(%d, %d)' % (x, y), bloc, count=1)
        so = ", ".join('"%s": ["%s", %d, %d]' % (c, v[0], v[1], v[2]) for c, v in sorted(sorties[nom].items()))
        bloc = re.sub(r'"sorties": \{[^}]*\}', lambda m: '"sorties": {%s}' % so, bloc, count=1)
        s = s[:debut] + bloc + s[fin:]
    open(ZONES_GD, "w").write(s)


COULEURS = {
    "#": (181, 72, 43), ".": (143, 138, 128), ",": (110, 106, 100), "m": (127, 138, 106),
    "q": (196, 187, 167), "d": (138, 106, 69), "s": (216, 196, 142), "p": (154, 107, 62),
    "w": (47, 111, 159), "h": (93, 154, 60), "g": (55, 110, 40), "t": (40, 90, 35),
    "b": (107, 102, 96), "v": (60, 60, 64), "=": (200, 200, 200), "r": (190, 150, 60),
    "L": (240, 210, 120), "S": (47, 168, 79), "B": (46, 134, 193), "M": (155, 89, 182),
    "T": (240, 240, 240), "R": (214, 79, 138), "X": (233, 197, 107),
    "1": (255, 255, 255), "2": (255, 255, 255), "j": (59, 125, 49), "n": (140, 90, 50),
}


def apercu(zones, chemin, echelle=4):
    lignes = []
    for nom in ZONES:
        lignes.extend(zones[nom])
    im = Image.new("RGB", (LARGEUR * echelle, len(lignes) * echelle), (0, 0, 0))
    d = ImageDraw.Draw(im)
    for y, l in enumerate(lignes):
        for x, c in enumerate(l):
            d.rectangle([x * echelle, y * echelle, x * echelle + echelle - 1, y * echelle + echelle - 1],
                        fill=COULEURS.get(c, (255, 0, 255) if c != "@" else (0, 0, 0)))
    im.save(chemin)


def reference(elements, chemin, echelle=4):
    """Les donnees OSM dessinees telles quelles, dans le meme cadre que la grille."""
    im = Image.new("RGB", (LARGEUR * echelle, HAUTEUR * echelle), (205, 200, 190))
    d = ImageDraw.Draw(im)

    def pts(geo):
        return [(x * echelle, y * echelle) for x, y in points(geo)]
    ordre = []
    for e in elements:
        tg = e.get("tags", {})
        geo = e.get("geometry") or []
        if e["type"] == "node" or len(geo) < 2:
            continue
        if tg.get("natural") == "water" or tg.get("waterway") == "riverbank":
            ordre.append((0, "poly", pts(geo), (47, 111, 159)))
        elif tg.get("leisure") in ("park", "garden", "playground", "pitch") or tg.get("landuse") in ("grass", "meadow"):
            ordre.append((1, "poly", pts(geo), (120, 175, 90)))
        elif tg.get("highway") in RUES and tg.get("tunnel") != "yes":
            ordre.append((2, "ligne", pts(geo), (110, 106, 100), echelle * (2 if tg["highway"] in GRANDS_AXES else 1)))
        elif tg.get("railway") == "rail" and tg.get("usage") == "main" and not tg.get("service") and tg.get("tunnel") != "yes":
            ordre.append((3, "ligne", pts(geo), (50, 50, 55), 2))
        elif tg.get("railway") == "tram" and tg.get("tunnel") != "yes":
            ordre.append((4, "ligne", pts(geo), (230, 180, 40), 3))
        if "building" in tg:
            ordre.append((5, "poly", pts(geo), (181, 72, 43)))
    for o in sorted(ordre, key=lambda o: o[0]):
        if o[1] == "poly" and len(o[2]) > 2:
            d.polygon(o[2], fill=o[3])
        elif o[1] == "ligne":
            d.line(o[2], fill=o[3], width=o[4])
    im.save(chemin)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--apercu", help="image PNG de controle")
    p.add_argument("--ecrire", action="store_true", help="met a jour scenes/world/zones.gd")
    p.add_argument("--reference", help="image PNG des donnees OSM brutes, meme cadre")
    a = p.parse_args()
    elements = charger()
    if a.reference:
        reference(elements, a.reference)
    g, eemi_bati = dessiner(elements)
    g = relier(g)
    zones, sorties, departs = placer_elements(g, eemi_bati)
    print("Grille %d x %d (%g m par case), zones de %d lignes" % (LARGEUR, HAUTEUR, METRES, HAUTEUR // len(ZONES)))
    for nom in ZONES:
        txt = "".join("".join(l) for l in zones[nom])
        print("  %-16s %s  depart %s  sorties %s" % (nom, {c: txt.count(c) for c in "SBMTXRg12r=" if c in txt},
                                                     departs[nom], sorties[nom]))
    if a.apercu:
        apercu(zones, a.apercu)
    if a.ecrire:
        ecrire_zones_gd(zones, sorties, departs)
        print("zones.gd mis a jour.")


if __name__ == "__main__":
    main()
