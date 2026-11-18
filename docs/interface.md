# Interface — le socle commun

*18 nov. 2026. Écrit en même temps que l'équipe carte/personnages et l'agent qui
pose les règles : ce document ne décrit que l'interface.*

Tous les écrans du jeu partagent une palette, un thème et cinq composants. Un
écran ne code plus ses couleurs en dur et n'écrit plus ses menus dans un seul
`Label`.

## Où ça se trouve

| Fichier | Rôle |
| --- | --- |
| `scripts/ui/palette_ui.gd` | Les couleurs, les couleurs de type, les libellés de type |
| `scenes/ui/theme_moustache.tres` | Le thème Godot : cadres, marges, taille de police |
| `scenes/ui/composants/barre_jauge.tscn` | Une jauge animée (Motivation, Café) |
| `scenes/ui/composants/badge_type.tscn` | La pastille colorée d'un type |
| `scenes/ui/composants/fiche_combattant.tscn` | Nom + niveau + type + jauges |
| `scenes/ui/composants/liste_menu.tscn` | Une liste de choix au clavier |
| `scenes/ui/composants/boite_dialogue.tscn` | Le texte qui s'écrit lettre par lettre |
| `scenes/ui/apercu_ui.tscn` | Écran d'aperçu, hors jeu : tout voir d'un coup (F6) |

Le thème est déclaré dans `project.godot` (`gui/theme/custom`) : il s'applique
tout seul à tous les `Control`, sans rien mettre sur chaque scène.

## Les règles

- **Aucune couleur en dur dans un écran.** On prend celles de `PaletteUi`, ou on
  laisse faire le thème. Changer la charte = changer un seul fichier.
- **Aucun menu écrit à la main dans un `Label`.** On instancie `ListeMenu` et on
  écoute `choix_valide`. Un composant ne décide jamais : il émet un signal,
  l'écran agit.
- **La souris ne remplace pas le clavier**, elle double. Tout écran doit rester
  jouable au clavier seul : le jeu tourne dans un navigateur, en 320×180.
- **Clavier par l'InputMap** (`ui_up`, `ui_down`, `ui_left`, `ui_right`,
  `ui_accept`, `ui_cancel`), jamais de keycode.
- **Tailles en 320×180.** Une boîte de dialogue fait ~42 px de haut, une fiche
  de combattant ~34, une jauge 6. La police par défaut est en taille 8.
- **Les cadres sont dessinés en `StyleBoxFlat`**, sans asset. Quand l'équipe
  livrera des cadres 9-slice, il suffira de remplacer les `StyleBox` du thème :
  aucun écran ne bougera.

## Les composants, en deux lignes chacun

### `BarreJauge`

```gdscript
%Motivation.definir(gone.pv, gone.pv_max())   # s'anime toute seule
await %Motivation.animation_terminee
```

Verte, jaune puis rouge selon ce qu'il reste. `couleur_fixe` pour une jauge qui
garde sa couleur (le Café est brun). Largeur arrondie au pixel.

### `BadgeType`

```gdscript
%Badge.definir(&"design")   # &"com" est ramené à &"marketing" par Affinites
```

### `FicheCombattant`

```gdscript
%FicheJoueur.depuis_gone(actif)
await %FicheEnnemi.definir_motivation(ennemi.pv, ennemi.pv_max())
```

`montrer_chiffres = false` pour l'adversaire : on voit la jauge baisser, pas le
compte exact. `definir_cafe()` affiche la deuxième jauge le jour où le combat
connaîtra le Café.

### `ListeMenu`

```gdscript
%Menu.definir_options([
    {"id": &"attaquer", "texte": "Attaquer"},
    {"id": &"sac", "texte": "Sac", "detail": "x3"},
    {"id": &"fuite", "texte": "Fuite", "actif": false},  # grisé, le curseur le saute
])
%Menu.choix_valide.connect(_sur_choix)
```

`colonnes = 2` donne le menu de combat en grille. `interactif = false` pendant
une animation.

**Clavier et souris bougent le même curseur.** Survoler une ligne y amène le
curseur, cliquer dessus revient à appuyer sur Entrée ; une ligne grisée ne
répond ni au survol ni au clic. Les lignes font 10 px de haut (`HAUTEUR_LIGNE`)
pour rester cliquables sans viser au pixel près — à l'écran, en 4×, ça fait
40 px. Un clic dans la boîte de dialogue vaut Entrée, lui aussi.

### `BoiteDialogue`

```gdscript
await %Boite.afficher(["Un Guignome sauvage vous barre la route !", "Que faites-vous ?"])
```

Un nom de locuteur s'affiche en doré au-dessus du texte :

```gdscript
await %Boite.afficher("Bienvenue à Perrache, petit.", "GÉRARD")
```

`attendre_validation = false` pour un journal de combat qui défile seul.
`capture_entree = false` quand l'écran gère lui-même le clavier.
`afficher_invite(texte)` pose une question qui reste à l'écran, sans flèche et
sans attendre Entrée : c'est ce qu'utilise un menu.

## L'écran de combat

Il est rebranché sur les composants. `battle.gd` n'a plus une seule ligne
d'affichage à lui : il appelle `_dire()`, `_afficher_menu()` et `_rafraichir()`,
qui parlent aux composants. Les règles (tour, dégâts, Café, capture, fuite,
évolution) n'ont pas bougé.

- Le menu principal est en **2 colonnes** (Attaquer / Objet — Changer / Fuir),
  les sous-menus en 1 colonne.
- Dans le menu des attaques, **le curseur raconte l'attaque survolée** dans la
  boîte : « Bucheronnage — soutien, type Dev. » Le coût en Café est à droite de
  chaque ligne.
- Un alternant KO, ou déjà au combat, est **grisé et sauté par le curseur**.
- Échap remonte d'un sous-menu au menu principal.

**La fiche du joueur est en haut à gauche, celle de l'adversaire en bas à
droite** (choix de Thibault, 18 nov. 2026) — l'inverse d'un Pokémon, où le
joueur est en bas. Ne pas le réinverser sans lui demander.

Le décor est dans `scenes/battle/fond_combat.gd` : une aube sur la Confluence,
Fourvière et sa basilique en silhouette, le Monolithe, l'eau et deux
plateformes de quai sous les combattants. Tout est tracé dans `_draw()`, sans
un seul asset, comme les cadres sont des `StyleBoxFlat`. Les couleurs du décor
vivent dans ce fichier : `PaletteUi` ne porte que l'interface. Les positions
sont données dans l'espace 320×180 et remises à l'échelle, donc le fond suit
une éventuelle autre résolution.

Le bas de l'écran change de largeur selon ce qu'il montre (constantes en haut de
`battle.gd`) : la boîte prend tout pendant un message, laisse 116 px au menu
principal, et se réduit à 112 px pour les sous-menus, dont les libellés sont
longs (« Lancer de sauce curry »).

## Un piège à connaître

Valider peut changer de scène. `BoiteDialogue.passer()` et `ListeMenu.valider()`
préviennent l'écran, et l'écran peut lancer un combat ou quitter l'intro dans la
foulée : le composant n'est alors **plus dans l'arbre** quand la fonction
reprend la main, et `get_viewport()` renvoie `null`. Les deux composants
retiennent donc le viewport *avant* d'agir. Si tu écris un composant qui marque
un événement comme traité après avoir émis un signal, fais pareil.

## Ce qui reste à faire

- [ ] Rebrancher le HUD de la carte : la boîte de dialogue des PNJ et le menu
      pause passent encore par un `Label` en overlay (`world.gd`).
- [ ] Écrans Équipe, Sac et boutique : aujourd'hui du texte dans un seul `Label`.
- [ ] Écran titre : choix Moustache / Moustachette (le menu est encore un
      `Label` avec des « > » dans `main_menu.tscn`).
- [ ] Composant `Fondu` (fondu au noir) pour les transitions entre carte,
      combat, mini-jeux et intro. L'intro du prologue l'attend : à poser dans
      `intro.gd`, au début et avant le passage à la carte.
- [ ] Le LinkedOut (l'encyclopédie) — hors MVP, à proposer avant de coder.
- [ ] Police bitmap : la police par défaut de Godot tient le coup, une police
      pixel art libre de droits serait plus nette. À décider en équipe (licence).
