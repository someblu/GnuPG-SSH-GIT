#!/bin/zsh

GPG_VER_REQ="2.0.0"

# install gpg if necessary
if ! type gpg &>/dev/null; then
  # use brew to instal GnuPG
  ## sudo chown -R $(whoami) /usr/local/{"bin","etc","include","lib","sbin","share","var","Frameworks"}
  brew install gnupg pinentry-mac
  gpg --list-keys
  echo "pinentry-program /usr/local/bin/pinentry-mac" > "${HOME}/.gnupg/gpg-agent.conf"
  chmod 600 "${HOME}/.gnupg/gpg-agent.conf"
  gpg-connect-agent reloadagent /bye >/dev/null
fi

# determine whether we are using required version or higher
GPG_VER=${gpg --version | head -n1 | awk '{print $3}'}
if [ "$(printf '%s\n' "$GPG_VER_REQ" "$GPG_VER" | sort -V | head -n1)" = "$GPG_VER_REQ" ]; then
  echo "GnuPG $GPG_VER is found. Great! "
else
  echo "GnuPG version is less than $GPG_VER_REQ. Please update first. "
  exit 1
fi

# prepare ENV
tee "${HOME}/.gnupg/gpg.zsh" << END
export LANG=en_US.UTF-8
if type gpg &>/dev/null; then
  export GPG_TTY="\$(tty)"
  export SSH_AUTH_SOCK="\$(gpgconf --list-dirs agent-ssh-socket)"
  gpg-connect-agent -q /bye
fi
END
chmod 600 "${HOME}/.gnupg/gpg.zsh"
if ! grep -q 'source "${HOME}/.gnupg/gpg.zsh"' "${HOME}/.zshrc"; then
  echo 'source "${HOME}/.gnupg/gpg.zsh"' >> "${HOME}/.zshrc"
fi

# gpg --expert --full-gen-key
## "ECC and ECC" - "Curve 25519" - "key does not expire" - "Jiahao Zhou" - "zhoujiahao@bytedance.com"
# gpg --expert --edit-key "Jiahao Zhou"
## "addkey" - "quit"/"-signing key +authenticate key quit"

if [ -n "$1" -a -d $1 ]; then
  gpg --import $1/secring.bak
  gpg --import-ownertrust $1/trustdb.bak
fi

# ask for gpg user name
while [ -z "$GPG_USERNAME" -o -z "$KEY_ID" ]; do
  read -p 'Enter your user name: ' GPG_USERNAME;
  # keyid
  KEY_ID=$(gpg -k --keyid-format long $GPG_USERNAME | grep 'pub' | tail -n 1 | awk -F '[ /]' '{print $5}')
done

# ask for gpg passphrase
while [ -z "$GPG_PASSPHRASE" ] || [ "0" -ne "$( echo $GPG_PASSPHRASE | gpg --pinentry-mode loopback --passphrase-fd 0 -a --export-secret-keys $KEY_ID 2>&1 >/dev/null | grep "skipped" | head -n1 | >&2 awk -F '[:-]' '{print $1":"$3":"$4}'; echo ${PIPESTATUS[1]}; )" ]; do
  read -sp 'Enter your passphrase: ' GPG_PASSPHRASE; echo;
done

# ssh pubkey
# gpg --export-ssh-key $GPG_USERNAME >> ${HOME}/.ssh/authorized_keys

# ssh add key from gpg
if [ -z "$(ssh-add -L | grep "$(gpg --export-ssh-key $GPG_USERNAME| awk '{print $2}')")" ]; then
  echo "$(gpg -k --with-keygrip $GPG_USERNAME | grep '\[A\]' -A1 | tail -n 1 | awk '{print $3}') 0" > "${HOME}/.gnupg/sshcontrol"
  chmod 600 "${HOME}/.gnupg/sshcontrol"
fi

# pubkey
# gpg -a --export

# global git config
git config --global gpg.program "gpg"
git config --global user.signingkey "$(gpg -k --keyid-format long | grep '\[S\]' | awk -F '[ /]' '{print $5}')"
git config --global commit.gpgsign true

# backup pub, sec and All-In-One sub keys
# rm -rf gpg && mkdir gpg
# gpg --export-ownertrust > gpg/trustdb.bak
# echo $GPG_PASSPHRASE | gpg --pinentry-mode loopback --passphrase-fd 0 -a --output gpg/secring.bak --export-secret-keys $GPG_USERNAME
# zip gpg.zip -r gpg
# rm -rf gpg

# backup sub keys seperately
# gpg -k --keyid-format long | grep 'sub' | awk -F '[][ /]' '{print $5" "$8}' | while read subkeyid type; do echo $GPG_PASSPHRASE | gpg --pinentry-mode loopback --passphrase-fd 0 -a --output sub-$type.asc --export-secret-subkeys $subkeyid'!'; done

# $gpg-agent --gpgconf-list
# $gpg-agent --dump-options
