# Règles du jeu

Le corps de règles complet de **Moustache Quest**. `histoire.md` dit *ce que* le jeu
raconte ; ce document dit *comment* il se joue, avec les nombres.

Chaque règle porte sa mention :
**[en jeu]** elle tourne · **[à faire]** elle est décidée mais pas codée · **[à valider]**
elle attend l'accord de l'équipe.

---

## 1. Le patron **[en jeu]**

Le prologue fait choisir entre deux patrons. Celui qu'on laisse devient le rival.

| | Moustache | Moustachette |
| --- | --- | --- |
| Société | Moustache Corp | Moustachette & Associés |
| Bonus | **+10 % de chance de recrutement** | **les alternants progressent plus longtemps** |
| Réplique | *« Un alternant, c'est un CDI sans les inconvénients. »* | *« Je ne les exploite pas. Je les fais monter en compétences. »* |

Le bonus de Moustache multiplie la chance de recrutement par 1,10, après le calcul
ordinaire : un recrutement à 60 % passe à 66 %.

Celui de Moustachette touche le plafond de montée en niveau. Un alternant ne monte que
s'il reste sous le niveau du vaincu **+ 3** ; chez elle, c'est **+ 4**. Ses alternants
continuent donc de progresser une marche plus haut, ce qui compte surtout en fin de
partie quand les adversaires plafonnent.

*Le document prévoyait « +10 % d'XP » pour elle. Le jeu n'a pas de points
d'expérience — un combat gagné vaut un niveau — donc le bonus a été traduit en
quelque chose qui existe, en gardant l'intention : chez elle, on progresse plus.*

**Il n'y a qu'un seul sprite de héros.** Moustachette s'affiche avec celui de
Moustache en attendant que l'équipe la dessine.

---

## 2. Les alternants

### Les quatre stats **[en jeu]**

| Stat | Rôle | Valeur effective |
| --- | --- | --- |
| **Motivation** | points de vie | `base + bonus + (niveau − 1) × 2` |
| **Compétence** | puissance offensive | `base + bonus + (niveau − 1)` |
| **Défense** | réduit les dégâts subis | `base + bonus + (niveau − 1)` |
| **Vitesse de rendu** | qui frappe en premier | `base + bonus + (niveau − 1)` |

Le `bonus` vient des mini-jeux d'entraînement. Il est permanent et se sauvegarde.

### Les barèmes de base **[en jeu]**

Quatre rôles, qui répartissent le même total de points. Aucun alternant n'est
simplement meilleur qu'un autre : ils sont différents.

| Rôle | Motivation | Compétence | Défense | Vitesse | Recrutement |
| --- | --- | --- | --- | --- | --- |
| Équilibré | 26 | 11 | 11 | 11 | 45 |
| Rapide | 22 | 11 | 9 | 16 | 50 |
| Costaud | 32 | 14 | 10 | 7 | 40 |
| Défensif | 28 | 8 | 16 | 9 | 42 |
| **Boss** | 200 | 30 | 20 | 14 | 0 |

### Les types **[en jeu]**

Cinq types en cycle fermé. Com et Marketing sont le même métier.

**Dev → Data → Product → Marketing → Design → Dev**

| Situation | Multiplicateur de dégâts |
| --- | --- |
| L'attaquant bat le type de la cible | **×1,5** |
| La cible bat le type de l'attaquant | **×0,67** |
| Tout le reste | ×1 |

`staff` et `neutre` sont hors du cycle : ×1 dans les deux sens. Un boss se bat sur
les stats, pas sur l'avantage de type.

---

## 2. Le combat

### Déroulement **[en jeu]**

Un contre un, au tour par tour. À chaque tour le joueur choisit : **attaquer**,
**utiliser un objet**, **changer d'alternant** ou **fuir**.

L'ordre dépend de la Vitesse de rendu : à égalité, le joueur passe en premier.
Un changement d'alternant ou un objet consomme le tour — l'adversaire frappe ensuite.

### Les dégâts **[en jeu]**

```
dégâts = puissance × Compétence attaquant ÷ Défense cible
         × (0,40 + 0,02 × niveau de l'attaquant)
         × multiplicateur de type
         × aléa entre 0,85 et 1,00
minimum 1
```

Le facteur `0,40 + 0,02 × niveau` (`DEGATS_ECHELLE`, `DEGATS_PAR_NIVEAU` dans
`battle.gd`) tient un combat entre 4 et 6 tours à tous les niveaux. Sans lui, la plupart
des combats se jouaient en un ou deux coups. Voir « Équilibrage » plus bas.

Une attaque qui rate ne fait rien : chaque attaque a une **précision** en pourcentage,
tirée avant le calcul.

### Les effets d'attaque **[en jeu]**

| Effet | Ce qu'il fait |
| --- | --- |
| **Brûlure** | la cible perd N points de Motivation à la fin de chaque tour, pendant M tours |
| **Étourdissement** | la cible passe son prochain tour |
| **Dégâts aléatoires** | les dégâts sont tirés entre deux bornes, en ignorant Compétence et Défense |
| **Coût en Motivation** | l'attaquant se blesse lui-même en frappant |
| **Coup critique** | une chance en pourcentage de frapper une fois et demie plus fort |
| **Recharge** | l'attaque est indisponible pendant N tours après usage |

**Un seul état à la fois.** Un alternant est brûlé *ou* étourdi, jamais les deux : un
nouvel état remplace le précédent. C'est une règle de lisibilité autant que de code —
le joueur voit une seule pastille, et sait toujours ce qui le touche.

Les états et les recharges disparaissent à la fin du combat. Les dégâts aléatoires
ignorent volontairement la Compétence et la Défense : c'est tout l'intérêt d'une attaque
imprévisible, elle ne récompense ni l'entraînement ni le choix du type.

### Ce qui n'est pas implémenté

Les **passives** — six alternants en ont une — n'ont aucun système : elles se
déclencheraient sans être choisies, ce que le tour par tour actuel ne sait pas faire.
L'**esquive** et le **renvoi de dégâts** non plus. Les attaques concernées existent avec
leurs dégâts, et leur description dit ce qui manque.

### Les attaques de soutien **[en jeu]**

Une attaque de puissance 0 ne fait pas de dégâts. Elle peut :

- **soigner** son lanceur d'un nombre fixe de points de Motivation ;
- **modifier une stat** — Compétence, Défense ou Vitesse — de l'alternant visé.

Les modifications de stat durent **jusqu'à la fin du combat** et sont annulées à la
sortie. Elles se cumulent sans plafond. *(Un plafond serait plus sain : à surveiller
à l'équilibrage.)*

### Le Café **[en jeu]**

L'énergie dépensée par les attaques. C'est ce qui empêche de marteler la même grosse
attaque du début à la fin.

| Règle | Valeur |
| --- | --- |
| Café maximum | `20 + 2 × (niveau − 1)` |
| Coût d'une attaque | `puissance ÷ 5`, arrondi au supérieur, minimum 2 |
| Attaque de soutien | 2 |
| Récupération | +2 par tour où l'alternant n'attaque pas |
| À sec | seule reste **Traîner des pieds** : 5 dégâts, neutre, gratuit |
| Machine à café | restaure Motivation **et** Café au maximum |

**Pourquoi ces nombres.** Une attaque à 25 de puissance coûte 5. Un alternant de
niveau 5 a 28 de Café, soit cinq grosses attaques, pour un combat qui en dure cinq à
huit tours. Il finit donc tout juste, et doit alterner s'il veut tenir. Face à un boss
à 200 de Motivation, il tombe forcément à sec : il faut des recettes de café, ou
changer d'alternant. C'est là que l'équipe de trois prend son sens.

### La fin d'un combat **[en jeu]**

| Issue | Effet |
| --- | --- |
| Victoire | l'alternant actif monte d'un niveau, **si** son niveau est inférieur à celui du vaincu + 3 |
| Alternant à 0 de Motivation | le suivant valide de l'équipe entre automatiquement |
| Équipe entière à 0 | retour à Perrache, équipe remotivée gratuitement |
| Fuite réussie | retour à la carte, sans gain |

La sauvegarde se déclenche automatiquement à la fin de chaque combat.

---

## 3. Le recrutement

### La formule **[en jeu]**

```
chance = taux de recrutement de l'alternant × (1 − 0,7 × part de Motivation restante)
       + valeur du contrat ÷ 2
bornée entre 5 % et 95 %
```

La *part de Motivation restante* va de 1 (intact) à 0 (épuisé). Un alternant à bout
de forces est donc bien plus facile à convaincre : c'est le cœur de la boucle de jeu.

**Exemple.** Un alternant à 45 de taux, à pleine Motivation, avec un Contrat Basique
(valeur 30) : `45 × 0,3 + 15 = 28 %`. Le même épuisé : `45 × 1 + 15 = 60 %`.

### Les règles de bordure **[en jeu]**

- Le contrat est consommé, réussite ou échec.
- Un échec donne son tour à l'adversaire.
- On ne recrute pas un boss.
- Équipe pleine (3 alternants) : le recrutement est refusé avant de dépenser le contrat.
- Recruté, l'alternant retrouve toute sa Motivation et **disparaît de la carte**.

### Les contrats **[en jeu]**

| Contrat | Valeur | Effet sur la chance |
| --- | --- | --- |
| Basique | 30 | +15 points |
| + Tickets Resto | 50 | +25 points |
| + Télétravail 2j | 80 | +40 points |
| CDI à la clé | 400 | plafonné à 95 %, donc quasi garanti — **un seul dans tout le jeu** |

Sur un alternant à 45 de taux de recrutement :

| Contrat | Intact | Épuisé |
| --- | --- | --- |
| Basique | 28 % | 60 % |
| + Tickets Resto | 38 % | 70 % |
| + Télétravail | 53 % | 85 % |
| CDI | 95 % | 95 % |

Chaque contrat vaut à peu près un palier d'épuisement : avec un Télétravail, inutile de
mettre l'alternant à terre. C'est le compromis que le joueur arbitre — user un contrat
rare, ou passer trois tours de plus à l'affaiblir.

*Les contrats ne sont pas encore vendus en boutique : ils existent en données mais rien
ne les distribue.*

---

## 4. La fuite **[en jeu]**

```
chance = 50 + (Vitesse du joueur − Vitesse de l'adversaire) × 5
bornée entre 20 % et 95 %
```

Un échec donne son tour à l'adversaire. On ne fuit pas un boss.

---

## 5. La carte

### Rencontrer un alternant **[en jeu]**

Deux façons, et le joueur ne décide d'aucune des deux.

**Dans les hautes herbes.** Chaque pas sur une case d'herbe haute a **14 %** de
déclencher une rencontre. L'alternant est tiré parmi ceux de la zone, à un niveau
tiré dans la fourchette de la zone.

**En abordant un alternant soi-même.** Se placer face à lui et appuyer sur Entrée
déclenche le combat **sans qu'il ait son mot à dire**. C'est la seule façon de choisir
son adversaire : utile pour aller chercher un type précis, ou pour achever un alternant
qu'on a déjà croisé.

**En croisant un alternant qui se balade.** Huit alternants arpentent le quartier.
Là, c'est lui qui décide.

| Le joueur lui marche dessus | |
| --- | --- |
| 60 % | il se bat |
| 25 % | il s'enfuit et continue sa course |
| 15 % | il ignore poliment |

Et **12 %** du temps, un alternant qui arrive sur une case voisine du joueur
l'attaque de lui-même. La rencontre n'est pas un menu.

### Aborder un alternant **[en jeu]**

Entrée face à un alternant ouvre un **dialogue** : il dit ce qu'il a sur le cœur, le
patron répond, puis choisit entre *lui proposer un contrat* (le combat commence) et
*le laisser travailler*. C'est la rencontre voulue, par opposition à la rencontre
subie, où c'est l'alternant qui décide de se battre, de fuir ou d'ignorer.

Les textes sont dans `scenes/world/dialogues.gd`, pas dans le code de la carte :
ajouter un alternant bavard, c'est ajouter une ligne à `PLAINTES`.

### Les lieux **[en jeu]**

| Case | Effet |
| --- | --- |
| Machine à café | remotive toute l'équipe, gratuitement, et sauvegarde |
| Boutique | achète des objets contre de la Note de Frais |
| Borne d'entraînement | lance un mini-jeu |
| Voûte | téléporte à l'autre bout du passage |
| Objet au sol | ramassé une seule fois : +25 de Note de Frais |
| Sortie de zone | change de zone, et sauvegarde |

### Les zones **[en jeu]**

Quatre zones reliées du nord au sud, de Perrache à la Pointe. Les niveaux des
alternants sauvages montent à mesure qu'on descend le quartier.

---

## 6. L'économie **[en jeu]**

La monnaie est unique : la **Note de Frais**. On commence la partie avec **120**.
Un objet ramassé au sol en rapporte **25**, une seule fois par gisement.

La boutique vend le catalogue de `GameState.BOUTIQUE`, au prix affiché à côté de
chaque ligne :

| Objet | Prix | Effet |
| --- | --- | --- |
| Contrat Basique | 30 | recrute un alternant épuisé |
| Contrat + Tickets Resto | 70 | recrute mieux |
| Contrat + Télétravail 2j | 140 | recrute beaucoup mieux |
| Barre de céréales | 25 | rend 25 de Motivation |
| Panier garni | 55 | rend 60 de Motivation |

Le **CDI à la clé** ne se vend pas : c'est l'objet unique de la fin.

Ajouter un article à la boutique, c'est ajouter une ligne à `BOUTIQUE` : un
article dont la fiche `.tres` manque est simplement sauté, l'écran ne casse pas.

La difficulté des mini-jeux suit le **niveau de l'alternant entraîné**, de 1 à 5
(`GameState.niveau_minijeu`, 18 nov. 2026, demande de Sébastien) : Niv.2-4 → 1,
5-7 → 2, 8-10 → 3, 11-13 → 4, 14 et plus → 5. Elle règle la vitesse et la précision
demandées : chute des notes, écart entre elles et tolérance au Rythme ; vitesse du
curseur et largeur de la zone à la Frappe (la zone bouge à partir de 4).

---

## 7. L'entraînement **[en jeu]**

Les mini-jeux montent **définitivement** une stat de l'alternant entraîné.

| Mini-jeu | Stat | Gain |
| --- | --- | --- |
| Frappe chronométrée | Compétence | 6 coups, score ramené sur 9 : `score × difficulté ÷ 4`, plafonné à 3 |
| Rythme | Vitesse de rendu | 90 % de réussite : `2 + difficulté` · 60 % : `1 + difficulté ÷ 2` · 35 % : 1, plafonné à 5 |

### Le plafond

**Le bonus permanent est plafonné à +10 par stat.** Sans lui, rejouer vingt fois le
même mini-jeu donnerait un alternant invincible et viderait les combats de leur
intérêt.

Dix points, c'est à peu près le double d'une stat de base : un entraînement assidu
transforme vraiment un alternant, mais il ne le rend jamais intouchable. Le plafond
s'applique stat par stat, donc un alternant lent le reste — l'entraînement corrige à
la marge, il ne refait pas le personnage.

Le mini-jeu annonce le gain **réellement accordé**, pas celui qu'on aurait eu sans
plafond, et prévient quand il n'y a plus rien à gagner. La fiche d'équipe affiche la
marge restante : `ATT 18 (+6/10)`.

Les modificateurs temporaires du combat ne sont pas concernés : ils passent par un
autre chemin, sans plafond, et sont annulés à la fin du combat.

---

## 8. L'évolution **[en jeu]**

`Chômeur → Stagiaire → Alternant`, déclenchée par le **niveau atteint**.

| Stade | À partir du niveau |
| --- | --- |
| Chômeur | 1 |
| Stagiaire | **8** |
| Alternant | **14** |

Chaque stade franchi ajoute, en plus du gain de niveau ordinaire :
**+4 Motivation** et **+2** sur la Compétence, la Défense et la Vitesse.
L'alternant est entièrement remotivé au passage. Son type et ses attaques ne changent
pas.

### La courbe

```
niveau  stade        Motivation  COMP  DEF  VIT
   5    Chômeur          40     18   14   11
   7    Chômeur          44     20   16   13
   8    Stagiaire        50     23   19   16   <-- évolution
  13    Stagiaire        60     28   24   21
  14    Alternant        66     31   27   24   <-- évolution
```

**Pourquoi 8 et 14.** Un alternant démarre au niveau 5 et plafonne vers 15, puisqu'il
ne monte que s'il reste sous le niveau du vaincu + 3. Les deux paliers sont donc
atteignables en jouant normalement, et le second tombe juste avant le combat final.
Plus haut, l'évolution serait décorative ; plus bas, elle arriverait avant que le
joueur ait compris la mécanique.

Le gain est volontairement modeste — un palier vaut environ trois niveaux d'un coup.
L'évolution est une récompense lisible, pas un raccourci qui périme l'entraînement.

La fiche d'équipe annonce le stade et le prochain palier : `Thigoat Chômeur Niv.5
(évolue au 8)`.

---

## 9. La Bienveillance RH **[en jeu]**

Un compteur caché décide de la fin. Il part de **zéro** et n'est jamais montré : c'est
ce qui l'empêche d'être optimisé. Pour obtenir la bonne fin il faut le faire monter —
ne rien faire de particulier mène à la fin exploiteuse.

| Geste | Effet |
| --- | --- |
| Remotiver l'équipe à la machine à café | **+1** |
| Écouter un alternant qui se plaint, jusqu'au bout | **+1** |
| Lui répondre « c'est formateur » | **−1** |
| Tendre un contrat plus généreux qu'un Basique | **+2** |
| Entrer en combat avec un alternant sous 25 % de Motivation | **−1** |

Le compteur est borné entre −20 et +20, et sauvegardé.

**Strictement positif à la fin : les alternants restent.** Zéro ou négatif : ils passent
tous freelance. Les deux épilogues sont dans `scenes/ui/fin.tscn`, et la victoire sur
Nael y mène directement au lieu de revenir à la carte.

Les deux gestes liés aux alternants passent par les **dialogues de la carte** : on
aborde un alternant avec Entrée, il se plaint, et le patron choisit sa réponse. La
plainte et son choix **ne reviennent pas** une fois l'alternant abordé (drapeau
`parle_<id>`) : sans ça, la Bienveillance se farmerait en boucle sur le même PNJ.

### Pas encore branché

*Écouter Gérard* attend que Gérard existe sur la carte : il n'a ni case ni sprite, et
réutiliser la planche d'un étudiant pour lui poserait un problème de consentement.

---

## 10. La sauvegarde **[en jeu]**

Une seule sauvegarde, dans `user://`, en JSON. Elle garde l'équipe avec niveaux,
Motivation et bonus, le sac, la Note de Frais, les drapeaux de progression, la zone et
la case exacte.

Elle se déclenche automatiquement à la fin d'un combat, au changement de zone et à la
machine à café — et manuellement par le menu. Dans un navigateur, fermer l'onglet ne
prévient pas : c'est pour ça qu'elle est automatique.

---

## Équilibrage **[en jeu]**

*18 nov. 2026, demande de Sébastien. Réglé avec un simulateur qui rejoue les règles
ci-dessus (stats, dégâts, précision, critiques, types, café, états, recharges), des
milliers de combats par réglage.*

**Avant** : un combat durait 2 tours, un tiers se finissait dès le premier coup à
Sainte-Blandine, l'avantage de type gagnait 99 % du temps, et Nael était imbattable
(0 à 1 % de victoires avec une équipe de 3 au même niveau).

**Ce qui a changé**

- l'échelle des dégâts (voir « Les dégâts ») ;
- les types : ×1,5 / ×0,67 au lieu de ×2 / ×0,5 ;
- Roulian, *Lancer de dés* : 6 à 18 dégâts au lieu de 5 à 45 ;
- Guignome : attaque 22 (précision 90) au lieu de 30 (100), étourdissement toutes les
  5 tours au lieu de 3 ;
- Palou : attaque 24 au lieu de 18, Motivation de base 25 ;
- Seb : attaque 27 ; Thibouclier : attaque 26 ;
- Thomasu, Paguera, Thibouclier : Compétence de base 10 au lieu de 8 ;
- Nael et Tristan : Motivation 130, Compétence 20, Défense 16 (au lieu de 200 / 30 / 20),
  coups à 34 et 22 (Nael), 32 (Tristan). *Invisibilité* (Tristan) augmente maintenant sa
  propre Défense, et non celle du joueur.

**Résultats mesurés**

| Mesure | Résultat |
| --- | --- |
| Combat sauvage, joueur au niveau moyen de la zone | 51 à 77 % de victoires, 3 à 5 tours |
| KO dès le premier tour | 0 % |
| Victoires de chaque alternant contre tous les autres, même niveau | de 39 % (Palou) à 64 % (Guignome) |
| Nael niv. 12 contre une équipe de 3 au niveau 11 / 13 / 15 | 10 % / 65 % / 100 % |

**Progression vers le boss.** Après une victoire, l'alternant qui a combattu gagne un
niveau (jusqu'au niveau de l'adversaire + 3, + 4 avec Moustachette). Les autres membres
de l'équipe encore debout gagnent aussi un niveau tant qu'ils sont sous le niveau de
l'adversaire battu. Pour avoir une équipe vers le niveau 13 face à Nael (niveau 12), il
faut donc s'être battu dans les zones du sud, où les alternants vont jusqu'au niveau 13.
