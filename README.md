# Gones

Un jeu d'exploration et de combat façon Pokémon, jouable dans le navigateur, où les
créatures à capturer sont les étudiants de la promo. Le monde est Lyon, en pixel art.

Cadrage complet : [docs/cadrage.md](docs/cadrage.md).

## État du projet

Le squelette jouable est en place : on démarre à Bellecour, on traverse le Vieux Lyon
par les traboules, on monte à Fourvière et on affronte le gardien. Tout tourne avec des
formes de couleur en guise de graphismes — **aucun sprite n'est encore dessiné**.

Ce qui marche déjà :

- déplacement case par case sur 3 zones, avec traboules, ressources et changement d'écran ;
- rencontres aléatoires dans l'herbe, combat 1 contre 1 au tour par tour
  (attaquer / objet / changer / fuir), capture au Filet à Gone ;
- équipe de 3 Gones maximum, inventaire, 3 ressources, boutique, soin ;
- 2 mini-jeux d'entraînement : Rythme (vitesse) et Frappe chronométrée (attaque) ;
- sauvegarde dans `user://sauvegarde_gones.json` ;
- export Web sans threads déjà configuré, plus un workflow GitHub Pages.

## Prise en main

1. Installer **Godot 4.7.2** (version standard, pas .NET : l'export Web ne prend pas en
   charge le C#) — c'est la version figée pour l'équipe.
   [godotengine.org/download](https://godotengine.org/download) ou `brew install --cask godot`.
2. Ouvrir `project.godot` depuis le gestionnaire de projets de Godot.
3. F5 pour lancer. Flèches pour se déplacer, **Entrée** pour agir et valider,
   **Échap** pour le menu.

### Exporter pour le navigateur

**Une seule fois** : *Éditeur > Gérer les modèles d'exportation > Télécharger et installer*.
Sans ces modèles (~1 Go), l'export échoue avec `Aucun modèle d'exportation n'a été trouvé`.
Ils doivent correspondre exactement à la version de l'éditeur.

Ensuite, le plus simple est le bouton **Exécuter dans le navigateur** en haut à droite de
l'éditeur : il exporte et sert le jeu tout seul. Sinon, *Projet > Exporter*, preset **Web**,
vers `build/web/index.html`.

En ligne de commande :

```bash
godot --headless --export-release "Web" build/web/index.html
```

Un `index.html` ouvert directement depuis le disque ne marchera pas (les navigateurs
bloquent le WebAssembly en `file://`). Il faut un petit serveur :

```bash
python3 -m http.server --directory build/web 8000
```

Le preset coche déjà **l'export sans threads** (`variant/thread_support=false`) : c'est
ce qui permet d'héberger sur itch.io ou GitHub Pages sans toucher aux en-têtes COOP/COEP.

## Arborescence

```
scenes/
  world/     world.tscn (la carte), zones.gd (les 3 plans de zone en texte)
  battle/    battle.tscn (combat au tour par tour)
  minigames/ rythme/ et frappe/
  ui/        main_menu.tscn
scripts/
  autoload/  game_state.gd — le seul autoload : équipe, sac, ressources, sauvegarde
  data/      gone_data.gd, move_data.gd, item_data.gd (Resources) + gone_instance.gd
data/
  gones/     un .tres par Gone     moves/ les attaques     items/ les objets
assets/      sprites/, tilesets/, audio/ (vides) + maps/SOURCES.md
tools/       hors jeu : données ouvertes et conversion de carte (à écrire)
docs/        cadrage.md, consentement.md
```

## Ajouter du contenu sans toucher au code

**Un Gone** : dupliquer `data/gones/_modele_etudiant.tres`, le renommer, remplir les
champs dans l'inspecteur, passer `consentement_recu` à `true` **une fois l'accord écrit
reçu** (voir [docs/consentement.md](docs/consentement.md)). Pour qu'il apparaisse dans
une zone, ajouter son `id` à la liste `rencontres` de la zone dans
`scenes/world/zones.gd`.

**Une attaque** : un `.tres` de plus dans `data/moves/`, puis le glisser dans
`attaque_de_base` ou `pouvoir_signature` d'un Gone.

**Une zone** : une entrée de plus dans `ZONES` (`scenes/world/zones.gd`), 10 lignes de
20 caractères, plus les sorties qui pointent vers les zones voisines.

## Décisions prises pour démarrer (à confirmer en équipe)

Le cadrage laissait des questions ouvertes. Le squelette a tranché provisoirement —
chaque point se change facilement :

| Question | Choix du squelette | Où le changer |
| --- | --- | --- |
| Nom des créatures | **Gones** | `project.godot`, textes des scènes |
| Quels 2 mini-jeux | **Rythme** (vitesse) et **Frappe chronométrée** (attaque) | `scenes/minigames/` |
| Version de Godot | **4.7.2 stable** | `project.godot`, `.github/workflows/export-web.yml` |
| Ressources | praline (Presqu'île), cocon (Vieux Lyon), quenelle (Fourvière) | `GameState.RESSOURCES` |
| Taille d'équipe | 3 Gones | `GameState.TAILLE_EQUIPE_MAX` |
| Hébergement | GitHub Pages via Actions | `.github/workflows/export-web.yml` |

La troisième ressource (le cocon) n'a pas encore de mini-jeu : elle sert pour l'instant à
la boutique, et attend le mini-jeu d'esquive si l'équipe décide d'en faire un troisième.

## Reste à faire pour le MVP

- [ ] Dessiner les sprites, les tilesets et remplacer `_draw()` par de vraies `TileMapLayer`
- [ ] Collecter les consentements et créer les 8 à 12 Gones de la promo
- [ ] Équilibrer les stats, les niveaux et le taux de capture
- [ ] Écrire les dialogues et l'objectif final du joueur
- [ ] Musiques et sons libres de droits
- [ ] Vérifier l'export Web sur itch.io ou GitHub Pages
- [ ] Écrire le script de conversion des données ouvertes (`tools/map_data/`)

Le suivi détaillé et les décisions provisoires sont dans [CLAUDE.MD](CLAUDE.MD).
