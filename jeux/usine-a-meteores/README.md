# Usine à Météores

Tycoon incrémental : des météores tombent sur ton usine, tu les ramasses en passant à côté, tu améliores ta production, puis tu fais un rebirth pour un multiplicateur permanent.

## Ce qui est déjà codé

- Carte générée par le code : 6 usines autour d'un spawn, ambiance de nuit.
- Météores Commun, Rare (x6) et Légendaire (x40), avec annonce à tout le serveur pour les légendaires.
- 4 améliorations : Valeur, Fréquence, Raffinerie (revenu passif), Aimant (rayon de ramassage).
- Rebirth : remet l'argent et les améliorations à zéro, +0,5 de multiplicateur à chaque fois.
- Sauvegarde automatique (toutes les 60 s, à la sortie et à l'arrêt du serveur).
- Boutique : 3 game passes (Argent x2, Ramassage auto, Météores chanceux) et 3 developer products (Boost x3 5 min, Pluie d'argent, Pluie de météores).
- Interface adaptée aux téléphones, « +X $ » flottants, ondes de choc, secousse de caméra.
- Tutoriel : 8 objectifs récompensés, avec une traînée lumineuse vers les météores au début et le bouton d'amélioration à acheter qui clignote.
- Cadeaux de temps de jeu (3, 8, 15, 25 et 40 minutes) et récompense quotidienne qui grossit sur 7 jours de suite.
- Classements globaux au spawn : les plus riches et le plus de rebirths.
- Codes promo (`LANCEMENT`, `METEORE`) à modifier dans `Config.Codes`.
- Sons de ramassage, d'impact, d'achat et de récompense (modifiables dans `Config.Sounds`).
- L'usine se construit : cristaux (Valeur), radars (Fréquence), pylônes (Aimant), tapis roulant et cheminées (Raffinerie), et la bordure change de couleur à chaque rebirth.

Tous les réglages (prix, vitesses, chances) sont dans [`src/shared/Config.luau`](src/shared/Config.luau).

## Équilibrage

`./outils/simulation.sh` simule un joueur qui joue bien et affiche le temps entre deux rebirths (il faut le programme [luau](https://github.com/luau-lang/luau/releases)). Réglage actuel : premier rebirth au bout de 8 minutes pour un joueur parfait, donc 15 à 25 minutes pour un vrai joueur, puis des rebirths de plus en plus longs (1 heure vers le 10e). Après avoir changé des prix dans `Config.luau`, relance la simulation.

## Tester dans Studio (10 minutes)

1. Ouvre Roblox Studio, crée une place vide (*Baseplate*).
2. Dans un terminal, va dans ce dossier et lance :
   ```
   cd jeux/usine-a-meteores
   rojo serve
   ```
3. Dans Studio, onglet *Plugins* → *Rojo* → *Connect*. Le code apparaît dans l'Explorer.
4. Appuie sur *Play*. Tu dois apparaître sur ton usine et voir tomber des météores.

Pour tester la sauvegarde dans Studio : *File* → *Publish to Roblox*, puis *Game Settings* → *Security* → active **Enable Studio Access to API Services**.

## Publier et monétiser

1. *File* → *Publish to Roblox*, puis rends le jeu public dans *Game Settings* → *Permissions*.
2. Sur [create.roblox.com](https://create.roblox.com/dashboard/creations), ouvre le jeu → *Monetization* :
   - *Passes* : crée Argent x2, Ramassage auto, Météores chanceux.
   - *Developer Products* : crée Boost x3, Pluie d'argent, Pluie de météores.
3. Copie chaque ID dans `src/shared/Config.luau` (à la place des `0`), puis republie.

Prix de départ conseillés : Argent x2 = 199 R$, Ramassage auto = 149 R$, Météores chanceux = 249 R$, Boost = 29 R$, Pluie d'argent = 49 R$, Pluie de météores = 79 R$.

## Ce qu'il reste à faire à la main

- Icône du jeu (512×512) et 3 miniatures (1920×1080).
- Tester sur téléphone (dans Studio : *Test* → *Device*).
- Description et titre du jeu, en anglais pour toucher le plus de monde.
