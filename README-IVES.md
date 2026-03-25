# AlmaLinux 9 IVES — Conteneur LXC Proxmox

Crée un conteneur LXC AlmaLinux 9 et y applique automatiquement le script de
préparation IVES (`prepare-almalinux-9-server.sh`) hébergé sur le GitLab interne.

## Prérequis

- Proxmox VE avec accès internet et accès au GitLab IVES (`git.ives.fr`)
- Shell root sur le nœud Proxmox
- Variable d'environnement `GITLAB_TOKEN` définie avec un token GitLab valide
  (accès lecture sur le projet 173)

## Ressources par défaut

| Ressource  | Valeur      |
|------------|-------------|
| CPU        | 1 vCPU      |
| RAM        | 2048 MB     |
| Disque     | 2 GB        |
| OS         | AlmaLinux 9 |
| Privilèges | Unprivileged |

## Configuration du token GitLab

Le token doit être disponible dans l'environnement du shell qui lance le script.
La méthode recommandée est de le définir dans `/etc/environment` sur le nœud
Proxmox pour qu'il persiste entre les sessions :

```bash
echo 'GITLAB_TOKEN=glpat-xxxxxxxxxxxxxxxxxxxx' >> /etc/environment
source /etc/environment
```

Ne pas stocker le token directement dans le script.

## Utilisation

Une fois `GITLAB_TOKEN` défini, exécuter depuis un shell root sur le nœud Proxmox :

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/InteractiviteVideoEtSystemes/ProxmoxVE/refs/heads/feat/add-almalinux-lxc-support/ct/almalinux-ives.sh)"
```

L'assistant interactif propose deux modes :

- **Default** — crée le conteneur avec les ressources par défaut
- **Advanced** — permet de personnaliser CPU, RAM, disque, réseau, mot de passe root, etc.

## Ce que le script fait

1. Télécharge le template AlmaLinux 9 depuis les dépôts Proxmox si absent
2. Crée le conteneur LXC avec les ressources choisies
3. Configure le réseau et vérifie la connectivité
4. Met à jour l'OS (`dnf -y update`)
5. Configure le MOTD et l'autologin root
6. Exécute `prepare-almalinux-9-server.sh` depuis le GitLab IVES à l'intérieur
   du conteneur via `pct exec`

## Mise à jour du conteneur (OS uniquement)

```bash
pct exec <CTID> -- bash -c "update"
```

La commande `update` met à jour l'OS via `dnf`. Elle ne re-joue pas le script
de préparation IVES. Pour re-appliquer la configuration IVES manuellement :

```bash
pct exec <CTID> -- bash -c "$(curl -fsSL \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
  "https://git.ives.fr/api/v4/projects/173/repository/files/prepare-almalinux-9-server.sh/raw?ref=master")"
```

## Dépannage

**Erreur `GITLAB_TOKEN not set`**
Le script refuse de démarrer si la variable n'est pas définie. Vérifier avec :
```bash
echo $GITLAB_TOKEN
```

**Erreur lors du `pct exec` (script IVES)**
La phase de setup standard s'est bien déroulée ; seule la personnalisation IVES
a échoué. Le conteneur existe et est fonctionnel. Corriger le problème dans
`prepare-almalinux-9-server.sh` puis re-jouer la commande manuelle ci-dessus.
