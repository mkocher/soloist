#!/bin/bash

set -e

echo "Updating package list"
sudo apt-get update > /dev/null

echo "Ensuring curl is available"
sudo apt-get install -y curl > /dev/null

echo "Setting up RVM"

user=$1
[ -z "$user" ] && user="ubuntu"

test -d /usr/local/rvm || curl -L https://get.rvm.io | sudo bash -s stable

test -e /usr/local/rvm || sudo tee /etc/profile.d/rvm.sh > /dev/null <<RVMSH_CONTENT
[[ -s "/usr/local/rvm/scripts/rvm" ]] && source "/usr/local/rvm/scripts/rvm"
RVMSH_CONTENT

test -x /usr/local/rvm || sudo chmod +x /etc/profile.d/rvm.sh

grep "^$user:" /etc/passwd > /dev/null || sudo useradd -m $user -G sudo,rvm,admin -s /bin/bash

test -e /etc/rvmrc || sudo tee /etc/rvmrc > /dev/null <<RVMRC_CONTENTS
rvm_install_on_use_flag=1
rvm_trust_rvmrcs_flag=1
rvm_gemset_create_on_use_flag=1
RVMRC_CONTENTS

echo "Detecting RVM requirements"

packages="build-essential openssl libreadline6 libreadline6-dev curl git-core zlib1g zlib1g-dev libssl-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt-dev autoconf libc6-dev libgdbm-dev ncurses-dev automake libtool bison subversion pkg-config libffi-dev"

echo "Detected RVM requirements: $packages"

selections=`dpkg --get-selections`
for package in $packages
do
  if ! echo "$selections" | grep "^$package\s" > /dev/null
  then
    to_install="$to_install $package"
  fi
done

if [ -z "$to_install" ]
then
  echo "Satisfied RVM requirements"
else
  echo "Installing missing RVM requirements: $to_install"
  sudo apt-get --no-install-recommends install -y $to_install
fi
