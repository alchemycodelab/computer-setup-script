#!/usr/bin/env bash
# DEBIAN_FRONTEND=noninteractive
apt="sudo apt-get -qq -y"
y_install="sudo yum install -y -q -e 0"

usage() {
  echo -e "\nUsage: $0 <options>\n\nInstalls most of the required software packages for Alchemy students.\n\nOptions:"
  echo -e "\t-g\tCheck for git and install if necessary\n\t-n\tCheck for and install nvm/node/eslint\n\t-m\tCheck for and install MongoDB and tools\n"
  echo -e "If you have any difficulties, please contact a member of the instructional staff in Slack."
  exit 1
}

info() {
  echo -e "\e[1;36m${1}\e[0m" # cyan
}
warn() {
  echo -e "\e[1;33m${1}\e[0m" # yellow
}

apt-update() {
  info "Updating system packages"
  $apt update >/dev/null
  $apt upgrade >/dev/null
}

yum-update() {
  info "Updating system packages"
  sudo yum update -y -q -e 0
}

linux-update() {
  if [[ $distro == debian ]]; then
    apt-update
  elif [[ $distro == redhat ]]; then
    yum-update
  fi
}

app-check() {
  info "Checking to see if $1 is installed..."
  sleep 1
  if [[ -n $(command -v $1) ]]; then
    warn "$1 is already installed"
    return 0
  fi
  info "Not found.  Installing $1..."
  return 1
}

version-check() {
  echo -ne "\e[1;34m${1}\e[0m: "
  echo `$1 --version 2>/dev/null|| echo -e "\e[31mNot Installed\e[0m"`
}

install-mongo-debian() {
  curl -qo- https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add - >/dev/null
  echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list > /dev/null
  $apt update >/dev/null
  $apt install mongodb-org >/dev/null

  curl -qo- https://downloads.mongodb.com/compass/mongodb-compass-community_1.21.2_amd64.deb > ~/.alchemy/downloads/mongodb-compass-community_1.21.2_amd64.deb
  $apt install ~/.alchemy/downloads/mongodb-compass-community_1.21.2_amd64.deb >/dev/null
}

install-mongo-redhat() {
  # TODO
  # Change this to the git location for the .repo file
  curl -qo- https://raw.githubusercontent.com/alchemycodelab/computer-setup-script/script-rewrite/lib/mongodb-org-4.2.repo | sudo tee /etc/yum.repos.d/mongodb-org-4.2.repo

  $y_install mongodb-org

  info "Downloading MongoDB Compass..."
  curl -so- https://downloads.mongodb.com/compass/mongodb-compass-1.21.2.x86_64.rpm > ~/.alchemy/downloads/mongodb-compass-1.21.2.x86_64.rpm
  info "Installing MongoDB Compass..."
  sleep 2
  $y_install ~/.alchemy/downloads/mongodb-compass-1.21.2.x86_64.rpm
}

install-mongo-darwin() {
  brew tap mongodb/brew
  brew install mongodb-community
  brew services start mongodb/brew/mongodb-community
}

install-mongo() {
  app-check mongo && return 0

  if [[ $OS == Linux ]]; then
    if [[ $distro == debian ]]; then
      install-mongo-debian
    elif [[ $distro == redhat ]]; then
      install-mongo-redhat
    fi
    if [[ -n $(command -v systemctl) ]]; then
      sudo systemctl enable mongodb
      sudo systemctl start mongodb
    fi
  else
    install-mongo-darwin
  fi
}

# Final report for students to screencap to submit and confirm everything
# is installed correctly
check-all-versions() {
  for app in ${apps[@]}
  do
    version-check ${app}
  done
}

install-heroku() {
  app-check heroku && return 0
  curl -o- https://cli-assets.heroku.com/install.sh | bash >/dev/null 2>&1
}

install-nvm() {
  if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
    source $HOME/.nvm/nvm.sh
  fi

  app-check nvm && return 0
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash

  export NVM_DIR="$HOME/.nvm"
  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

  info "Installing node"
  nvm install node
  nvm alias default node
  npm install -g eslint
}

install-git() {
  app-check git && return 0
  if [[ $OS == Linux ]]; then
    if [[ $distro == debian ]]; then
      $apt install git
    elif [[ $distro == redhat ]]; then
      $y_install git
    fi
  else
    brew install git
  fi
}

install-homebrew() {
  app-check brew && return 0
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

distro-check() {
  if [[ $(command -v apt) ]]; then
    distro='debian'
  else if [[ $(command -v yum) ]]; then
    distro='redhat'
    fi
  fi
  info "Detected a ${distro}-based installation."
}

init() {
  if [[ ! -d ~/.alchemy ]]; then
    mkdir -p ~/.alchemy/downloads
  fi
  distro-check
  if [[ $OS == Linux ]]; then
    linux-update
  elif [[ $OS == Darwin ]]; then
    install-homebrew
  fi
}

cleanup() {
  rm -rf ~/.alchemy/downloads
}

distro='none'
apps=('git' 'node' 'npm' 'eslint' 'heroku' 'mongo')
OS=$(uname -s)

set -e


main() {
  init

  install-git
  install-nvm
  install-heroku
  install-mongo

  check-all-versions
}

while getopts 'ngmh' flag; do
  case "${flag}" in
    n) install-nvm ; exit 0 ;;
    g) init ; install-git ; exit 0 ;;
    m) init ; install-mongo ; exit 0 ;;
    h) usage ; exit 0 ;;
    *) main ;;
  esac
done

main "$@"
