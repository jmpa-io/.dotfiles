
# determine os (export so it's available in .zshrc).
os=$(uname) || { echo "failed to get operating system" >&2; exit 1; }
export os

# general (cross-platform).
export DOTFILES="$HOME/.dotfiles"
export ROOT="$HOME/go/src/github.com"
export PATH="$PATH:$HOME/bin"
export EDITOR="nvim"
export BROWSER="firefox"

# zsh.
export HISTFILE="$HOME/.zhistory" # history file location.

# starship.
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# go.
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$HOME/go"
export PATH="$PATH:$GOPATH/bin"
# NOTE: GOPRIVATE and CDPATH are set in ~/work — they include CBA orgs and are
# machine-specific so they live outside dotfiles.

# aws.
export AWS_DEFAULT_REGION="ap-southeast-2"
export AWS_REGION="$AWS_DEFAULT_REGION"

# grep.
export GREP_COLORS='mt=01;34'

# mason (neovim lsp tool installer) - same path on all platforms.
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

# os-specific configurations.
case "$os" in
  "Darwin")
    # homebrew — prepend so brew tools take precedence.
    # /opt/homebrew = Apple Silicon; /usr/local = Intel x86_64.
    if [[ "$(uname -m)" == "arm64" ]]; then
      export HOMEBREW_PREFIX="/opt/homebrew"
    else
      export HOMEBREW_PREFIX="/usr/local"
    fi
    export PATH="$HOMEBREW_PREFIX/bin:$HOMEBREW_PREFIX/sbin:$PATH"

    # use GNU make instead of macOS make.
    export PATH="$HOMEBREW_PREFIX/libexec/gnubin:$PATH"
    ;;

  "Linux")
    # gtk (Linux specific).
    export GTK_THEME="Adwaita:dark"
    ;;

esac

# email-manager.
if [[ -d "$GOPATH/src/github.com/jmpa-io/email-manager" ]]; then
  export EMAIL_MANAGER_BIN="$GOPATH/src/github.com/jmpa-io/email-manager/email-manager"
  export EMAIL_FOLDERS_CONFIG="$GOPATH/src/github.com/jmpa-io/email-manager/folders.json"
fi

# source ~/work early so secrets (e.g. PORTKEY_API_KEY) are available to all
# processes, including Claude Code which launches outside interactive shells.
if [[ -f "$HOME/work" ]]; then
  source "$HOME/work"
fi

