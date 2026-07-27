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


# enable for tab-completion.
# Skip compaudit if the dump file is less than 24h old (fast path).
# Regenerate fully if it's stale — catches new completions from brew installs etc.
autoload -U compinit
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
HISTSIZE=50000   # lines kept in memory.
SAVEHIST=50000   # lines written to $HISTFILE.
setopt EXTENDED_HISTORY       # write the history file in the ':start:elapsed;command' format.
setopt SHARE_HISTORY          # share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST # expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS       # do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS   # delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS      # do not display a previously found event.
setopt HIST_IGNORE_SPACE      # do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS      # do not write a duplicate event to the history file.
setopt HIST_VERIFY            # do not execute immediately upon history expansion.

# source external files.
# NOTE: ~/work is intentionally omitted here — it's sourced by .zshenv so it's
# available to all processes (including non-interactive ones like Claude Code).
# Sourcing it again here would double-run pyenv init, gh auth token, etc.
files=(
  "$HOME/aliases"
)
for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    source "$file"
  fi
done

# set HISTFILE after sourcing external files so nothing in ~/work can clobber it.
# NOTE: HISTFILE is exported in .zshenv — the override here ensures ~/work cannot
# change it after the fact.
export HISTFILE="$HOME/.zhistory"

# use starship, if installed.
if command -v starship &>/dev/null; then
  eval "$(starship init zsh)" \
    || die "failed to setup starship"
fi

# enable zsh-syntax-highlighting.
case "$os" in
  "Darwin")
    alias firefox='/Applications/Firefox.app/Contents/MacOS/firefox --marionette -remote-allow-system-access'
    if [[ -n "$HOMEBREW_PREFIX" ]]; then
      if [[ -f "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
        source "$HOMEBREW_PREFIX/opt/zsh-syntax-highlighting/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
      fi
    fi
  ;;
  "Linux")
    if [[ -f "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
      source "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
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
if [[ -t 1 ]]; then
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

