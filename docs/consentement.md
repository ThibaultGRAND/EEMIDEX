# Consentement des étudiants

Le jeu sera publié en ligne et affiche des prénoms et des portraits (même stylisés).
C'est une donnée personnelle et une image : **aucun étudiant n'entre dans le jeu sans
son accord écrit**, et chacun peut se retirer à tout moment, sans avoir à se justifier.

## Comment le code applique la règle

- Chaque Gone est un fichier `.tres` dans `data/gones/`.
- `GoneData.consentement_recu` vaut `false` par défaut.
- `GameState.gones_jouables()` ne renvoie que les Gones dont le consentement est reçu
  (ou les Gones génériques, qui ne représentent personne). Un `.tres` sans accord est
  chargé mais **n'apparaît jamais** en jeu.
- Se retirer = supprimer son `.tres` (ou repasser `consentement_recu` à `false`),
  et supprimer son sprite dans `assets/sprites/`. Rien d'autre à toucher.
- `data/gones/_modele_etudiant.tres` est le modèle à copier. Il a `consentement_recu = false`.

## Formulaire à envoyer à la promo

> **Jeu de la promo — participation**
>
> On réalise pour un projet de cours un petit jeu façon Pokémon, situé à Lyon, dans
> lequel les créatures à capturer sont les étudiants de la promo. Le jeu sera publié
> en ligne (page publique), gratuitement et sans publicité.
>
> 1. Acceptes-tu d'apparaître dans le jeu ? ☐ Oui ☐ Non
> 2. Sous quel nom ? (prénom, ou pseudo si tu préfères) : ______________
> 3. Quel pouvoir aimerais-tu avoir ? ______________
> 4. Traits de design à reprendre (coiffure, lunettes, couleurs, objet fétiche) : ______________
> 5. Acceptes-tu qu'on s'inspire d'une photo pour dessiner le sprite ? ☐ Oui ☐ Non
>    (la photo ne sera pas publiée, elle sert uniquement de référence de dessin)
> 6. Validation : on te montrera le sprite final avant publication. ☐ D'accord
>
> Tu peux demander ton retrait à tout moment en écrivant à <contact du groupe>. Le
> retrait est appliqué à la publication suivante, sous 7 jours.
>
> Date et signature (ou réponse par mail / formulaire en ligne, qui vaut accord écrit) :

## Suivi

| Étudiant | Accord reçu le | Nom en jeu | Sprite validé | Fichier `.tres` |
| --- | --- | --- | --- | --- |
| *(exemple)* | *(à remplir)* | *(à remplir)* | ☐ | `data/gones/____.tres` |

## Points de vigilance

- Conserver les accords (mails, réponses de formulaire) quelque part de durable, hors dépôt Git.
- Ne pas committer de photos de personnes dans `assets/` : seulement les sprites dessinés.
- Pas de nom de famille, pas de mail, pas de photo dans le jeu ni dans les `.tres`.
- Un étudiant qui refuse n'est pas absent du jeu : il est simplement représenté par le
  Gone générique, comme tout le monde au début.
