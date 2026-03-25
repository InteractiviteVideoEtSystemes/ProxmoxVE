#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/InteractiviteVideoEtSystemes/ProxmoxVE/refs/heads/feat/add-almalinux-lxc-support/misc/build.func)
# Source: https://almalinux.org/

APP="AlmaLinux"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-2}"
var_os="${var_os:-almalinux}"
var_version="${var_version:-9}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /var ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi
  msg_info "Updating $APP LXC"
  $STD dnf -y update
  $STD dnf -y upgrade
  msg_ok "Updated $APP LXC"
  msg_ok "Updated successfully!"
  exit
}

start
build_container

msg_info "Applying IVES configuration"
pct exec "$CTID" -- bash -c "$(curl -fsSL \
  --header "PRIVATE-TOKEN: ${GITLAB_TOKEN:?GITLAB_TOKEN not set}" \
  "https://git.ives.fr/api/v4/projects/173/repository/files/prepare-almalinux-9-server.sh/raw?ref=master")"
msg_ok "IVES configuration applied"

description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
