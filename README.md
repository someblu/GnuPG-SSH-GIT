# GnuPG-SSH-GIT

a script that helps GPG users to use authentication keys for ssh connections and signing keys for signing commits

BACKUP your ~/.gnugp folder before using this script

(currently MacOS only)

```shell
# SUB_KEY_FOLDER will be used to import *.asc keys
# ommit it if you already have keys set up or if you dont't have one
./gpg.zsh [SUB_KEY_FOLDER]
```

## REQUIREMENTS

```json
"Homebrew": "^2.2.2",
"GnuPG": "^2.2.19",
```

## TODO

- [x] add an installation step
- [x] use a more secure file written method
- [ ] add support for various kinds of distributions of linux
- [ ] ...
