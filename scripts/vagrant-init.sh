#!/usr/bin/env bash
set -o errtrace
trap 'echo "error occurred on line $LINENO ";exit 1' ERR

SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit ; pwd -P )"

ansible-galaxy install -r "${SCRIPTPATH}/../ansible/requirements.yml" --roles-path "${SCRIPTPATH}/../ansible/roles/"

pathadd() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then PATH="${PATH:+"$PATH:"}$1"; fi
}

# for wsl
if grep -q Microsoft /proc/version; then
  echo "Windows Subsystem for Linux detected"
  echo "Please specify VirtualBox install directory on Windows (e.g.: /mnt/c/Program Files/Oracle/VirtualBox)"
  read -p "[/mnt/c/apps/VirtualBox]: " -r virtualbox_installation_path
  if [ -z "$virtualbox_installation_path" ]; then virtualbox_installation_path='/mnt/c/apps/VirtualBox'; fi
  pathadd "${virtualbox_installation_path}"
  export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
fi

base_box_exists=$( vagrant box list | grep bionic_docker_local | awk '{print $1}' )
if [ -z "${base_box_exists}" ]; then
  # build base VM from bionic ubuntu cloud image with addition of docker
  VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile_base" vagrant up

  # stop built VM
  VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile_base" vagrant halt

  # remove box file
  rm -f bionic_docker_local.box

  # export VM as a new box file
  vagrant package --base bionic_docker_local --output bionic_docker_local.box

  # add the box file as box
  vagrant box add bionic_docker_local.box --name bionic_docker_local

  # remove the no longer needed VM
  VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile_base" vagrant destroy -f
fi

# init all the other VMs
VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile" vagrant up --no-provision

# provision all the other VMs
VAGRANT_VAGRANTFILE="${SCRIPTPATH}/../vagrant/Vagrantfile" vagrant provision
