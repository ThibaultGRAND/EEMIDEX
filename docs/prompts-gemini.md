# Prompts pour générer les cartes de zone

But : partir d'une carte globale de Lyon en pixel art (vue d'ensemble, peu détaillée) et
en tirer **plusieurs cartes de secteur** détaillées, utilisables comme référence de
dessin pour les tilemaps du jeu.

> **Ce que ça produit et ce que ça ne produit pas.** Un générateur d'images rend une
> *image de référence* : une vue d'ambiance, juste sur l'implantation et les couleurs.
> Il ne rend **pas** un tileset exploitable — la grille de 16 px ne sera pas alignée au
> pixel près, la transparence sera approximative, et deux images successives ne seront
> pas raccord. Le travail de l'équipe reste de **redessiner** les tuiles par-dessus.
> C'est un gain de cadrage et de direction artistique, pas un gain de pixel art.

---

## Prompt 1 — faire proposer le découpage

À envoyer avec la carte globale en pièce jointe.

```text
Tu es directeur artistique sur un jeu vidéo en pixel art, vue de dessus en 3/4,
style Pokémon sur Nintendo DS.

L'image jointe est la carte d'ensemble d'un quartier de Lyon, en France. Elle est
volontairement peu détaillée : c'est une carte de navigation, pas une carte jouable.

Ta tâche : proposer un découpage de cette carte en secteurs jouables.

Contraintes :
- entre 4 et 8 secteurs, pas plus ;
- chaque secteur doit tenir dans un écran de jeu de 20 cases sur 11, où une case
  représente environ 8 mètres de terrain réel ;
- chaque secteur doit contenir au moins un repère reconnaissable par un Lyonnais ;
- deux secteurs voisins doivent se raccorder par un passage évident (une rue, un pont,
  un quai), parce que le joueur passera de l'un à l'autre.

Pour chaque secteur, donne-moi :
1. un nom court ;
2. sa position sur l'image jointe (décris-la : « tiers nord-ouest », « pointe sud »…) ;
3. les bâtiments et lieux réels qu'il contient, nommés précisément ;
4. les rues réelles qui le traversent ;
5. par où on entre et par où on sort, vers quel autre secteur.

Réponds en texte, en français. Ne génère aucune image à cette étape.
```

---

## Prompt 2 — générer un secteur, à répéter pour chacun

Remplacer ce qui est entre crochets avec le tableau des secteurs plus bas. Joindre **la
carte globale** et, à partir du deuxième secteur, **l'image du secteur déjà validé**,
pour garder la même palette et le même style.

```text
Génère une carte de jeu en pixel art pour le secteur décrit ci-dessous.
Produis directement l'image, ne me demande pas de confirmation.

LIEU RÉEL
Quartier de [NOM DU SECTEUR], à Lyon Confluence, France.
Repères à faire apparaître, reconnaissables : [LISTE DES REPÈRES].
Rues et quais qui traversent le secteur : [LISTE DES RUES].
Respecte l'implantation réelle : orientation des rues, hauteur relative des bâtiments,
couleur des façades et des toitures, position de l'eau. Un habitant de Lyon doit
reconnaître l'endroit au premier coup d'oeil. Appuie-toi sur ce que tu sais de ces
adresses précises, et consulte des photos de rue ou des vues aériennes si tu peux.

STYLE, À RESPECTER STRICTEMENT
- Pixel art, vue de dessus en 3/4 : la caméra est inclinée, on voit la face avant des
  bâtiments et pas seulement leur toit.
- Référence exacte : les jeux Pokémon sur Nintendo DS, époque Pokémon Ranger et
  Donjon Mystère. Ni Game Boy à plat, ni isométrique pur, ni rendu 3D, ni vectoriel.
- Palette limitée, couleurs franches, ombres portées nettes, lumière venant du haut.
- Contour sombre autour des volumes qui dépassent du sol.
- Sol texturé : pavés, herbe, gravier, planches de quai. Jamais un aplat uni sur une
  grande surface.
- Les arbres et les bâtiments sont plus hauts que larges et masquent partiellement ce
  qui est derrière eux.

ÉCHELLE, IDENTIQUE DANS TOUS LES SECTEURS
Une case de jeu vaut 8 mètres de terrain réel. L'image couvre exactement 20 cases sur
11, soit 160 mètres sur 88 mètres de terrain. Ni plus, ni moins : ne dézoome pas pour
faire tenir un bâtiment entier, quitte à le couper au bord de l'image.
Tailles de référence, à respecter à l'identique d'un secteur à l'autre :
- un arbre adulte : 2 cases de large, 3 cases de haut
- une voiture : 1 case de long
- une voie ferrée : 1 case de large
- une rue à deux voies : 3 cases de large
- un immeuble de bureaux de 5 étages : 6 à 8 cases de large
- un personnage debout : 2 cases de haut

RÉSOLUTION
- La scène doit correspondre à une grille de 20 cases de large sur 11 de haut, soit un
  format proche du 16/9.
- Rends l'image en grand, mais avec des pixels carrés parfaitement nets : chaque pixel
  du jeu doit apparaître comme un bloc carré d'au moins 8 sur 8 pixels dans l'image que
  tu produis. Aucun anti-aliasing, aucun flou, aucun dégradé lissé, aucun demi-pixel.
- Vue de dessus, nord en haut.
- Les bords gauche et droit doivent pouvoir se raccorder aux secteurs voisins : une rue
  qui sort d'un côté doit sortir à la même hauteur que chez le voisin.

RACCORDS
[INDIQUER PAR QUEL BORD ON SORT ET VERS QUEL SECTEUR]
Ces sorties doivent être des rues ou des quais dégagés, pas des façades fermées.

INTERDIT
- Aucun texte, aucune légende, aucun nom de rue, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun piéton : seulement le décor.
- Aucun damier gris de transparence dessiné dans l'image.
- Pas de cadre, pas de bordure, pas de marge, pas de vignettage.
```

### Les 7 secteurs de la carte Confluence

Découpage proposé par Gemini à partir de la carte globale, le 18 nov. 2026.
Recopier les trois colonnes dans les crochets du prompt 2.

| # | Secteur | Repères à nommer | Rues et quais |
| --- | --- | --- | --- |
| 1 | **Le Hub Perrache** | la gare et le centre d'échanges de Lyon-Perrache, la place Carnot en bordure nord, la place des Archives, le campus Saint-Paul de l'Université Catholique et ses toits de brique, le pont Gallieni à l'est | cours de Verdun, cours Suchet, rue Smith, quai Perrache |
| 2 | **Le Viaduc & la Patinoire** | le pont Kitchener-Marchand et son arc métallique, la patinoire Charlemagne, les halles du marché gare réhabilitées, les premières résidences en brique rouge de la ZAC | quai Rambaud nord, rue Casimir-Périer, rue Marc-Antoine Petit |
| 3 | **Sainte-Blandine & Charlemagne** | l'église Sainte-Blandine, le lycée professionnel, les immeubles anciens du faubourg aux toits de tuiles orangées | cours Charlemagne et ses rails de tram, rue Denuzière, rue Delandine, quai Perrache |
| 4 | **Les Docks & la Darse** | la darse nautique et son bassin rectangulaire, le Pôle de Commerces et de Loisirs Confluence, la capitainerie, les immeubles contemporains colorés dont l'îlot vert pomme | quai Antoine Riboud, rue Paul Montrochet, quai Rambaud |
| 5 | **L'Hôtel de Région** | l'Hôtel de Région Auvergne-Rhône-Alpes, grand bâtiment blanc carré à cour intérieure, le Jardin d'Érevan, les bureaux modernes le long du Rhône | esplanade François Mitterrand, cours Charlemagne, quai Perrache |
| 6 | **Le Cube Orange & la Sucrière** | La Sucrière au bord de la Saône, le Cube Orange, le Pavillon 52, les anciens silos et grues des quais | quai Rambaud sud, rue Hrant Dink |
| 7 | **Le Champ & la Pointe** | le Musée des Confluences, vaisseau de verre et d'inox à la pointe, le jardin du musée, la friche arborée du Champ, le pont Raymond-Barre à l'est | quai Perrache sud, allée du Musée, promenade des quais de Saône |

### Les raccords entre secteurs

À reporter dans le bloc RACCORDS du prompt, pour que les rues tombent en face.

```
1 Hub Perrache     --sud-ouest--> 3 Sainte-Blandine   (cours Charlemagne, rue Smith)
1 Hub Perrache     --nord-ouest-> 2 Le Viaduc         (cours Suchet, le long des rails)
2 Le Viaduc        --sud--------> 4 Les Docks         (quai Rambaud, rue Casimir-Périer)
3 Sainte-Blandine  --ouest------> 4 Les Docks         (rue Denuzière, rue Paul Montrochet)
3 Sainte-Blandine  --sud--------> 5 Hôtel de Région   (cours Charlemagne, quai Perrache)
4 Les Docks        --sud--------> 6 Cube Orange       (passerelle de la darse)
5 Hôtel de Région  --ouest------> 6 Cube Orange       (esplanade François Mitterrand)
5 Hôtel de Région  --sud--------> 7 Le Champ          (cours Charlemagne, quai Perrache)
6 Cube Orange      --sud--------> 7 Le Champ          (quai Rambaud)
```

### Ordre de génération

Commencer par le **secteur 4, Les Docks & la Darse**. Il contient à lui seul tous les
matériaux du quartier : eau, quai, pavé, pelouse, bâtiment moderne clair, bâtiment
coloré. La palette qu'il fixe servira pour les six autres, qu'on génère ensuite en
joignant son image.

Finir par le **secteur 7, Le Champ & la Pointe** : c'est le plus spectaculaire, donc
celui qui bénéficie le plus d'une palette déjà rodée.

### Un chevauchement à trancher

Gemini place « la place Nautique côté est » dans le secteur 3 alors que la darse est le
coeur du secteur 4 — c'est le même bassin. Il faut décider à qui il appartient, sinon
les deux images dessineront le plan d'eau et le raccord sera faux. Le plus simple :
le bassin entier au secteur 4, et le secteur 3 s'arrête à la rue Denuzière.

## Comment relier les secteurs entre eux

**Deux images générées séparément ne se raccorderont jamais au pixel près.** Un
générateur d'images n'a aucune mémoire spatiale d'une requête à l'autre : il redessine
une scène plausible, il ne continue pas la précédente. Aucune formulation de prompt ne
corrige ça.

Trois façons de s'en sortir, de la plus simple à la plus lourde.

### 1. Ne pas avoir besoin du raccord (recommandé)

Dans le jeu, le joueur **ne voit jamais deux secteurs en même temps**. Il quitte un
écran et le suivant se charge, exactement comme dans les Pokémon où les routes
s'enchaînent sans continuité visuelle réelle. Il suffit donc que la sortie d'un secteur
*ait l'air* de mener au suivant : une rue qui part vers le sud, un quai qui continue.

Les images générées ne sont de toute façon **pas** les cartes du jeu : ce sont des
références d'ambiance, qu'on retrace en tuiles. La continuité se décide au moment du
retraçage, dans l'éditeur, où elle est maîtrisée.

### 2. Générer deux secteurs voisins dans la même image

Quand un raccord doit vraiment être lisible — le long d'un quai, par exemple — demander
**une seule image de 40 cases sur 11** contenant les deux secteurs côte à côte, puis la
couper en deux au milieu. La couture est dessinée par le générateur, donc elle tombe
juste. C'est la seule méthode fiable.

### 3. Prolonger une image existante

Joindre le secteur déjà validé et demander une extension :

```text
Voici une carte en pixel art. Prolonge-la vers le sud sur 11 cases supplémentaires.
Le bord inférieur de l'image que je te donne doit devenir le bord supérieur de ton
image : mêmes routes aux mêmes positions horizontales, même largeur de quai, même
couleur d'eau, même échelle, même angle de caméra, même palette.
Ce qui s'y trouve ensuite : [DÉCRIRE LE SECTEUR SUIVANT].
```

Ça marche une fois sur deux. À réserver aux raccords importants.

### Le piège qu'on a déjà rencontré : l'échelle

Sans unité absolue dans le prompt, le générateur rezoome à chaque image. Sur les deux
premiers secteurs produits, le 7 couvrait environ 400 mètres de terrain et le 6 à peine
120 : un arbre du secteur 6 était deux fois plus gros qu'un arbre du secteur 7. Les deux
images sont belles et pourtant inassemblables.

C'est à ça que sert le bloc ÉCHELLE du prompt 2, ajouté après coup : il donne des
tailles de référence en cases, et impose l'emprise au sol de 160 m sur 88 m.

## Prompt 3 — corriger un secteur déjà généré

```text
Reprends l'image que tu viens de produire et corrige uniquement ces points :
[LISTER LES CORRECTIONS]

Garde tout le reste identique : même cadrage, même palette, même style, mêmes
bâtiments aux mêmes endroits. Ne redessine pas la scène depuis zéro.
```

---

## Après la génération

1. Vérifier le réalisme avec quelqu'un qui connaît le quartier.
2. Retracer les tuiles dans l'éditeur de pixel art : c'est là que la grille de 16 px
   devient exacte et que les tuiles deviennent réutilisables entre les zones.
3. Noter dans `assets/maps/SOURCES.md` ce qui a servi de référence.
4. Ne rien publier qui reprenne des tuiles d'un jeu commercial.


---

## Prompt 4 — générer une planche de tuiles

**Une famille à la fois.** Demander soixante tuiles d'un coup donne de la bouillie :
le générateur perd la grille, mélange les échelles et invente des objets non demandés.
Une planche = une famille = 4 à 12 tuiles.

```text
Génère une planche de tuiles (tileset) pour un jeu en pixel art.

FORMAT
- Une grille de [N] colonnes sur [M] lignes, séparées par rien du tout : les tuiles se
  touchent, bord à bord, sans trait de séparation ni marge.
- Chaque case de la grille est une tuile carrée qui représente 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  apparaît comme un bloc d'au moins 16 sur 16 pixels dans l'image. Aucun anti-aliasing,
  aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond : magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond.

CONTENU, case par case, de gauche à droite puis de haut en bas
[LISTER CHAQUE TUILE, UNE LIGNE PAR CASE]

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Contour sombre #2a2420 autour des volumes qui dépassent du sol. Les sols plats n'ont
  pas de contour.
- Palette imposée, n'utilise aucune autre couleur :
  [COLLER LA PALETTE DE docs/tuiles-inventaire.md]

RACCORD
- Les tuiles de sol doivent être répétables : le bord droit doit prolonger le bord
  gauche sans couture visible, et le bord bas prolonger le bord haut. Si je pose la même
  tuile quatre fois en carré, on ne doit pas voir la jointure.
- Pas de détail qui touche le bord d'une tuile de sol, sinon la répétition se voit.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature.
- Aucun personnage, aucune voiture.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
```

### Exemple rempli : les sols de base

```text
FORMAT : une grille de 4 colonnes sur 2 lignes.

CONTENU, case par case :
1. pavé lyonnais gris-beige, pavés irréguliers de 3 à 4 pixels
2. le même pavé, avec deux ou trois pavés plus clairs, usés
3. le même pavé, avec une fine fissure et un peu de mousse dans un joint
4. dalle de quai claire, grandes dalles rectangulaires, joints fins
5. terre battue et gravier, grain fin, quelques cailloux
6. herbe courte, brins courts, deux verts
7. herbe haute, brins hauts et touffus, plus sombre, impression de volume
8. eau de rivière, bleu-gris, petites vaguelettes horizontales

Toutes ces tuiles sont des sols plats, donc sans contour sombre et sans transparence :
la planche n'a pas de fond magenta, chaque case est remplie bord à bord.
```

### Le truc du fond magenta

Un damier gris dessiné dans l'image est impossible à détourer proprement — c'est ce qui
bloque la planche de sprites de Julian. Un aplat de magenta pur, en revanche, n'existe
dans aucune des couleurs de la palette : un script l'enlève sans risque et le remplace
par de la vraie transparence.

### Ce qu'il ne faut PAS générer : les transitions

Les ~100 tuiles de transition de l'inventaire sont **mécaniques**. Elles se déduisent de
deux tuiles de base par découpe en coins — c'est toujours le même jeu de 16 masques. Les
faire générer donnerait 16 dessins incohérents entre eux, et la transition sauterait aux
yeux.

Elles se fabriquent par script : on donne la tuile A, la tuile B, et on obtient les 16
combinaisons de coins. Le travail de dessin tombe alors d'environ 210 tuiles à **une
soixantaine**.
