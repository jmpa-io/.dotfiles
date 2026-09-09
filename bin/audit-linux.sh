#!/usr/bin/env bash
# Full system audit for Arch/Manjaro — cross-references everything expected by these dotfiles.
# Run on the Linux machine and paste output back to Claude.

set -euo pipefail

PASS="✓"
FAIL="✗"
WARN="~"

check() {
  local label="$1" cmd="$2"
  if command -v "$cmd" &>/dev/null; then
    local ver
    ver=$("$cmd" --version 2>/dev/null | head -1 || true)
    printf "  %s  %-38s %s\n" "$PASS" "$label" "${ver:-$(command -v "$cmd")}"
  else
    printf "  %s  %-38s not found\n" "$FAIL" "$label"
  fi
}

check_pkg() {
  local label="$1" pkg="$2"
  if pacman -Qi "$pkg" &>/dev/null 2>&1; then
    local ver
    ver=$(pacman -Qi "$pkg" 2>/dev/null | awk '/^Version/{print $3}')
    printf "  %s  %-38s %s\n" "$PASS" "$label" "$ver"
  else
    printf "  %s  %-38s not installed\n" "$FAIL" "$label"
  fi
}

check_file() {
  local label="$1" path="$2"
  if [ -e "$path" ]; then
    printf "  %s  %-38s %s\n" "$PASS" "$label" "$path"
  else
    printf "  %s  %-38s not found\n" "$FAIL" "$label"
  fi
}

check_symlink() {
  local label="$1" path="$2"
  if [ -L "$path" ]; then
    printf "  %s  %-38s -> %s\n" "$PASS" "$label" "$(readlink "$path")"
  elif [ -e "$path" ]; then
    printf "  %s  %-38s exists (NOT a symlink)\n" "$WARN" "$label"
  else
    printf "  %s  %-38s missing\n" "$FAIL" "$label"
  fi
}

check_font() {
  local label="$1" name="$2"
  if fc-list 2>/dev/null | grep -qi "$name"; then
    printf "  %s  %-38s installed\n" "$PASS" "$label"
  else
    printf "  %s  %-38s not found\n" "$FAIL" "$label"
  fi
}

check_mason() {
  local label="$1" bin="$2"
  local mason_bin="$HOME/.local/share/nvim/mason/bin/$bin"
  if [ -x "$mason_bin" ]; then
    printf "  %s  %-38s %s\n" "$PASS" "$label" "$mason_bin"
  else
    printf "  %s  %-38s not installed\n" "$FAIL" "$label"
  fi
}

section() {
  echo ""
  echo "[ $1 ]"
}

echo "========================================"
echo " Dotfiles Audit — $(hostname) — $(date '+%Y-%m-%d %H:%M')"
echo " OS:     $(grep '^PRETTY_NAME' /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"')"
echo " Kernel: $(uname -r)"
echo " Arch:   $(uname -m)"
echo "========================================"

# ── Window manager / display ──────────────────────────────────────────────────
section "Window Manager / Display"
check        "i3"                        i3
check        "picom"                     picom
check        "polybar"                   polybar
check        "xautolock"                 xautolock
check        "rofi"                      rofi
check        "nitrogen"                  nitrogen
check        "arandr"                    arandr
check        "xrandr"                    xrandr
check        "fix_xcursor"               fix_xcursor
check        "lightdm"                   lightdm
check        "lightdm-settings"          lightdm-settings
check_file   "polkit-gnome agent"        /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
check_file   "/etc/pam.d/i3lock"         /etc/pam.d/i3lock

# ── Terminal / shell ──────────────────────────────────────────────────────────
section "Terminal / Shell"
check        "wezterm"                   wezterm
check        "zsh"                       zsh
check        "bash"                      bash
check        "tmux"                      tmux
check        "starship"                  starship
check        "fzf"                       fzf
check_pkg    "zsh-syntax-highlighting"   zsh-syntax-highlighting
check_pkg    "zsh-autosuggestions"       zsh-autosuggestions

# ── Audio ─────────────────────────────────────────────────────────────────────
section "Audio"
check        "pavucontrol"               pavucontrol
check        "pulsemixer"                pulsemixer
check        "volumeicon"                volumeicon
check_pkg    "pulseaudio"                pulseaudio
check_pkg    "pipewire"                  pipewire
check_pkg    "pipewire-pulse"            pipewire-pulse
check_pkg    "wireplumber"               wireplumber

# ── Clipboard ─────────────────────────────────────────────────────────────────
section "Clipboard"
check        "clipit"                    clipit
check        "xclip"                     xclip
check        "xsel"                      xsel

# ── File management ───────────────────────────────────────────────────────────
section "File Management"
check        "pcmanfm"                   pcmanfm
check        "ranger"                    ranger

# ── Media ─────────────────────────────────────────────────────────────────────
section "Media"
check        "vlc"                       vlc
check        "ffmpeg"                    ffmpeg
check        "mpv"                       mpv

# ── Dev tools ─────────────────────────────────────────────────────────────────
section "Dev Tools"
check        "go"                        go
check        "git"                       git
check        "gh"                        gh
check        "delta"                     delta
check        "docker"                    docker
check        "docker compose"            docker
check        "jq"                        jq
check        "rclone"                    rclone
check        "terraform"                 terraform
check        "kubectl"                   kubectl
check        "ripgrep (rg)"              rg
check        "act"                       act
check        "aws"                       aws
check        "nvim"                      nvim

# ── Neovim / Mason LSP tools ──────────────────────────────────────────────────
section "Neovim Mason LSP Tools (~/.local/share/nvim/mason/bin)"
check_mason  "bash-language-server"      bash-language-server
check_mason  "shellcheck"                shellcheck
check_mason  "shfmt"                     shfmt
check_mason  "ansible-language-server"   ansible-language-server
check_mason  "ansible-lint"              ansible-lint
check_mason  "gopls"                     gopls
check_mason  "golangci-lint"             golangci-lint
check_mason  "delve"                     dlv
check_mason  "lua-language-server"       lua-language-server
check_mason  "stylua"                    stylua
check_mason  "deno"                      deno

# ── GTK / Themes ─────────────────────────────────────────────────────────────
section "GTK / Themes"
check_pkg    "adwaita-icon-theme"        adwaita-icon-theme
check_pkg    "lxappearance"              lxappearance
echo "  GTK_THEME=${GTK_THEME:-not set}"

# ── Fonts ─────────────────────────────────────────────────────────────────────
section "Fonts"
if command -v fc-list &>/dev/null; then
  check_font "FiraCode Nerd Font"        "FiraCode Nerd Font"
  check_font "Noto Color Emoji"          "Noto Color Emoji"
  check_font "Noto Emoji"               "Noto Emoji"
  check_font "Font Awesome"             "Font Awesome"
else
  echo "  $WARN  fc-list not available — skipping font check"
fi

# ── Config symlinks ───────────────────────────────────────────────────────────
section "Config Symlinks (~/.config)"
check_symlink "~/.config/tmux"           "$HOME/.config/tmux"
check_symlink "~/.config/nvim"           "$HOME/.config/nvim"
check_symlink "~/.config/starship"       "$HOME/.config/starship"
check_symlink "~/.config/btop"           "$HOME/.config/btop"
check_symlink "~/.config/polybar"        "$HOME/.config/polybar"
check_symlink "~/.config/picom"          "$HOME/.config/picom"
check_symlink "~/.i3"                    "$HOME/.i3"
check_symlink "~/.config/gh/config.yml"  "$HOME/.config/gh/config.yml"

section "Home Symlinks"
check_symlink "~/.gitconfig"             "$HOME/.gitconfig"
check_symlink "~/.gitconfig-personal"    "$HOME/.gitconfig-personal"
check_symlink "~/.zshenv"               "$HOME/.zshenv"
check_symlink "~/.zshrc"                "$HOME/.zshrc"
check_symlink "~/.wezterm.lua"           "$HOME/.wezterm.lua"
check_symlink "~/.ssh/config"            "$HOME/.ssh/config"
check_symlink "~/.tmux"                  "$HOME/.tmux"
check_symlink "~/.npmrc"                 "$HOME/.npmrc"
check_symlink "~/.dotfiles.d/aliases"    "$HOME/.dotfiles.d/aliases"
check_symlink "~/.dotfiles.d/ai-aliases" "$HOME/.dotfiles.d/ai-aliases"

section "~/bin Scripts"
for script in \
  aws-cloudfront-invalidate-distribution \
  aws-ssm-list-parameters-by-name \
  claude-dispatch \
  git-credential-gh \
  github-actions-clear-workflow-runs \
  github-list-repository-topics \
  obsidian-upload-to-google-drive \
  tailscale-list-dns-nameservers; do
  check_symlink "$script" "$HOME/bin/$script"
done

# ── Shell environment ─────────────────────────────────────────────────────────
section "Shell Environment"
echo "  SHELL:          ${SHELL:-not set}"
echo "  EDITOR:         ${EDITOR:-not set}"
echo "  BROWSER:        ${BROWSER:-not set}"
echo "  GOPATH:         ${GOPATH:-not set}"
echo "  DOTFILES:       ${DOTFILES:-not set}"
echo "  STARSHIP_CONFIG: ${STARSHIP_CONFIG:-not set}"
[[ -f "$HOME/.dotfiles.d/work" ]] \
  && echo "  $PASS  ~/.dotfiles.d/work exists" \
  || echo "  $FAIL  ~/.dotfiles.d/work missing"
[[ -f "$HOME/.gitconfig-work" ]] \
  && echo "  $PASS  ~/.gitconfig-work exists" \
  || echo "  $FAIL  ~/.gitconfig-work missing"

# ── Display / monitors ────────────────────────────────────────────────────────
section "Display"
echo "  DISPLAY:        ${DISPLAY:-not set}"
echo "  XDG_SESSION:    ${XDG_SESSION_TYPE:-not set}"
echo "  DE/WM:          ${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-unknown}}"
if command -v xrandr &>/dev/null && [ -n "${DISPLAY:-}" ]; then
  echo "  Monitors:"
  xrandr --query 2>/dev/null | grep " connected" | while read -r line; do
    printf "    - %s\n" "$line"
  done
fi

# ── GPU / Xorg ────────────────────────────────────────────────────────────────
section "GPU / Xorg"
if command -v lspci &>/dev/null; then
  echo "  GPU(s):"
  lspci 2>/dev/null | grep -iE "vga|3d|display" | while read -r line; do
    printf "    - %s\n" "$line"
  done
else
  echo "  $WARN  lspci not available"
fi
echo "  Xorg conf.d files:"
if [ -d /etc/X11/xorg.conf.d ]; then
  ls /etc/X11/xorg.conf.d/ 2>/dev/null | while read -r f; do printf "    - /etc/X11/xorg.conf.d/%s\n" "$f"; done
else
  echo "    (none)"
fi
check_file   "~/.Xresources"             "$HOME/.Xresources"
check_pkg    "xorg-server"               xorg-server
check_pkg    "xf86-video-amdgpu"         xf86-video-amdgpu
check_pkg    "xf86-video-intel"          xf86-video-intel
check_pkg    "nvidia"                    nvidia

# ── LightDM config ────────────────────────────────────────────────────────────
section "LightDM Config"
check_file   "/etc/lightdm/lightdm.conf"            /etc/lightdm/lightdm.conf
check_file   "/etc/lightdm/lightdm-gtk-greeter.conf" /etc/lightdm/lightdm-gtk-greeter.conf
if [ -f /etc/lightdm/lightdm.conf ]; then
  echo "  Contents:"
  grep -v '^\s*#\|^\s*$' /etc/lightdm/lightdm.conf 2>/dev/null | sed 's/^/    /'
fi

# ── AUR helper ────────────────────────────────────────────────────────────────
section "AUR Helper"
check        "yay"                       yay
check        "paru"                      paru

# ── SSH keys ──────────────────────────────────────────────────────────────────
section "SSH Keys (~/.ssh)"
if [ -d "$HOME/.ssh" ]; then
  echo "  Key files (name only, no content):"
  find "$HOME/.ssh" -maxdepth 1 -type f | while read -r f; do
    base=$(basename "$f")
    case "$base" in
      *.pub) printf "    - %s (public)\n" "$base" ;;
      known_hosts|authorized_keys|config) printf "    - %s\n" "$base" ;;
      *) printf "    - %s (private)\n" "$base" ;;
    esac
  done
else
  echo "  $FAIL  ~/.ssh not found"
fi

# ── npm global packages ───────────────────────────────────────────────────────
section "npm Global Packages"
if command -v npm &>/dev/null; then
  npm list -g --depth=0 2>/dev/null | tail -n +2 | sed 's/^/  /' || echo "  (none)"
else
  echo "  $WARN  npm not found"
fi

# ── Locale + timezone ─────────────────────────────────────────────────────────
section "Locale + Timezone"
echo "  Locale:"
locale 2>/dev/null | sed 's/^/    /' || echo "    (locale not available)"
echo "  Timezone:"
if command -v timedatectl &>/dev/null; then
  timedatectl 2>/dev/null | grep -E "Time zone|Local time|RTC" | sed 's/^/    /'
else
  cat /etc/timezone 2>/dev/null | sed 's/^/    /' || echo "    (not available)"
fi

# ── ~/bin unmanaged scripts ───────────────────────────────────────────────────
section "~/bin — Unmanaged Scripts (not symlinked from dotfiles)"
if [ -d "$HOME/bin" ]; then
  found=0
  while IFS= read -r -d '' f; do
    if [ ! -L "$f" ]; then
      printf "  $WARN  %s\n" "${f#$HOME/bin/}"
      found=1
    fi
  done < <(find "$HOME/bin" -type f -print0 2>/dev/null)
  [ "$found" -eq 0 ] && echo "  $PASS  all files are symlinks"
else
  echo "  $WARN  ~/bin not found"
fi

# ── ~/.config unmanaged dirs ──────────────────────────────────────────────────
section "~/.config — Dirs NOT symlinked from dotfiles"
if [ -d "$HOME/.config" ]; then
  while IFS= read -r -d '' entry; do
    if [ ! -L "$entry" ]; then
      printf "  $WARN  %s\n" "${entry#$HOME/.config/}"
    fi
  done < <(find "$HOME/.config" -mindepth 1 -maxdepth 1 -print0 2>/dev/null | sort -z)
else
  echo "  $WARN  ~/.config not found"
fi

# ── $GOPATH/bin global Go tools ──────────────────────────────────────────────
section "GOPATH/bin — Global Go Tools"
gobin="${GOPATH:-$HOME/go}/bin"
if [ -d "$gobin" ]; then
  echo "  Location: $gobin"
  find "$gobin" -maxdepth 1 -type f -o -type l 2>/dev/null | sort | while read -r f; do
    printf "  %s  %s\n" "$PASS" "$(basename "$f")"
  done
else
  echo "  $WARN  $gobin not found"
fi

# ── tmux plugins ──────────────────────────────────────────────────────────────
section "tmux Plugins (~/.tmux/plugins)"
if [ -d "$HOME/.tmux/plugins" ]; then
  find "$HOME/.tmux/plugins" -mindepth 1 -maxdepth 1 -type d | sort | while read -r d; do
    name=$(basename "$d")
    # get the current commit for the plugin
    commit=$(git -C "$d" rev-parse --short HEAD 2>/dev/null || echo "no git")
    printf "  %s  %-38s %s\n" "$PASS" "$name" "$commit"
  done
else
  echo "  $FAIL  ~/.tmux/plugins not found (TPM not initialised?)"
fi

# ── Neovim plugin dir ─────────────────────────────────────────────────────────
section "Neovim Plugins"
for plugdir in \
  "$HOME/.local/share/nvim/lazy" \
  "$HOME/.local/share/nvim/plugged" \
  "$HOME/.config/nvim/plugged"; do
  if [ -d "$plugdir" ]; then
    echo "  Plugin dir: $plugdir"
    find "$plugdir" -mindepth 1 -maxdepth 1 -type d | sort | while read -r d; do
      printf "  %s  %s\n" "$PASS" "$(basename "$d")"
    done
    break
  fi
done
if [ ! -d "${HOME}/.local/share/nvim/lazy" ] && [ ! -d "${HOME}/.local/share/nvim/plugged" ]; then
  echo "  $WARN  no plugin dir found"
fi

# ── XDG autostart ─────────────────────────────────────────────────────────────
section "XDG Autostart (~/.config/autostart)"
if [ -d "$HOME/.config/autostart" ]; then
  find "$HOME/.config/autostart" -name "*.desktop" | sort | while read -r f; do
    name=$(grep -m1 '^Name=' "$f" 2>/dev/null | cut -d= -f2 || basename "$f")
    exec=$(grep -m1 '^Exec=' "$f" 2>/dev/null | cut -d= -f2 || "")
    printf "  %s  %-30s %s\n" "$PASS" "$name" "$exec"
  done
else
  echo "  (none)"
fi

# ── ~/.local/bin ──────────────────────────────────────────────────────────────
section "~/.local/bin Contents"
if [ -d "$HOME/.local/bin" ]; then
  find "$HOME/.local/bin" -maxdepth 1 \( -type f -o -type l \) | sort | while read -r f; do
    if [ -L "$f" ]; then
      printf "  %s  %-38s -> %s\n" "$WARN" "$(basename "$f")" "$(readlink "$f")"
    else
      printf "  %s  %s\n" "$PASS" "$(basename "$f")"
    fi
  done
else
  echo "  (not found)"
fi

# ── Conflicting shell init files ──────────────────────────────────────────────
section "Potentially Conflicting Shell Init Files"
for f in \
  "$HOME/.bashrc" \
  "$HOME/.bash_profile" \
  "$HOME/.bash_login" \
  "$HOME/.profile" \
  "$HOME/.zprofile" \
  "$HOME/.zlogin"; do
  if [ -e "$f" ]; then
    lines=$(wc -l < "$f" 2>/dev/null || echo "?")
    if [ -L "$f" ]; then
      printf "  %s  %-30s symlink -> %s\n" "$WARN" "$(basename "$f")" "$(readlink "$f")"
    else
      printf "  %s  %-30s exists (%s lines)\n" "$WARN" "$(basename "$f")" "$lines"
    fi
  else
    printf "  %s  %-30s not present\n" "$PASS" "$(basename "$f")"
  fi
done

# ── Hardware summary ──────────────────────────────────────────────────────────
section "Hardware Summary"
echo "  CPU:"
lscpu 2>/dev/null | grep -E "^(Model name|CPU\(s\)|Thread|Core|Socket|Architecture)" | sed 's/^/    /'
echo "  Memory:"
free -h 2>/dev/null | sed 's/^/    /' || echo "    (free not available)"
echo "  Disk:"
df -h 2>/dev/null | grep -v tmpfs | sed 's/^/    /'

# ── /etc/environment ──────────────────────────────────────────────────────────
section "/etc/environment (system-wide env)"
if [ -f /etc/environment ]; then
  grep -v '^\s*#\|^\s*$' /etc/environment | sed 's/^/  /'
else
  echo "  (not found)"
fi

# ── Default MIME applications ─────────────────────────────────────────────────
section "Default MIME Applications"
if command -v xdg-mime &>/dev/null; then
  for mime in \
    "x-scheme-handler/http" \
    "x-scheme-handler/https" \
    "terminal" \
    "inode/directory" \
    "video/mp4" \
    "audio/mpeg"; do
    result=$(xdg-mime query default "$mime" 2>/dev/null || echo "not set")
    printf "  %-38s %s\n" "$mime" "$result"
  done
else
  echo "  $WARN  xdg-mime not found"
fi
# Also dump mimeapps.list if it exists
if [ -f "$HOME/.config/mimeapps.list" ]; then
  echo "  ~/.config/mimeapps.list:"
  grep -v '^\s*#\|^\s*$' "$HOME/.config/mimeapps.list" | sed 's/^/    /'
fi

# ── Nitrogen wallpaper config ─────────────────────────────────────────────────
section "Nitrogen Wallpaper Config"
if [ -f "$HOME/.config/nitrogen/bg-saved.cfg" ]; then
  cat "$HOME/.config/nitrogen/bg-saved.cfg" | sed 's/^/  /'
else
  echo "  $WARN  ~/.config/nitrogen/bg-saved.cfg not found"
fi
if [ -f "$HOME/.config/nitrogen/nitrogen.cfg" ]; then
  echo "  nitrogen.cfg dirs:"
  grep -A2 '^\[nitrogen\]' "$HOME/.config/nitrogen/nitrogen.cfg" 2>/dev/null | sed 's/^/    /'
fi

# ── pacman explicitly installed packages (full list) ─────────────────────────
section "Explicitly Installed Packages (pacman -Qe)"
pacman -Qe 2>/dev/null || echo "  (pacman not available)"

# ── AUR packages ─────────────────────────────────────────────────────────────
section "AUR / Foreign Packages (pacman -Qm)"
pacman -Qm 2>/dev/null || echo "  (none or pacman not available)"

# ── Enabled systemd services ──────────────────────────────────────────────────
section "Enabled systemd Services"
systemctl list-unit-files --state=enabled --no-pager 2>/dev/null | grep -v "^UNIT\|^$\|listed" || echo "  (systemctl not available)"

echo ""
echo "========================================"
echo " Done. Paste this output back to Claude."
echo "========================================"
