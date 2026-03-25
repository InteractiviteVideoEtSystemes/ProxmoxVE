# AlmaLinux 9 — Proxmox LXC Container

Creates a base AlmaLinux 9 LXC container using the community-scripts framework.
The container is ready to use out of the box: network configured, OS up to date, root access enabled.

**What is new here**: support for AlmaLinux 9 as a base OS, on par with
Debian (`ct/debian.sh`) or Alpine (`ct/alpine.sh`) which already existed.
The MOTD, autologin, `update` command and interactive wizard are community-scripts
framework features, identical across all supported OSes.
The only difference specific to AlmaLinux is the package manager: `dnf`
replaces `apt` (Debian/Ubuntu) and `apk` (Alpine).

## Requirements

- Proxmox VE with internet access
- Root shell on the Proxmox node

## Default resources

| Resource   | Value        |
|------------|--------------|
| CPU        | 1 vCPU       |
| RAM        | 512 MB       |
| Disk       | 2 GB         |
| OS         | AlmaLinux 9  |
| Privileges | Unprivileged |

## Usage

Run the following command from a root shell on the Proxmox node:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/almalinux.sh)"
```

The interactive wizard offers two modes:

- **Default** — creates the container with default resources, no confirmation at each step
- **Advanced** — lets you customize CPU, RAM, disk, network, root password, etc.

## Updating the container

From the Proxmox shell, run the `update` script installed inside the container:

```bash
pct exec <CTID> -- bash -c "update"
```

Or from inside the container:

```bash
update
```

This command re-runs `ct/almalinux.sh` which executes `update_script()`: `dnf -y update` + `dnf -y upgrade`.

## What the script does

Steps 1 to 3 and 5 to 6 are common to all OSes in the framework (Debian,
Ubuntu, Alpine). Only step 4 is specific to AlmaLinux.

1. Downloads the AlmaLinux 9 template from Proxmox repositories if not already present
2. Creates the LXC container with the chosen resources
3. Configures networking and verifies connectivity
4. **Updates the OS via `dnf -y update`** ← AlmaLinux-specific (`apt` on Debian, `apk` on Alpine)
5. Configures the MOTD (container information displayed at login)
6. Enables root autologin if no password is set
