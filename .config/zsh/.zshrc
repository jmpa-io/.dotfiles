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

# funcs.
die() { echo "$1" >&2; }

# determine os.
os=$(uname) \
  || die "failed to get operating system"

# enable for tab-completion.
autoload -U compinit; compinit -u

# enable to allow tab completion to work with dashes.
# eg. try `cp -` + tab
_comp_options+=(globdots)

# navigation.
setopt AUTO_CD                # go to folder path without using cd.
setopt CORRECT                # spelling correction.
setopt CDABLE_VARS            # change directory to a path stored in a variable.
setopt EXTENDED_GLOB          # cse extended globbing syntax.
setopt AUTO_PUSHD             # push the current directory visited on the stack.
setopt PUSHD_IGNORE_DUPS      # do not store duplicates in the stack.
setopt PUSHD_SILENT           # do not print the directory stack after pushd or popd

# history.
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
files=(
  "$HOME/work"
  "$HOME/aliases"
)
for file in "${files[@]}"; do
  if [[ -f "$file" ]]; then
    source "$file"
  fi
done

# use starship, if installed.
if [[ $(starship -V &>/dev/null) -eq 0 ]]; then
  eval "$(starship init zsh)" \
    || die "failed to setup starship"
fi

# enable zsh-syntax-highlighting.
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# enable fzf completion & key bindings, if installed.
if [[ $(fzf --version &>/dev/null) -eq 0 ]]; then
  source /usr/share/fzf/completion.zsh
  source /usr/share/fzf/key-bindings.zsh
fi

# load opener image + quote.
case "$os" in
  "Linux") cat "$HOME/tree-v2.png" | wezterm imgcat ;;
esac
echo; echo

