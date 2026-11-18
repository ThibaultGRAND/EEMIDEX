# Provenance et licence des fichiers audio

Même règle que `assets/maps/SOURCES.md` : rien n'entre dans le jeu sans savoir
d'où ça vient. Les crédits du jeu devront reprendre ce qui est écrit ici.

> **⚠ À REMPLIR PAR L'ÉQUIPE — les deux colonnes « Auteur » et « Licence » sont
> vides parce que personne ne les a données.** Les fichiers ont été transmis
> bruts, sans mention d'origine. Tant que ces cases ne sont pas remplies, on ne
> sait pas si le jeu a le droit de les diffuser, et la case « licences » du
> CLAUDE.MD reste non cochée.
>
> - Auteur : …
> - Licence : …
> - Si ces sons ont été **générés** (Suno, ElevenLabs, autre) : nommer l'outil,
>   la date, et vérifier ses conditions d'utilisation commerciale / de diffusion.
> - Si ils viennent d'une **banque de sons** : nommer le site, le numéro de
>   licence, et si l'attribution est obligatoire.

## Ce qu'on sait avec certitude

- Les 16 fichiers ont été fournis par l'équipe le **18 novembre 2026**, en deux
  envois (les 3 musiques d'abord, les 13 bruitages ensuite), sous forme d'un
  dossier partagé.
- Aucun n'a été produit par Claude : la conversion seule a été faite ici.
- Sources d'origine en `.mp3`, sauf la musique de boutique, livrée en `.wav`.
  Les originaux ne sont **pas** dans le dépôt (37 Mo) : seuls les `.ogg`
  convertis y sont.

## Conversion appliquée

Ogg Vorbis qualité 3, 44,1 kHz, avec `ffmpeg` (pris via le paquet Python
`imageio-ffmpeg`, rien n'a été installé sur le poste) :

    ffmpeg -i source.mp3 -vn -c:a libvorbis -q:a 3 -ar 44100 assets/audio/nom.ogg

Les bruitages courts ont en plus été rognés de leurs silences de début et de
fin (sinon `niveau_gagne` répondait 0,18 s trop tard) :

    -af "silenceremove=start_periods=1:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_threshold=-50dB,areverse"

## Correspondance fichier d'origine → fichier du jeu

| Fichier reçu | Dans le jeu | Durée | Auteur | Licence |
| --- | --- | --- | --- | --- |
| `exploration.mp3` | `exploration.ogg` | 3 min 45 | ? | ? |
| `combat.mp3` | `combat.ogg` | 1 min 57 | ? | ? |
| `shop.wav` | `boutique.ogg` | 2 min 32 | ? | ? |
| `bruit de fond gare .mp3` | `ambiance_gare.ogg` | 1 min 36 | ? | ? |
| `arrivee train en gare.mp3` | `train_en_gare.ogg` | 38,7 s | ? | ? |
| `bruit texte taper.mp3` | `texte.ogg` | 10,1 s | ? | ? |
| `bruit entree shop.mp3` | `entree_boutique.ogg` | 7,0 s | ? | ? |
| `gagner un combat.mp3` | `victoire.ogg` | 6,7 s | ? | ? |
| `defaite.mp3` | `defaite.ogg` | 3,1 s | ? | ? |
| `attaque.mp3` | `attaque.ogg` | 1,9 s | ? | ? |
| `achat boutique.mp3` | `achat.ogg` | 1,0 s | ? | ? |
| `amelioration_ level up.mp3` | `niveau_gagne.ogg` | 0,8 s | ? | ? |
| `marche.mp3` | `marche.ogg` | 0,28 s | ? | ? |
| `click.mp3` | `clic.ogg` | 0,22 s | ? | ? |
| `bruit passer dialogue.mp3` | `dialogue_suivant.ogg` | 0,16 s | ? | ? |
| `entree dans un lieux.mp3` | `entree_lieu.ogg` | 0,13 s | ? | ? |

Les durées sont celles des `.ogg` du jeu, après rognage des silences.
