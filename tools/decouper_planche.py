#!/usr/bin/env python3
"""Découpe une planche de personnage et l'intègre à Godot, au format de PnjThomas.

Entrée : une planche d'origine (fond vert, magenta ou transparent), disposée comme
les planches fournies par l'équipe :

    ligne 0 : 8 poses immobiles
    ligne 1 : marche bas-gauche (3 images) | marche gauche (3 images)
    ligne 2 : marche bas-droite (3)        | marche droite (3)
    ligne 3 : marche bas (3)               | marche haut (3)
    ligne 4 : marche haut-gauche (3)       | marche haut-droite (3)

Une planche « unique » (une seule pose de face) est aussi acceptée : toutes les
animations reprennent cette pose, la marche ajoute un rebond d'1 px.

Sortie, dans assets/characters/<id>/ :
    <id>_sheet.png    toutes les poses dans une grille régulière, pieds sur la
                      dernière ligne de chaque case, personnage de HAUTEUR px
                      (104 par défaut, option --hauteur) ;
    <id>_frames.tres  SpriteFrames avec 16 animations : idle_<dir> et walk_<dir>
                      pour les 8 directions (down, down_left, left, up_left, up,
                      up_right, right, down_right).

Dépendances : Pillow, numpy, scipy (pip install pillow numpy scipy).

Exemples :
    python3 tools/decouper_planche.py tools/planches/pnj_thomas.jpg pnj_thomas --fond vert
    python3 tools/decouper_planche.py tools/planches/pnj_julian.jpg pnj_julian --fond vert --face-en-premier
    python3 tools/decouper_planche.py tools/planches/pnj_thibaut.png pnj_thibaut --fond magenta --unique
"""
import argparse
import os

import numpy as np
from PIL import Image
from scipy import ndimage

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

## Hauteur du personnage dans la planche produite (affiché à scale 0.25 en jeu :
## 104 px de texture = 26 px dans le monde).
HAUTEUR = 104
## Marge vide au-dessus du personnage le plus grand, dans chaque case.
MARGE_HAUT = 4

## Correspondance poses -> animations, (ligne, colonne) dans la planche d'origine.
## Les poses immobiles bas-droite et droite sont prises dans la marche : sur les
## planches fournies, les poses 6 et 7 de la ligne 0 sont souvent ambiguës.
MARCHES = {
    "down_left": [(1, 0), (1, 1), (1, 2)],
    "left": [(1, 3), (1, 4), (1, 5)],
    "down_right": [(2, 0), (2, 1), (2, 2)],
    "right": [(2, 3), (2, 4), (2, 5)],
    "down": [(3, 0), (3, 1), (3, 2)],
    "up": [(3, 3), (3, 4), (3, 5)],
    "up_left": [(4, 0), (4, 1), (4, 2)],
    "up_right": [(4, 3), (4, 4), (4, 5)],
}
IMMOBILES = {
    "up": (0, 0), "up_left": (0, 1), "left": (0, 2), "down_left": (0, 3),
    "down": (0, 4), "down_right": (2, 1), "right": (2, 4), "up_right": (0, 7),
}
FPS_IMMOBILE = 5.0
FPS_MARCHE = 7.0


def masque_fond(im, fond):
    r, g, b = im[..., 0], im[..., 1], im[..., 2]
    if fond == "vert":
        return (g > 140) & (g - r > 50) & (g - b > 50)
    if fond == "magenta":
        return (r > 140) & (b > 140) & (r - g > 60) & (b - g > 60)
    raise ValueError(fond)


def lire_poses(chemin, fond, unique):
    """Renvoie {(ligne, colonne): image RGBA recadrée} et la liste des lignes."""
    src = Image.open(chemin)
    if fond == "transparent":
        rgba = np.asarray(src.convert("RGBA")).astype(int)
        rgb, premier_plan = rgba[..., :3], rgba[..., 3] > 40
    else:
        rgb = np.asarray(src.convert("RGB")).astype(int)
        premier_plan = ndimage.binary_opening(~masque_fond(rgb, fond), iterations=2)
    # Regroupe les pixels proches (mains, mèches) sans coller deux poses voisines.
    etiquettes, _ = ndimage.label(ndimage.binary_dilation(premier_plan, iterations=4))
    poses = []
    for i, tranche in enumerate(ndimage.find_objects(etiquettes)):
        hauteur = tranche[0].stop - tranche[0].start
        if hauteur < 0.08 * rgb.shape[0] and not unique:
            continue
        masque = (etiquettes == i + 1) & premier_plan
        ys, xs = np.nonzero(masque)
        y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
        morceau = rgb[y0:y1, x0:x1].copy()
        alpha = masque[y0:y1, x0:x1]
        if fond != "transparent":
            # Retire le reflet coloré du fond sur les bords.
            bord = alpha & ~ndimage.binary_erosion(alpha, iterations=3)
            if fond == "vert":
                lim = np.maximum(morceau[..., 0], morceau[..., 2])
                morceau[..., 1] = np.where(bord & (morceau[..., 1] > lim), lim, morceau[..., 1])
            else:
                exces = np.clip(np.minimum(morceau[..., 0], morceau[..., 2]) - morceau[..., 1], 0, None) * bord
                morceau[..., 0] -= exces
                morceau[..., 2] -= exces
        poses.append({"cy": (y0 + y1) / 2, "x0": x0, "h": y1 - y0,
                      "rgba": np.dstack([morceau, alpha * 255]).astype(np.uint8)})
    if unique:
        return {(0, 0): max(poses, key=lambda p: p["h"])}, [1]
    poses.sort(key=lambda p: p["cy"])
    lignes = []
    for p in poses:
        if lignes and abs(lignes[-1][0]["cy"] - p["cy"]) < 0.5 * p["h"]:
            lignes[-1].append(p)
        else:
            lignes.append([p])
    for ligne in lignes:
        ligne.sort(key=lambda p: p["x0"])
    nb = [len(l) for l in lignes]
    if nb != [8, 6, 6, 6, 6]:
        raise SystemExit("Planche inattendue : %s poses par ligne au lieu de [8, 6, 6, 6, 6]" % nb)
    return {(r, c): p for r, ligne in enumerate(lignes) for c, p in enumerate(ligne)}, nb


def reduire(rgba, echelle):
    """Réduction prémultipliée (pas de halo sombre), alpha binaire."""
    h, w = rgba.shape[:2]
    taille = (max(1, round(w * echelle)), max(1, round(h * echelle)))
    a = rgba[..., 3:4].astype(float) / 255
    pm = np.concatenate([rgba[..., :3] * a, rgba[..., 3:4]], -1).astype(np.uint8)
    r = np.asarray(Image.fromarray(pm).resize(taille, Image.BOX)).astype(float)
    ra = r[..., 3:4] / 255
    rgb = np.where(ra > 0, r[..., :3] / np.maximum(ra, 1e-6), 0)
    return np.concatenate([np.clip(rgb, 0, 255), np.where(ra > 0.45, 255, 0)], -1).astype(np.uint8)


def centre_tete(rgba):
    """Abscisse du centre de la tête (30 % du haut) : aligne les poses entre elles."""
    a = rgba[..., 3] > 0
    return float(np.nonzero(a[: max(1, int(a.shape[0] * 0.3))])[1].mean())


def ecrire_frames(chemin_tres, chemin_png_res, cw, ch, anims):
    cases = sorted({rc for images, _, _ in anims.values() for rc in images})
    ids = {rc: "atlas_%d_%d" % rc for rc in cases}
    l = ['[gd_resource type="SpriteFrames" load_steps=%d format=3]' % (len(cases) + 2), "",
         '[ext_resource type="Texture2D" path="%s" id="1_sheet"]' % chemin_png_res, ""]
    for rc in cases:
        l += ['[sub_resource type="AtlasTexture" id="%s"]' % ids[rc], 'atlas = ExtResource("1_sheet")',
              "region = Rect2(%d, %d, %d, %d)" % (rc[1] * cw, rc[0] * ch, cw, ch), ""]
    blocs = []
    for nom, (images, fps, boucle) in anims.items():
        cadres = ", ".join('{\n"duration": 1.0,\n"texture": SubResource("%s")\n}' % ids[rc] for rc in images)
        blocs.append('{\n"frames": [%s],\n"loop": %s,\n"name": &"%s",\n"speed": %.1f\n}'
                     % (cadres, "true" if boucle else "false", nom, fps))
    l += ["[resource]", "animations = [" + ", ".join(blocs) + "]"]
    with open(chemin_tres, "w") as f:
        f.write("\n".join(l) + "\n")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("planche")
    p.add_argument("id", help="nom du personnage, ex. pnj_thomas")
    p.add_argument("--fond", choices=["vert", "magenta", "transparent"], required=True)
    p.add_argument("--face-en-premier", action="store_true",
                   help="la pose 1 de la ligne 0 est de face : l'immobile « haut » est pris dans la marche de dos")
    p.add_argument("--unique", action="store_true", help="une seule pose de face")
    p.add_argument("--hauteur", type=int, default=HAUTEUR,
                   help="hauteur du personnage en pixels de texture (défaut %d)" % HAUTEUR)
    args = p.parse_args()

    poses, _ = lire_poses(args.planche, args.fond, args.unique)
    echelle = args.hauteur / max(pz["h"] for pz in poses.values())
    petites = {rc: reduire(pz["rgba"], echelle) for rc, pz in poses.items()}

    if args.unique:
        seule = petites[(0, 0)]
        # Case 0 : debout ; case 1 : la même, 1 px plus haut (rebond de marche).
        petites = {(0, 0): seule, (0, 1): seule}
        rebond = {(0, 1): 1}
        marches = {d: [(0, 1), (0, 0), (0, 1), (0, 0)] for d in MARCHES}
        immobiles = {d: (0, 0) for d in IMMOBILES}
    else:
        rebond = {}
        marches = {d: [a, m, b, m] for d, (a, m, b) in MARCHES.items()}
        immobiles = dict(IMMOBILES)
        if args.face_en_premier:
            immobiles["up"] = MARCHES["up"][1]

    largeur_max = max(im.shape[1] for im in petites.values())
    hauteur_max = max(im.shape[0] for im in petites.values())
    cw = largeur_max + 8 + (largeur_max % 2)
    ch = hauteur_max + MARGE_HAUT
    lignes = max(r for r, _ in petites) + 1
    colonnes = max(c for _, c in petites) + 1
    planche = Image.new("RGBA", (cw * colonnes, ch * lignes), (0, 0, 0, 0))
    for (r, c), im in petites.items():
        x = c * cw + int(round(cw / 2 - centre_tete(im)))
        y = r * ch + ch - im.shape[0] - rebond.get((r, c), 0)   # pieds sur la dernière ligne
        planche.alpha_composite(Image.fromarray(im), (x, y))

    dossier = os.path.join(RACINE, "assets", "characters", args.id)
    os.makedirs(dossier, exist_ok=True)
    png = os.path.join(dossier, "%s_sheet.png" % args.id)
    planche.save(png)
    anims = {}
    for d in ["down", "down_left", "left", "up_left", "up", "up_right", "right", "down_right"]:
        anims["idle_" + d] = ([immobiles[d]], FPS_IMMOBILE, True)
    for d in ["down", "down_left", "left", "up_left", "up", "up_right", "right", "down_right"]:
        anims["walk_" + d] = (marches[d], FPS_MARCHE, True)
    tres = os.path.join(dossier, "%s_frames.tres" % args.id)
    ecrire_frames(tres, "res://assets/characters/%s/%s_sheet.png" % (args.id, args.id), cw, ch, anims)
    print("%-18s case %dx%d, perso de %d px -> %s" % (args.id, cw, ch, args.hauteur,
                                                       os.path.relpath(dossier, RACINE)))


if __name__ == "__main__":
    main()
