#!/usr/bin/env bash

set -e

function info {
  echo -e "\e[34m${1}\e[0m"
}

function warn {
  echo -e "\e[33m${1}\e[0m"
}

function error {
  echo -e "\e[31m${1}\e[0m" 1>&2
  exit 1
}

OS=$(uname -s)
if [[ $OS != Linux && $OS != Darwin ]]; then
  error "Unsupported Operating System: ${OS}"
fi

if [[ -z $(command -v apt) ]]; then
  error "Unsupported Linux Distribution"
fi

function updateAPT {
  if [[ $OS == Linux ]]; then
    clear
    info "Updating APT Database"
    sudo apt update
    sudo apt -y upgrade
    sudo apt autoremove
  fi
}

function installHomebrew {
  if [[ $OS != Darwin ]]; then
    return
  fi

  clear

  if [[ -n $(command -v brew) ]]; then
    warn "Homebrew already installed"
    return
  fi

  info "Istalling Homebrew"
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
}

function installNVM {
  clear

  if [[ -f "$HOME/.nvm/nvm.sh" ]]; then
    source $HOME/.nvm/nvm.sh
  fi

  if [[ -n $(command -v nvm) ]]; then
    warn "NVM already installed"
    return
  fi

  info "Installing nvm"
  mkdir ~/.nvm

  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
  export NVM_DIR="$HOME/.nvm"

  export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
}

function installNode {
  clear
  info "Installing node.js"
  nvm install node
  npm install -g eslint
}

function installGit {
  clear
  if [[ -n $(command -v git) ]]; then
    warn "git already installed"
    return
  fi

  info "Installing git"
  if [[ $OS == Linux ]]; then
    sudo apt install -y git
  else
    brew install git
  fi
}

function installHeroku {
  if [[ -n $(command -v heroku) ]]; then
    warn "Heroku already installed."
    return
  fi

  if [[ $OS == Linux ]]; then
    curl https://cli-assets.heroku.com/install.sh | sh
  else
    brew tap heroku/brew && brew install heroku
  fi
}

function installPostgres {
  clear

  if [[ -n $(command -v psql) ]]; then
    warn "postgres already installed"
    return
  fi

  info "Installing postgres"
  if [[ $OS == Linux ]]; then
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt update
    sudo apt install -y postgresql

    if [[ -n $(command -v systemctl) ]]; then
      sudo systemctl enable postgresql
      sudo systemctl start postgresql
    else
      sudo service postrgesql start
    fi

  else
    brew install postgres
    brew services start postgresql
  fi

  echo "Create Postgres user and default database"
  echo "   When Prompted ..."
  echo "     - Use your wsl username as the database name"
  echo "     - Provide your wsl username and password to create a new pg user"
  echo "     - Say 'Yes' when asked if this user should be a Super User'"
  echo ""

  # sudo -u postgres createuser --interactive --pwprompt
  # sudo -u postgres createdb -O `whoami` `whoami`

  createuser --interactive --pwprompt
  createdb -O `whoami` `whoami`
}

function installMongo {
  clear

  if [[ -n $(command -v mongo) ]]; then
    warn "mongo already installed"
    return
  fi

  info "Installing 'mongo database server and client'"

  if [[ $OS == Linux ]]; then
    wget -qO - https://www.mongodb.org/static/pgp/server-4.2.asc | sudo apt-key add -
    echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/4.2 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.2.list
    sudo apt update
    sudo apt install -y mongodb-org

    if [[ -n $(command -v systemctl) ]]; then
      sudo systemctl enable mongodb
      sudo systemctl start mongodb
    fi
  else
    brew tap mongodb/brew
    brew install mongodb-community
    brew services start mongodb/brew/mongodb-community
  fi

}

updateAPT
installHomebrew
installNVM
installNode
installGit
installHeroku
installPostgres
installMongo

echo "GIT `git --version`"
echo "NODE `node --version`"
echo "NPM `npm --version`"
echo "HEROKU `heroku --version`"
echo "PSQL `psql --version`"
echo "MONGO `mongo --version`"

echo -e "\n\n\e[1m\e[32mSUCCESS! :)\e[0m\n\n"
