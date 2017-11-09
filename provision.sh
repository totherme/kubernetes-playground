#!/bin/bash

set -eu
set -o pipefail

DISK_DEVICE='/dev/disk/by-path/pci-0000:00:14.0-scsi-0:0:2:0'
WORKSPACE="/home/ubuntu/workspace"
DOCKER_DIR="${WORKSPACE}/docker_state"

sudo -u ubuntu mkdir -p "$WORKSPACE"

if ! mount "$DISK_DEVICE" "$WORKSPACE" >/dev/null 2>&1 ; then
  mkfs.ext4 "$DISK_DEVICE"
  mount "$DISK_DEVICE" "$WORKSPACE"
  chown ubuntu.ubuntu "$WORKSPACE"
fi

mkdir -p "${DOCKER_DIR}"
ln -s "${DOCKER_DIR}" /var/lib/docker || true

apt-get -y update
apt-get -y clean

apt-get install -y git vim-nox jq cgroup-lite build-essential ntp htop docker.io

wget -qO- https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz | tar -C /usr/local -xzf -

#Set up $GOPATH and add go executables to $PATH
cat > /etc/profile.d/go_env.sh <<\EOF
export GOPATH=/home/ubuntu/workspace/go
export PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
EOF
chmod +x /etc/profile.d/go_env.sh

source /etc/profile.d/go_env.sh

cat /vagrant/vimrc >> /etc/vim/vimrc

export UCF_FORCE_CONFFNEW=YES
export DEBIAN_FRONTEND=noninteractive

