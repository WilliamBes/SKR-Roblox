# SKR Roblox

Tous les jeux Roblox de William, écrits en Luau et synchronisés avec Roblox Studio grâce à [Rojo](https://rojo.space).

```
commun/                 code partagé par tous les jeux
  shared/Format.luau    affichage des nombres (1.2K, 3.4M…)
  server/PlayerData.luau  sauvegarde des joueurs (DataStore)
jeux/
  usine-a-meteores/     premier jeu : tycoon de météores
```

Chaque jeu a son propre `default.project.json` qui inclut le dossier `commun/`.

## Installation (une seule fois)

1. Installe [Roblox Studio](https://create.roblox.com/) et [VS Code](https://code.visualstudio.com/).
2. Installe [Rokit](https://github.com/rojo-rbx/rokit) (gestionnaire d'outils), puis dans ce dossier lance `rokit install` : ça installe la bonne version de Rojo.
3. Dans Roblox Studio, installe le plugin Rojo : onglet *Plugins* → *Manage Plugins*, ou lance `rojo plugin install`.
4. Dans VS Code, installe l'extension « Luau Language Server » (autocomplétion).

## Lancer un jeu

Voir le README du jeu, par exemple [jeux/usine-a-meteores](jeux/usine-a-meteores/README.md).
