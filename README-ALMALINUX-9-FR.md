# AlmaLinux 9 — Conteneur LXC Proxmox

Crée un conteneur LXC AlmaLinux 9 de base via le framework community-scripts.
Le conteneur est prêt à l'emploi : réseau configuré, OS à jour, accès root actif.

**Ce qui est nouveau ici** : le support d'AlmaLinux 9 comme OS de base, au même
titre que Debian (`ct/debian.sh`) ou Alpine (`ct/alpine.sh`) qui existaient déjà.
Le MOTD, l'autologin, la commande `update` et l'assistant interactif sont des
fonctionnalités du framework community-scripts, identiques sur tous les OS.
La seule différence propre à AlmaLinux est le gestionnaire de paquets : `dnf`
remplace `apt` (Debian/Ubuntu) et `apk` (Alpine).

## Prérequis

- Proxmox VE avec accès internet
- Shell root sur le nœud Proxmox

## Ressources par défaut

| Ressource | Valeur |
|-----------|--------|
| CPU       | 1 vCPU |
| RAM       | 512 MB |
| Disque    | 2 GB   |
| OS        | AlmaLinux 9 |
| Privilèges | Unprivileged |

## Utilisation

Exécuter la commande suivante depuis un shell root sur le nœud Proxmox :

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/almalinux.sh)"
```

L'assistant interactif propose deux modes :

- **Default** — crée le conteneur avec les ressources par défaut, sans confirmation à chaque étape
- **Advanced** — permet de personnaliser CPU, RAM, disque, réseau, mot de passe root, etc.

## Mise à jour du conteneur

Depuis le shell Proxmox, lancer le script `update` installé dans le conteneur :

```bash
pct exec <CTID> -- bash -c "update"
```

Ou depuis l'intérieur du conteneur :

```bash
update
```

Cette commande relance `ct/almalinux.sh` qui exécute `update_script()` : `dnf -y update` + `dnf -y upgrade`.

## Ce que le script fait

Les étapes 1 à 3 et 5 à 6 sont communes à tous les OS du framework (Debian,
Ubuntu, Alpine). Seule l'étape 4 est spécifique à AlmaLinux.

1. Télécharge le template AlmaLinux 9 depuis les dépôts Proxmox si absent
2. Crée le conteneur LXC avec les ressources choisies
3. Configure le réseau et vérifie la connectivité
4. **Met à jour l'OS via `dnf -y update`** ← spécifique AlmaLinux (`apt` sur Debian, `apk` sur Alpine)
5. Configure le MOTD (informations du conteneur à la connexion)
6. Active l'autologin root si aucun mot de passe n'est défini
