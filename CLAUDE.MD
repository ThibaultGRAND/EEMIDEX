# CLAUDE.md — Gones (nom de travail)

Jeu façon Pokémon dans un Lyon en pixel art, jouable dans le navigateur. Le joueur est une Moustache ou une Moustachette. Les créatures (« Gones ») sont les étudiants de la promo. Projet de cours.

Le document de référence est la page de cadrage. En cas de doute sur le périmètre, demande avant de coder.

## Stack

- Godot 4.x (version figée pour toute l'équipe : **4.7.2 stable**), en GDScript uniquement.
- Cible principale : export Web (HTML5/WebAssembly). Tout ce qui ne marche pas en Web est exclu.

## Règles Godot

### Langage et style
- GDScript seulement. Pas de C# (non supporté par l'export Web de Godot 4) ni de GDExtension.
- Typage statique partout : `var hp: int = 10`, `func take_damage(amount: int) -> void:`.
- Respecter le style guide officiel de GDScript :
  - fichiers et dossiers en `snake_case` (`battle_manager.gd`, `battle_screen.tscn`) ;
  - `class_name` et noms de nœuds en `PascalCase` ;
  - variables et fonctions en `snake_case`, constantes en `CONSTANT_CASE` ;
  - ordre dans un script : `class_name`, `extends`, signaux, enums, constantes, `@export`, variables, `_ready`, autres fonctions.
- Indentation : tabulations (défaut Godot).

### Architecture
- Un seul autoload : `GameState` (équipe, inventaire, progression, sauvegarde). N'en ajoute pas d'autre sans demander.
- Communication entre scènes par **signaux**. Pas de chaînes `get_node("../../X")`.
- Références aux nœuds : `@onready var x: Node = %UniqueName` ou `@export`. Pas de chemins en dur fragiles.
- Données de jeu dans des `Resource` (`.tres`), pas dans le code :
  - `data/gones/` : un `.tres` par étudiant (classe `GoneData`) ;
  - `data/moves/` : attaques et pouvoirs (classe `MoveData`) ;
  - `data/items/` : objets (classe `ItemData`).
  Ajouter un Gone ne doit jamais demander de toucher au code.
- Une scène = une responsabilité. Le combat ne connaît pas la carte, les mini-jeux ne connaissent pas le combat : ils renvoient un résultat par signal.
- Entrées clavier via l'InputMap (`ui_accept`, `move_up`…), jamais via des keycodes en dur.

### Interface

Tout l'habillage passe par un socle commun. Voir `docs/interface.md`.

- **Palette** : `scripts/ui/palette_ui.gd` (`PaletteUi`). Aucune couleur en dur
  dans un écran, y compris les couleurs de type (Dev, Data, Product, Marketing,
  Design, Staff, Neutre).
- **Thème** : `scenes/ui/theme_moustache.tres`, déclaré dans `project.godot`
  (`gui/theme/custom`). Il s'applique seul à tous les `Control` : ne pas poser de
  `theme` sur chaque scène, ne pas multiplier les `theme_override_*`.
- **Composants** dans `scenes/ui/composants/` : `BarreJauge`, `BadgeType`,
  `FicheCombattant`, `ListeMenu`, `BoiteDialogue`. On les instancie, on écoute
  leurs signaux. **Ne plus écrire de menu dans un seul `Label`** (« > Attaquer »)
  ni de PV en texte : c'est `ListeMenu` et `BarreJauge`.
- Un composant ne décide rien : il émet un signal, l'écran agit.
- Les cadres sont des `StyleBoxFlat` dessinées en code, sans asset. Les cadres
  9-slice de l'équipe les remplaceront dans le thème, sans toucher aux écrans.
- `scenes/ui/apercu_ui.tscn` montre tous les composants d'un coup (F6). C'est un
  écran de travail, il n'est pas branché au jeu.

### Fichiers à ne pas toucher
- Ne jamais modifier `.godot/`, les fichiers `.import` ni les `.uid`. Committer les `.uid`, ignorer `.godot/`.
- Les `.tscn` et `.tres` : modifications minimales et ciblées. Pour une nouvelle scène complexe, propose la structure de nœuds et laisse l'équipe la construire dans l'éditeur. Après toute édition d'un `.tscn`, signale qu'il faut l'ouvrir dans l'éditeur pour vérifier.

### Pixel art
- **Résolution de base : 320×180. Tuiles de 16×16. Décidé le 18 nov. 2026, ne pas y revenir
  sans l'accord de l'équipe.** Stretch mode `canvas_items`, scale `integer`.
- **⚠ Rendu des personnages — NE PAS DÉFAIRE (choix de Sébastien, 18 nov. 2026).**
  La logique du jeu reste en 320×180 (carte, caméra, cases de 16), mais le rendu se fait
  à la résolution de la fenêtre pour que les personnages soient nets. Concrètement :
  - `project.godot` : `window/stretch/mode="canvas_items"`. **Ne jamais le remettre en
    `viewport`**, même pour « respecter le pixel-perfect » ou suivre un ancien document.
  - Les sprites de personnages (`assets/characters/<id>/<id>_sheet.png` et `_frames.tres`)
    sont fournis **en 4× (~52 px de haut)** et affichés avec **`scale = 0.25`** dans
    `scenes/world/player.tscn` et `scenes/world/pnj.tscn`. **Ne pas les réduire** à
    24-32 px réels, **ne pas retirer le `scale`**, ne pas « corriger » leur taille :
    ils font déjà 13 px dans le monde, centrés au milieu de leur case.
  - L'offset des pieds tient compte de ce `scale` (`pnj.gd`, `player.tscn`) : ne pas le
    recalculer comme si le sprite était à l'échelle 1.
  - Les **tuiles de la carte** suivent le même principe depuis le 18 nov. 2026 : atlas
    64×64 (`assets/tilesets/placeholder_tuiles_hd.png` + `.tres`), couches `Sol` et
    `Decor` de `world.tscn` à `scale = 0.25`. La logique reste en cases de 16
    (`Zones.TAILLE_CASE`). Ne pas retirer ce `scale` ni remettre `lyon.tres`.
  - Si une consigne (ici ou dans `docs/`) semble dire le contraire, c'est qu'elle date
    d'avant ce choix : **demander à l'équipe avant de toucher** à ces réglages.
  - Si l'éditeur Godot est ouvert pendant une modification de `project.godot`, il peut la
    réécrire avec ses anciens réglages : recharger le projet avant de lancer, et vérifier
    que le mode est toujours `canvas_items`.
- Tailles imposées, valables pour tout le monde :

  | Élément | Taille |
  | --- | --- |
  | Écran | 320 × 180 pixels |
  | Tuile | 16 × 16 |
  | Personnage | 16 à 20 de large, 24 à 32 de haut **dans le monde** (sprite fourni en 4×, `scale = 0.25`) |
  | Objet posé au sol | 16 × 16 |
  | Bâtiment | multiple de 16, 2 à 3 cases de haut |

  Un asset livré à une autre échelle est à refaire : réduire du pixel art le détruit.
  **Exception : les personnages**, fournis en 4× exprès (voir ci-dessus).
- **Vue de dessus en 3/4** (style Pokémon DS), pas vue de dessus à plat. Voir
  `docs/direction-artistique.md` : Y-sort obligatoire, caméra qui suit le joueur,
  personnages de 24 à 32 px de haut dans le monde, origine des sprites aux pieds.
- Filtre de texture par défaut : `Nearest`. Pas de mipmaps.
- Tuiles de 16×16 px. Carte construite avec `TileMapLayer` (pas l'ancien nœud `TileMap`, déprécié).

### Contraintes Web
- Export sans threads (option disponible depuis Godot 4.3) : pas de headers COOP/COEP à configurer.
- Sauvegarde uniquement dans `user://` (IndexedDB côté navigateur). Aucun accès à d'autres chemins.
- Pas d'API spécifiques à un OS (`OS.execute`, système de fichiers local…).
- Audio : `.ogg`. Le son ne démarre qu'après une première interaction du joueur (règle des navigateurs).

### Musique

- Les trois pistes sont dans `assets/audio/` : `exploration.ogg`, `combat.ogg`,
  `boutique.ogg` (Ogg Vorbis, qualité 3, 44,1 kHz stéréo ; 6,3 Mo en tout).
- **Un seul lecteur, dans `GameState`** (`AudioStreamPlayer` créé au démarrage).
  Une scène ne crée jamais son propre lecteur : elle appelle
  `GameState.jouer_musique(&"exploration" | &"combat" | &"boutique")` dans son
  `_ready()`. Redemander la piste en cours ne la recommence pas, et le passage
  d'une piste à l'autre se fait en fondu (`DUREE_FONDU`).
- Qui joue quoi : écran titre et carte → exploration, écran de combat → combat,
  menu de la boutique → boutique (retour à exploration en fermant le menu). Les
  mini-jeux ne demandent rien : la musique de la carte continue.
- La boucle est posée au chargement (`piste.loop = true`), pas dans le `.import` :
  on ne touche pas aux fichiers `.import`.
- **L'écran titre n'appelle `jouer_musique()` qu'à la première touche**, parce
  qu'un navigateur refuse le son tant que le joueur n'a rien touché.
- Volume dans `GameState.VOLUME_MUSIQUE_DB` (-12 dB). La musique reste derrière
  le jeu : ne pas la remonter sans l'accord de l'équipe.
- Pour convertir une nouvelle piste (ffmpeg n'est pas installé sur le poste, il a
  été pris via le paquet Python `imageio-ffmpeg`) :
  `ffmpeg -i source.mp3 -vn -c:a libvorbis -q:a 3 -ar 44100 -ac 2 assets/audio/piste.ogg`.
  Un `.wav` brut n'entre pas dans le dépôt : 26 Mo pour 2 min 30, contre 1,9 Mo en Ogg.
- En quittant le jeu, Godot écrit `resources still in use at exit` quand une
  musique joue : c'est le serveur audio du moteur, pas une fuite du jeu.
- Garder le poids du build raisonnable : pas d'assets inutilisés dans le projet.

### Vérification
- Avant de dire qu'une tâche est terminée : le projet s'ouvre sans erreur et la scène concernée se lance.
- Export Web en ligne de commande (preset nommé `Web`) :
  `godot --headless --export-release "Web" build/web/index.html`
- Si une commande ou une API Godot est incertaine, vérifie dans la doc de la version utilisée. N'invente pas d'API.

## Carte de Lyon : données publiques

La carte est construite à partir de données ouvertes, puis simplifiée en tilemap pixel art. On ne dessine pas Lyon de mémoire.

- Sources :
  - **OpenStreetMap** (licence ODbL) : rues, bâtiments, parcs, cours d'eau ;
  - **data.grandlyon.com** (open data de la Métropole de Lyon) : voirie, espaces verts, lieux remarquables.
- Vérifier la licence de **chaque** jeu de données avant usage, et la noter dans `assets/maps/SOURCES.md`.
- Attribution obligatoire dans les crédits du jeu, au minimum « © les contributeurs d'OpenStreetMap ».
- Les données brutes (GeoJSON, etc.) restent dans `tools/map_data/` et ne sont **pas** chargées par le jeu.
- Un script de conversion dans `tools/` transforme une zone (emprise en lat/lon) en grille de tuiles 16×16 : route, bâtiment, eau, parc. Le langage du script est à décider avec l'équipe.
- La grille générée sert de base ; l'équipe retouche ensuite à la main dans l'éditeur (traboules, passages, décor). La géographie reste reconnaissable, pas exacte au mètre.
- Zones du MVP : Presqu'île (Bellecour), Vieux Lyon, Fourvière.

## Arborescence

```
res://
├── scenes/
│   ├── world/        # zones (TileMapLayer), joueur
│   ├── battle/       # écran de combat
│   ├── minigames/    # un sous-dossier par mini-jeu
│   └── ui/           # menus, inventaire, dialogues
├── scripts/
│   └── autoload/     # game_state.gd
├── data/
│   ├── gones/
│   ├── moves/
│   └── items/
├── assets/
│   ├── sprites/
│   ├── tilesets/
│   ├── maps/         # SOURCES.md des données de carte
│   └── audio/
└── tools/            # hors jeu : conversion des données de carte
    └── map_data/
```

## Règles du projet

- Aucun Gone sans l'accord écrit de l'étudiant concerné. Un étudiant qui refuse est remplacé par un Gone générique.
- **Les PNJ de la carte ne passent pas par ce garde-fou** : ils sont codés dans
  `zones.gd`, pas chargés depuis un `.tres`. Tout PNJ portant un prénom réel doit être
  inscrit à la main dans `docs/consentement.md`, accord reçu avant le commit.
- Les sprites et le pixel art sont faits par l'équipe. Claude ne génère pas d'assets graphiques, sauf placeholders explicitement marqués `placeholder_`.
- Rester dans le périmètre MVP (3 zones, 8 à 12 Gones, combat 1 contre 1, 2 mini-jeux, 1 sauvegarde). Toute fonctionnalité en plus : la proposer, ne pas la coder.
- Pas d'addon ni de plugin de l'Asset Library sans validation de l'équipe.
- Changements petits et ciblés. Un commit = une modification compréhensible.

METS TOUJOURS A JOUR LE CLAUDE.MD POUR LES REGLES ET LAVANCE

---

## Avancement

*Mis à jour le 18 nov. 2026.*

### Ce qui existe

Jeu jouable de bout en bout dans le navigateur, avec les vraies tuiles de l'equipe
pour les sols et des placeholders pour les batiments.

- `scripts/autoload/game_state.gd` — l'autoload unique : equipe (3 max), sac, 3
  ressources, drapeaux de progression, catalogues charges depuis `data/`, sauvegarde
  JSON dans `user://`, plus `sauvegarde_auto()` appele apres un combat, au changement
  de zone et au poste de soin.
- `scenes/world/` — la **Confluence en 4 bandes collées** du nord au sud : `perrache`,
  `sainte_blandine`, `darse`, `pointe`. Deux `TileMapLayer` (sol et decor trie en Y),
  camera qui suit le joueur et bornee a la zone, deplacement glisse d'une case a
  l'autre. Les plans sont en texte dans `zones.gd`.
- `scenes/world/pnj.tscn` — 8 PNJ qui se baladent, deux par zone, sans case imposee :
  la carte leur trouve une place libre au demarrage.
- **Collisions entre personnages** : deux personnages ne s'arrêtent jamais sur la même
  case, mais ils ne se bloquent plus. Quand le joueur avance vers un PNJ arrêté, ou un PNJ
  vers un autre, ils **échangent leurs cases** et se croisent (`world.gd` : `_tenter_pas`,
  `_sur_envie_pnj`).
- **Musique de fond** : 3 pistes `.ogg` dans `assets/audio/`, jouees par le lecteur
  unique de `GameState` (`jouer_musique()`), avec fondu entre deux pistes.
  Exploration sur la carte et l'ecran titre, combat a l'ecran de combat, boutique
  dans le menu du magasin. Voir « Musique » plus haut.
- **Carte : une seule carte d'après OpenStreetMap, nord en haut** (18 nov. 2026, demande
  de Sébastien, d'après une capture Google Maps du quartier). `tools/osm_vers_zones.py
  --ecrire` dessine la Confluence de la gare de Perrache à la rue Paul-Montrochet, de la
  Saône au Rhône (119 × 140 cases, 10 m par case), puis la coupe en **4 bandes collées**
  de 35 lignes : `perrache`, `sainte_blandine`, `darse` (avec l'EEMI) et `pointe` (titre
  « Montrochet »). Les ids sont gardés pour ne casser ni la sauvegarde ni l'histoire.
  - **Pas de case de sortie** : `Zones.ORDRE` donne l'ordre nord-sud. Sortir par le haut ou
    le bas d'une bande mène à la bande voisine, sur la même colonne
    (`world.gd` : `_passer_dans_la_bande_voisine`).
  - L'EEMI est au **Monolithe, au nord de la darse** (`EEMI` dans le script) : le nœud
    « EEMI » d'OSM pointe vers une ancienne adresse, ne pas le reprendre. Le combat final
    `X` est devant.
  - Les rues sont dessinées par-dessus le bâti, avec au moins une case de large : sinon
    elles disparaissent à 10 m par case.
  - `--apercu plan.png` dessine le résultat, `--reference ref.png` les données OSM brutes.
    Relancer `tools/verifier_plans.py` après : il contrôle qu'on atteint tout **à travers
    les bandes**. Les retouches à la main dans `zones.gd` sont perdues si on relance le
    script.
- **Tramways** : `r` = rails de tram (on marche dessus). `scenes/world/tram.tscn` : une rame
  de 3 cases par ligne (plus sur les longues) qui fait l'aller-retour ; elle attend si le
  joueur ou un PNJ est sur la voie, et le joueur ne traverse pas une rame. Les rails
  (`r`, `v`, `=`) prennent le sens de leurs voisins (`Zones.sol_de_zone`).
- **Décor transparent** : `scenes/world/decor.gd` (couche `Decor`). Quand le joueur est
  derrière une partie haute (bord de toit, feuillage, tête de lampadaire), elle passe à
  35 % d'opacité.
- `scenes/ui/carte_monde.tscn` — **carte du monde en jeu** : menu pause > « Carte ». Les 4
  bandes dessinées **collées, sans écart ni cadre** : une seule carte, nord en haut, avec le
  joueur qui clignote, les repères (soins, boutique, entraînement, passages, ressources,
  combat final) et une légende qui indique la zone courante. Couleurs dans `PaletteUi`
  (`COULEURS_CARTE`, `REPERES_CARTE`). `world.gd` passe en `Mode.CARTE` tant qu'elle est
  ouverte.
- **Tuiles HD (placeholder)** : `tools/generer_tuiles_hd.py` dessine en code un atlas
  64×64 (`assets/tilesets/placeholder_tuiles_hd.*`) : pavés, quais, eau, herbe, rails,
  façades lyonnaises (fenêtres à volets, portes, vitrines), toits en tuiles, arbres,
  lampadaires, mobilier, ressources. La table caractère -> tuile est dans `zones.gd`
  (`SOLS`, `VARIANTES`, `DECORS`, `DECORS_HAUT`, `TUILES_RESSOURCES`) ; les bâtiments
  `#` s'assemblent seuls (`Zones.decor_batiment` / `haut_batiment` : façade au rang du
  bas, toit au-dessus, bords à gauche et à droite). Ce sont des **placeholders** : les
  tuiles définitives restent à produire par l'équipe ; les anciennes (`lyon.tres`,
  16 px) sont toujours dans le dépôt.
- **Personnages : tous au même format, celui de PnjThomas.** Chaque personnage a un
  dossier `assets/characters/<id>/` avec `<id>_sheet.png` (personnage de 52 px, pieds
  sur le bas de chaque case) et `<id>_frames.tres` (SpriteFrames : `idle_<dir>` et
  `walk_<dir>` pour 8 directions). Le jeu les joue avec un `AnimatedSprite2D` à
  `scale = 0.25` : `player.tscn` (joueur Moustache) et `pnj.tscn` (le `.tres` de chaque
  PNJ est donné dans `zones.gd`, clé `"frames"`, à côté de son `"gone"`). Idle à l'arrêt, walk en marche.
  **Ajouter ou refaire un personnage** : déposer la planche d'origine dans
  `tools/planches/`, puis `python3 tools/decouper_planche.py tools/planches/<id>.jpg <id>
  --fond vert|magenta|transparent` (options `--face-en-premier`, `--unique` : voir l'aide
  du script ; il demande Pillow, numpy et scipy).
  Si deux poses se touchent presque, le script réessaie seul avec une marge plus fine.
  **Planches découpées le 18 nov. 2026** : `joueur_moustachette` (branchée dans
  `GameState.HEROS`, choisie au prologue), `pnj_julian` et `pnj_guillaume`
  refaits, et `pnj_celia`, `pnj_gabriel`, `pnj_matheo`. Ces trois derniers ne sont **pas
  encore placés sur la carte** : il faut d'abord les inscrire dans `docs/consentement.md`.
- `scripts/ui/` + `scenes/ui/composants/` — le socle d'interface : palette,
  thème Godot, jauge animée, badge de type, fiche de combattant, liste à curseur,
  boîte de dialogue qui s'écrit lettre par lettre. `scenes/ui/apercu_ui.tscn` les
  montre tous. **Les écrans existants ne sont pas encore rebranchés dessus.**
- `scenes/battle/`, `scenes/minigames/`, `scenes/ui/` — combat au tour par tour,
  Rythme et Frappe chronometree, ecran titre. Toute l'interface est en **ancrages
  proportionnels** : elle suit la resolution sans retouche.
- `assets/tilesets/lyon.png` — 113 tuiles importees des planches de l'equipe. Les
  sols, l'eau, les berges, les buissons, le ferroviaire, le mobilier et les tuiles de
  jeu sont exploitables ; murs, facades, toits et falaise restent en placeholder.
- `data/` — 5 Gones generiques, 7 attaques, 3 objets, plus `_modele_etudiant.tres`.
- `tools/` — `importer_tuiles.py` (planche -> atlas + TileSet), `generer_placeholders.py`,
  `creer_gone.py` (reponses du formulaire -> fiches .tres), `verifier_plans.py`
  (controle les cartes), `changer_resolution.py`, `png_simple.py` (lecture/ecriture PNG
  sans dependance).
- `export_presets.cfg` — preset `Web`, **sans threads**. `.github/workflows/export-web.yml`
  publie sur GitHub Pages a chaque push sur `main`.

### Décisions provisoires, à confirmer en équipe

| Question ouverte du cadrage | Choix provisoire |
| --- | --- |
| Nom des créatures | Gones |
| Quels 2 mini-jeux | Rythme (vitesse) et Frappe chronométrée (attaque) |
| Version de Godot | **4.7.2 stable** (installée le 18 nov. 2026, à confirmer avec l’équipe) |
| Ressources | praline (Presqu'île), cocon (Vieux Lyon), quenelle (Fourvière) |
| Histoire et objectif final | non écrits : le MVP s'arrête au gardien de Fourvière |

Le cocon n'a pas encore de mini-jeu : il ne sert qu'à la boutique, en attendant une
éventuelle décision sur un troisième mini-jeu (esquive, pour la défense).

### Écarts assumés aux règles ci-dessus

- **Pas de script de conversion des données de carte** : le langage n'est pas décidé.
  `tools/map_data/README.md` dit ce qu'il doit faire.
- **`placeholder_icon.svg`** est le seul asset graphique généré, marqué comme tel.
- Les changements de scène passent par `get_tree().change_scene_to_file()` avec les
  constantes de `GameState`. Les mini-jeux et le combat n'appellent jamais la carte
  directement : ils écrivent leur résultat dans `GameState` et rendent la main.

### Démo de personnages (hors jeu)

`scenes/main.tscn` : les 9 personnages côte à côte (`scenes/joueur_moustache.tscn`,
`scenes/pnj_*.tscn`, script `scripts/pnj.gd`), en 8 directions, Tab pour passer de l'un
à l'autre. Elle utilise les mêmes `_frames.tres` que le jeu ; elle n'est pas branchée
au jeu (touches Maj et Tab codées en dur, tolérées pour cette démo).

### Reste à faire pour le MVP

- [x] Figer la version de Godot : **4.7.2 stable** (`project.godot` et la CI sont alignés)
- [ ] Collecter les consentements (voir `docs/consentement.md`), puis créer les 8 à 12 Gones
- [x] Passer la carte en `TileMapLayer` avec Y-sort, caméra qui suit, déplacement glissé
- [ ] Refaire les planches 4 a 8 (quai, murs, facades, toits, falaise) : Gemini a
      dessine un grand objet continu au lieu de cases independantes, les tuiles
      decoupees ne sont que des fragments. Planche 9 (arbres) jamais recue.
- [ ] Calculer les tuiles de transition entre sols a partir des tuiles de base
- [x] Personnages à la bonne taille dans le monde : sprites en 4× affichés à `scale = 0.25`
  (rendu `canvas_items`). **Ne pas les redessiner en 24-32 px réels.**
- [ ] Écrire le script de découpage des planches de sprites
- [ ] Décider le script de conversion des données ouvertes et remplir `assets/maps/SOURCES.md`
- [ ] Équilibrer stats, niveaux, taux de capture
- [ ] Rebrancher combat, HUD de carte, équipe, sac et boutique sur les composants
      d'interface (voir `docs/interface.md`)
- [ ] Dialogues, histoire, objectif final
- [x] Musique de fond : 3 pistes en `.ogg` jouées par `GameState` (exploration,
      combat, boutique)
- [ ] **Noter la provenance et la licence des 3 musiques** (fournies par l'équipe
      le 18 nov. 2026) et les mettre dans les crédits du jeu
- [ ] Bruitages (coup, capture, ramassage, validation de menu) : rien pour l'instant
- [ ] Vérifier l'export Web en ligne (GitHub Pages ou itch.io)
