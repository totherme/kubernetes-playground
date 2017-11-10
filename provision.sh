#!/bin/bash

set -eu
set -o pipefail

export UCF_FORCE_CONFFNEW=YES
export DEBIAN_FRONTEND=noninteractive

VM_USER='ubuntu'
DISK_DEVICE='/dev/disk/by-path/pci-0000:00:14.0-scsi-0:0:2:0'
WORKSPACE="/home/${VM_USER}/workspace"
DOCKER_DIR="${WORKSPACE}/docker_state"

main() {
  setup_workspace_disk
  install_devtools
  setup_golang
  get_k8s_go_deps

  install_lsyncd
  configure_lsyncd
  service lsyncd restart

  configure_docker

  cat /vagrant/vimrc >> /etc/vim/vimrc
}

setup_workspace_disk() {
  local fstab_line

  echo "About to set up the workspace disk"
  sudo -u "$VM_USER" mkdir -p "$WORKSPACE"

  if ! mount | grep -q "$WORKSPACE"
  then
    if ! mount "$DISK_DEVICE" " $WORKSPACE " >/dev/null 2>&1 ; then
      echo "couldn't mount disk, so making a fresh FS"
      mkfs.ext4 "$DISK_DEVICE"
    fi

    fstab_line="${DISK_DEVICE}  ${WORKSPACE}  ext4  defaults,auto,noatime,nodiratime  0  2"
    if ! grep -qF "$fstab_line" /etc/fstab
    then
      echo "$fstab_line" >> /etc/fstab
    fi

    mount "$WORKSPACE"
  fi

  chown "${VM_USER}.${VM_USER}" "$WORKSPACE"

  mkdir -p "${DOCKER_DIR}"
  ln -s "${DOCKER_DIR}" /var/lib/docker || true
}

install_devtools() {
  apt-get -y update
  apt-get -y clean

  apt-get install -y git vim-nox jq cgroup-lite build-essential ntp htop \
    docker.io silversearcher-ag
}

setup_golang() {
  wget -qO- https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz \
    | tar -C /usr/local -xzf -

  # Set up $GOPATH and add go executables to $PATH
  cat > /etc/profile.d/go_env.sh <<EOF
  export GOPATH=/home/${VM_USER}/workspace/go
  export PATH=\$GOPATH/bin:/usr/local/go/bin:\$PATH
EOF
  chmod +x /etc/profile.d/go_env.sh
}

get_k8s_go_deps() {
  echo "Getting k8s golang dependences"
  source /etc/profile.d/go_env.sh
  CGO_ENABLED=0 go install -a -installsuffix cgo std

  sudo -u "$VM_USER" -E bash <<'EOF'
    source /etc/profile.d/go_env.sh
    go get -u github.com/jteeuwen/go-bindata/go-bindata
EOF

}

install_lsyncd() {
  local tmp_dir

  apt-get -y install cmake lua5.2 liblua5.2-dev
  tmp_dir="$(mktemp -d)"
  #shellcheck disable=2064
  trap "rm -rf -- $tmp_dir" EXIT

  (
    cd "$tmp_dir"
    curl -L 'https://github.com/axkibe/lsyncd/archive/release-2.2.2.tar.gz' \
      | tar -xzf -

    cd lsyncd-release-*
    mkdir build

    cd build
    cmake ..
    make
    make install

    cp /vagrant/lsyncd.init /etc/init.d/lsyncd
    chmod 750 /etc/init.d/lsyncd

    systemctl daemon-reload
  )
}

configure_lsyncd() {
  local lsyncd_conf target source

  lsyncd_conf='/etc/lsyncd/lsyncd.conf.lua'
  target="${WORKSPACE}/go/src/k8s.io/kubernetes"
  source='/vagrant/go/src/k8s.io/kubernetes'

  mkdir -p "$( dirname "$lsyncd_conf" )"

  sudo -u "$VM_USER" mkdir -p "$target"

  cat <<EOF >"$lsyncd_conf"
sync {
  default.rsync,
  source = "${source}",
  target = "${target}",
  delay  = 2,
  delete = "running",
  rsync  = {
    archive = true,   -- use the archive flag in rsync
    perms   = true,   -- Keep the permissions
    owner   = true,   -- Keep the owner
    _extra  = {"-a"}, -- Sometimes permissions and owners isn't copied correctly so the _extra can be used for any flag in rsync
  }
}
EOF
}

configure_docker() {
  adduser "$VM_USER" docker
}

main
