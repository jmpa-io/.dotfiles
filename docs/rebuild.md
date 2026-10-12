# Rebuilding from scratch (Arch Linux)

This setup was previously on Manjaro. Notes for a clean Arch install.

## 1. Before wiping
- Commit and push this repo (including `.worktrees/` branches).
- Run `bin/backup-secrets.sh` and store the encrypted archive off-machine.
  Secrets (SSH/AWS/kube keys, keyrings, rclone) are deliberately **not** in git.
- Triage `~/Downloads`, `~/go` (rebuildable), `~/Music`, Docker volumes
  (`docker volume ls`), game saves under `~/.local/share` and `~/.config`.

## 2. After a fresh install
```sh
grep -v '^#' system/arch/pkgs-core.txt    | xargs sudo pacman -S --needed
grep -v '^#' system/arch/pkgs-desktop.txt | xargs sudo pacman -S --needed
grep -v '^#' system/arch/pkgs-aur.txt     | xargs yay -S --needed
make configure-system   # installs system/etc/* (greeter, vconsole, keyboard, lightdm)
```
Then enable services: `NetworkManager`, `lightdm`, `docker.socket`,
`tailscaled`, `bluetooth`, `cronie`, `paccache.timer`.

`system/arch/REVIEW.md` lists what was dropped from the Manjaro install and why.

## 3. Restore secrets and logins
- `gpg -d secrets-*.tar.gpg | tar -xvf - -C "$HOME"`
- `tailscale up`, re-login to NordVPN (see note below), `gh auth login`.
- Restore the crontab: `crontab .config/crontab/crontab.txt`

## 4. Known problems on the old install
- `slick-greeter.conf` went missing after a package update, leaving the login
  screen on defaults. It now lives in `system/etc/lightdm/`.
- `KEYMAP=au` in `vconsole.conf` doesn't exist, which failed
  `systemd-vconsole-setup` at boot. Fixed to `us`.
- NordVPN's killswitch daemon crash-looped on a corrupt config
  (`cipher: message authentication failed`) and delayed boot. Skip the
  killswitch unit, or use WireGuard.
- Docker delayed boot; enable `docker.socket` rather than `docker.service`.
- dunst failed as a systemd user unit (no X11 yet); start it from i3 instead.
- Keep `.pacnew` files merged with `pacdiff` after updates.

## Loose home configs stored here
`.config/x11` (xinitrc, Xresources, Xclients), `screenlayout`, `moc`, `ranger`,
`vlc`, `aseprite`, `dmenu`, `nano`, `dircolors`, `makepkg`, `ncpamixer.conf`.
Symlink them back to `~` as needed, e.g. `ln -s ~/.dotfiles/.config/x11/.xinitrc ~/.xinitrc`.
