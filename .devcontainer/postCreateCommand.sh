#!/bin/bash

function install_by_script {
  cd ~/
  wget https://dot.net/v1/dotnet-install.sh
  sudo chmod +x ./dotnet-install.sh
  ./dotnet-install.sh --channel 6.0

  echo 'export DOTNET_ROOT=$HOME/.dotnet' >>~/.bashrc
  echo 'export PATH=$HOME/.dotnet:$HOME/.dotnet/tools:$PATH' >>~/.bashrc
}

function install_by_dnf {
  rpm -Uvh https://packages.microsoft.com/config/centos/8/packages-microsoft-prod.rpm
  dnf install -y dotnet-sdk-6.0 dotnet-runtime-6.0
  mkdir -p /root/.dotnet
  ln -s /usr/bin/dotnet /root/.dotnet/dotnet
}

function install_by_apt {
  # Install .NET SDK
  wget https://dot.net/v1/dotnet-install.sh -O /tmp/dotnet-install.sh
  chmod +x /tmp/dotnet-install.sh
  /tmp/dotnet-install.sh --channel 6.0

  echo 'export DOTNET_ROOT=/root/.dotnet' >>/root/.bashrc
  echo 'export PATH=$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH' >>/root/.bashrc

  # sudo apt-get update && \
  # sudo apt-get install -y dotnet-sdk-6.0
}

function create_user {
  USERNAME=dev
  USER_UID=1000
  USER_GID=$USER_UID

  # Create the user
  groupadd --gid $USER_GID $USERNAME
  useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

  # [Optional] Add sudo support. Omit if you don't need to install software after connecting.
  apt install -y sudo
  echo $USERNAME ALL=\(root\) NOPASSWD:ALL >/etc/sudoers.d/$USERNAME
  chmod 0440 /etc/sudoers.d/$USERNAME
}

function install_clangd {
  clangd_version=20.1.0
  clangd_dir=/usr/local/lib/clangd

  wget "https://github.com/clangd/clangd/releases/download/${clangd_version}/clangd-linux-${clangd_version}.zip" -O /tmp/clangd.zip
  unzip /tmp/clangd.zip -d ${clangd_dir}
  mv ${clangd_dir}/clangd_${clangd_version}/* ${clangd_dir}
  rm -rf ${clangd_dir}/clangd_${clangd_version}
  rm -rf /tmp/clangd.zip

  unset clangd_dir
  unset clangd_version
}

function main {
  # need to reload vscode to enable cmake language server

  # install_by_script
  #   install_by_dnf
  install_by_apt

  # install other deps

  install_clangd

  mkdir -p /root/.ccache
  echo "max_size = 20.0G" >>/root/.ccache/ccache.conf
  echo "cache_dir = /opt/ccache" >>/root/.ccache/ccache.conf

  create_user

  #   echo "unset http_proxy" >>/root/.bashrc
  #   echo "unset https_proxy" >>/root/.bashrc
  echo 'export PATH=/usr/local/lib/clangd/bin/:$PATH' >>/root/.bashrc

  # enable coredump
  echo "* soft core unlimited" >>/etc/security/limits.conf
  sysctl -w kernel.core_pattern="/coredumps/core-%e-%s-%u-%g-%p-%t"

  # replace container settings.json with our project settings.json
  pushd /root/.vscode-server/data/Machine
  rm -rf settings.json
  ln -s /opt/transwarp/db-engine-paradigms/.devcontainer/settings.json settings.json
  popd
}

main $@
