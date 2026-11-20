#!/usr/bin/env bash
# Simule l'économie du jeu et affiche le temps entre deux rebirths.
# Usage : ./outils/simulation.sh [nombre de rebirths] [part de météores ramassés entre 0 et 1]
# Il faut le programme « luau » : https://github.com/luau-lang/luau/releases
set -e
cd "$(dirname "$0")"
TMP="$(mktemp --suffix=.luau)"
{
  echo "local COUNT, RATIO = '${1:-10}', '${2:-0.7}'"
  # Config sans les couleurs Roblox (inutiles ici)
  sed -e 's/Color3\.fromRGB([^)]*)/0/g' ../src/shared/Config.luau | sed '$d'
  cat simulation.luau
} > "$TMP"
luau "$TMP"
rm -f "$TMP"
