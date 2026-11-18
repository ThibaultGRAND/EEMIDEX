# Les prompts de génération des tuiles

Tout ce qu'il faut envoyer à Gemini pour obtenir le jeu de tuiles du MVP.
L'inventaire de ce que ça couvre est dans [tuiles-inventaire.md](tuiles-inventaire.md).

## Mode d'emploi

1. **Une planche à la fois**, dans l'ordre. Demander tout d'un coup donne de la bouillie.
2. À partir de la planche 2, **joindre la planche 1 validée** au message : c'est ce qui
   tient la palette et l'échelle d'une planche à l'autre.
3. Après chaque planche, vérifier trois choses avant de passer à la suivante :
   les pixels sont nets et carrés ; aucun texte ne s'est glissé dans l'image ;
   le fond est bien magenta uni, pas un damier.
4. Si une planche part de travers, utiliser le prompt de correction tout en bas plutôt
   que de tout relancer.

**Ne pas demander les tuiles de transition** (bord d'herbe sur le pavé, angle de quai sur
l'eau). Elles se fabriquent par calcul à partir des sols de base : générées, elles
seraient incohérentes entre elles et la couture se verrait partout.

---

## Planche 1 — Sols de base

*8 tuiles, grille 4 × 2.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 2 lignes, soit 8 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Pas de transparence : ce sont des sols, chaque case est remplie bord à bord.
- Pas de contour sombre : un sol plat n'a pas de contour.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. pavé lyonnais gris-beige, pavés irréguliers de 3 à 4 pixels, joints plus sombres
2. le même pavé, avec deux ou trois pavés plus clairs et usés
3. le même pavé, avec une fine fissure et un peu de mousse dans un joint
4. dalle de quai claire, grandes dalles rectangulaires, joints fins et réguliers
5. terre battue et gravier, grain fin, quelques petits cailloux
6. herbe courte, brins courts, deux verts mélangés
7. herbe haute, brins hauts et touffus, vert plus sombre, impression de volume
8. eau de rivière, bleu-gris, petites vaguelettes horizontales

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD, LE POINT LE PLUS IMPORTANT
- Chaque tuile doit être répétable à l'infini : son bord droit doit prolonger son
  bord gauche sans couture, et son bord bas prolonger son bord haut.
- Si je pose la même tuile quatre fois en carré, la jointure ne doit pas se voir.
- Aucun gros détail ne doit toucher le bord d'une tuile, sinon la répétition se
  remarque immédiatement.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 2 — Variantes de sol et marquages

*8 tuiles, grille 4 × 2.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 2 lignes, soit 8 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Pas de transparence : ce sont des sols, chaque case est remplie bord à bord.
- Pas de contour sombre : un sol plat n'a pas de contour.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. terre battue avec plus de cailloux et deux ornières
2. terre battue avec une flaque d'eau peu profonde
3. dalle de quai claire, variante aux joints plus larges
4. bande blanche de passage piéton peinte sur du pavé
5. plaque d'égout en fonte ronde posée sur du pavé
6. bordure de trottoir vue de dessus, dalle d'un côté, pavé de l'autre
7. sable de berge, clair, grain très fin
8. ballast ferroviaire, cailloux gris anguleux

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD, LE POINT LE PLUS IMPORTANT
- Chaque tuile doit être répétable à l'infini : son bord droit doit prolonger son
  bord gauche sans couture, et son bord bas prolonger son bord haut.
- Si je pose la même tuile quatre fois en carré, la jointure ne doit pas se voir.
- Aucun gros détail ne doit toucher le bord d'une tuile, sinon la répétition se
  remarque immédiatement.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 3 — Eau et berges

*8 tuiles, grille 4 × 2.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 2 lignes, soit 8 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Pas de transparence : ce sont des sols, chaque case est remplie bord à bord.
- Pas de contour sombre : un sol plat n'a pas de contour.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. eau de rivière, vaguelettes en position A, pour l'animation
2. eau de rivière, mêmes vaguelettes décalées, position B
3. eau profonde, plus sombre, sans vaguelette
4. enrochement de berge, gros blocs de pierre grise irréguliers
5. enrochement de berge, variante avec un bloc plus clair
6. planches de ponton en bois, posées horizontalement
7. planches de ponton en bois, posées verticalement
8. vase et algues vertes au bord de l'eau, peu profond

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD, LE POINT LE PLUS IMPORTANT
- Chaque tuile doit être répétable à l'infini : son bord droit doit prolonger son
  bord gauche sans couture, et son bord bas prolonger son bord haut.
- Si je pose la même tuile quatre fois en carré, la jointure ne doit pas se voir.
- Aucun gros détail ne doit toucher le bord d'une tuile, sinon la répétition se
  remarque immédiatement.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 4 — Objets de quai

*8 tuiles, grille 4 × 2.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 2 lignes, soit 8 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. bollard d'amarrage en fonte noire, trapu
2. borne en pierre claire, basse
3. pied d'une grue de quai ancienne, structure métallique
4. haut de la même grue, flèche métallique qui dépasse
5. escalier de pierre descendant vers l'eau, vu de 3/4
6. garde-corps métallique vu de face, section droite
7. garde-corps métallique, angle
8. pneu d'amarrage et cordage sur le bord du quai

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 5 — Murs et parapets

*8 tuiles, grille 4 × 2.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 2 lignes, soit 8 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. muret de pierre bas, extrémité gauche
2. muret de pierre bas, section centrale répétable
3. muret de pierre bas, extrémité droite
4. muret de pierre bas, angle vu de l'extérieur
5. muret de pierre bas, angle vu de l'intérieur
6. parapet de quai en pierre claire, section centrale répétable
7. parapet de quai en pierre claire, extrémité
8. pilier de pierre carré, plus haut que le muret

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 6 — Façades en pierre dorée du Vieux Lyon

*12 tuiles, grille 4 × 3.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 3 lignes, soit 12 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. rez-de-chaussée, mur de pierre dorée nu
2. rez-de-chaussée, porte en bois à deux battants
3. rez-de-chaussée, vitrine de commerce avec auvent
4. rez-de-chaussée, fenêtre basse à barreaux
5. étage, mur de pierre dorée nu
6. étage, fenêtre à petits carreaux
7. étage, fenêtre avec volets en bois ouverts
8. étage, petit balcon en fer forgé
9. corniche de toit, extrémité gauche
10. corniche de toit, section centrale répétable
11. corniche de toit, extrémité droite
12. porche de traboule : encadrement de pierre et ouverture très sombre

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 7 — Toits de tuiles rouges

*9 tuiles, grille 3 × 3.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 3 colonnes sur 3 lignes, soit 9 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. toit de tuiles rouges, coin haut gauche
2. toit de tuiles rouges, bord haut
3. toit de tuiles rouges, coin haut droit
4. toit de tuiles rouges, bord gauche
5. toit de tuiles rouges, centre répétable
6. toit de tuiles rouges, bord droit
7. toit de tuiles rouges, coin bas gauche, avec gouttière
8. toit de tuiles rouges, bord bas, avec gouttière
9. toit de tuiles rouges, coin bas droit, avec gouttière

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 8 — Falaise et escaliers de Fourvière

*12 tuiles, grille 4 × 3.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 3 lignes, soit 12 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. haut de falaise calcaire, coin gauche, herbe au-dessus
2. haut de falaise calcaire, section centrale, herbe au-dessus
3. haut de falaise calcaire, coin droit, herbe au-dessus
4. escalier de pierre vu de 3/4, marche du haut
5. face de falaise calcaire, bord gauche, strates visibles
6. face de falaise calcaire, section centrale répétable
7. face de falaise calcaire, bord droit, strates visibles
8. escalier de pierre vu de 3/4, marches répétables
9. pied de falaise, coin gauche, éboulis
10. pied de falaise, section centrale, éboulis
11. pied de falaise, coin droit, éboulis
12. escalier de pierre vu de 3/4, marche du bas

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 9 — Arbres

*12 tuiles, grille 4 × 3.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 3 lignes, soit 12 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. platane, houppier, quart haut gauche
2. platane, houppier, quart haut droit
3. marronnier plus sombre, houppier, quart haut gauche
4. marronnier plus sombre, houppier, quart haut droit
5. platane, houppier, quart bas gauche
6. platane, houppier, quart bas droit
7. marronnier, houppier, quart bas gauche
8. marronnier, houppier, quart bas droit
9. platane, tronc et départ de branches, moitié gauche
10. platane, tronc et départ de branches, moitié droite
11. marronnier, tronc, moitié gauche
12. marronnier, tronc, moitié droite

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 10 — Buissons et détails verts

*8 tuiles, grille 4 × 2.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 2 lignes, soit 8 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. buisson rond, vert moyen
2. buisson plus large et plus sombre
3. buisson fleuri, quelques points de couleur
4. touffe d'herbe isolée
5. petites fleurs sauvages au sol
6. jardinière en bois plantée
7. haie taillée, section centrale répétable
8. haie taillée, extrémité

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 11 — Ferroviaire

*12 tuiles, grille 4 × 3.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 3 lignes, soit 12 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. rail droit horizontal avec traverses, sur ballast
2. rail droit vertical avec traverses, sur ballast
3. rail, courbe reliant le haut à la droite
4. rail, courbe reliant le haut à la gauche
5. rail, courbe reliant le bas à la droite
6. rail, courbe reliant le bas à la gauche
7. aiguillage, deux voies qui se séparent
8. passage à niveau, rails traversant une route pavée
9. butoir de fin de voie, rouge et blanc
10. poteau caténaire, partie basse
11. poteau caténaire, partie haute avec le bras
12. traverses de bois empilées au sol

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 12 — Mobilier urbain

*12 tuiles, grille 4 × 3.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 3 lignes, soit 12 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. lampadaire lyonnais, pied en fonte
2. lampadaire lyonnais, tête et lanterne
3. banc public en bois et fonte, vu de 3/4
4. poubelle de rue
5. borne anti-stationnement en fonte
6. panneau de signalisation sur poteau
7. abribus vitré, moitié gauche
8. abribus vitré, moitié droite
9. barrière métallique, section répétable
10. plot de chantier
11. boîte aux lettres jaune
12. horodateur

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Planche 13 — Tuiles de jeu

*8 tuiles, grille 4 × 2.*

```text
Génère une planche de tuiles (tileset) pour un jeu vidéo en pixel art.

FORMAT
- Une grille de 4 colonnes sur 2 lignes, soit 8 tuiles.
- Les tuiles se touchent bord à bord : aucun trait de séparation, aucune marge, aucun
  espace entre les cases.
- Chaque case représente une tuile de 16 x 16 pixels de jeu.
- Rends l'image en grand, avec des pixels carrés parfaitement nets : chaque pixel du jeu
  doit apparaître comme un bloc d'au moins 16 sur 16 pixels dans ton image. Aucun
  anti-aliasing, aucun flou, aucun dégradé lissé, aucune ombre douce.
- Fond magenta pur #FF00FF partout où la tuile doit être transparente. Jamais de
  damier gris, jamais de blanc, jamais d'ombre portée sur le fond magenta.
- Contour sombre #2a2420 autour de chaque volume.

CONTENU, case par case, de gauche à droite puis de haut en bas
1. touffe d'herbe haute qui frémit, plus sombre que l'herbe normale, position A
2. la même touffe d'herbe haute, frémissement en position B
3. praline rose brillante posée au sol, petit reflet
4. cocon de soie beige posé au sol
5. quenelle dorée posée au sol
6. bouche de traboule au sol : dalle sombre avec une arche de pierre
7. borne d'entraînement : petite console de bois et métal, écran lumineux
8. marqueur de sortie de zone : flèche de pierre gravée au sol

STYLE
- Vue de dessus en 3/4, caméra inclinée, comme les jeux Pokémon sur Nintendo DS.
- Lumière venant du haut à gauche, dans toutes les tuiles sans exception.
- Décor de la ville de Lyon, en France.
- Palette imposée, n'utilise aucune autre couleur :
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

RACCORD
- Les éléments décrits comme « répétables » ou « centraux » doivent se raccorder à
  eux-mêmes bord à bord, sans décalage.
- Les morceaux d'un même objet réparti sur plusieurs cases doivent s'aligner
  exactement : le tronc sous le houppier, la corniche sur l'étage.

INTERDIT
- Aucun texte, aucune légende, aucun numéro de case, aucune signature, aucun filigrane.
- Aucun personnage, aucune voiture, aucun animal.
- Aucun cadre, aucune bordure, aucune marge autour de la planche.
- Ne rajoute aucune tuile que je n'ai pas demandée.
```

---

## Prompt de correction

À utiliser quand une planche est presque bonne.

```text
Reprends la planche que tu viens de produire et corrige uniquement ces points :
[LISTER LES CORRECTIONS]

Garde tout le reste strictement identique : même grille, même nombre de cases, même
contenu dans chaque case, même palette, même style, même lumière, même fond.
Ne redessine pas la planche depuis zéro, ne réorganise pas les cases.
```

## Récapitulatif

| Planche | Tuiles | Fond |
| --- | --- | --- |
| 1. Sols de base | 8 | opaque |
| 2. Variantes de sol et marquages | 8 | opaque |
| 3. Eau et berges | 8 | opaque |
| 4. Objets de quai | 8 | magenta |
| 5. Murs et parapets | 8 | magenta |
| 6. Façades en pierre dorée du Vieux Lyon | 12 | magenta |
| 7. Toits de tuiles rouges | 9 | magenta |
| 8. Falaise et escaliers de Fourvière | 12 | magenta |
| 9. Arbres | 12 | magenta |
| 10. Buissons et détails verts | 8 | magenta |
| 11. Ferroviaire | 12 | magenta |
| 12. Mobilier urbain | 12 | magenta |
| 13. Tuiles de jeu | 8 | magenta |
| **Total** | **125** | |

Les tuiles de transition viennent en plus, fabriquées par script à partir des sols de
la planche 1.
