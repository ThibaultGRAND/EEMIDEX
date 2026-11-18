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

Planche « de combat » (reconnue toute seule, 7 poses sur les lignes 1 a 3) :

    ligne 0 : 8 poses immobiles
    ligne 1 : marche bas-gauche (3) | coup de poing (4)
    ligne 2 : marche bas-droite (3) | coup de pied (4)
    ligne 3 : marche bas (3)        | touche, il encaisse (4)
    ligne 4 : marche haut-gauche (3) | marche haut-droite (3) (+ 1 pose ignoree)

Elle ajoute trois animations au SpriteFrames : combat_poing, combat_pied et
combat_touche (vues de profil, tournees vers la droite). Elle n'a pas de marche
gauche, droite ni haut : on reprend bas-gauche, bas-droite et haut-gauche.
Avec --combat, la marche vient de la planche principale et seul le combat est pris
dans la planche de combat.

Sortie, dans assets/characters/<id>/ :
    <id>_sheet.png    toutes les poses dans une grille régulière, pieds sur la
                      dernière ligne de chaque case, personnage de HAUTEUR px
                      (52 par défaut, option --hauteur) ;
    <id>_frames.tres  SpriteFrames avec 16 animations : idle_<dir> et walk_<dir>
                      pour les 8 directions (down, down_left, left, up_left, up,
                      up_right, right, down_right).

Dépendances : Pillow, numpy, scipy (pip install pillow numpy scipy).

Exemples :
    python3 tools/decouper_planche.py tools/planches/pnj_thomas.jpg pnj_thomas --fond vert
    python3 tools/decouper_planche.py tools/planches/pnj_julian.jpg pnj_julian --fond vert --face-en-premier
    python3 tools/decouper_planche.py tools/planches/pnj_thibaut.png pnj_thibaut --fond magenta --unique
    python3 tools/decouper_planche.py tools/planches/pnj_emile.jpg pnj_emile --fond magenta \
        --combat tools/planches/pnj_emile_combat.jpg
"""
import argparse
import os

import numpy as np
from PIL import Image
from scipy import ndimage

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

## Hauteur du personnage dans la planche produite (affiché à scale 0.25 en jeu :
## 52 px de texture = 13 px dans le monde).
HAUTEUR = 52
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
## Planche de combat : marche de remplacement et poses de combat.
MARCHES_COMBAT = dict(MARCHES)
MARCHES_COMBAT.update({
    "left": MARCHES["down_left"],
    "right": MARCHES["down_right"],
    "up": MARCHES["up_left"],
})
IMMOBILES_COMBAT = {
    "up": (0, 0), "up_left": (0, 1), "left": (0, 2), "down_left": (0, 3),
    "down": (0, 4), "down_right": (0, 5), "right": (0, 6), "up_right": (0, 7),
}
COMBATS = {
    "combat_poing": [(1, 3), (1, 4), (1, 5), (1, 6)],
    "combat_pied": [(2, 3), (2, 4), (2, 5), (2, 6)],
    "combat_touche": [(3, 3), (3, 4), (3, 5), (3, 6)],
}
FPS_COMBAT = 8.0
CLASSIQUE = [8, 6, 6, 6, 6]
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
    """Renvoie {(ligne, colonne): image RGBA recadrée} et la liste des lignes.

    Les poses sont d'abord regroupées avec une marge de 4 px ; si deux poses très
    proches se collent (moins de 8 px d'écart), on réessaie avec une marge plus petite.
    """
    for dilatation in (4, 3, 2):
        resultat = _lire_poses(chemin, fond, unique, dilatation)
        if unique or resultat[1] == CLASSIQUE or est_combat(resultat[1]):
            return resultat
    raise SystemExit("Planche inattendue : %s poses par ligne au lieu de %s (ou [8, 7, 7, 7, 6] "
                     "pour une planche de combat)" % (resultat[1], CLASSIQUE))


def est_combat(nb):
    """Disposition d'une planche de combat : 7 poses sur les lignes 1 a 3."""
    return len(nb) == 5 and nb[:4] == [8, 7, 7, 7] and nb[4] in (6, 7)


def _lire_poses(chemin, fond, unique, dilatation):
    src = Image.open(chemin)
    if fond == "transparent":
        rgba = np.asarray(src.convert("RGBA")).astype(int)
        rgb, premier_plan = rgba[..., :3], rgba[..., 3] > 40
    else:
        rgb = np.asarray(src.convert("RGB")).astype(int)
        premier_plan = ndimage.binary_opening(~masque_fond(rgb, fond), iterations=2)
    # Regroupe les pixels proches (mains, mèches) sans coller deux poses voisines.
    etiquettes, _ = ndimage.label(ndimage.binary_dilation(premier_plan, iterations=dilatation))
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
    p.add_argument("--combat", help="planche de combat dont on ne prend que les poses de combat")
    p.add_argument("--hauteur", type=int, default=HAUTEUR,
                   help="hauteur du personnage en pixels de texture (défaut %d)" % HAUTEUR)
    args = p.parse_args()

    poses, nb = lire_poses(args.planche, args.fond, args.unique)
    combat = not args.unique and est_combat(nb)
    if combat:
        # les poses de combat (bras leves, jambe tendue) ne fixent pas l'echelle
        echelle = args.hauteur / max(pz["h"] for (r, _), pz in poses.items() if r == 0)
    else:
        echelle = args.hauteur / max(pz["h"] for pz in poses.values())
    petites = {rc: reduire(pz["rgba"], echelle) for rc, pz in poses.items()}
    combats = {}
    if combat:
        combats = {nom: images for nom, images in COMBATS.items()}
    elif args.combat:
        # combat pris dans une autre planche, range sur les lignes 10 et suivantes
        autres, nb_c = lire_poses(args.combat, args.fond, False)
        if not est_combat(nb_c):
            raise SystemExit("--combat : %s n'est pas une planche de combat (%s)" % (args.combat, nb_c))
        echelle_c = args.hauteur / max(pz["h"] for (r, _), pz in autres.items() if r == 0)
        for nom, images in COMBATS.items():
            for r, c in images:
                petites[(10 + r, c)] = reduire(autres[(r, c)]["rgba"], echelle_c)
            combats[nom] = [(10 + r, c) for r, c in images]

    if args.unique:
        seule = petites[(0, 0)]
        # Case 0 : debout ; case 1 : la même, 1 px plus haut (rebond de marche).
        petites = {(0, 0): seule, (0, 1): seule}
        rebond = {(0, 1): 1}
        marches = {d: [(0, 1), (0, 0), (0, 1), (0, 0)] for d in MARCHES}
        immobiles = {d: (0, 0) for d in IMMOBILES}
    else:
        rebond = {}
        source = MARCHES_COMBAT if combat else MARCHES
        marches = {d: [a, m, b, m] for d, (a, m, b) in source.items()}
        immobiles = dict(IMMOBILES_COMBAT if combat else IMMOBILES)
        if args.face_en_premier:
            immobiles["up"] = MARCHES["up"][1]
    # on ne garde dans la planche que les poses servies par une animation
    servies = set(immobiles.values()) | {rc for m in marches.values() for rc in m} \
        | {rc for images in combats.values() for rc in images}
    petites = {rc: im for rc, im in petites.items() if rc in servies}
    # les lignes vides (entre la marche et le combat) ne prennent pas de place
    lignes_utiles = sorted({r for r, _ in petites})
    rang = {r: i for i, r in enumerate(lignes_utiles)}
    petites = {(rang[r], c): im for (r, c), im in petites.items()}
    rebond = {(rang[r], c): v for (r, c), v in rebond.items() if r in rang}
    def rangee(rc):
        return (rang[rc[0]], rc[1])
    immobiles = {d: rangee(rc) for d, rc in immobiles.items()}
    marches = {d: [rangee(rc) for rc in m] for d, m in marches.items()}
    combats = {n: [rangee(rc) for rc in m] for n, m in combats.items()}

    # Chaque pose est centree sur la tete : la case doit contenir ce qui depasse de
    # chaque cote (une jambe tendue dans un coup de pied), sinon elle deborde.
    demi = max(max(centre_tete(im), im.shape[1] - centre_tete(im)) for im in petites.values())
    hauteur_max = max(im.shape[0] for im in petites.values())
    cw = 2 * int(np.ceil(demi)) + 8
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
    for nom, images in combats.items():
        anims[nom] = (images, FPS_COMBAT, False)
    tres = os.path.join(dossier, "%s_frames.tres" % args.id)
    ecrire_frames(tres, "res://assets/characters/%s/%s_sheet.png" % (args.id, args.id), cw, ch, anims)
    print("%-18s case %dx%d, perso de %d px%s -> %s" % (args.id, cw, ch, args.hauteur,
                                                         ", combat" if combats else "",
                                                         os.path.relpath(dossier, RACINE)))


if __name__ == "__main__":
    main()
