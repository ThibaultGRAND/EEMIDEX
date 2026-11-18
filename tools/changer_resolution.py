#!/usr/bin/env python3
"""Double (ou halve) la resolution du jeu, d'un seul coup et de facon reversible.

Le projet melange des tailles exprimees en pixels a plusieurs endroits : la
resolution de la fenetre, la taille d'une case, la taille des tuiles dans les
outils, et la taille des polices dans les scenes. Les changer a la main, c'est
en oublier une.

    python3 tools/changer_resolution.py 2      # 320x180 -> 640x360, tuiles 16 -> 32
    python3 tools/changer_resolution.py 0.5    # retour en arriere

Apres l'avoir lance, il faut regenerer les images a la nouvelle taille :
    python3 tools/generer_placeholders.py
    python3 tools/importer_tuiles.py assets/tilesets/brutes
puis rouvrir le projet pour que Godot reimporte.
"""
import os
import re
import sys

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def chemin(rel):
    return os.path.join(RACINE, rel)


def multiplier_entier(texte, motif, facteur, etiquette, rapport):
    """Multiplie le nombre capture par le groupe 1 du motif."""
    def remplace(m):
        avant = int(m.group(1))
        apres = int(round(avant * facteur))
        rapport.append("  %-42s %4d -> %4d" % (etiquette, avant, apres))
        return m.group(0).replace(m.group(1), str(apres), 1)
    nouveau, n = re.subn(motif, remplace, texte, flags=re.M)
    if n == 0:
        rapport.append("  %-42s INTROUVABLE" % etiquette)
    return nouveau


def main(facteur):
    rapport = []

    # --- project.godot : la taille de la fenetre ----------------------------
    p = chemin("project.godot")
    s = open(p).read()
    s = multiplier_entier(s, r"window/size/viewport_width=(\d+)", facteur,
                          "project.godot viewport_width", rapport)
    s = multiplier_entier(s, r"window/size/viewport_height=(\d+)", facteur,
                          "project.godot viewport_height", rapport)
    open(p, "w").write(s)

    # --- zones.gd : la taille d'une case ------------------------------------
    p = chemin("scenes/world/zones.gd")
    s = open(p).read()
    s = multiplier_entier(s, r"const TAILLE_CASE := (\d+)", facteur,
                          "zones.gd TAILLE_CASE", rapport)
    open(p, "w").write(s)

    # --- les outils : la taille d'une tuile ---------------------------------
    for rel in ["tools/generer_placeholders.py", "tools/importer_tuiles.py"]:
        p = chemin(rel)
        s = open(p).read()
        s = multiplier_entier(s, r"^TUILE = (\d+)", facteur, rel + " TUILE", rapport)
        open(p, "w").write(s)

    # --- le sprite du joueur : hauteur d'une image --------------------------
    p = chemin("tools/generer_placeholders.py")
    s = open(p).read()
    s = multiplier_entier(s, r"SPRITE_L, SPRITE_H = \d+, (\d+)", facteur,
                          "placeholder joueur, hauteur", rapport)
    s = multiplier_entier(s, r"SPRITE_L, SPRITE_H = (\d+)", facteur,
                          "placeholder joueur, largeur", rapport)
    open(p, "w").write(s)

    # --- toutes les scenes : la taille des polices --------------------------
    polices = 0
    for dossier, _, fichiers in os.walk(chemin("scenes")):
        for f in fichiers:
            if not f.endswith(".tscn"):
                continue
            p = os.path.join(dossier, f)
            s = open(p).read()
            def remplace(m):
                return "theme_override_font_sizes/font_size = %d" % round(int(m.group(1)) * facteur)
            s, n = re.subn(r"theme_override_font_sizes/font_size = (\d+)", remplace, s)
            polices += n
            open(p, "w").write(s)
    rapport.append("  %-42s %d valeurs" % ("polices des scenes", polices))

    print("Facteur %g" % facteur)
    print("\n".join(rapport))
    print()
    print("A faire maintenant :")
    print("  python3 tools/generer_placeholders.py")
    print("  python3 tools/importer_tuiles.py assets/tilesets/brutes")
    print("  Godot --headless --editor --path . --quit     # reimport")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    sys.exit(main(float(sys.argv[1])) or 0)
