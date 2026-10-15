# Dropped from the old Manjaro system (check before the rebuild)

## Manjaro-specific (no equivalent on Arch)
manjaro-* (alsa, browser-settings, i3-settings, ranger-settings, release, system, zsh-config, hotfixes)
mhwd mhwd-db linux66 linux-meta linux-lts-nvidia-meta grub-theme-manjaro grub-hook kvantum-manjaro
maia-console pamac-gtk bmenu zensu i3-default-artwork netctl
NOTE: manjaro-zsh-config and manjaro-i3-settings supplied your zsh and i3 setup. Back up ~/.zshrc, ~/.config/i3, ~/.config/polybar etc BEFORE wiping.

## Unused hardware / drivers
xf86-video-amdgpu xf86-video-ati xf86-video-nouveau xf86-video-intel (modesetting is enough)
vulkan-radeon lib32-vulkan-radeon xf86-input-elographics xf86-input-void b43-fwcutter

## Obsolete filesystem / RAID tools
reiserfsprogs jfsutils hfsprogs f2fs-tools dmraid mdadm lvm2 device-mapper squashfs-tools ecryptfs-utils

## Maybe unneeded, your call
syslog-ng (journald is enough) ntp (use systemd-timesyncd) x11vnc osxcross-git mitogen
webkit2gtk libva-vdpau-driver lib32-libva-vdpau-driver luajit-tiktoken-bin pa-applet-git pacmixer
xpointerbarrier-git spectre-meltdown-checker electron opencode act actionlint python-cfn-lint
stack-related and dotnet-runtime-6.0 (EOL) if not used.

## Not in the lists: pick on install
- Window manager pieces I assumed: i3-wm i3status picom dunst feh (not in your explicit list, check your config)
- Reinstall NordVPN carefully (its killswitch daemon broke boot) or use WireGuard.
