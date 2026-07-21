# Graphs·Clone

Visualiseur de données interactif, mono-fichier HTML, inspiré de GNOME Graphs. Affichage pur — aucun traitement, calcul ou transformation des données importées.

Pensé pour l'ingénierie simulation / analyse de mesures, sur poste verrouillé et hors ligne.

## Utilisation

Double-cliquer sur `graphs-clone.html` pour l'ouvrir dans le navigateur. Aucune installation, aucun serveur, aucune connexion réseau requise.

1. **Importer CSV** → choisir un ou plusieurs fichiers. Pour chaque fichier, une boîte de dialogue propose un aperçu, le séparateur/décimale/en-tête détectés (modifiables), le choix de la colonne X et des colonnes Y à importer, et le nom du jeu de données.
2. Le panneau **Données** (à gauche) liste les jeux importés et leurs séries — il fait aussi office de légende : cliquer une série la sélectionne pour la styliser, cliquer l'œil 👁 la masque/affiche.
3. Le panneau **Style** (sous Données) permet de personnaliser en temps réel la série sélectionnée : couleur, épaisseur, style de trait, marqueur, opacité, axe Y primaire/secondaire.
4. **Export PNG** exporte l'état actuel du graphe.
5. Le bouton **⚙** règle l'affichage : taille des libellés d'axes, croix au survol.

## Sauvegarde du travail

Le menu **Projet** de la barre supérieure gère la persistance :

- **Enregistrer le projet…** télécharge un fichier `.json` contenant les données importées, la sélection des colonnes, tous les styles de courbes, le cadrage et les réglages d'affichage. Ce fichier s'archive à côté des CSV d'origine.
- **Ouvrir un projet…** recharge un tel fichier et restaure l'état complet.
- **Nouveau projet** repart d'une page vide.

Une **sauvegarde automatique** est également conservée dans le navigateur : rouvrir le fichier restaure la dernière session (message « Session précédente restaurée »). Elle est liée au navigateur et à la machine — pour archiver ou transférer un travail, utiliser *Enregistrer le projet*.

Les fichiers du dossier `exemples/` couvrent les trois combinaisons courantes de séparateur/décimale (utile pour tester l'import) :

| Fichier | Séparateur | Décimale | En-tête |
|---|---|---|---|
| `exemple-temperature.csv` | `,` | `.` | oui |
| `exemple-vibrations.csv` | `;` | `,` | oui |
| `exemple-reponse-frequentielle.txt` | espace | `.` | non |

## Interactions du graphe

| Action | Effet |
|---|---|
| Molette | Zoom centré sur le curseur |
| Clic-glissé | Déplace la vue (pan) |
| Maj + clic-glissé | Zoom boîte sur la zone dessinée |
| Double-clic | Recadre automatiquement sur les séries visibles |
| Survol | Croix + point le plus proche + valeurs `(x, y)` — la croix est désactivable via la case « croix au survol » dans la barre de statut |

## Format d'entrée

- 1 colonne X + N colonnes Y par fichier ; chaque fichier garde sa propre colonne X.
- Séparateur (`,` `;` tabulation espace) et décimale (`.` ou `,`) auto-détectés, modifiables au dialogue d'import.
- 1ʳᵉ ligne non numérique = noms de colonnes, sinon colonnes nommées automatiquement.
- Lignes débutant par `#` ignorées (commentaires).

## Contraintes

Fichier HTML unique, zéro dépendance et zéro CDN, rendu par un canvas maison, fonctionne entièrement hors ligne. Le détail complet des spécifications fonctionnelles est dans `graphs-clone-spec.md`.

## Hors périmètre

Tout traitement ou calcul sur les données (équations, fit), échelle logarithmique, export CSV, export SVG.

> La sauvegarde/restauration de projet a été ajoutée après coup ; elle est donc encore listée comme hors périmètre dans `graphs-clone-spec.md` (v0.3), à mettre à jour lors d'une prochaine révision de la spec.
