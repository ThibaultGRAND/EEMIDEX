# MOUSTACHE QUEST : Les Chasseurs d'Alternants de Confluence

> RPG pixel art au tour par tour dans le quartier Confluence, à Lyon.
> Le joueur est un·e grand·e patron·ne qui débarque à Perrache pour recruter des
> alternants, conquérir les arènes du quartier et monter son équipe avec les
> étudiants de l'EEMI, au 2ᵉ étage du Monolithe.

**Ce document remplace `cadrage.md` comme référence de contenu.** Le cadrage reste
valable pour la méthode et les contraintes techniques.

---

## 1. Le pitch

Paris, c'est fini. Trop cher, trop de concurrence. Le PDG de **Moustache Corp**
installe son nouveau siège à Lyon, dans le quartier le plus « innovant » de la ville :
**Confluence**.

Son plan est simple : monter une équipe entière **uniquement avec des alternants**.
Pas chers, motivés, et « ils apprennent tellement de choses ».

Mais à Confluence, chaque bâtiment est une **arène** tenue par un·e manager qui protège
ses talents. Pour avoir le droit de recruter à l'**EEMI**, il faut d'abord réunir
**8 Recommandations**.

Tout commence sur un quai de la **gare de Perrache**.

---

## 2. Le choix du héros

L'écran titre montre un TGV qui entre en gare de Perrache, au lever du soleil. Deux
silhouettes en descendent, valise à roulettes et costume trois-pièces.

| | **MOUSTACHE** | **MOUSTACHETTE** |
| --- | --- | --- |
| Statut | PDG de Moustache Corp | PDG de Moustachette & Associés |
| Look | Moustache en guidon, costume rayé, montre en or | Fine moustache recourbée, tailleur impeccable, AirPods vissés dans les oreilles |
| Style | Patron à l'ancienne, tape dans le dos, « mon petit » | Patronne start-up, parle en anglicismes, « on est une famille » |
| Bonus de départ | +10 % de chance de recrutement | +10 % d'XP pour les alternants |
| Réplique culte | *« Un alternant, c'est un CDI sans les inconvénients. »* | *« Je ne les exploite pas. Je les fais monter en compétences. »* |

Le personnage non choisi devient **le Rival**.

---

## 3. Les mécaniques

- **Les Alternants** sont les créatures du jeu. On les recrute dans les hautes herbes
  des quais, à la sortie du tram T1, dans les cafés.
- **Le Contrat d'Alternance** est l'objet de capture :

  | Contrat | Effet |
  | --- | --- |
  | Basique | taux de recrutement normal |
  | + Tickets Resto | taux amélioré |
  | + Télétravail 2j/semaine | taux très élevé |
  | CDI à la clé | recrutement garanti — **un seul exemplaire dans tout le jeu** |

- **Les stats d'un alternant** : Motivation (PV), Café (énergie pour les attaques),
  Compétence, Vitesse de rendu.
- **Le LinkedOut** : l'encyclopédie du jeu, où s'enregistrent tous les alternants
  rencontrés.
- **Les centres de soin** sont les **machines à café** : elles restaurent la Motivation
  et le Café de toute l'équipe.
- **La Note de Frais** est la monnaie. Elle sert à acheter des objets de motivation
  (PV) et des recettes de café (énergie).
- **Évolution** : un alternant évolue en finissant son année.
  `Chômeur` → `Stagiaire` → `Alternant`

### Les types

**Com et Marketing sont le même métier**, donc le même type : « Com » est un autre nom
de « Marketing ». Il reste **cinq types en cycle fermé**, chacun battant le suivant et
perdant contre le précédent.

| Type | Fort contre | Faible contre |
| --- | --- | --- |
| Dev | Data | Design |
| Data | Product | Dev |
| Product | Marketing | Data |
| Marketing *(= Com)* | Design | Product |
| Design | Dev | Marketing |

Soit la boucle : **Dev → Data → Product → Marketing → Design → Dev**.

Un cycle impair est plus propre qu'un cycle pair : aucune paire de types ne s'annule
mutuellement, et la règle tient en une phrase.

### Les types hors cycle

| Type | Qui | Effet |
| --- | --- | --- |
| **Staff** | Nael, Tristan — l'encadrement de l'école | Ni avantage ni désavantage, dans les deux sens. Ce ne sont pas des étudiants : on les bat sur les stats, pas sur le type. |
| **Neutre** | un alternant sans spécialité | Idem |

---

## 4. Les alternants

Les attaques marquées *(Passive)* se déclenchent sans être choisies : elles demandent un
système que le combat n'a pas encore.

### Thigoat — Dev
- **Lancer de sauce curry** : 20 dégâts à distance, brûle (3 PV par tour pendant 2 tours).
- **Lancer de p'tit wrap** : 15 dégâts, soigne Thigoat de 5 PV.
- **Bûcheronnage** : ses mains grandissent, +30 % de dégâts sur sa prochaine attaque.

### Roulian — Design
- **TDAHattack** : dégâts totalement aléatoires, entre 5 et 45.
- **Mise en bière** : +10 % de dégâts de façon permanente (sauf TDAHattack), cumulable 2 fois.
- **Gros doigt de pied** : 22 dégâts physiques.

### Matiti — Marketing
- **Attaque énergisante** *(Passive)* : +20 % sur ses prochains dégâts.
- **Attaque Bre-Som** : 12 dégâts, 50 % de chances de faire rater la prochaine attaque adverse.
- **BKtaque** : 28 dégâts lourds.

### Palou — Com *(= Marketing)*
- **La Vilainerie** : 18 dégâts, ignore 20 % de la défense.
- **aquababe** *(Passive)* : +25 % de risque que l'adversaire rate ou soit inefficace.

### Seb — Dev
- **Daronnage** : remet l'adversaire à sa place, 25 dégâts.
- **Tour de magie** *(Passive)* : étourdit l'adversaire 1 tour. Recharge : 3 tours.
- **Attaque Diet** : 10 dégâts, et −25 % de dégâts adverses au tour suivant.

### Thomasu — Dev
- **Crash boursier** : 5 dégâts, et −5 à −15 % sur les dégâts adverses pour tout le combat.
- **Noyade** : empêche d'attaquer pendant 1 tour. Recharge : 4 tours.
- **BTC attaque** : 30 à 40 dégâts massifs, coûte 5 PV à Thomasu.

### 👑 Nael — Staff — BOSS
*Multiplicateur de dégâts global +35 %, 200 PV.*
- **La FAWALISATION** : l'adversaire passe son tour. Chance de fuite réduite à 5 %.
- **RH attack** : 40 de base, soit ~54 dégâts réels.
- **EDUSIGN** : 32 dégâts, bloque les bonus adverses pendant 2 tours.

### 👑 Tristan — Staff — BOSS
*Multiplicateur de dégâts global +35 %, 200 PV.*
- **Invisibilité** : 15 dégâts, esquive les 2 prochaines attaques.
- **Alt attack** : force la fuite (réduite à 8 %). Si ça échoue, 30 dégâts.
- **Portes ouvertes** : 36 de base, soit ~48 dégâts réels.

### Paguera — Dev
- **Insensible à la douleur** : −30 à −50 % sur la prochaine attaque adverse.
- **Ink God** : 26 dégâts à l'aiguille à tatouage.

### Thibouclier — Dev
- **Rebond des attaques** : renvoie 60 % des dégâts reçus.
- **DEVATTACK** : 22 dégâts de code.

### Tortheo — Marketing
- **Carapace en feu** : +20 % de dégâts, s'inflige 5 PV par tour, dure 3 tours.
- **Tortatack** : 25 dégâts, 30 si la carapace est en feu.

### Guignome — Product
- **Attaque cernes** : endort l'adversaire 1 tour. Recharge : 3 tours.
- **Mario Karttaque** : carapace bleue inévitable, 30 dégâts.

### E1000 — Dev
- **Attaque headshot** : 30 dégâts, 20 % de critique (×1,5).
- **Parfum** : 18 dégâts, −10 % de précision adverse.

### CeCissoussou — Marketing
- **Storytelling intense** : 16 dégâts, −15 % de précision au tour suivant.
- **Placement produit** : 24 dégâts.
- **Hype virale** *(Passive)* : +5 % de dégâts cumulés par attaque réussie, max +20 %,
  remis à zéro en cas d'échec.

---

## 5. Les personnages

- **Gérard, assistant de direction** : il attend le joueur à Perrache avec un panneau.
  Fidèle depuis 25 ans, il porte la valise, gère l'agenda et donne des conseils souvent
  ignorés. C'est lui qui remet le premier alternant.
- **Le Rival** : le·la patron·ne non choisi·e, descendu·e du même train.
- **La Team Freelance** : des sbires en sweat à capuche qui veulent *libérer* les
  alternants pour en faire des freelances sans contrat ni mutuelle.
  *« Pas de patron, pas de problème ! (pas de salaire non plus) »*. Leur chef :
  **Louboubou**.
- **Mamie Rambaud** : promène son chien quai Rambaud, connaît tous les secrets du
  quartier et n'a pas peur des patrons.
- **Le recruteur de l'EEMI** : le champion final, aperçu de loin une ou deux fois.

---

## 6. L'arène finale : le Monolithe

- **Rez-de-chaussée** : l'accueil. Il faut montrer les 8 Recommandations au gardien.
- **1ᵉʳ étage, le Conseil Pédagogique** — 4 professeurs à la suite, sans retour à la
  machine à café :
  1. **Marketing Digital** (Marketing / Com) : *« Votre stratégie de recrutement n'a aucun KPI. »*
  2. **Data** : il a déjà calculé les chances de victoire du joueur (3,7 %).
  3. **Gestion de projet** (Product) : elle fait remplir un diagramme de Gantt avant chaque attaque.
  4. **Dev** (Dev / Design) : *« Ton code de recrutement ne compile pas. »*
- **2ᵉ étage, l'EEMI** : le Directeur pédagogique attend dans la salle de cours.

---

## 7. L'histoire, acte par acte

### Prologue — « Terminus Perrache »

*Gare de Perrache, quai B, 8 h 12.*

> **GÉRARD** : Bienvenue à Lyon, Monsieur le Président. Les bureaux de Confluence sont
> prêts. Il ne manque plus qu'une chose…
> **TOI** : Des employés.
> **GÉRARD** : Des employés, oui. Et le budget RH est de… *(il regarde sa tablette)*
> …zéro euro.
> **TOI** : Parfait. Alors on prend des alternants.

Gérard sort trois CV : **le joueur choisit son premier alternant**.

Au bout du quai, le Rival descend du même train.

> **RIVAL** : Tiens, tiens… Toi aussi, tu installes ton siège à Confluence ? Les
> meilleurs alternants de Lyon seront pour MOI. Et surtout ceux de l'EEMI.
> **TOI** : L'EEMI ?
> **RIVAL** : Deuxième étage du Monolithe. Mais le Directeur ne les laisse partir
> qu'aux patrons qui ont franchi les étages. Bonne chance, *« boss »*.

Le Rival prend l'alternant qui a l'avantage de type et défie le joueur sous la verrière.

**➜ Premier combat, tutoriel.**

Gérard remet **5 Contrats Basiques**, le **LinkedOut** et une carte du quartier.

> **GÉRARD** : Pour aller à Confluence, descendez le Cours Charlemagne vers le sud. Et
> Monsieur… essayez d'être gentil avec eux. Les alternants, ça parle entre eux.

### Acte 1 — « Le Cours Charlemagne »

Les quais de la Saône, la Place Nautique, les premières tours.

- Premiers alternants sauvages dans les hautes herbes du **quai Rambaud**.
- **Mamie Rambaud** : *« Un patron, hein ? Les alternants, c'est comme les pigeons, mon
  grand. Ils viennent quand on leur donne à manger. Essaie avec des tickets resto,
  radin. »*
- Première rencontre avec la **Team Freelance** : deux sbires tentent de convaincre un
  alternant de passer auto-entrepreneur.

> **SBIRE** : Encore un patron ! Tu viens les exploiter ! Nous, on les LIBÈRE !
> **TOI** : Et vous leur proposez quoi, exactement ?
> **SBIRE** : …de la visibilité.

### Acte suivant — « Le Quai du Monolithe »

Devant le Monolithe, au bord de la darse, une silhouette en sweat à capuche.

> **STAGIAIRE ZÉRO** : Tu ne me reconnais pas, hein ? Normal. Tu ne m'as jamais regardé.
> J'ai fait des photocopies pour toi pendant 2 ans. Tu m'avais promis un CDI. Le dernier
> jour, tu m'as offert… un mug. *(il sort un mug ébréché)* Je l'ai gardé. Pour ne jamais
> oublier. Et maintenant, tu veux les étudiants de l'EEMI ? Il faudra d'abord me passer
> sur le corps.

**➜ BOSS : le Stagiaire Zéro.** Six alternants niveau Lead, tous démissionnaires.

Après sa défaite, il entre avec le joueur dans le Monolithe.

> **STAGIAIRE ZÉRO** : Je veux voir ce que le Directeur va te dire.

### Acte final — « L'EEMI, 2ᵉ étage »

> **DIRECTEUR NAEL** : Alors c'est vous, le·la patron·ne dont tout Confluence parle.
> Mes étudiants ne sont pas des photocopieuses. Ce sont de futurs développeurs,
> designers, marketeurs, chefs de projet. Avant de vous en confier un seul, je veux
> savoir une chose. Vous les voulez pour les former… ou pour les exploiter ?

**➜ COMBAT FINAL.** Son équipe : ses deux meilleurs étudiants, un de chaque type, au
niveau maximum, et son recruteur **Tristan**.

---

## 8. Les deux fins

Un **compteur caché de Bienveillance RH** monte ou descend tout au long du jeu :

| Geste | Effet |
| --- | --- |
| Soigner son équipe à la machine à café | **+** |
| Faire combattre un alternant à 0 Motivation | **−** |
| Donner un Contrat + Télétravail plutôt qu'un Basique | **+** |
| Répondre « c'est formateur » à un alternant qui se plaint | **−** |
| Écouter les conseils de Gérard | **+** |

### 🌟 Fin bienveillante — compteur positif

Avant le dernier coup, l'équipe s'avance devant le Directeur et explique qu'elle a
**choisi** de rester. Le joueur tend au Stagiaire Zéro le **Contrat CDI à la clé**, le
seul du jeu.

> **TOI** : Je te le dois depuis 20 ans.

Le Stagiaire Zéro pose son mug. Le Directeur signe un partenariat avec l'EEMI. Dernière
image : le siège plein à craquer, Gérard sert le café.

> **TOI** : Finalement, la meilleure façon de recruter des alternants… c'est de bien les
> traiter.

### 💀 Fin exploiteuse — compteur négatif

Le Directeur soupire et laisse passer. Trente contrats signés d'un coup. Le lendemain,
les bureaux sont vides. Même Gérard est parti. Sur le fauteuil de PDG, un mot :

> *« On est tous passés freelance. Bisous. — Ton équipe. »*

À côté, un mug ébréché. Écran noir, bruit d'un TGV qui repart.
**« Tu es reparti·e à Paris. Seul·e. »**

---

## 9. Dialogues de remplissage

- *Un voyageur à Perrache* : « Perrache, c'est la seule gare où on se perd en sortant ET en entrant. »
- *Un alternant sauvage* : « Je cherche une entreprise… mais pas trop loin du tram. »
- *Un étudiant dans le tram T1* : « Il paraît que le 2ᵉ étage du Monolithe a la meilleure vue de Lyon. Dommage que les fenêtres ne s'ouvrent pas. »
- *Un joggeur sur les quais* : « Je cours pour oublier mon rapport de fin d'année. »
- *Un panneau devant la Sucrière* : « Expo du moment : "Le pixel, cet incompris". »
- *Une alternante fatiguée* : « Mon tuteur m'a dit que j'étais "force de proposition". Depuis, je fais tout. »
- *Gérard, si on lui parle trop souvent* : « Monsieur, ça fait 25 ans que je travaille pour vous. Toujours pas d'augmentation. Je dis ça, je dis rien. »
- *La machine à café* : « *Brrrrzzzt.* Votre équipe a retrouvé toute sa motivation. Prochain café : 0,50 €. »

---

## 10. Ce que le document ne dit pas encore

À trancher avant de coder les parties concernées :

- **Les 8 Recommandations** : seule l'arène du Monolithe est décrite. Les sept autres
  arènes, leurs managers et leurs bâtiments restent à inventer.
- **Le stat « Café »** : énergie dépensée par les attaques. Combien par attaque, comment
  elle se régénère, ce qui se passe à zéro.
- **Les passives** : six alternants en ont une. Le combat n'a aucun système pour ça.
- **Les trois CV du prologue** : quels alternants, et de quels types.
- **Le niveau « Lead »** et l'échelle de niveaux en général.
- **Consentement** : plusieurs alternants nommés ne figurent pas encore dans
  `consentement.md` (Nael, Tristan, Matiti, CeCissoussou, Paguera).
