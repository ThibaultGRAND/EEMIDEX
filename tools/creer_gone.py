#!/usr/bin/env python3
"""Fabrique les fiches .tres des Gones a partir des reponses au formulaire.

Creer douze Gones a la main dans l'inspecteur, c'est douze occasions de se
tromper et des stats posees au hasard. Ce script lit un fichier de reponses et
ecrit les .tres correspondants, avec des stats tirees d'un bareme commun.

    python3 tools/creer_gone.py data/reponses_promo.txt

Format du fichier, une ligne par etudiant, les champs separes par des barres :

    prenom | archetype | nom du pouvoir | ce que fait le pouvoir | type

  archetype : rapide, costaud, defensif, equilibre
  type      : libre (promo, ville, bouchon, colline...), sert aux affinites

Les lignes vides et celles qui commencent par # sont ignorees.

IMPORTANT : le script ecrit toujours consentement_recu = false. C'est a la main,
fiche par fiche, qu'on le passe a true une fois l'accord ecrit recu. Voir
docs/consentement.md. Un Gone sans accord est charge mais n'apparait jamais.
"""
import os
import re
import sys
import unicodedata

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Bareme : chaque archetype repartit le meme total de points, autrement
# certains Gones seraient simplement meilleurs que d'autres.
ARCHETYPES = {
    "equilibre": {"pv": 26, "attaque": 11, "defense": 11, "vitesse": 11, "capture": 45},
    "rapide":    {"pv": 22, "attaque": 11, "defense": 9,  "vitesse": 16, "capture": 50},
    "costaud":   {"pv": 32, "attaque": 14, "defense": 10, "vitesse": 7,  "capture": 40},
    "defensif":  {"pv": 28, "attaque": 8,  "defense": 16, "vitesse": 9,  "capture": 42},
}

# Couleur de repli, tant que le sprite n'est pas dessine. Une teinte par
# archetype, pour qu'on distingue les Gones en jeu des le premier essai.
COULEURS = {
    "equilibre": "Color(0.55, 0.65, 0.78, 1)",
    "rapide":    "Color(0.49, 0.78, 0.56, 1)",
    "costaud":   "Color(0.85, 0.52, 0.36, 1)",
    "defensif":  "Color(0.62, 0.55, 0.76, 1)",
}

PUISSANCE_POUVOIR = {"equilibre": 18, "rapide": 15, "costaud": 22, "defensif": 14}
PRECISION_POUVOIR = {"equilibre": 90, "rapide": 95, "costaud": 80, "defensif": 95}


def identifiant(texte):
    """Prenom -> identifiant de fichier : sans accent, sans espace, en minuscules."""
    sans_accent = "".join(c for c in unicodedata.normalize("NFD", texte)
                          if unicodedata.category(c) != "Mn")
    return re.sub(r"[^a-z0-9]+", "_", sans_accent.lower()).strip("_")


def echapper(texte):
    return texte.replace("\\", "\\\\").replace('"', '\\"')


def ecrire_pouvoir(id_gone, nom, description, archetype, type_gone):
    chemin = "data/moves/%s_pouvoir.tres" % id_gone
    complet = os.path.join(RACINE, chemin)
    if os.path.exists(complet):
        return chemin, False
    contenu = """[gd_resource type="Resource" script_class="MoveData" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/data/move_data.gd" id="1_script"]

[resource]
script = ExtResource("1_script")
id = &"%s_pouvoir"
display_name = "%s"
description = "%s"
type = &"%s"
cible = 0
puissance = %d
precision = %d
""" % (id_gone, echapper(nom), echapper(description), type_gone,
       PUISSANCE_POUVOIR[archetype], PRECISION_POUVOIR[archetype])
    os.makedirs(os.path.dirname(complet), exist_ok=True)
    open(complet, "w").write(contenu)
    return chemin, True


def ecrire_gone(prenom, archetype, pouvoir_nom, pouvoir_desc, type_gone):
    id_gone = identifiant(prenom)
    stats = ARCHETYPES[archetype]
    chemin_pouvoir, cree = ecrire_pouvoir(id_gone, pouvoir_nom, pouvoir_desc,
                                          archetype, type_gone)
    chemin = "data/gones/%s.tres" % id_gone
    contenu = """[gd_resource type="Resource" script_class="GoneData" load_steps=4 format=3]

[ext_resource type="Script" path="res://scripts/data/gone_data.gd" id="1_script"]
[ext_resource type="Resource" path="res://data/moves/regard_qui_tue.tres" id="2_base"]
[ext_resource type="Resource" path="res://%s" id="3_signature"]

[resource]
script = ExtResource("1_script")
id = &"%s"
display_name = "%s"
description = "%s"
type = &"%s"
couleur = %s
base_pv = %d
base_attaque = %d
base_defense = %d
base_vitesse = %d
taux_capture = %d
sauvage = true
consentement_recu = false
note_consentement = "Accord ecrit a recevoir. Voir docs/consentement.md."
attaque_de_base = ExtResource("2_base")
pouvoir_signature = ExtResource("3_signature")
""" % (chemin_pouvoir, id_gone, echapper(prenom),
       echapper("%s, de la promo. Archetype %s." % (prenom, archetype)),
       type_gone, COULEURS[archetype], stats["pv"], stats["attaque"],
       stats["defense"], stats["vitesse"], stats["capture"])
    complet = os.path.join(RACINE, chemin)
    os.makedirs(os.path.dirname(complet), exist_ok=True)
    open(complet, "w").write(contenu)
    return chemin, chemin_pouvoir, cree


def main(fichier):
    if not os.path.exists(fichier):
        print("Fichier introuvable : %s" % fichier)
        return 1
    cree = 0
    for numero, ligne in enumerate(open(fichier), 1):
        ligne = ligne.strip()
        if not ligne or ligne.startswith("#"):
            continue
        champs = [c.strip() for c in ligne.split("|")]
        if len(champs) < 4:
            print("  ligne %d ignoree, il faut au moins 4 champs : %s" % (numero, ligne))
            continue
        prenom, archetype, pouvoir_nom, pouvoir_desc = champs[:4]
        type_gone = champs[4] if len(champs) > 4 else "neutre"
        if archetype not in ARCHETYPES:
            print("  ligne %d : archetype inconnu '%s', connus : %s"
                  % (numero, archetype, ", ".join(ARCHETYPES)))
            continue
        g, p, pouvoir_neuf = ecrire_gone(prenom, archetype, pouvoir_nom,
                                         pouvoir_desc, type_gone)
        print("  %-28s %s%s" % (prenom, g, "  + " + p if pouvoir_neuf else ""))
        cree += 1
    print()
    print("%d Gone(s) ecrit(s), tous avec consentement_recu = false." % cree)
    print("Passer a true fiche par fiche une fois l'accord ecrit recu,")
    print("et le noter dans docs/consentement.md.")
    return 0


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    sys.exit(main(sys.argv[1]))
