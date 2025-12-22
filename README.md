ll
# Liaison Git ↔ Dataverse via Microsoft Power Platform CLI

## Prérequis
- Git installé et accès à un dépôt (GitHub/GitLab/...)
- Power Platform CLI (pac) installé
- Compte Azure AD avec droits sur l'environnement Dataverse

## Étapes rapides

1. Initialiser le dépôt local
```bash
git init
echo "# .gitignore" > .gitignore
# ajouter patterns (node_modules, .vs, etc.)
git add .
git commit -m "Init repo"
git remote add origin <url-repo>
git push -u origin main
```

2. Installer et s'authentifier au CLI
```bash
# installer pac (suivre la doc officielle) puis :
pac auth create --url https://<votre-org>.crm.dynamics.com --name prod
pac auth select --name prod
```

3. Récupérer (exporter) la solution Dataverse en local
```bash
# télécharger / cloner la solution vers un dossier local

pac org select --env https://org2cd222c0.crm4.dynamics.com/ 
.\Export-Unpack-PP.ps1 -SolutionName "Dematerialisation_des_Processus" -ProcessCanvasApps

```

4. Versionner la solution
```bash

git add src/solutions
git commit -m "DEV updates"
git push origin dev
```

5. Déployer (importer) depuis le dépôt vers Dataverse
```bash

#Prendre en main le script de mise en prod à avant de continuer

git checkout main && git pull
# si la solution est packagée en .zip :

# ou utiliser la commande d'import/deploiement appropriée du CLI
```

6. Intégration continue (recommandé)
- Créer un workflow CI/CD (GitHub Actions / Azure DevOps) qui :
    - s'authentifie via le CLI (using secrets)
    - télécharge/pack/importe la solution automatiquement sur l'environnement cible

## Bonnes pratiques
- Utiliser des branches pour chaque fonctionnalité
- Stocker les secrets (client id/secret) dans les secrets du CI
- Versionner uniquement les fichiers sources (pas les binaires générés)
- Documenter les commandes et profils d'authentification dans le README

</README>