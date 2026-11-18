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

### `BoiteDialogue`

```gdscript
await %Boite.afficher(["Un Guignome sauvage vous barre la route !", "Que faites-vous ?"])
```

`attendre_validation = false` pour un journal de combat qui défile seul.
`capture_entree = false` quand l'écran gère lui-même le clavier.

## Ce qui reste à faire

- [ ] Rebrancher l'écran de combat sur `FicheCombattant`, `ListeMenu` et
      `BoiteDialogue` (à faire avec l'agent qui écrit les règles : il travaille
      dans `battle.gd` et `battle.tscn`).
- [ ] Rebrancher le HUD de la carte : la boîte de dialogue des PNJ et le menu
      pause passent encore par un `Label` en overlay (`world.gd`).
- [ ] Écrans Équipe, Sac et boutique : aujourd'hui du texte dans un seul `Label`.
- [ ] Écran titre : choix Moustache / Moustachette.
- [ ] Transitions entre carte, combat et mini-jeux (fondu, ouverture de combat).
- [ ] Le LinkedOut (l'encyclopédie) — hors MVP, à proposer avant de coder.
- [ ] Police bitmap : la police par défaut de Godot tient le coup, une police
      pixel art libre de droits serait plus nette. À décider en équipe (licence).
