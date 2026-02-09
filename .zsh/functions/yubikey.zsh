# Yubikey Functions
# Source: Modularized from ~/.functions

# yubikill: Fix Yubikey connection issues
yubikill() {
  SCDAEMON_CONF="disable-ccid\nreader-port \"$(pcsctest <<< 01 | grep 'Reader 01' | awk -F ': ' '{print $2}' | head -n1)\""
  echo $SCDAEMON_CONF;
  echo $SCDAEMON_CONF > ~/.gnupg/scdaemon.conf
  gpgconf --kill all
}

# yubinudge: Restart GPG/SSH agents
yubinudge() {
    pkill gpg-agent
    pkill ssh-agent
    pkill pinentry
    gpg-connect-agent updatestartuptty /bye
    gpg --card-status
    ssh-add -L
}

# yubitransport: Safely transport Yubikey
yubitransport() {
  echo "[!] Remove Yubikey from device port."
  if read -q "REPLY?[?] Yubikey is unplugged? [Y/y]: "; then
    pkill gpg-agent
    pkill ssh-agent
    pkill pinentry
    echo -e "\nKilled gpg-agent, ssh-agent, and pinentry"
  else
    eval $(gpg-agent --daemon --enable-ssh-support)
  fi

  echo -e "\n[!] Reinsert Yubikey to device port."
  if read -q "REPLY?[?] Yubikey is attached? [Y/y]: "; then
    gpg-connect-agent updatestartuptty /bye
    gpg --card-status
    ssh-add -L
  else
    echo "Not launching GPG-agent"
  fi
}
