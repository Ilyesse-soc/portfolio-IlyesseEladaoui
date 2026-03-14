# portfolio-IlyesseEladaoui

Portfolio statique (HTML/CSS/JS) de Ilyesse El Adaoui.

## Local
- Ouvrir `index.html` dans un navigateur, ou lancer un serveur local.

## Auto-push (mise à jour automatique sur GitHub)
Ce repo inclut un watcher PowerShell qui, à chaque modification de fichier, fait automatiquement `git add`, `git commit`, puis `git push`.

- Dans VS Code : la tâche **Auto-push: watch & sync to GitHub** démarre automatiquement à l’ouverture du dossier.
- Pour l’arrêter : `Terminal` → arrêter la tâche (ou fermer le terminal de la tâche).
- Pour désactiver l’auto-démarrage : enlever `runOptions.runOn` dans `.vscode/tasks.json`.
- Ou en terminal :
	- `powershell -NoProfile -ExecutionPolicy Bypass -File scripts\autopush.ps1`

Remarque : ouvre le site via un serveur (HTTP) plutôt que `file://` si tu veux afficher le PDF (CV) dans une fenêtre intégrée.
