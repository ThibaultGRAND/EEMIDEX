#!/usr/bin/env python3
"""Construit les plans des 4 zones de la Confluence depuis OpenStreetMap.

Une seule carte continue, nord en haut (comme Google Maps), de la gare de Perrache
au nord a la rue Paul-Montrochet au sud, de la Saone au Rhone. Elle est coupee en
4 bandes horizontales collees : on passe de l'une a l'autre n'importe ou sur la
limite (Zones.ORDRE dans zones.gd), sans case de sortie.

    python3 tools/osm_vers_zones.py --apercu apercu.png     # dessine, n'ecrit rien
    python3 tools/osm_vers_zones.py --ecrire                 # met a jour zones.gd

Entree : tools/map_data/confluence_osm.json, un export Overpass (« out geom tags »)
du quartier : batiments, voirie, voies ferrees et de tram, eau, parcs, arbres.
Donnees © les contributeurs d'OpenStreetMap, licence ODbL (voir assets/maps/SOURCES.md).

Ce que fait le script :
  1. projette l'emprise nord en haut (Perrache en haut, Montrochet en bas, la Saone
     a gauche, le Rhone a droite) ;
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

METRES = 10.0           # metres par case
SUR = 4                 # sur-echantillonnage du dessin
ZONES = ["perrache", "sainte_blandine", "darse", "pointe"]

# Emprise de la carte (nord en haut) : la capture Google Maps de reference, plus
# la gare de Perrache au nord.
LAT_NORD, LAT_SUD = 45.7512, 45.7383
LON_OUEST, LON_EST = 4.8132, 4.8285
NORD = (LAT_NORD, (LON_OUEST + LON_EST) / 2)
SUD = (LAT_SUD, (LON_OUEST + LON_EST) / 2)
MARGE_NORD, MARGE_SUD = 0.0, 0.0
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
LAT0, LON0 = (NORD[0] + SUD[0]) / 2, (NORD[1] + SUD[1]) / 2
KX = math.cos(math.radians(LAT0)) * 111320.0
KY = 110540.0


def metres(lat, lon):
    """x vers l'est, y vers le sud, en metres."""
    return (lon - LON0) * KX, (LAT0 - lat) * KY


NX, NY = metres(*NORD)
SX, SY = metres(*SUD)
_long = math.hypot(SX - NX, SY - NY)
BAS = ((SX - NX) / _long, (SY - NY) / _long)        # unitaire, du nord vers le sud
DROITE = (BAS[1], -BAS[0])                           # perpendiculaire, vers l'est
LARGEUR = int(round((LON_EST - LON_OUEST) * KX / METRES))
HAUTEUR = int(math.ceil((_long + MARGE_NORD + MARGE_SUD) / METRES))
HAUTEUR -= HAUTEUR % len(ZONES)


def grille(lat, lon):
    """Coordonnees (colonne, ligne) flottantes dans la grille."""
    x, y = metres(lat, lon)
    dx, dy = x - NX, y - NY
    u = dx * DROITE[0] + dy * DROITE[1]
    s = dx * BAS[0] + dy * BAS[1]
    return u / METRES + LARGEUR / 2, (s + MARGE_NORD) / METRES


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
LARGEUR_ROUTE_M = {   # largeur de chaussee, en metres
    "trunk": 18, "trunk_link": 9, "primary": 16, "primary_link": 9,
    "secondary": 14, "tertiary": 12, "residential": 9, "unclassified": 9,
    "living_street": 7, "service": 5, "pedestrian": 8, "footway": 3, "cycleway": 3, "path": 3,
}
# Au moins une case de large pour une rue (sinon elle disparait sous le bati a 10 m
# par case), un peu moins pour un chemin pieton.
LARGEUR_ROUTE = {k: max(v / METRES, 1.3 if v >= 7 else 1.0) for k, v in LARGEUR_ROUTE_M.items()}


def dessiner(elements):
    t = {k: Toile() for k in ["eau", "parc", "sable", "emprise_fer", "route", "pieton",
                             "rail", "tram", "quai_fer", "ponton", "bati"]}
    arbres = []
    eemi_bati = None
    for e in elements:
        tg = e.get("tags", {})
        sous_terre = tg.get("tunnel") in ("yes", "building_passage") or tg.get("layer", "0").startswith("-")
        if e["type"] == "node":
            if tg.get("natural") == "tree":
                arbres.append(grille(e["lat"], e["lon"]))
            continue
        ext, inte = anneaux(e) if (e["type"] == "relation" or (e.get("geometry") and
                                   e["geometry"][0] == e["geometry"][-1])) else ([], [])
        geo = points(e.get("geometry", []) or [])
        if tg.get("riviere_interieur"):          # ile au milieu d'un fleuve
            for p in ext: t["eau"].poly(p, 0)
        elif tg.get("natural") == "water" or tg.get("waterway") == "riverbank" or \
                tg.get("landuse") in ("basin", "reservoir"):
            for p in ext: t["eau"].poly(p)
            for p in inte: t["eau"].poly(p, 0)
        elif tg.get("leisure") in ("park", "garden", "playground", "pitch") or \
                tg.get("landuse") in ("grass", "meadow", "forest") or \
                tg.get("natural") in ("wood", "scrub", "grassland"):
            for p in ext: t["parc"].poly(p)
        elif tg.get("natural") in ("sand", "beach"):
            for p in ext: t["sable"].poly(p)
        elif tg.get("landuse") == "railway":
            for p in ext: t["emprise_fer"].poly(p)
        if "building" in tg and not sous_terre:
            for p in ext: t["bati"].poly(p)
            if tg.get("name", "").startswith("« Lumen"):
                eemi_bati = ext
        if tg.get("man_made") == "pier":
            if ext: t["ponton"].poly(ext[0])
            else: t["ponton"].ligne(geo, 1.0)
        if sous_terre or tg.get("bridge") == "yes" and "highway" in tg:
            continue
        hw = tg.get("highway")
        if hw in LARGEUR_ROUTE:
            if tg.get("area") == "yes" and ext:
                t["pieton"].poly(ext[0])
            else:
                pieton = hw in ("pedestrian", "footway", "cycleway", "path")
                (t["pieton"] if pieton else t["route"]).ligne(geo, LARGEUR_ROUTE[hw])
        rw = tg.get("railway")
        if rw == "rail":
            t["rail"].ligne(geo, 1.6 / METRES * 1.8)
        elif rw == "tram":
            t["tram"].ligne(geo, 3.0 / METRES)
        elif rw == "platform":
            if ext: t["quai_fer"].poly(ext[0])
            else: t["quai_fer"].ligne(geo, 1.0)
    m = {k: v.cases(0.5) for k, v in t.items()}
    m["bati"] = t["bati"].cases(0.45)
    m["rail"] = t["rail"].cases(0.25)
    m["tram"] = t["tram"].cases(0.3)
    m["route"] = t["route"].cases(0.3)
    m["pieton"] = t["pieton"].cases(0.4)

    g = np.full((HAUTEUR, LARGEUR), ".", dtype="<U1")
    g[m["parc"]] = "h"
    g[m["sable"]] = "s"
    g[m["emprise_fer"]] = "b"
    g[m["eau"]] = "w"
    g[m["ponton"]] = "p"
    g[m["bati"] & ~m["eau"]] = "#"
    # les rues passent devant le bati : le quadrillage reste lisible
    g[m["pieton"] & ~m["eau"]] = "."
    g[m["route"] & ~m["eau"]] = ","
    g[m["quai_fer"]] = "q"
    # ballast autour des rails, puis les rails par-dessus tout le reste (sauf l'eau)
    autour = np.zeros_like(m["rail"])
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            autour |= np.roll(np.roll(m["rail"], dy, 0), dx, 1)
    g[autour & ~m["eau"] & (g != "#") & (g != "q")] = "b"
    g[m["rail"] & ~m["eau"]] = "v"
    g[m["tram"] & ~m["eau"]] = "r"
    # la presqu'ile seule : toute terre separee d'elle par l'eau redevient fleuve
    terre = g != "w"
    lab, n = composantes_masque(terre)
    centre = lab[HAUTEUR // 2, LARGEUR // 2]
    if centre < 0:
        centre = int(np.argmax(np.bincount(lab[lab >= 0])))
    g[terre & (lab != centre)] = "w"
    # cours fermees au milieu des immeubles : elles font partie du bati
    marchable = ~np.isin(g, list(BLOQUANTS))
    lab, n = composantes_masque(marchable)
    tailles = np.bincount(lab[lab >= 0], minlength=n)
    principale = int(np.argmax(tailles))
    for k in range(n):
        if k != principale and tailles[k] < 60:
            g[lab == k] = "#"
    # quais : la terre au bord de l'eau
    eau = g == "w"
    bord = np.zeros_like(eau)
    for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        bord |= np.roll(np.roll(eau, dy, 0), dx, 1)
    g[bord & np.isin(g, [".", ","])] = "q"
    # arbres d'alignement et des parcs (un sur deux, jamais colles)
    for x, y in arbres:
        c, r = int(x), int(y)
        if 0 <= r < HAUTEUR and 0 <= c < LARGEUR and g[r, c] in "h." and (c * 7 + r * 13) % 2 == 0:
            voisins = g[max(0, r - 1):r + 2, max(0, c - 1):c + 2]
            if "t" not in voisins and "#" not in voisins and "," not in voisins and "r" not in voisins:
                g[r, c] = "t"
    return g, eemi_bati


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
        elif tg.get("highway") in LARGEUR_ROUTE and tg.get("tunnel") != "yes":
            ordre.append((2, "ligne", pts(geo), (110, 106, 100), max(1, int(LARGEUR_ROUTE[tg["highway"]] * echelle))))
        elif tg.get("railway") == "rail" and tg.get("tunnel") != "yes":
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
