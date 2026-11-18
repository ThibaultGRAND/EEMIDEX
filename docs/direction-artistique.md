# Direction artistique

*Fixée le 18 nov. 2026, d'après des références montrées par l'équipe (captures de jeux
Pokémon sur DS, époque Ranger / Donjon Mystère).*

## Ce qui est visé

Une vue de dessus **en 3/4**, pas une vue de dessus stricte. C'est la différence entre
les premiers Pokémon (Game Boy, vue à plat, personnage vu du dessus) et les Pokémon DS :
la caméra est inclinée, on voit le **visage** des personnages et la **face avant** des
rochers, des troncs et des murs.

Les autres marqueurs du style visé :

- décor dense et texturé : touffes d'herbe, cailloux, racines, variations de sol —
  jamais un aplat de couleur uni sur plusieurs cases ;
- palettes riches, dégradés courts, lumière qui vient d'en haut ;
- objets plus hauts qu'une case : un rocher occupe une case au sol mais se dessine sur
  deux cases de haut ;
- ombre portée sous chaque personnage, posée au sol ;
- la carte défile, elle ne se lit pas écran par écran.

## Ce que ça implique, chiffré

La DS affiche 256×192 par écran. Nos 320×180 donnent une densité de pixels équivalente,
donc **la résolution du projet ne change pas**.

| Élément | Valeur | Remarque |
| --- | --- | --- |
| Résolution | 320×180 | inchangée, proche d'un écran DS |
| Tuile | 16×16 px | inchangée, c'est le standard de ces jeux |
| Personnage | 16 à 20 px de large, 24 à 32 px de haut | soit ~2 cases de haut |
| Ombre | ellipse sombre semi-transparente, ~14×5 px | sous les pieds, dans le sprite ou à part |
| Directions | 4 (bas, haut, gauche, droite) | 2 à 4 images par direction pour la marche |
| Objets hauts | 1 case au sol, 2 à 3 cases dessinées | rochers, arbres, murs, bâtiments |

Le sprite `julian.html` fait 24×33 px : **c'est la bonne taille pour ce style**, en
personnage de carte comme en combat. (Je l'avais dit trop grand quand je pensais encore
à une vue de dessus stricte à la Game Boy — avec ces références, il tombe juste.)

## Ce que ça change dans le code

Quatre points, par ordre d'importance :

1. **Tri par profondeur (Y-sort).** En 3/4, le joueur doit passer *derrière* un rocher
   quand il est au-dessus, et *devant* quand il est en dessous. Sans ça, tout se
   superpose dans le désordre. Dans Godot : `y_sort_enabled` sur le nœud de la zone et
   sur la `TileMapLayer`, et l'origine des sprites posée **aux pieds**, pas au centre.
2. **Caméra qui suit le joueur.** Aujourd'hui une zone fait exactement un écran
   (20×10 cases) et ne défile pas. Les références défilent. Il faut un `Camera2D` sur le
   joueur, avec des limites calées sur la taille de la zone — et les zones peuvent alors
   être plus grandes qu'un écran.
3. **Déplacement animé.** Le déplacement case par case reste (c'est ce que font Donjon
   Mystère et les Pokémon DS), mais le personnage doit **glisser** d'une case à l'autre
   en ~0,15 s au lieu de sauter d'un coup, avec l'animation de marche pendant ce temps.
4. **Hauteur des obstacles.** La grille de collision reste une grille au sol. Ce qui
   change, c'est le dessin : un mur bloque une case mais s'affiche sur deux. Les plans
   texte de `zones.gd` restent valables, c'est le rendu qui s'étoffe.

## Le vrai risque : la charge de dessin

C'est le point à regarder en face. Ce style demande **beaucoup plus de pixel art** que
les premiers Pokémon : chaque type de sol a besoin de ses transitions avec les sols
voisins, chaque falaise a besoin de ses angles, chaque personnage a besoin de 4
directions animées.

Pour que 3 zones restent tenables sur un projet de cours :

- **Limiter les matériaux par zone** à quatre : un sol, une bordure (falaise ou mur),
  une végétation, une eau. Pas plus.
- **Utiliser les terrains de Godot** (autotiles) pour que les transitions se calculent
  toutes seules au lieu d'être placées à la main.
- **Partager les tuiles entre zones** : la Presqu'île, le Vieux Lyon et Fourvière sont
  trois ambiances de pierre et de pavé. Un même jeu de tuiles reteinté fait beaucoup.
- **Commencer par un seul personnage complet** (4 directions, 2 images par direction)
  pour mesurer le temps réel que ça prend, avant d'en lancer douze.

## Attention aux références

Les captures qui ont servi à fixer la direction sont des **captures de jeux commerciaux**
(Nintendo). Elles servent de référence de style, elles ne sont **pas** versionnées dans ce
dépôt et aucune de leurs tuiles ne doit être reprise dans le jeu : il sera publié en
ligne. Tout le pixel art est dessiné par l'équipe.

## Les planches de sprites

L'équipe fournit **une planche par personnage**, en grille, une pose par case
(idle, marche, course, esquive, attaque, saut, sort, défense, dégâts). Le découpage en
fichiers séparés se fait ensuite par script.

Pour que le découpage soit propre, la planche doit respecter ceci :

| Exigence | Pourquoi |
| --- | --- |
| **Vraie transparence** (alpha PNG) | Un damier gris *dessiné* dans l'image ne peut pas être enlevé sans risquer de manger des pixels gris du personnage — la monture des lunettes, par exemple |
| **Pas de texte ni de bordure** dans l'image | Les libellés « IDLE », « WALK » et les traits de séparation se retrouveraient dans les sprites découpés |
| **Cases de taille identique** | Le script coupe sur une grille régulière |
| **Personnage calé sur une ligne de sol commune** | Sinon il sautille d'une pose à l'autre une fois en jeu |
| **Une marge vide** autour de chaque pose | Les poses larges (attaque, saut) ne doivent pas toucher le bord de leur case |

Si la planche arrive avec les libellés et le damier, elle sert de **référence** : il faut
alors une seconde export propre pour le jeu.

### Ce qui manque encore

La planche actuelle est une planche de **combat** : neuf poses, toutes de face. Il
manque, pour la carte, les **4 directions** (bas, haut, gauche, droite) avec deux images
de marche chacune. Deux options :

- une seconde planche par personnage pour la carte (le plus propre, le plus de travail) ;
- ou un seul sprite de face sur la carte, qui ne tourne pas. Ça se voit, mais certains
  jeux l'assument. À décider avant de lancer douze personnages.
