# lordhelp

Declarative package management for HolyArch (and any Arch-based system).

The whole system is described in `/etc/holyarch/holyconfig.arch`. Install
packages however you like and they get added to it, or edit it by hand and
run `rebuildconfig` (or reboot) to apply.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/HolyArchProject/lordhelp-pkgmngr/main/install.sh | sudo sh
```

Your current packages and services are written to the config, so nothing
changes until you edit it.

## Config

```
settings {
    hostname = "holybox"
    timezone = "Europe/Warsaw"
    remove_unlisted = true
    sources = "repo aur flatpak snap"
    aur_user = "you"
}

packages {
    firefox
    git neovim
    aur:visual-studio-code-bin
    flatpak:com.spotify.Client
}

services {
    sshd
    !bluetooth
}
```

A plain name is looked up in `sources` order. A prefix (`aur:`, `flatpak:`,
`snap:`, `repo:`) picks the source. `!` disables a service.

## Usage

```
lordhelp install <pkg>     install from the best source and add to config
lordhelp remove <pkg>      uninstall and remove from config
lordhelp search <pkg>      show which sources have it
lordhelp add/del <pkg>     only edit the config
lordhelp diff              show what rebuildconfig would change
rebuildconfig              apply the config
lordhelp rollback [N]      go back to an earlier config
```

Packages installed with `pacman`, `paru` or `yay` are recorded automatically.

## Building the ISO

On Arch: `sudo ./build-iso.sh`. The ISO ends up in `out/`.
