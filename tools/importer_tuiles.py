#!/usr/bin/env python3
"""Transforme les planches generees en un jeu de tuiles utilisable par Godot.

Pour chaque planche : decoupe la grille, enleve le fond magenta, reduit chaque
case a 16 x 16 pixels, puis assemble le tout dans un seul atlas avec sa
ressource TileSet.

    python3 tools/importer_tuiles.py assets/tilesets/brutes

Nommage attendu des fichiers : le numero de la planche en tete, comme dans
docs/prompts-tuiles.md -> 01_sols.png, 02_variantes.png, 07_toits.png...
Pour forcer une grille differente de celle prevue, l'ecrire dans le nom :
12_mobilier_5x3.png

Les .webp sont convertis en PNG a la volee avec sips (macOS).
"""
import os
import re
import subprocess
import sys
import tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from png_simple import Image, lire_png, VIDE

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TUILE = 16
ATLAS_COLONNES = 8

# numero -> (nom, colonnes, lignes, fond magenta attendu, volume)
PLANCHES = {
    1:  ("Sols de base",            4, 2, False, False),
    2:  ("Variantes de sol",        4, 2, False, False),
    3:  ("Eau et berges",           4, 2, False, False),
    4:  ("Objets de quai",          4, 2, True,  True),
    5:  ("Murs et parapets",        4, 2, True,  True),
    6:  ("Facades pierre doree",    4, 3, True,  True),
    7:  ("Toits de tuiles",         3, 3, True,  True),
    8:  ("Falaise et escaliers",    4, 3, True,  True),
    9:  ("Arbres",                  4, 3, True,  True),
    10: ("Buissons",                4, 2, True,  True),
    11: ("Ferroviaire",             4, 3, True,  False),
    12: ("Mobilier urbain",         4, 3, True,  True),
    13: ("Tuiles de jeu",           4, 2, True,  True),
}


def est_magenta(p):
    """Vrai pour le fond magenta, meme abime par la compression JPEG.

    Le magenta pur est #FF00FF. Le JPEG l'etale en un halo rose-violet : on
    accepte donc tout ce qui est franchement rouge ET bleu sans etre vert.
    Le rose d'une praline, lui, a nettement moins de bleu que de rouge, il
    n'est pas attrape.
    """
    r, v, b, a = p
    if a == 0:
        return True
    return r > 140 and b > 140 and (r - v) > 60 and (b - v) > 60


def charger(chemin):
    if chemin.lower().endswith(".png"):
        return lire_png(chemin)
    # sips sait convertir webp, jpg, heic... en PNG
    tmp = os.path.join(tempfile.gettempdir(), "import_tuiles.png")
    subprocess.run(["sips", "-s", "format", "png", chemin, "--out", tmp],
                   check=True, capture_output=True)
    return lire_png(tmp)


def taille_du_pixel(cellule, tolerance=26):
    """Estime la taille d'un pixel de jeu dans la planche.

    Parcourt des lignes horizontales et mesure la longueur des plages de
    couleur a peu pres constante. La longueur mediane vaut la taille d'un
    pixel dessine. La tolerance absorbe le bruit de la compression JPEG, qui
    rend deux pixels voisins jamais exactement identiques.
    """
    plages = []
    for y in range(cellule.h // 8, cellule.h, max(1, cellule.h // 12)):
        debut = 0
        ref = cellule.lire(0, y)
        for x in range(1, cellule.l):
            p = cellule.lire(x, y)
            ecart = max(abs(p[0] - ref[0]), abs(p[1] - ref[1]), abs(p[2] - ref[2]))
            if ecart > tolerance:
                if x - debut > 1:
                    plages.append(x - debut)
                debut = x
                ref = p
    if not plages:
        return 1
    plages.sort()
    return max(1, plages[len(plages) // 2])


def reduire(cellule, cote=TUILE):
    """Reduit une case a cote x cote en moyennant, en ignorant le transparent."""
    out = Image(cote, cote)
    for y in range(cote):
        for x in range(cote):
            x0, x1 = cellule.l * x // cote, max(cellule.l * (x + 1) // cote, cellule.l * x // cote + 1)
            y0, y1 = cellule.h * y // cote, max(cellule.h * (y + 1) // cote, cellule.h * y // cote + 1)
            r = v = b = 0
            opaques = 0
            total = 0
            for j in range(y0, y1):
                for i in range(x0, x1):
                    p = cellule.lire(i, j)
                    total += 1
                    if p[3] > 127:
                        r += p[0]; v += p[1]; b += p[2]
                        opaques += 1
            if opaques * 2 < total:
                out.px[y][x] = VIDE
            else:
                out.px[y][x] = (r // opaques, v // opaques, b // opaques, 255)
    return out


def grille_depuis_nom(nom, defaut):
    m = re.search(r"_(\d+)x(\d+)", nom)
    if m:
        return int(m.group(1)), int(m.group(2))
    return defaut


def main(dossier):
    chemins = sorted(
        os.path.join(dossier, f) for f in os.listdir(dossier)
        if f.lower().endswith((".png", ".webp", ".jpg", ".jpeg"))
        and not f.startswith(".")
    )
    if not chemins:
        print("Aucune planche dans %s" % dossier)
        return 1

    # Une planche refaite ("11 bis") remplace la premiere version.
    par_numero = {}
    for chemin in chemins:
        m = re.search(r"(\d+)", os.path.basename(chemin))
        numero = int(m.group(1)) if m else 0
        if numero in par_numero and "bis" not in os.path.basename(chemin).lower():
            continue
        if numero in par_numero:
            print("  %s remplace %s" % (os.path.basename(chemin),
                                        os.path.basename(par_numero[numero])))
        par_numero[numero] = chemin
    chemins = [par_numero[n] for n in sorted(par_numero)]

    tuiles = []        # [(nom, Image)]
    volumes = []       # index des tuiles qui depassent du sol
    for chemin in chemins:
        nom_fichier = os.path.basename(chemin)
        m = re.search(r"(\d+)", nom_fichier)
        numero = int(m.group(1)) if m else 0
        nom, c_def, l_def, magenta_attendu, volume = PLANCHES.get(
            numero, ("Planche %s" % nom_fichier, 4, 2, True, True))
        colonnes, lignes = grille_depuis_nom(nom_fichier, (c_def, l_def))

        planche = charger(chemin)
        if planche.l % colonnes or planche.h % lignes:
            print("  ! %s : %d x %d ne se divise pas en %d x %d, cases arrondies"
                  % (nom_fichier, planche.l, planche.h, colonnes, lignes))
        cl, ch = planche.l // colonnes, planche.h // lignes

        premiere = planche.decouper(0, 0, cl, ch)
        bloc = taille_du_pixel(premiere)
        echelle = cl / float(bloc) if bloc else 0
        verdict = "ok" if abs(echelle - TUILE) < 0.01 else "%.0f px de jeu par tuile" % echelle
        print("%-28s %4d x %-4d  grille %dx%d  case %dx%d  -> %s"
              % (nom, planche.l, planche.h, colonnes, lignes, cl, ch, verdict))

        magenta_vu = False
        for ligne in range(lignes):
            for colonne in range(colonnes):
                cellule = planche.decouper(colonne * cl, ligne * ch, cl, ch)
                for y in range(cellule.h):
                    for x in range(cellule.l):
                        if est_magenta(cellule.px[y][x]):
                            cellule.px[y][x] = VIDE
                            magenta_vu = True
                if volume:
                    volumes.append(len(tuiles))
                tuiles.append(("%02d_%d_%d" % (numero, colonne, ligne), reduire(cellule)))
        if magenta_attendu and not magenta_vu:
            print("  ! %s : aucun magenta trouve, la transparence sera absente" % nom_fichier)

    # --- assemblage de l'atlas ----------------------------------------------
    colonnes = ATLAS_COLONNES
    rangs = (len(tuiles) + colonnes - 1) // colonnes
    atlas = Image(colonnes * TUILE, rangs * TUILE)
    for i, (_, img) in enumerate(tuiles):
        atlas.coller(img, (i % colonnes) * TUILE, (i // colonnes) * TUILE)
    chemin_png = "assets/tilesets/lyon.png"
    atlas.ecrire(os.path.join(RACINE, chemin_png))

    # --- ressource TileSet ---------------------------------------------------
    placeholder = "assets/tilesets/placeholder_tuiles.png"
    sortie = [
        '[gd_resource type="TileSet" load_steps=5 format=3]', '',
        '[ext_resource type="Texture2D" path="res://%s" id="1_tex"]' % chemin_png,
        '[ext_resource type="Texture2D" path="res://%s" id="2_placeholder"]' % placeholder, '',
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_lyon"]',
        'texture = ExtResource("1_tex")',
        'texture_region_size = Vector2i(%d, %d)' % (TUILE, TUILE),
    ]
    for i in range(len(tuiles)):
        cx, cy = i % colonnes, i // colonnes
        sortie.append('%d:%d/0 = 0' % (cx, cy))
        if i in volumes:
            sortie.append('%d:%d/0/y_sort_origin = 16' % (cx, cy))
    # Source 1 : les placeholders, 8 x 4 tuiles, pour ce qui manque encore.
    sortie += ['', '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_placeholder"]',
               'texture = ExtResource("2_placeholder")',
               'texture_region_size = Vector2i(%d, %d)' % (TUILE, TUILE)]
    for cy in range(4):
        for cx in range(8):
            sortie.append('%d:%d/0 = 0' % (cx, cy))
            if cy >= 2:
                sortie.append('%d:%d/0/y_sort_origin = %d' % (cx, cy, 32 if (cx, cy) in [(1, 2), (6, 2), (1, 3)] else 16))
    sortie += ['', '[resource]',
               'tile_size = Vector2i(%d, %d)' % (TUILE, TUILE),
               'sources/0 = SubResource("TileSetAtlasSource_lyon")',
               'sources/1 = SubResource("TileSetAtlasSource_placeholder")', '']
    with open(os.path.join(RACINE, "assets/tilesets/lyon.tres"), "w") as f:
        f.write("\n".join(sortie))

    print()
    print("atlas   : %s  (%d x %d, %d tuiles)" % (chemin_png, atlas.l, atlas.h, len(tuiles)))
    print("tileset : assets/tilesets/lyon.tres")
    print()
    print("Correspondance nom -> case de l'atlas :")
    for i, (nom, _) in enumerate(tuiles):
        print("  %-12s %d:%d" % (nom, i % colonnes, i // colonnes))
    return 0


if __name__ == "__main__":
    dossier = sys.argv[1] if len(sys.argv) > 1 else "assets/tilesets/brutes"
    sys.exit(main(os.path.join(RACINE, dossier) if not os.path.isabs(dossier) else dossier))
