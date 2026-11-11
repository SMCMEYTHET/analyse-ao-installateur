#!/usr/bin/env bash
# Construit l'installateur Analyse AO 0.5.2 à partir de l'installateur 0.5.1 publié :
# même application (Electron 37.10.3, mêmes fichiers), avec le correctif de lecture IA Claude
# (correctifs/0.5.1-lecture-ia-claude.patch) et le numéro de version passé à 0.5.2.
# Usage : outils/construire-0.5.2.sh <dossier de travail>   → <dossier>/proj/dist/Analyse-AO-Installateur-0.5.2.exe
set -euo pipefail

DEPOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
W="$(mkdir -p "$1" && cd "$1" && pwd)"
SOURCE_URL="https://github.com/SMCMEYTHET/analyse-ao-installateur/releases/download/v0.5.1/Analyse-AO-Installateur-0.5.1.exe"
SOURCE_SHA256="cc6e60d2155f0a62392b6e3f7ed962b361a8eec4f262c27778ae3ed27061dc4d"
cd "$W"

echo "== Téléchargement de l'installateur 0.5.1"
curl -sSfL -o setup-0.5.1.exe "$SOURCE_URL"
echo "$SOURCE_SHA256  setup-0.5.1.exe" | sha256sum -c -

echo "== Extraction"
rm -rf nsis win-unpacked appsrc proj
7z x -y -onsis setup-0.5.1.exe > /dev/null
7z x -y -owin-unpacked 'nsis/$PLUGINSDIR/app-64.7z' > /dev/null
R="win-unpacked/resources"

echo "== Correctif lecture IA Claude"
(cd "$R/serveur" && git apply --verbose "$DEPOT_DIR/correctifs/0.5.1-lecture-ia-claude.patch")
# Les appels Claude ne doivent plus envoyer temperature ; ceux de Gemini la gardent (2 lignes).
test "$(grep -c 'temperature: 0' "$R/serveur/server/ia.js")" -eq 2

echo "== Version 0.5.2"
sed -i 's/"version": "0.5.1"/"version": "0.5.2"/' "$R/serveur/package.json"
grep -q '"version": "0.5.2"' "$R/serveur/package.json"
npx --yes @electron/asar@3.2.17 extract "$R/app.asar" appsrc
sed -i 's/"version": "0.5.1"/"version": "0.5.2"/' appsrc/package.json
grep -q '"version": "0.5.2"' appsrc/package.json
npx --yes @electron/asar@3.2.17 pack appsrc "$R/app.asar"

echo "== Installateur (mêmes réglages que 0.5.1 : appId fr.analyse-ao.app, un clic, par utilisateur)"
mkdir -p proj/build
cp appsrc/build/icon.png proj/build/icon.png
cat > proj/package.json <<'EOF'
{
  "name": "analyse-ao-desktop",
  "productName": "Analyse AO",
  "version": "0.5.2",
  "description": "Analyse AO - application Windows (fenêtre + serveur embarqué)",
  "author": "Analyse AO",
  "private": true,
  "main": "main.js",
  "build": {
    "appId": "fr.analyse-ao.app",
    "productName": "Analyse AO",
    "electronVersion": "37.10.3",
    "directories": { "output": "dist", "buildResources": "build" },
    "win": { "target": [{ "target": "nsis", "arch": ["x64"] }], "icon": "build/icon.png", "signAndEditExecutable": false },
    "nsis": { "artifactName": "Analyse-AO-Installateur-${version}.${ext}" }
  }
}
EOF
cd proj
npm i -D electron-builder@26.0.12 --no-audit --no-fund
# electron-builder s'arrête parfois après l'installateur, sur le fichier de mise à jour
# automatique qu'Analyse AO n'utilise pas : on vérifie donc le résultat nous-mêmes.
npx electron-builder --win nsis --x64 --prepackaged ../win-unpacked --publish never || true
test -s dist/Analyse-AO-Installateur-0.5.2.exe
test -s dist/Analyse-AO-Installateur-0.5.2.exe.blockmap

echo "== Contrôle du contenu de l'installateur"
cd "$W"
rm -rf verif && 7z x -y -overif/nsis proj/dist/Analyse-AO-Installateur-0.5.2.exe > /dev/null
7z x -y -overif/app 'verif/nsis/$PLUGINSDIR/app-64.7z' > /dev/null
grep -q '"version": "0.5.2"' verif/app/resources/serveur/package.json
cmp verif/app/resources/serveur/server/ia.js "$R/serveur/server/ia.js"
test -f "verif/nsis/\$R0/Uninstall Analyse AO.exe"
sha256sum proj/dist/Analyse-AO-Installateur-0.5.2.exe
echo "OK : $W/proj/dist/Analyse-AO-Installateur-0.5.2.exe"
