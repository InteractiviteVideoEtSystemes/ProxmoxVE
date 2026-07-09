#!/usr/bin/env bash
# patch-build-func.sh — applique les patchs IVES à misc/build.func (idempotent)
#   A) sources surchargeables : framework depuis FUNC_REPO/BRANCH (public),
#      install/<app>.sh depuis INSTALL_REPO/BRANCH (+ INSTALL_TOKEN si privé)
#   B) support AlmaLinux/RHEL : installe les paquets de base via dnf
set -euo pipefail
F="misc/build.func"
[ -f "$F" ] || { echo "ERREUR: $F introuvable (lancez depuis la racine du dépôt)"; exit 1; }

# --- Idempotence : ne rien refaire si déjà patché ---
if grep -q "IVES_PATCH_MARKER" "$F"; then
  echo "build.func déjà patché — rien à faire."; exit 0
fi

# --- A1) Injecter l'entête (helpers + variables surchargeables) après le shebang ---
perl -0777 -i -pe '
  my $hdr = <<'"'"'EOF'"'"';

# ===== IVES_PATCH_MARKER : sources surchargeables ============================
: "${FUNC_REPO:=community-scripts/ProxmoxVE}"     # dépôt framework (public)
: "${FUNC_BRANCH:=main}"
FUNC_RAW="https://raw.githubusercontent.com/${FUNC_REPO}/${FUNC_BRANCH}"
: "${INSTALL_REPO:=$FUNC_REPO}"                   # dépôt des install/<app>.sh (privé possible)
: "${INSTALL_BRANCH:=$FUNC_BRANCH}"
: "${INSTALL_TOKEN:=}"                            # PAT lecture seule si INSTALL_REPO est privé
ives_ghfetch() {                                  # <repo> <branch> <path> [token]
  if [ -n "${4:-}" ]; then
    curl -fsSL -H "Authorization: Bearer $4" -H "Accept: application/vnd.github.raw" \
      "https://api.github.com/repos/$1/contents/$3?ref=$2"
  else
    curl -fsSL "https://raw.githubusercontent.com/$1/$2/$3"
  fi
}
# ============================================================================
EOF
  s/(#!\/usr\/bin\/env bash\n)/$1$hdr/;
' "$F"

# --- A2) Rediriger les DEUX lignes installer app vers INSTALL_REPO (privé) ---
perl -0777 -i -pe '
  s{_install_script="\$\(curl -fsSL "https://raw\.githubusercontent\.com/community-scripts/ProxmoxVE/main/install/\$\{var_install\}\.sh"\)"}
   {_install_script="\$(ives_ghfetch "\$INSTALL_REPO" "\$INSTALL_BRANCH" "install/\${var_install}.sh" "\$INSTALL_TOKEN")"}g;
' "$F"

# --- A3) Rediriger les fichiers framework (*.func) vers FUNC_RAW (public) ---
perl -i -pe '
  s{https://raw\.githubusercontent\.com/community-scripts/ProxmoxVE/main}{\${FUNC_RAW}}g if /\.func\b/;
' "$F"

# --- B) Support AlmaLinux/RHEL : brancher dnf dans l'étape « Customizing » ---
perl -0777 -i -pe '
  my $elif = <<'"'"'EOF'"'"';
  elif pct exec "$CTID" -- sh -c '"'"'command -v dnf >/dev/null 2>&1'"'"'; then
    # IVES: paquets de base pour la famille RHEL (AlmaLinux/Rocky/CentOS/Fedora)
    sleep 3
    local _tz_rhel="${tz:-UTC}"
    pct exec "$CTID" -- bash -c "test -e /usr/share/zoneinfo/$_tz_rhel && ln -sf /usr/share/zoneinfo/$_tz_rhel /etc/localtime || true"
    pct exec "$CTID" -- bash -c "dnf -y install sudo curl nano jq tar" >>"$BUILD_LOG" 2>&1 || {
      msg_error "dnf base packages installation failed"
      install_exit_code=1
    }
  else
    sleep 3
    LANG=${LANG:-en_US.UTF-8}
EOF
  # On insère le elif juste avant le "else" du bloc Debian (ancre unique)
  s/\n  else\n    sleep 3\n    LANG=\$\{LANG:-en_US\.UTF-8\}\n/\n$elif/;
' "$F"

echo "Patch appliqué."
