#!/usr/bin/env python3
"""Fabrique les images placeholder du projet : le jeu de tuiles et le sprite du joueur.

Ces images sont volontairement moches. Elles existent pour que la carte tourne tant que
l'equipe n'a pas dessine les vraies tuiles. Le jour ou les vraies arrivent, on remplace
les PNG en gardant la meme grille : les cartes ne bougent pas.

Usage :  python3 tools/generer_placeholders.py
Sortie :  assets/tilesets/placeholder_tuiles.png
          assets/tilesets/placeholder_tuiles.tres
          assets/sprites/placeholder_joueur.png
"""
import os
import struct
import zlib

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

## Taille finale d'une tuile, alignee sur celle du jeu.
TUILE = 16
## Les tuiles sont dessinees a cette taille, puis agrandies d'un facteur
## entier. Les coordonnees des rectangles n'ont ainsi jamais a changer.
BASE = 16
FACTEUR = max(1, TUILE // BASE)

# --- Palette commune, voir docs/tuiles-inventaire.md -------------------------
P = {
    "contour":   (0x2a, 0x24, 0x20),
    "pave":      (0x8a, 0x83, 0x78),
    "pave2":     (0x6e, 0x67, 0x5d),
    "dalle":     (0xb9, 0xb2, 0xa3),
    "dalle2":    (0x9a, 0x94, 0x88),
    "terre":     (0x9c, 0x84, 0x65),
    "terre2":    (0x7d, 0x6a, 0x51),
    "herbe":     (0x4f, 0x8a, 0x46),
    "herbe2":    (0x3a, 0x6b, 0x36),
    "herbe3":    (0x68, 0xa8, 0x5c),
    "eau":       (0x3f, 0x6f, 0x93),
    "eau2":      (0x2c, 0x55, 0x74),
    "eau3":      (0x5b, 0x8f, 0xb0),
    "toit":      (0xb4, 0x55, 0x3a),
    "toit2":     (0x8e, 0x3f, 0x2c),
    "pierre":    (0xd8, 0xc8, 0x9d),
    "pierre2":   (0xb8, 0xa6, 0x7c),
    "creme":     (0xe3, 0xd6, 0xbd),
    "creme2":    (0xc4, 0xb8, 0x9c),
    "metal":     (0x5a, 0x5f, 0x66),
    "metal2":    (0x3d, 0x42, 0x48),
    "bois":      (0x8a, 0x62, 0x39),
    "bois2":     (0x6b, 0x4a, 0x2a),
    "rouge":     (0xdc, 0x58, 0x58),
    "bleu":      (0x49, 0x83, 0xc6),
    "violet":    (0x86, 0x66, 0xb9),
    "or":        (0xef, 0xbd, 0x54),
    "blanc":     (0xf0, 0xec, 0xe0),
    "peau":      (0xf5, 0xd1, 0xab),
    "jean":      (0x3a, 0x40, 0x5a),
}
VIDE = (0, 0, 0, 0)


def rgba(nom, a=255):
    r, g, b = P[nom]
    return (r, g, b, a)


class Image:
    def __init__(self, largeur, hauteur):
        self.l = largeur
        self.h = hauteur
        self.px = [[VIDE] * largeur for _ in range(hauteur)]

    def point(self, x, y, couleur):
        if 0 <= x < self.l and 0 <= y < self.h:
            self.px[y][x] = couleur

    def rect(self, x, y, l, h, couleur):
        for j in range(y, y + h):
            for i in range(x, x + l):
                self.point(i, j, couleur)

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
        os.makedirs(os.path.dirname(chemin), exist_ok=True)
        with open(chemin, "wb") as f:
            f.write(png)


# --- Petit generateur pseudo-aleatoire, pour que le resultat soit reproductible
class Des:
    def __init__(self, graine=1234):
        self.etat = graine

    def suivant(self, n):
        self.etat = (self.etat * 1103515245 + 12345) & 0x7fffffff
        return self.etat % n


# =============================================================================
# Le jeu de tuiles : 8 colonnes sur 4 lignes, tuiles de 16 px
# =============================================================================
# Ligne 0 : sols            Ligne 1 : sols porteurs d'une regle de jeu
# Ligne 2 : volumes         Ligne 3 : objets
ATLAS_COLONNES = 8
ATLAS_LIGNES = 4


def grain(img, ox, oy, base, tache, densite, des):
    """Remplit une tuile d'une couleur de base piquetee, pour eviter l'aplat uni."""
    img.rect(ox, oy, BASE, BASE, base)
    for _ in range(densite):
        img.point(ox + des.suivant(BASE), oy + des.suivant(BASE), tache)


def joints(img, ox, oy, couleur, pas=4):
    for y in range(0, BASE, pas):
        for x in range(BASE):
            img.point(ox + x, oy + y, couleur)
    for x in range(0, BASE, pas):
        for y in range(BASE):
            img.point(ox + x, oy + y, couleur)


def dessiner_tuiles(img, des):
    def t(cx, cy):
        return cx * BASE, cy * BASE

    # --- Ligne 0 : les sols --------------------------------------------------
    ox, oy = t(0, 0)                                    # pave
    grain(img, ox, oy, rgba("pave"), rgba("pave2"), 26, des)
    joints(img, ox, oy, rgba("pave2"))

    ox, oy = t(1, 0)                                    # pave use
    grain(img, ox, oy, rgba("pave"), rgba("dalle"), 20, des)
    joints(img, ox, oy, rgba("pave2"))

    ox, oy = t(2, 0)                                    # dalle de quai
    grain(img, ox, oy, rgba("dalle"), rgba("dalle2"), 10, des)
    joints(img, ox, oy, rgba("dalle2"), 8)

    ox, oy = t(3, 0)                                    # terre
    grain(img, ox, oy, rgba("terre"), rgba("terre2"), 34, des)

    ox, oy = t(4, 0)                                    # herbe courte
    grain(img, ox, oy, rgba("herbe"), rgba("herbe2"), 30, des)
    for _ in range(8):
        x, y = ox + des.suivant(BASE), oy + des.suivant(BASE - 2)
        img.point(x, y, rgba("herbe3"))
        img.point(x, y + 1, rgba("herbe3"))

    ox, oy = t(5, 0)                                    # herbe haute
    grain(img, ox, oy, rgba("herbe2"), rgba("herbe"), 20, des)
    for _ in range(16):
        x, y = ox + des.suivant(BASE), oy + 3 + des.suivant(BASE - 6)
        for k in range(4):
            img.point(x, y + k, rgba("herbe3") if k < 2 else rgba("herbe"))

    ox, oy = t(6, 0)                                    # eau
    grain(img, ox, oy, rgba("eau"), rgba("eau2"), 14, des)
    for y in range(2, BASE, 5):
        for x in range(1, BASE - 3, 6):
            img.rect(ox + x, oy + y, 3, 1, rgba("eau3"))

    ox, oy = t(7, 0)                                    # sable de berge
    grain(img, ox, oy, rgba("pierre"), rgba("pierre2"), 28, des)

    # --- Ligne 1 : les sols qui portent une regle ----------------------------
    ox, oy = t(0, 1)                                    # soin
    grain(img, ox, oy, rgba("dalle"), rgba("dalle2"), 8, des)
    img.rect(ox + 6, oy + 3, 4, 10, rgba("rouge"))
    img.rect(ox + 3, oy + 6, 10, 4, rgba("rouge"))

    ox, oy = t(1, 1)                                    # boutique
    grain(img, ox, oy, rgba("dalle"), rgba("dalle2"), 8, des)
    img.rect(ox + 3, oy + 4, 10, 8, rgba("bleu"))
    img.rect(ox + 5, oy + 6, 6, 4, rgba("blanc"))

    ox, oy = t(2, 1)                                    # entrainement
    grain(img, ox, oy, rgba("dalle"), rgba("dalle2"), 8, des)
    img.rect(ox + 3, oy + 3, 10, 10, rgba("violet"))
    img.rect(ox + 6, oy + 6, 4, 4, rgba("or"))

    ox, oy = t(3, 1)                                    # bouche de traboule
    grain(img, ox, oy, rgba("dalle"), rgba("dalle2"), 6, des)
    img.rect(ox + 3, oy + 2, 10, 12, rgba("contour"))
    img.rect(ox + 5, oy + 5, 6, 9, (12, 10, 14, 255))

    ox, oy = t(4, 1)                                    # ressource au sol
    grain(img, ox, oy, rgba("herbe"), rgba("herbe2"), 24, des)
    img.rect(ox + 6, oy + 7, 5, 5, rgba("or"))
    img.rect(ox + 7, oy + 5, 3, 3, rgba("toit"))

    ox, oy = t(5, 1)                                    # sortie de zone
    grain(img, ox, oy, rgba("pave"), rgba("pave2"), 16, des)
    img.rect(ox + 7, oy + 3, 2, 10, rgba("blanc"))
    img.rect(ox + 5, oy + 5, 6, 2, rgba("blanc"))

    ox, oy = t(6, 1)                                    # bord d'eau
    grain(img, ox, oy, rgba("eau"), rgba("eau2"), 10, des)
    img.rect(ox, oy, BASE, 5, rgba("pierre"))
    img.rect(ox, oy + 5, BASE, 2, rgba("pierre2"))

    ox, oy = t(7, 1)                                    # ballast
    grain(img, ox, oy, rgba("metal"), rgba("metal2"), 40, des)

    # --- Ligne 2 : les volumes ----------------------------------------------
    ox, oy = t(0, 2)                                    # mur de pierre, bas
    grain(img, ox, oy, rgba("pierre2"), rgba("pierre"), 14, des)
    joints(img, ox, oy, rgba("contour"), 8)

    ox, oy = t(1, 2)                                    # mur de pierre, haut
    grain(img, ox, oy, rgba("pierre"), rgba("pierre2"), 14, des)
    joints(img, ox, oy, rgba("contour"), 8)
    img.rect(ox, oy, BASE, 2, rgba("contour"))

    ox, oy = t(2, 2)                                    # facade, rez-de-chaussee
    grain(img, ox, oy, rgba("pierre"), rgba("pierre2"), 10, des)
    img.rect(ox + 5, oy + 4, 6, 12, rgba("bois2"))
    img.rect(ox + 6, oy + 6, 4, 10, rgba("bois"))

    ox, oy = t(3, 2)                                    # facade, etage
    grain(img, ox, oy, rgba("pierre"), rgba("pierre2"), 10, des)
    img.rect(ox + 4, oy + 4, 8, 8, rgba("contour"))
    img.rect(ox + 5, oy + 5, 6, 6, rgba("eau3"))

    ox, oy = t(4, 2)                                    # toit de tuiles
    grain(img, ox, oy, rgba("toit"), rgba("toit2"), 18, des)
    for y in range(0, BASE, 4):
        img.rect(ox, oy + y, BASE, 1, rgba("toit2"))

    ox, oy = t(5, 2)                                    # arbre, tronc
    img.rect(ox + 6, oy, 4, BASE, rgba("bois2"))
    img.rect(ox + 7, oy, 2, BASE, rgba("bois"))

    ox, oy = t(6, 2)                                    # arbre, houppier
    for y in range(BASE):
        for x in range(BASE):
            dx, dy = x - 7.5, y - 8.0
            if dx * dx + dy * dy < 56:
                img.point(ox + x, oy + y, rgba("herbe2"))
            elif dx * dx + dy * dy < 68:
                img.point(ox + x, oy + y, rgba("contour"))
    for _ in range(18):
        img.point(ox + 3 + des.suivant(10), oy + 3 + des.suivant(10), rgba("herbe"))

    ox, oy = t(7, 2)                                    # parapet de quai
    img.rect(ox, oy + 4, BASE, 10, rgba("pierre2"))
    img.rect(ox, oy + 4, BASE, 2, rgba("pierre"))
    img.rect(ox, oy + 13, BASE, 1, rgba("contour"))

    # --- Ligne 3 : les objets ------------------------------------------------
    ox, oy = t(0, 3)                                    # lampadaire, pied
    img.rect(ox + 7, oy, 2, BASE, rgba("metal2"))
    img.rect(ox + 5, oy + 13, 6, 3, rgba("metal"))

    ox, oy = t(1, 3)                                    # lampadaire, tete
    img.rect(ox + 7, oy + 6, 2, 10, rgba("metal2"))
    img.rect(ox + 5, oy + 2, 6, 5, rgba("or"))
    img.rect(ox + 4, oy + 1, 8, 2, rgba("metal"))

    ox, oy = t(2, 3)                                    # banc
    img.rect(ox + 2, oy + 7, 12, 3, rgba("bois"))
    img.rect(ox + 2, oy + 10, 12, 2, rgba("bois2"))
    img.rect(ox + 3, oy + 12, 2, 3, rgba("metal2"))
    img.rect(ox + 11, oy + 12, 2, 3, rgba("metal2"))

    ox, oy = t(3, 3)                                    # borne d'entrainement
    img.rect(ox + 4, oy + 4, 8, 11, rgba("violet"))
    img.rect(ox + 5, oy + 6, 6, 4, rgba("or"))
    img.rect(ox + 4, oy + 14, 8, 2, rgba("contour"))

    ox, oy = t(4, 3)                                    # porche de traboule
    img.rect(ox + 1, oy, 14, BASE, rgba("pierre2"))
    img.rect(ox + 4, oy + 3, 8, 13, rgba("contour"))
    img.rect(ox + 5, oy + 5, 6, 11, (10, 8, 12, 255))

    ox, oy = t(5, 3)                                    # enseigne de boutique
    img.rect(ox + 7, oy + 6, 2, 10, rgba("bois2"))
    img.rect(ox + 2, oy + 1, 12, 6, rgba("bleu"))
    img.rect(ox + 4, oy + 3, 8, 2, rgba("blanc"))

    ox, oy = t(6, 3)                                    # croix de soin
    img.rect(ox + 7, oy + 8, 2, 8, rgba("metal2"))
    img.rect(ox + 3, oy + 1, 10, 8, rgba("blanc"))
    img.rect(ox + 7, oy + 2, 2, 6, rgba("rouge"))
    img.rect(ox + 5, oy + 4, 6, 2, rgba("rouge"))

    ox, oy = t(7, 3)                                    # statue du gardien
    img.rect(ox + 4, oy + 12, 8, 4, rgba("dalle2"))
    img.rect(ox + 5, oy + 3, 6, 10, rgba("dalle"))
    img.rect(ox + 6, oy, 4, 4, rgba("pierre"))
    img.rect(ox + 3, oy + 5, 10, 2, rgba("dalle2"))


# =============================================================================
# Le sprite du joueur : 2 images de marche x 4 directions, cases de 16 x 24
# =============================================================================
SPRITE_L, SPRITE_H = 16, 24
# L'ordre des lignes doit correspondre a Joueur.Direction dans player.gd
DIRECTIONS = ["bas", "haut", "gauche", "droite"]


def dessiner_perso(img, ox, oy, direction, pas):
    peau, jean, pull = rgba("peau"), rgba("jean"), rgba("bleu")
    bonnet, ctr = rgba("toit"), rgba("contour")

    # jambes, decalees selon l'image de marche
    gauche_avant = (pas == 0)
    img.rect(ox + 4, oy + 18, 3, 6 if gauche_avant else 5, jean)
    img.rect(ox + 9, oy + 18, 3, 5 if gauche_avant else 6, jean)
    img.rect(ox + 4, oy + 23 if gauche_avant else oy + 22, 3, 1, ctr)
    img.rect(ox + 9, oy + 22 if gauche_avant else oy + 23, 3, 1, ctr)

    # buste
    img.rect(ox + 3, oy + 11, 10, 8, pull)
    img.rect(ox + 3, oy + 11, 10, 1, ctr)
    if direction == "gauche":
        img.rect(ox + 2, oy + 12, 2, 5, pull)
    elif direction == "droite":
        img.rect(ox + 12, oy + 12, 2, 5, pull)
    else:
        img.rect(ox + 2, oy + 12, 2, 5, pull)
        img.rect(ox + 12, oy + 12, 2, 5, pull)

    # tete
    img.rect(ox + 4, oy + 4, 8, 8, peau)
    img.rect(ox + 3, oy + 1, 10, 4, bonnet)
    img.rect(ox + 3, oy + 1, 10, 1, ctr)

    # visage, selon la direction
    if direction == "bas":
        img.rect(ox + 5, oy + 7, 2, 2, ctr)
        img.rect(ox + 9, oy + 7, 2, 2, ctr)
        img.rect(ox + 5, oy + 10, 6, 1, ctr)       # moustache
    elif direction == "gauche":
        img.rect(ox + 4, oy + 7, 2, 2, ctr)
        img.rect(ox + 4, oy + 10, 4, 1, ctr)
    elif direction == "droite":
        img.rect(ox + 10, oy + 7, 2, 2, ctr)
        img.rect(ox + 8, oy + 10, 4, 1, ctr)
    # de dos : pas de visage

    # contour bas
    img.rect(ox + 3, oy + 18, 1, 4, ctr)
    img.rect(ox + 12, oy + 18, 1, 4, ctr)


def generer_joueur(chemin):
    img = Image(SPRITE_L * 2, SPRITE_H * len(DIRECTIONS))
    for ligne, direction in enumerate(DIRECTIONS):
        for pas in range(2):
            dessiner_perso(img, pas * SPRITE_L, ligne * SPRITE_H, direction, pas)
    img = agrandir(img, FACTEUR)
    img.ecrire(chemin)
    return img.l, img.h


# =============================================================================
# La ressource TileSet, generee en meme temps pour ne jamais desynchroniser
# =============================================================================
# Tuiles hautes : elles doivent se trier comme si elles etaient a la hauteur de
# leur base, sinon le joueur passe devant un toit situe au-dessus de lui.
Y_SORT = {
    (1, 2): 32, (6, 2): 32, (1, 3): 32,       # mur haut, houppier, lanterne
    (2, 2): 16, (3, 2): 16, (4, 2): 16, (5, 2): 16, (7, 2): 16,
    (0, 2): 16, (0, 3): 16, (2, 3): 16, (3, 3): 16,
    (4, 3): 16, (5, 3): 16, (6, 3): 16, (7, 3): 16,
}


def generer_tileset(chemin_tres, chemin_png):
    lignes = [
        '[gd_resource type="TileSet" load_steps=3 format=3]',
        '',
        '[ext_resource type="Texture2D" path="res://%s" id="1_tex"]' % chemin_png,
        '',
        '[sub_resource type="TileSetAtlasSource" id="TileSetAtlasSource_placeholder"]',
        'texture = ExtResource("1_tex")',
        'texture_region_size = Vector2i(%d, %d)' % (TUILE, TUILE),
    ]
    for cy in range(ATLAS_LIGNES):
        for cx in range(ATLAS_COLONNES):
            lignes.append('%d:%d/0 = 0' % (cx, cy))
            if (cx, cy) in Y_SORT:
                lignes.append('%d:%d/0/y_sort_origin = %d' % (cx, cy, Y_SORT[(cx, cy)]))
    lignes += [
        '',
        '[resource]',
        'tile_size = Vector2i(%d, %d)' % (TUILE, TUILE),
        'sources/0 = SubResource("TileSetAtlasSource_placeholder")',
        '',
    ]
    with open(os.path.join(RACINE, chemin_tres), 'w') as f:
        f.write('\n'.join(lignes))


def agrandir(img, facteur):
    if facteur <= 1:
        return img
    out = Image(img.l * facteur, img.h * facteur)
    for y in range(out.h):
        for x in range(out.l):
            out.px[y][x] = img.px[y // facteur][x // facteur]
    return out


def main():
    des = Des(20261118)
    atlas = Image(ATLAS_COLONNES * BASE, ATLAS_LIGNES * BASE)
    dessiner_tuiles(atlas, des)
    atlas = agrandir(atlas, FACTEUR)
    png_tuiles = 'assets/tilesets/placeholder_tuiles.png'
    atlas.ecrire(os.path.join(RACINE, png_tuiles))
    print('tuiles   : %s  (%d x %d, %d tuiles)'
          % (png_tuiles, atlas.l, atlas.h, ATLAS_COLONNES * ATLAS_LIGNES))

    generer_tileset('assets/tilesets/placeholder_tuiles.tres', png_tuiles)
    print('tileset  : assets/tilesets/placeholder_tuiles.tres')

    png_joueur = 'assets/sprites/placeholder_joueur.png'
    l, h = generer_joueur(os.path.join(RACINE, png_joueur))
    print('joueur   : %s  (%d x %d, 2 images x %d directions)'
          % (png_joueur, l, h, len(DIRECTIONS)))


if __name__ == '__main__':
    main()
