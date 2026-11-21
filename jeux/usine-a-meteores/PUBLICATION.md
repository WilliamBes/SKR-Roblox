# Publier l'Usine à Météores

Tout ce qu'il faut préparer à la main avant de rendre le jeu public. Compte environ 2 heures, hors tests.

## 1. Réglages du jeu (Creator Dashboard, onglet du jeu)

| Réglage | Valeur |
| --- | --- |
| Nombre maximum de joueurs | **6** (il y a 6 usines : un 7e joueur serait renvoyé du serveur). Pour plus de joueurs, augmente `Config.Plot.count`. |
| Accès aux API (*Game Settings, Security*) | **Enable Studio Access to API Services** activé, sinon rien ne se sauvegarde en test |
| Appareils | Ordinateur, téléphone, tablette (l'interface s'adapte). Console : non, il n'y a pas de support manette. |
| Questionnaire d'âge | À remplir honnêtement (jeu sans violence, achats avec Robux, contenu aléatoire par œufs) |
| Langues | Ajoute dans *Localization* les 15 langues du jeu pour le titre, la description et les noms des achats |

## 2. Page du jeu (en anglais, pour toucher le monde entier)

**Titre** (max 50 caractères) : `Meteor Factory Tycoon`

**Description** (max 1000 caractères) :

> Meteors are falling on your factory!
> Collect them, upgrade your machines and rebirth to unlock new worlds.
>
> • Walk over meteors to collect them. Rare and legendary ones are worth a fortune
> • 4 upgrades, a passive-income refinery and a magnet to grab meteors from afar
> • Hatch eggs to get pets that boost your earnings
> • Rebirth to unlock 4 worlds: Meteor Plains, Frozen Wastes, Magma Core, Cosmic Void
> • Daily rewards, playtime gifts and promo codes
> • Playable in 15 languages
>
> Try the code LAUNCH for a free boost! (Open the Codes button on the left.)
>
> Updates every week!

Pour que le code `LAUNCH` marche, remplace `LANCEMENT` par `LAUNCH` dans `Config.Codes`, ou garde `LANCEMENT` et change le texte. Ne mets dans la description que des codes qui existent vraiment.

**Genre** : Tycoon. **Tags utiles** : tycoon, simulator, idle, pets.

## 3. Icône et miniatures

Roblox demande une icône 512×512 et jusqu'à 10 miniatures 1920×1080. Voici des prompts à donner à un générateur d'images (ils décrivent un style original, sans copier un jeu existant) :

- **Icône** : `Cute cartoon glowing orange meteor with a happy face, falling toward a small factory with a tall chimney, dark purple night sky with stars, bold outlines, bright saturated colors, square composition, game icon, no text`
- **Miniature 1** : `Wide shot of a colorful low-poly factory on a dark floating island at night, many glowing orange and blue meteors falling from the sky, golden coins flying, playful cartoon style, 16:9, no text`
- **Miniature 2** : `Three cute glowing pets (a comet, a moon creature, a phoenix) floating next to a Roblox-style character, magical sparkles, purple background, 16:9, no text`
- **Miniature 3** : `Four world islands side by side: green plains, frozen ice land, volcano with lava, cosmic purple void, cartoon game art, 16:9, no text`

Ajoute le titre `METEOR FACTORY` toi-même avec un éditeur d'image : les générateurs écrivent souvent mal le texte.

## 4. Achats Robux (Monetization)

Crée-les dans l'onglet *Monetization* du jeu, puis copie les ID dans `src/shared/Config.luau`.

| Objet | Type | Prix de départ | ID à copier dans |
| --- | --- | --- | --- |
| Argent x2 (`DoubleCash`) | Game pass | 199 R$ | `Config.GamePasses.DoubleCash.id` |
| Ramassage auto (`AutoCollect`) | Game pass | 149 R$ | `Config.GamePasses.AutoCollect.id` |
| Météores chanceux (`LuckyMeteors`) | Game pass | 249 R$ | `Config.GamePasses.LuckyMeteors.id` |
| Boost x3 (`Boost`) | Developer product | 29 R$ | `Config.Products.Boost.id` |
| Pluie d'argent (`CashPack`) | Developer product | 49 R$ | `Config.Products.CashPack.id` |
| Pluie de météores (`MeteorShower`) | Developer product | 79 R$ | `Config.Products.MeteorShower.id` |

Les œufs s'achètent avec l'argent du jeu, pas avec des Robux : pas besoin d'afficher de règles de tirage payant, mais les chances sont déjà montrées dans la fenêtre.

## 5. Avant de publier

- [ ] Remets `Config.Studio` à `0` (`minCash` et `minRebirths`)
- [ ] Joue 15 minutes jusqu'au premier rebirth, sur ordinateur puis sur téléphone (*Test*, *Device* dans Studio)
- [ ] Teste un achat avec un faux compte ou en mode test de Roblox
- [ ] Vérifie que la sauvegarde marche : joue, quitte, reviens
- [ ] Mets les ID des achats dans `Config.luau` et republie
- [ ] Rends le jeu public (*Game Settings, Permissions*)

## 6. Après la publication

- Regarde dans le Creator Dashboard : temps de jeu moyen, retour le lendemain, achats. Le temps de jeu et le retour à J+1 décident si Roblox pousse ton jeu.
- Une mise à jour par semaine (nouveau code, nouvel œuf, événement) fait remonter le jeu dans la découverte.
- Les clips courts (TikTok, Shorts) d'un météore légendaire ou d'un Phénix sont ce qui fait connaître un jeu de ce genre.
- La pub dans Roblox (*Sponsored Ads*) peut aider au lancement, avec un petit budget d'abord, pour mesurer ce que coûte un joueur.
- Les gains ne sont pas garantis : beaucoup de jeux n'ont presque aucun joueur. Compte plusieurs jeux et plusieurs mises à jour avant de juger.
