# Cadrage — jeu Gones (projet de cours)

*18 nov. 2026 · @Thibault*

## Pitch

Un jeu d'exploration et de combat façon Pokémon, jouable dans le navigateur, où les
créatures à capturer sont les étudiants de la promo.

- Le joueur incarne une Moustache ou une Moustachette.
- Les créatures (nom de travail : **Gones**) sont les étudiants. Chacun a son design
  pixel art, son prénom et un pouvoir qui lui est propre.
- Le monde est Lyon, en pixel art dans le style des premiers Pokémon (vue de dessus,
  déplacement case par case).
- La progression passe par les combats et par des mini-jeux d'entraînement, alimentés
  par les ressources trouvées sur la carte.

## Systèmes

Cinq systèmes suffisent pour le MVP. Les valeurs chiffrées restent à définir pendant
l'équilibrage.

| Système | Rôle | Contenu minimal |
| --- | --- | --- |
| Gones | Les créatures-alliées | Prénom, sprite, type, 4 stats (PV, attaque, défense, vitesse), 1 pouvoir signature + 1 attaque de base |
| Combat | Affrontement au tour par tour | 1 contre 1, choix entre attaquer, utiliser un objet, changer de Gone ou fuir |
| Capture | Recruter un Gone sauvage | Possible quand le Gone adverse est affaibli, avec un objet de capture |
| Ressources | Monnaie de la progression | 3 à 5 ressources ramassées sur la carte, chacune liée à un mini-jeu |
| Mini-jeux | Entraîner un Gone | Le score obtenu fait monter une stat, et les ressources débloquent des niveaux de difficulté |

Mini-jeux proposés (choisir 2 ou 3) :

1. **Rythme**, pour la vitesse : on appuie sur des touches en cadence.
2. **Esquive**, pour la défense : on évite des projectiles pendant 30 secondes.
3. **Frappe chronométrée**, pour l'attaque : on arrête une jauge dans la zone cible.
4. **Mémoire**, pour les PV : on retient une séquence de cases.

Chaque mini-jeu est un petit jeu en soi. Au-delà de 3, le projet déborde.

## Carte de Lyon

Le MVP se limite à 3 zones reliées entre elles. Chaque zone ajoutée ensuite est une
tilemap de plus à dessiner.

| Zone | Ambiance | Particularité de gameplay |
| --- | --- | --- |
| Presqu'île (Bellecour) | Point de départ, ville | Hub central : soin et boutique |
| Vieux Lyon | Ruelles, traboules | Les traboules servent de passages cachés et de raccourcis entre les écrans |
| Fourvière | Colline, basilique | Zone plus difficile, avec le combat de fin du MVP |

Zones possibles après le MVP : Croix-Rousse, quais de Saône et du Rhône, Part-Dieu,
parc de la Tête d'Or, et la Fête des Lumières comme événement.

## Technique

Le projet utilise Godot 4 en GDScript, avec un export Web (HTML5/WebAssembly).
Le premier livrable technique est un export Web vide qui tourne en ligne, dès la semaine 1.

- **Langage** : GDScript uniquement, parce que l'export Web de Godot 4 ne prend pas en
  charge le C#. À revérifier sur votre version.
- **Export** : cocher l'option sans threads (disponible depuis Godot 4.3). Elle évite de
  configurer les headers COOP/COEP sur le serveur.
- **Hébergement** : itch.io ou GitHub Pages pour une page statique.
- **Résolution** : basse résolution (par exemple 320×180) mise à l'échelle, filtre de
  texture Nearest pour garder un pixel art net.
- **Sauvegarde** : un fichier dans `user://`, qui correspond à l'IndexedDB du navigateur sur Web.
- **Données des Gones** : des fichiers Resource (`.tres`), un par étudiant. On ajoute un
  Gone sans toucher au code.
- **Versioning** : Git, avec le `.gitignore` Godot officiel (qui exclut `.godot/`).

Arborescence proposée :

```
res://
├── scenes/
│   ├── world/        # zones (tilemaps), joueur
│   ├── battle/       # écran de combat
│   ├── minigames/    # un sous-dossier par mini-jeu
│   └── ui/           # menus, inventaire, dialogues
├── scripts/
│   └── autoload/     # GameState (équipe, inventaire, sauvegarde)
├── data/
│   ├── gones/        # un .tres par étudiant
│   ├── moves/        # attaques et pouvoirs
│   └── items/
└── assets/
    ├── sprites/
    ├── tilesets/
    └── audio/
```

Un seul autoload, `GameState`, porte l'état global. Le reste communique par signaux.

## Consentement des étudiants

Aucun étudiant n'apparaît dans le jeu sans son accord écrit, puisque le jeu sera en ligne
et utilise des prénoms et des portraits (droit à l'image, RGPD).

- [ ] Envoyer à la promo un court formulaire : accord, prénom ou pseudo, pouvoir souhaité, traits de design
- [ ] Faire valider le sprite final par chaque étudiant
- [x] Prévoir un Gone générique pour ceux qui refusent → `data/gones/generique_gone.tres`
- [x] Permettre le retrait sur simple demande (un `.tres` à supprimer)

Voir [consentement.md](consentement.md).

## Périmètre MVP

Le MVP est atteint quand on peut jouer une partie complète de 15 à 20 minutes dans le
navigateur, du départ au combat de fin.

| Dans le MVP | Hors MVP |
| --- | --- |
| 3 zones (Presqu'île, Vieux Lyon, Fourvière) | Les autres quartiers |
| 8 à 12 Gones | Toute la promo |
| Combat 1 contre 1 au tour par tour | Combats en double, météo, statuts complexes |
| Équipe de 3 Gones maximum | Stockage de Gones (« PC ») |
| 2 mini-jeux | Les autres mini-jeux |
| 1 sauvegarde | Multijoueur, échanges |
| Musique et sons libres de droits | Bande-son originale |

## Questions ouvertes

- [ ] Nom définitif des créatures : Gones, Traboulins, Lugdumons ou autre ?
- [ ] Quels 2 mini-jeux pour le MVP ? *(le squelette part sur Rythme + Frappe chronométrée)*
- [ ] Quelle est l'histoire et quel est l'objectif final du joueur ?
- [ ] Taille de l'équipe, répartition des rôles (code, pixel art, game design) et date de rendu ?
- [ ] Quelle version de Godot 4, et faut-il la figer pour tout le monde ? *(le squelette vise 4.3+)*
- [ ] Quelles règles du cours sur l'usage de l'IA (Claude Code) ?
