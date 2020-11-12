export NVM_DIR="$HOME/.nvm" && (
  git clone https://github.com/creationix/nvm.git "$NVM_DIR"
  cd "$NVM_DIR"
  git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" origin`
) && \. "$NVM_DIR/nvm.sh"

nvm install 10.18 --latest-npm
nvm install --lts --latest-npm

npm install --global pure-prompt;

brew install yarn --without-node
npm install gulp-cli -g
