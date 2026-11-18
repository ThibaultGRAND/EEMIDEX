# Inventaire des tuiles

Liste de ce qu'il faut dessiner pour que les 3 zones du MVP tiennent debout. Tuiles de
**16 × 16 pixels**. Cocher au fur et à mesure.

> **Le piège à comprendre avant de commencer.** Une tuile de sol toute seule ne sert à
> rien : ce qui fait tenir une carte, ce sont les **transitions** entre deux matériaux —
> le bord d'herbe sur le pavé, l'angle du quai sur l'eau. C'est là que se trouvent les
> trois quarts du travail, et c'est ce qu'on oublie toujours de commander.
>
> Godot sait les poser tout seul si on lui donne le jeu complet : c'est le système de
> **terrains** (autotile). En mode « coins seulement », il faut **16 tuiles par terrain**.

## A. Sols — les terrains

Chacun a besoin de sa tuile pleine **et** de ses 16 tuiles de transition vers la terre,
qui sert de sol de référence partout.

| | Terrain | Tuiles | Où |
| --- | --- | --- | --- |
| ☐ | **Terre / gravier** | 1 pleine + 3 variantes | sol de référence, chemins, friches |
| ☐ | **Pavé lyonnais** | 1 + 3 variantes + 16 transitions | rues, places, Bellecour |
| ☐ | **Dalle claire** | 1 + 2 variantes + 16 transitions | quais, esplanades |
| ☐ | **Herbe courte** | 1 + 3 variantes + 16 transitions | parcs, talus |
| ☐ | **Herbe haute** | 1 + 2 variantes + 16 transitions | **déclenche les rencontres** |
| ☐ | **Eau** | 1 + 2 d'animation + 16 transitions | Saône, Rhône, darse |
| ☐ | **Ballast ferroviaire** | 1 + 1 variante | sous les rails |

Sous-total : environ **100 tuiles**. C'est le gros morceau, et il est incompressible.

## B. Volumes — ce qui dépasse du sol

Pas des terrains : des objets posés par-dessus, plus hauts qu'une case, triés en
profondeur (Y-sort).

| | Élément | Tuiles | Note |
| --- | --- | --- | --- |
| ☐ | Mur de pierre bas | 3 (gauche, centre, droite) + 2 angles | parapets de quai, murets |
| ☐ | Façade d'immeuble | 3 bandes (rez, étage, corniche) × 2 largeurs | pierre dorée pour le Vieux Lyon |
| ☐ | Variantes de façade | fenêtre, porte, vitrine, volet | 4 à 6 tuiles |
| ☐ | Toit de tuiles rouges | 9 (centre, 4 bords, 4 coins) | signature lyonnaise |
| ☐ | Toit plat moderne | 9 | Confluence, Part-Dieu |
| ☐ | Falaise / colline | 9 + 2 angles rentrants | **Fourvière** |
| ☐ | Escalier | 3 (haut, marches, bas) | montées de Fourvière |
| ☐ | Porche de traboule | 2 (encadrement, ouverture sombre) | **passage caché** |
| ☐ | Pont / passerelle | 4 (tablier, garde-corps, culées) | franchissements |

Sous-total : environ **50 tuiles**.

## C. Ferroviaire

| | Élément | Tuiles |
| --- | --- | --- |
| ☐ | Rail droit | 2 (horizontal, vertical) |
| ☐ | Courbes | 4 |
| ☐ | Aiguillage | 2 |
| ☐ | Passage à niveau | 2 |
| ☐ | Poteau caténaire | 2 (base, haut) |

Sous-total : **12 tuiles**.

## D. Végétation

| | Élément | Tuiles |
| --- | --- | --- |
| ☐ | Arbre | 6 par variante (2 cases de large × 3 de haut), 3 variantes |
| ☐ | Buisson | 3 variantes de 1 case |
| ☐ | Touffe décorative | 3 |
| ☐ | Jardinière / bac | 2 |

Sous-total : environ **26 tuiles**.

## E. Mobilier urbain

| | Élément | Tuiles |
| --- | --- | --- |
| ☐ | Lampadaire | 2 (pied, tête) |
| ☐ | Banc | 2 |
| ☐ | Poubelle, borne, panneau | 3 |
| ☐ | Ponton de bois | 3 |
| ☐ | Bollard, grue de quai | 3 |
| ☐ | Passage piéton | 2 |

Sous-total : **15 tuiles**.

## F. Tuiles de jeu — à ne pas oublier

Celles-ci ne sont pas du décor : elles portent une règle. Si elles manquent, la carte
est jolie et injouable.

| | Élément | Rôle |
| --- | --- | --- |
| ☐ | Herbe haute | déclenche les rencontres aléatoires |
| ☐ | Ressource au sol | praline, cocon, quenelle — 3 tuiles |
| ☐ | Entrée de soin | le hub de Bellecour |
| ☐ | Devanture de boutique | échange de ressources |
| ☐ | Borne d'entraînement | lance les mini-jeux |
| ☐ | Bouche de traboule | téléporte vers l'autre bout |
| ☐ | Marqueur de sortie de zone | passage vers la zone voisine |

## Total

Environ **210 tuiles** pour le MVP complet, dont la moitié sont des transitions.

C'est beaucoup, et c'est pour ça qu'on commence par un jeu **placeholder** complet et
moche : les cartes se construisent tout de suite, et chaque tuile est remplacée ensuite
par la vraie, sans jamais retoucher les cartes.

## Palette commune

Toutes les tuiles doivent sortir de la même palette, sinon elles ne vont pas ensemble.

```
contour      #2a2420
pavé         #8a8378  #6e675d
dalle claire #b9b2a3  #9a9488
terre        #9c8465  #7d6a51
herbe        #4f8a46  #3a6b36  #68a85c
eau          #3f6f93  #2c5574  #5b8fb0
toit tuile   #b4553a  #8e3f2c
pierre dorée #d8c89d  #b8a67c
façade crème #e3d6bd  #c4b89c
métal / rail #5a5f66  #3d4248
bois         #8a6239  #6b4a2a
```
