#!/usr/bin/env python3
"""Relit scenes/world/zones.gd et verifie que les plans tiennent debout.

    python3 tools/verifier_plans.py

Ce que le script controle, zone par zone :

  1. chaque ligne du plan fait exactement LARGEUR caracteres ;
  2. tous les caracteres employes existent dans SOLS ;
  3. tout caractere de sortie present dans le plan est decrit dans "sorties",
     et reciproquement ;
  4. la case d'arrivee annoncee par une sortie tombe dans la zone visee, y est
     traversable, et n'est pas elle-meme une sortie (sinon le joueur boucle) ;
  5. la case de depart est traversable, les PNJ demarrent sur un sol qui les
     accepte, et il y a 0 ou 2 passages sous les voies ("T") ;
  6. chaque zone a bien sa ressource, au moins deux cases "R", et de l'herbe
     haute si elle compte des rencontres ;
  7. tout ce qui compte (sorties, R, S, B, M, X, T) est joignable a pied depuis
     la case de depart.

Sortie : la liste des anomalies, et un code de retour non nul s'il y en a.
"""
import os
import re
import sys
from collections import deque

RACINE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZONES_GD = os.path.join(RACINE, "scenes/world/zones.gd")

## Caracteres qui ouvrent sur une autre zone.
SORTIES = "123"
## Ce qui doit rester joignable depuis le depart.
REMARQUABLES = "RSBMXT" + SORTIES


def verifier_pas_sous_un_volume(nom, plan, cases, erreur):
    """Une case coiffee par le haut d'un batiment cache ce qui s'y trouve.

    world.gd pose la partie haute d'un mur ou d'un arbre sur la case du dessus,
    et le tri en profondeur la dessine devant le joueur : on y est invisible.
    Interdit donc pour un depart ou une arrivee de zone.
    """
    for etiquette, (x, y) in cases:
        if y + 1 < len(plan) and plan[y + 1][x] in "#t":
            erreur("%s : %s en (%d,%d) est coiffe par un '%s', on y serait cache"
                   % (nom, etiquette, x, y, plan[y + 1][x]))


def lire_constante_chaine(source, nom):
    m = re.search(r'const %s := "([^"]*)"' % nom, source)
    if not m:
        raise SystemExit("constante %s introuvable dans zones.gd" % nom)
    return m.group(1)


def lire_constante_entier(source, nom):
    m = re.search(r"const %s := (\d+)" % nom, source)
    if not m:
        raise SystemExit("constante %s introuvable dans zones.gd" % nom)
    return int(m.group(1))


def lire_sols(source):
    """Les clefs du dictionnaire SOLS."""
    m = re.search(r"const SOLS := \{(.*?)\n\}", source, re.S)
    if not m:
        raise SystemExit("dictionnaire SOLS introuvable dans zones.gd")
    return set(re.findall(r'^\t"(.)":', m.group(1), re.M))


def lire_zones(source):
    """id de zone -> dictionnaire des champs qui nous interessent."""
    corps = re.search(r"const ZONES := \{\n(.*?)\n\}\n", source, re.S)
    if not corps:
        raise SystemExit("dictionnaire ZONES introuvable dans zones.gd")
    texte = corps.group(1)

    zones = {}
    blocs = re.split(r'\n\t&"', texte)
    for bloc in blocs:
        bloc = bloc.lstrip('\t&"')
        m = re.match(r"(\w+)\"", bloc)
        if not m:
            continue
        nom = m.group(1)
        plan = re.findall(r'^\t\t\t"(.*)",$', bloc, re.M)
        depart = re.search(r'"depart": Vector2i\((\d+), (\d+)\)', bloc)
        sorties = {}
        ligne_sorties = re.search(r'"sorties": \{(.*?)\},', bloc)
        if ligne_sorties:
            for c, cible, x, y in re.findall(
                    r'"(.)": \["(\w+)", (\d+), (\d+)\]', ligne_sorties.group(1)):
                sorties[c] = (cible, int(x), int(y))
        pnj = [(int(x), int(y))
               for x, y in re.findall(r'"case": Vector2i\((\d+), (\d+)\)', bloc)]
        ressource = re.search(r'"ressource": &"(\w+)"', bloc)
        zones[nom] = {
            "plan": plan,
            "depart": (int(depart.group(1)), int(depart.group(2))) if depart else None,
            "sorties": sorties,
            "pnj": pnj,
            "ressource": ressource.group(1) if ressource else "",
            "tuile": re.search(r'"tuile_ressource": Vector2i\(\d+, \d+\)', bloc) is not None,
            "rencontres": re.findall(r'&"(generique_\w+)"', bloc),
        }
    return zones


def case(plan, x, y):
    if y < 0 or y >= len(plan):
        return "#"
    if x < 0 or x >= len(plan[y]):
        return "#"
    return plan[y][x]


def joignables(plan, depart, bloquants):
    """Toutes les cases atteignables a pied depuis le depart."""
    vus = {depart}
    file = deque([depart])
    while file:
        x, y = file.popleft()
        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            suivant = (x + dx, y + dy)
            if suivant in vus:
                continue
            if case(plan, suivant[0], suivant[1]) in bloquants:
                continue
            vus.add(suivant)
            # Une sortie quitte la zone : on ne poursuit pas au-dela.
            if case(plan, suivant[0], suivant[1]) not in SORTIES:
                file.append(suivant)
    return vus


def main():
    source = open(ZONES_GD).read()
    largeur = lire_constante_entier(source, "LARGEUR")
    bloquants = lire_constante_chaine(source, "BLOQUANTS")
    sols_pnj = lire_constante_chaine(source, "SOLS_PNJ")
    sols = lire_sols(source)
    zones = lire_zones(source)

    anomalies = []

    def rater(zone, texte):
        anomalies.append("%-16s %s" % (zone, texte))

    print("%d zones lues dans %s" % (len(zones), os.path.relpath(ZONES_GD, RACINE)))
    for nom, z in zones.items():
        plan = z["plan"]
        print("  %-16s %2d lignes x %d colonnes" % (nom, len(plan), largeur))

        # 1. largeur des lignes
        for y, ligne in enumerate(plan):
            if len(ligne) != largeur:
                rater(nom, "ligne %d : %d caracteres au lieu de %d"
                      % (y, len(ligne), largeur))

        # 2. caracteres connus
        for y, ligne in enumerate(plan):
            for x, c in enumerate(ligne):
                if c not in sols:
                    rater(nom, "ligne %d colonne %d : caractere '%s' absent de SOLS"
                          % (y, x, c))

        # 2 bis. ni le depart ni une arrivee ne doivent etre coiffes
        verifier_pas_sous_un_volume(
            nom, plan, [("depart", z["depart"])], lambda t: anomalies.append(t))

        # 3. sorties declarees et sorties dessinees
        dessinees = {c for ligne in plan for c in ligne if c in SORTIES}
        declarees = set(z["sorties"])
        for c in dessinees - declarees:
            rater(nom, "sortie '%s' dessinee mais absente de \"sorties\"" % c)
        for c in declarees - dessinees:
            rater(nom, "sortie '%s' declaree mais absente du plan" % c)

        # 4. les arrivees se repondent
        for c, (cible, x, y) in z["sorties"].items():
            if cible not in zones:
                rater(nom, "sortie '%s' vers la zone inconnue %s" % (c, cible))
                continue
            plan_cible = zones[cible]["plan"]
            if y >= len(plan_cible) or x >= largeur:
                rater(nom, "sortie '%s' : arrivee (%d, %d) hors de %s"
                      % (c, x, y, cible))
                continue
            arrivee = case(plan_cible, x, y)
            if arrivee in bloquants:
                rater(nom, "sortie '%s' : arrivee (%d, %d) dans %s bloquee par '%s'"
                      % (c, x, y, cible, arrivee))
            if arrivee in SORTIES:
                rater(nom, "sortie '%s' : arrivee (%d, %d) dans %s est elle-meme "
                           "une sortie, le joueur boucle" % (c, x, y, cible))

        # 5. depart, PNJ, passages sous les voies
        depart = z["depart"]
        if depart is None:
            rater(nom, "pas de case de depart")
        elif case(plan, depart[0], depart[1]) in bloquants:
            rater(nom, "depart (%d, %d) bloque par '%s'"
                  % (depart[0], depart[1], case(plan, *depart)))
        for (x, y) in z["pnj"]:
            if case(plan, x, y) not in sols_pnj:
                rater(nom, "PNJ sur (%d, %d) : '%s' n'est pas dans SOLS_PNJ"
                      % (x, y, case(plan, x, y)))
        passages = sum(ligne.count("T") for ligne in plan)
        if passages not in (0, 2):
            rater(nom, "%d passages sous les voies : il en faut 0 ou 2" % passages)

        # 6. ressource et herbe haute
        if not z["ressource"] or not z["tuile"]:
            rater(nom, "ressource ou tuile_ressource manquante")
        ramassages = sum(ligne.count("R") for ligne in plan)
        if ramassages < 2:
            rater(nom, "%d case(s) 'R' : il en faut au moins deux" % ramassages)
        herbe = sum(ligne.count("g") for ligne in plan)
        if herbe == 0 and z["rencontres"]:
            rater(nom, "des rencontres declarees mais aucune herbe haute")

        # 7. tout ce qui compte est joignable a pied
        if depart is not None:
            atteints = joignables(plan, depart, bloquants)
            manquants = {}
            for y, ligne in enumerate(plan):
                for x, c in enumerate(ligne):
                    if c in REMARQUABLES and (x, y) not in atteints:
                        manquants.setdefault(c, []).append((x, y))
            for c, cases in sorted(manquants.items()):
                rater(nom, "'%s' injoignable depuis le depart : %s"
                      % (c, ", ".join("(%d, %d)" % p for p in cases)))

    print()
    for nom, z in zones.items():
        for c, (cible, ax, ay) in z["sorties"].items():
            if cible in zones:
                verifier_pas_sous_un_volume(
                    cible, zones[cible]["plan"],
                    [("arrivee depuis %s" % nom, (ax, ay))],
                    lambda t: anomalies.append(t))

    if anomalies:
        print("%d anomalie(s) :" % len(anomalies))
        for ligne in anomalies:
            print("  " + ligne)
        return 1
    print("Tous les plans sont valides.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
