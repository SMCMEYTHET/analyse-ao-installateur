# Correctif 0.5.1 — lecture IA des PDF avec Claude

## Symptôme
Avec le fournisseur « Claude (Anthropic) » (modèle par défaut `claude-sonnet-5-5`),
« Lire avec l'IA » échoue sur tout PDF ou image, ainsi que le classement IA des postes :

> Claude a refusé la demande (400) : …temperature…

## Cause
`server/ia.js` envoie `temperature: 0` à l'API Messages (lecture des pièces et classement).
Les modèles Claude récents (Sonnet 5.5, Opus 4.7 et suivants) refusent toute valeur
de `temperature` autre que celle par défaut (erreur 400). La lecture Gemini n'est pas concernée.

## Correction
Retirer `temperature: 0` des deux appels Claude — voir `0.5.1-lecture-ia-claude.patch`
(à appliquer dans le dépôt source, à la racine du serveur : `git apply`).

## Contournement immédiat
Réglages > Lecture IA : passer sur Gemini, ou, sur un PC déjà installé, supprimer les deux lignes
`temperature: 0,` des appels Claude dans
`<dossier d'installation>\resources\serveur\server\ia.js`, puis relancer Analyse AO.
