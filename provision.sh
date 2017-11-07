#!/bin/bash

set -eu
set -o pipefail

apt-get -y update
apt-get -y clean

apt-get install -y git vim-nox jq cgroup-lite build-essential ntp htop

wget -qO- https://redirector.gvt1.com/edgedl/go/go1.9.2.linux-amd64.tar.gz | tar -C /usr/local -xzf -

#Set up $GOPATH and add go executables to $PATH
cat > /etc/profile.d/go_env.sh <<\EOF
export GOPATH=/vagrant/go
export PATH=$GOPATH/bin:/usr/local/go/bin:$PATH
EOF
chmod +x /etc/profile.d/go_env.sh

source /etc/profile.d/go_env.sh

mkdir -p $GOPATH/src/github.com/opencontainers/
pushd $GOPATH/src/github.com/opencontainers/
git clone https://github.com/opencontainers/runc
pushd runc

go build -o runc .
cp runc /usr/local/bin/runc

cp /vagrant/mount-tmpfs.sh /etc/init.d/
/etc/init.d/mount-tmpfs.sh start

cat /vagrant/vimrc >> /etc/vim/vimrc

export UCF_FORCE_CONFFNEW=YES
export DEBIAN_FRONTEND=noninteractive

