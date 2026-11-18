#!/usr/bin/env python3
"""Ecrit les fiches .tres des alternants de docs/histoire.md.

Le document donne les degats de chaque attaque ; les stats de base viennent
d'un bareme par role, pour qu'aucun alternant ne soit simplement meilleur
qu'un autre.

    python3 tools/creer_alternants.py

Les effets que le combat ne sait pas encore faire (brulure, etourdissement,
esquive, degats aleatoires, recharge, passives) ne sont pas traduits : la
fiche garde l'attaque et ses degats, l'effet reste a implementer. Le detail
complet est dans docs/histoire.md.
"""
import os
import re
import unicodedata

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# role -> pv, attaque, defense, vitesse, taux de capture
ROLES = {
    "equilibre": (26, 11, 11, 11, 45),
    "rapide":    (22, 11,  9, 16, 50),
    "costaud":   (32, 14, 10,  7, 40),
    "defensif":  (28,  8, 16,  9, 42),
    "boss":      (200, 30, 20, 14, 0),
}
COULEURS = {
    "dev":       "Color(0.35, 0.62, 0.86, 1)",
    "design":    "Color(0.85, 0.45, 0.68, 1)",
    "marketing": "Color(0.95, 0.68, 0.25, 1)",
    "product":   "Color(0.52, 0.78, 0.45, 1)",
    "data":      "Color(0.62, 0.52, 0.85, 1)",
    "staff":     "Color(0.78, 0.76, 0.72, 1)",
}

# nom, type, role, [(attaque, puissance, precision, soin, stat, modif, note)]
ALTERNANTS = [
    ("Thigoat", "dev", "costaud", [
        ("Lancer de sauce curry", 20, 95, 0, "", 0, "brulure non implementee"),
        ("Bucheronnage", 0, 100, 0, "attaque", 2, "le bonus dure tout le combat au lieu d'une attaque"),
    ]),
    ("Roulian", "design", "rapide", [
        ("Gros doigt de pied", 22, 95, 0, "", 0, ""),
        ("Mise en biere", 0, 100, 4, "attaque", 1, "cumul non limite pour l'instant"),
    ]),
    ("Matiti", "marketing", "equilibre", [
        ("BKtaque", 28, 85, 0, "", 0, ""),
        ("Attaque Bre-Som", 12, 95, 0, "", 0, "la gene de visee n'est pas implementee"),
    ]),
    ("Palou", "marketing", "rapide", [
        ("La Vilainerie", 18, 100, 0, "", 0, "l'ignorance de la defense n'est pas implementee"),
        ("aquababe", 0, 100, 0, "defense", 2, "passive transformee en attaque de soutien"),
    ]),
    ("Seb", "dev", "equilibre", [
        ("Daronnage", 25, 90, 0, "", 0, ""),
        ("Attaque Diet", 10, 95, 0, "attaque", -2, "le malus dure tout le combat"),
    ]),
    ("Thomasu", "dev", "defensif", [
        ("BTC attaque", 35, 80, 0, "", 0, "le cout en PV n'est pas implemente"),
        ("Crash boursier", 5, 100, 0, "attaque", -1, ""),
    ]),
    ("Paguera", "dev", "defensif", [
        ("Ink God", 26, 90, 0, "", 0, ""),
        ("Insensible a la douleur", 0, 100, 0, "defense", 3, ""),
    ]),
    ("Thibouclier", "dev", "defensif", [
        ("DEVATTACK", 22, 95, 0, "", 0, ""),
        ("Rebond des attaques", 0, 100, 0, "defense", 2, "le renvoi de degats n'est pas implemente"),
    ]),
    ("Tortheo", "marketing", "costaud", [
        ("Tortatack", 25, 90, 0, "", 0, ""),
        ("Carapace en feu", 0, 100, 0, "attaque", 2, "les degats de recul ne sont pas implementes"),
    ]),
    ("Guignome", "product", "equilibre", [
        ("Mario Karttaque", 30, 100, 0, "", 0, "l'attaque est inevitable, donc precision 100"),
        ("Attaque cernes", 8, 95, 0, "vitesse", -2, "l'endormissement n'est pas implemente"),
    ]),
    ("E1000", "dev", "rapide", [
        ("Attaque headshot", 30, 85, 0, "", 0, "le coup critique n'est pas implemente"),
        ("Parfum", 18, 95, 0, "vitesse", -1, ""),
    ]),
    ("CeCissoussou", "marketing", "equilibre", [
        ("Placement produit", 24, 90, 0, "", 0, ""),
        ("Storytelling intense", 16, 95, 0, "vitesse", -1, ""),
    ]),
    ("Nael", "staff", "boss", [
        ("RH attack", 54, 90, 0, "", 0, "les 40 de base plus 35 % du boss"),
        ("EDUSIGN", 32, 95, 0, "attaque", -2, "le blocage des bonus n'est pas implemente"),
    ]),
    ("Tristan", "staff", "boss", [
        ("Portes ouvertes", 48, 90, 0, "", 0, "les 36 de base plus 35 % du boss"),
        ("Invisibilite", 15, 100, 0, "defense", 3, "l'esquive n'est pas implementee"),
    ]),
]


def identifiant(texte):
    sans_accent = "".join(c for c in unicodedata.normalize("NFD", texte)
                          if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", sans_accent.lower()).strip("_")


def ecrire(chemin, contenu):
    complet = os.path.join(RACINE, chemin)
    os.makedirs(os.path.dirname(complet), exist_ok=True)
    open(complet, "w").write(contenu)


def main():
    for nom, type_gone, role, attaques in ALTERNANTS:
        base = identifiant(nom)
        chemins = []
        for i, (titre, puissance, precision, soin, stat, modif, note) in enumerate(attaques):
            id_attaque = "%s_%d" % (base, i + 1)
            description = note if note else "Attaque de %s." % nom
            ecrire("data/moves/%s.tres" % id_attaque,
'''[gd_resource type="Resource" script_class="MoveData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/move_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"%s"
display_name = "%s"
description = "%s"
type = &"%s"
cible = %d
puissance = %d
precision = %d
stat_modifiee = &"%s"
modificateur = %d
soin = %d
''' % (id_attaque, titre, description, type_gone,
       1 if puissance == 0 and stat != "" else 0,
       puissance, precision, stat, modif, soin))
            chemins.append("data/moves/%s.tres" % id_attaque)

        pv, att, dfn, vit, capture = ROLES[role]
        ecrire("data/gones/%s.tres" % base,
'''[gd_resource type="Resource" script_class="GoneData" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/data/gone_data.gd" id="1_script"]
[ext_resource type="Resource" path="res://%s" id="2_base"]
[ext_resource type="Resource" path="res://%s" id="3_signature"]

[resource]
script = ExtResource("1_script")
id = &"%s"
display_name = "%s"
description = "%s, alternant %s de la promo."
type = &"%s"
couleur = %s
base_pv = %d
base_attaque = %d
base_defense = %d
base_vitesse = %d
taux_capture = %d
sauvage = %s
consentement_recu = true
note_consentement = "Accord note dans docs/consentement.md."
attaque_de_base = ExtResource("2_base")
pouvoir_signature = ExtResource("3_signature")
''' % (chemins[0], chemins[1], base, nom, nom, type_gone, type_gone,
       COULEURS[type_gone], pv, att, dfn, vit, capture,
       "false" if role == "boss" else "true"))
        print("  %-14s %-10s %-10s PV%3d ATT%2d DEF%2d VIT%2d  %s"
              % (nom, type_gone, role, pv, att, dfn, vit,
                 " / ".join(a[0] for a in attaques)))
    print()
    print("%d alternants ecrits dans data/gones, %d attaques dans data/moves."
          % (len(ALTERNANTS), sum(len(a[3]) for a in ALTERNANTS)))


if __name__ == "__main__":
    main()
