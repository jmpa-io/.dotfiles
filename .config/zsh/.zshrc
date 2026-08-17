#  ______     ______     __  __     ______     ______
# /\___  \   /\  ___\   /\ \_\ \   /\  == \   /\  ___\
# \/_/  /__  \ \___  \  \ \  __ \  \ \  __<   \ \ \____
#   /\_____\  \/\_____\  \ \_\ \_\  \ \_\ \_\  \ \_____\
#   \/_____/   \/_____/   \/_/\/_/   \/_/ /_/   \/_____/
#
#
# (http://patorjk.com/software/taag/#p=display&h=0&f=Sub-Zero&t=zshrc)
#
#
# REFERENCES:
# — https://thevaluable.dev/zsh-install-configure-mouseless
# - https://github.com/BrodieRobertson/dotfiles


# Re-prepend homebrew after /etc/zprofile (login shell init) overwrites PATH order.
[[ -n "$HOMEBREW_PREFIX" ]] && export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"

# enable for tab-completion.
# Skip compaudit if the dump file is less than 24h old (fast path).
# Regenerate fully if it's stale — catches new completions from brew installs etc.
autoload -U compinit
# shellcheck disable=SC1036,SC1072,SC1073,SC1009  # zsh extended glob qualifier — not valid bash syntax
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# enable to allow tab completion to work with dashes.
# eg. try `cp -` + tab
_comp_options+=(globdots)

# navigation.
setopt AUTO_CD                # go to folder path without using cd.
setopt CORRECT                # spelling correction.
setopt CDABLE_VARS            # change directory to a path stored in a variable.
setopt EXTENDED_GLOB          # use extended globbing syntax.
setopt AUTO_PUSHD             # push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS      # do not store duplicates in the stack.
setopt NO_NOTIFY              # suppress background job completion notifications.
setopt NO_MONITOR             # suppress background job status reporting entirely.

# history.
HISTSIZE=100000   # lines kept in memory.
SAVEHIST=100000   # lines written to $HISTFILE.
setopt EXTENDED_HISTORY       # write the history file in the ':start:elapsed;command' format.
setopt SHARE_HISTORY          # share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS       # do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS      # do not display a previously found event.
setopt HIST_IGNORE_SPACE      # do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS      # do not write a duplicate event to the history file.
setopt HIST_VERIFY            # do not execute immediately upon history expansion.

# source external files from ~/.dotfiles.d/ if it exists, otherwise fall back
# to legacy home-dir locations.
# NOTE: work is intentionally omitted — sourced by .zshenv so it's available to
# all processes (including non-interactive ones like Claude Code). Sourcing it
# again here would double-run pyenv init, gh auth token, etc.
if [[ -d "$HOME/.dotfiles.d" ]]; then
  for f in "$HOME/.dotfiles.d/aliases" "$HOME/.dotfiles.d/ai-aliases"; do
    [[ -f "$f" ]] && source "$f"
  done
else
  # legacy fallback.
  [[ -f "$HOME/aliases" ]] && source "$HOME/aliases"
  if [[ -f "$HOME/.ai-aliases" ]] && command -v claude &>/dev/null; then
    source "$HOME/.ai-aliases"
  fi
fi


# use starship, if installed.
# Cache the init script keyed by the binary's mtime — invalidated automatically on upgrade.
if command -v starship &>/dev/null; then
  _starship_bin=$(command -v starship)
  _starship_mtime=$(date -r "$_starship_bin" +%s 2>/dev/null || stat -c %Y "$_starship_bin" 2>/dev/null)
  _starship_cache="${XDG_CACHE_HOME:-$HOME/.cache}/starship-init-${_starship_mtime}.zsh"
  if [[ ! -f "$_starship_cache" ]]; then
    rm -f "${XDG_CACHE_HOME:-$HOME/.cache}"/starship-init-*.zsh
    starship init zsh > "$_starship_cache"
  fi
  # shellcheck disable=SC1090
  source "$_starship_cache" || die "failed to setup starship"
  unset _starship_bin _starship_mtime _starship_cache
fi

# enable zsh-syntax-highlighting + zsh-autosuggestions.
case "$os" in
  "Darwin")
    alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox --marionette -remote-allow-system-access'
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
      if [[ -f "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
        source "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      fi
      if [[ -f "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
        source "$HOMEBREW_PREFIX/opt/zsh-autosuggestions/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
      fi
    fi
  ;;
  "Linux")
    if [[ -f "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
      source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
    fi
    if [[ -f "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
      source "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    fi
    ;;
esac

# enable fzf completion & key bindings, if installed.
if command -v fzf &>/dev/null; then
  case "$os" in
  "Darwin")
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
      if [[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh" ]]; then
        source "$HOMEBREW_PREFIX/opt/fzf/shell/completion.zsh"
      fi
      if [[ -f "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]]; then
        source "$HOMEBREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
      fi
    fi
  ;;
    "Linux")
      if [[ -f "/usr/share/fzf/completion.zsh" ]]; then
        source "/usr/share/fzf/completion.zsh"
      fi
      if [[ -f "/usr/share/fzf/key-bindings.zsh" ]]; then
        source "/usr/share/fzf/key-bindings.zsh"
      fi
      ;;
  esac
fi

# load opener image (only in interactive terminals, not programmatic shells).
if [[ -t 1 && -z "$TMUX" ]]; then
  case "$os" in
    "Linux")
      [[ -f "$HOME/tree-v2.png" ]] && command -v wezterm &>/dev/null && wezterm imgcat "$HOME/tree-v2.png"
      ;;
    "Darwin")
      [[ -f "$HOME/tree-v2.png" ]] && command -v imgcat &>/dev/null && imgcat "$HOME/tree-v2.png"
      ;;
  esac
  echo; echo
fi

# browser-manager: launch Firefox with Marionette enabled (no red bar in main profile).
# macOS only — Linux uses system Firefox directly. Also defined in common/aliases Darwin block.

