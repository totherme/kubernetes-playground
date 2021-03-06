#!/usr/bin/env bash

set -eu
set -o pipefail

[ -z "${DEBUG:-}" ] || set -x

readonly BASE_DIR="$(greadlink -f "$(dirname "$0")")"
readonly VAGRANT_DOT_PATH="${BASE_DIR}/.vagrant"
readonly LSYNCD_CONF="${VAGRANT_DOT_PATH}/lsyncd.conf"
readonly SSH_CONF="${VAGRANT_DOT_PATH}/ssh-conf"
readonly LSYNCD_PID="${VAGRANT_DOT_PATH}/lsyncd.pid"

run_vagrant() {
  VAGRANT_CWD="${BASE_DIR}" vagrant "$@"
}

get_ssh_conf() {
  run_vagrant ssh-config --host "$1"
}

template_lsyncd_conf() {
  local host source_dir target_dir

  host="$1"
  source_dir="$2"
  target_dir="$3"
  ssh_conf="$4"

  erb \
    host="$host" \
    source_dir="$source_dir" \
    target_dir="$target_dir" \
    ssh_conf="$ssh_conf" \
    "${BASE_DIR}/lsyncd.lua.conf.erb"
}

start_lsyncd() {
  local conf pidfile

  conf="${1:?"Expected a path to a config file in start_lsyncd"}"
  pidfile="${2:?"Expected a path to a pidfile in start_lsyncd"}"

  # on macos lsyncd needs to run as root, as root permissions are needed to
  # listen for FS events
  sudo lsyncd -pidfile $pidfile "$conf"
}

start() {
  local target_dir source_dir host

  source_dir="${BASE_DIR}/go/src"
  target_dir="workspace/go/src"
  host='vagrant_k8s'

  get_ssh_conf "$host" > "$SSH_CONF"
  template_lsyncd_conf "$host" "$source_dir" "$target_dir" "$SSH_CONF" \
    > "$LSYNCD_CONF"
  start_lsyncd "$LSYNCD_CONF" "$LSYNCD_PID"
}

stop() {
  sudo kill "$(cat "$LSYNCD_PID")"
}

usage() {
  cat <<'EOF' >&2
watch.sh [start|stop]

  start  configure & start lsyncd to sync from host to guest
  stop   stop lsyncd
EOF
}

main() {
  local action="${1:-usage}"

  case "$action" in
    start) start "$@"    ;;
    stop)  stop "$@"     ;;
    *)     usage; exit 1 ;;
  esac
}

main "$@"
