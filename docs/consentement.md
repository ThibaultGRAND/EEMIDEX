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

### Personnages nommés

Ceux-ci ne passent **pas** par le garde-fou `consentement_recu` : ce sont des PNJ
codés dans `scenes/world/zones.gd`, pas des Gones. Leur accord se suit donc ici, à la
main, et nulle part ailleurs.

| Étudiant | Accord reçu le | Nom en jeu | Sprite validé | Fichiers |
| --- | --- | --- | --- | --- |
| Julian | 18 nov. 2026 | Julian | ☐ | `assets/characters/pnj_julian/`, `tools/planches/pnj_julian.jpg` |
| Seb | 18 nov. 2026 | Seb | ☐ | `assets/characters/pnj_seb/`, `tools/planches/pnj_seb.jpg` |
| Thomas | 18 nov. 2026 | Thomas | ☐ | `assets/characters/pnj_thomas/`, `tools/planches/pnj_thomas.jpg` |
| Paloma | 18 nov. 2026 | Paloma | ☐ | `assets/characters/pnj_paloma/`, `tools/planches/pnj_paloma.jpg` |
| Thibaut | 18 nov. 2026 | Thibaut | ☐ | `assets/characters/pnj_thibaut/`, `tools/planches/pnj_thibaut.png` |
| Théophile | 18 nov. 2026 | Théophile | ☐ | `assets/characters/pnj_theophile/`, `tools/planches/pnj_theophile.jpg` |
| Émile | 18 nov. 2026 | Émile | ☐ | `assets/characters/pnj_emile/`, `tools/planches/pnj_emile.jpg` |
| Guillaume | 18 nov. 2026 | Guillaume | ☐ | `assets/characters/pnj_guillaume/`, `tools/planches/pnj_guillaume.jpg` |
| Célia | 18 nov. 2026 | Célia | ☐ | `assets/characters/pnj_celia/`, `tools/planches/pnj_celia.jpg` |
| Gabriel | 18 nov. 2026 | Paguera | ☐ | `assets/characters/pnj_gabriel/`, `tools/planches/pnj_gabriel.jpg`, `pnj_gabriel_combat.jpg`, `data/gones/paguera.tres` |
| Mathéo | 18 nov. 2026 | Mathéo | ☐ | `assets/characters/pnj_matheo/`, `tools/planches/pnj_matheo.jpg` |
| Nael | 18 nov. 2026 | Nael — Directeur pédagogique | ☐ | *(boss, pas encore de sprite)* |
| Tristan | 18 nov. 2026 | Tristan — recruteur | ☐ | *(boss, pas encore de sprite)* |
| *(prénom à compléter)* | 18 nov. 2026 | Matiti | ☐ | *(pas encore de sprite)* |
| *(prénom à compléter)* | 18 nov. 2026 | CeCissoussou | ☐ | *(pas encore de sprite)* |

Il reste à leur faire **valider le sprite final** avant la mise en ligne, et à conserver
les accords écrits hors du dépôt.

### Gones

| Étudiant | Accord reçu le | Nom en jeu | Sprite validé | Fichier `.tres` |
| --- | --- | --- | --- | --- |
| *(aucun pour l'instant)* | | | ☐ | `data/gones/____.tres` |

## Points de vigilance

- Conserver les accords (mails, réponses de formulaire) quelque part de durable, hors dépôt Git.
- Ne pas committer de photos de personnes dans `assets/` : seulement les sprites dessinés.
- Pas de nom de famille, pas de mail, pas de photo dans le jeu ni dans les `.tres`.
- Un étudiant qui refuse n'est pas absent du jeu : il est simplement représenté par le
  Gone générique, comme tout le monde au début.

## Les noms de jeu

`docs/histoire.md` donne à chaque étudiant un nom de personnage : Thigoat, Roulian,
Matiti, Palou, Thomasu, Guignome, Tortheo, E1000, Paguera, Thibouclier, CeCissoussou.
Un surnom reste une donnée personnelle dès lors qu'il désigne quelqu'un de reconnaissable
dans sa promo : il relève du même accord que le prénom.

Trois d'entre eux ne sont connus ici que par leur nom de jeu — Matiti, CeCissoussou et
Paguera. À compléter avec le prénom réel, pour que le retrait soit possible sur simple
demande.
