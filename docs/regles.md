# Règles du jeu

Le corps de règles complet de **Moustache Quest**. `histoire.md` dit *ce que* le jeu
raconte ; ce document dit *comment* il se joue, avec les nombres.

Chaque règle porte sa mention :
**[en jeu]** elle tourne · **[à faire]** elle est décidée mais pas codée · **[à valider]**
elle attend l'accord de l'équipe.

---

## 1. Les alternants

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
| L'attaquant bat le type de la cible | **×2** |
| La cible bat le type de l'attaquant | **×0,5** |
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
         × multiplicateur de type
         × aléa entre 0,85 et 1,00
minimum 1
```

Une attaque qui rate ne fait rien : chaque attaque a une **précision** en pourcentage,
tirée avant le calcul.

### Les attaques de soutien **[en jeu]**

Une attaque de puissance 0 ne fait pas de dégâts. Elle peut :

- **soigner** son lanceur d'un nombre fixe de points de Motivation ;
- **modifier une stat** — Compétence, Défense ou Vitesse — de l'alternant visé.

Les modifications de stat durent **jusqu'à la fin du combat** et sont annulées à la
sortie. Elles se cumulent sans plafond. *(Un plafond serait plus sain : à surveiller
à l'équilibrage.)*

### Le Café **[à faire]**

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

### Les contrats **[à faire]**

| Contrat | Valeur | Effet sur la chance |
| --- | --- | --- |
| Basique | 30 | +15 points |
| + Tickets Resto | 50 | +25 points |
| + Télétravail 2j | 80 | +40 points |
| CDI à la clé | — | réussite garantie, **un seul dans tout le jeu** |

*Seul le Contrat Basique existe en données aujourd'hui.*

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

**En croisant un alternant qui se balade.** Huit alternants arpentent le quartier.

| Le joueur lui marche dessus | |
| --- | --- |
| 60 % | il se bat |
| 25 % | il s'enfuit et continue sa course |
| 15 % | il ignore poliment |

Et **12 %** du temps, un alternant qui arrive sur une case voisine du joueur
l'attaque de lui-même. La rencontre n'est pas un menu.

### Les lieux **[en jeu]**

| Case | Effet |
| --- | --- |
| Machine à café | remotive toute l'équipe, gratuitement, et sauvegarde |
| Boutique | échange de ressources contre des objets |
| Borne d'entraînement | lance un mini-jeu |
| Voûte | téléporte à l'autre bout du passage |
| Objet au sol | ramassé une seule fois, définitivement |
| Sortie de zone | change de zone, et sauvegarde |

### Les zones **[en jeu]**

Quatre zones reliées du nord au sud, de Perrache à la Pointe. Les niveaux des
alternants sauvages montent à mesure qu'on descend le quartier.

---

## 6. L'économie **[en jeu, à refondre]**

Trois ressources se ramassent sur la carte, deux par gisement. Elles servent à la
boutique et débloquent les niveaux de difficulté des mini-jeux.

| Ressource | Quantité possédée | Difficulté débloquée |
| --- | --- | --- |
| — | 0 à 2 | niveau 1 |
| — | 3 à 7 | niveau 2 |
| — | 8 et plus | niveau 3 |

*Le document d'histoire prévoit une monnaie unique, la **Note de Frais**. Les trois
ressources actuelles sont un héritage de la version précédente du jeu : à remplacer.*

---

## 7. L'entraînement **[en jeu]**

Les mini-jeux montent **définitivement** une stat de l'alternant entraîné.

| Mini-jeu | Stat | Gain |
| --- | --- | --- |
| Frappe chronométrée | Compétence | `score × difficulté ÷ 4`, plafonné à 3 |
| Rythme | Vitesse de rendu | 90 % de réussite : `2 + difficulté` · 60 % : `1 + difficulté ÷ 2` · 35 % : 1 |

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

## 8. L'évolution **[à valider]**

`Chômeur → Stagiaire → Alternant`, en finissant son année.

**Rien n'est décidé** : ni le déclencheur — niveau atteint, nombre de combats, objet —
ni ce que l'évolution change dans les stats, ni si elle modifie le type ou les attaques.

---

## 9. La Bienveillance RH **[à faire]**

Un compteur caché décide de la fin du jeu.

| Geste | Effet |
| --- | --- |
| Remotiver l'équipe à la machine à café | **+** |
| Faire combattre un alternant à 0 de Motivation | **−** |
| Utiliser un contrat généreux plutôt qu'un Basique | **+** |
| Répondre « c'est formateur » à un alternant qui se plaint | **−** |
| Écouter Gérard | **+** |

Positif à la fin : les alternants restent. Négatif : ils passent tous freelance.

---

## 10. La sauvegarde **[en jeu]**

Une seule sauvegarde, dans `user://`, en JSON. Elle garde l'équipe avec niveaux,
Motivation et bonus, le sac, les ressources, les drapeaux de progression, la zone et
la case exacte.

Elle se déclenche automatiquement à la fin d'un combat, au changement de zone et à la
machine à café — et manuellement par le menu. Dans un navigateur, fermer l'onglet ne
prévient pas : c'est pour ça qu'elle est automatique.
