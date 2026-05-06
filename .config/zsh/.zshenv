
# determine os (export so it's available in .zshrc).
export os=$(uname) || { echo "failed to get operating system" >&2; exit 1; }

# general (cross-platform).
export DOTFILES="$HOME/.dotfiles"
export ROOT="$HOME"
export PATH="$PATH:$ROOT/bin"
export EDITOR="nvim"
export BROWSER="firefox"

# zsh.
export HISTFILE="$HOME/.zhistory" # history filepath.
export HISTSIZE=100000            # maximum events for internal history.
export SAVEHIST=100000            # maximum events in history file.

# starship.
export STARSHIP_CONFIG="$HOME/.config/starship/starship.toml"

# go.
export PATH="$PATH:/usr/local/go/bin"
export GOPATH="$ROOT/go"
export GOPRIVATE="github.com/jmpa-io,github.com/jcleal"
export CDPATH="$GOPATH/src/github.com/jmpa-io"
export PATH="$PATH:$GOPATH/bin"

# aws.
export AWS_DEFAULT_REGION="ap-southeast-2"
export AWS_REGION="$AWS_DEFAULT_REGION"

# grep.
export GREP_COLOR='mt=01;34'

# mason (neovim lsp tool installer) - same path on all platforms.
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

# os-specific configurations.
# NOTE: Darwin block must come before GH_TOKEN so brew-installed gh is on PATH.
case "$os" in
  "Darwin")
    # homebrew — prepend so brew tools take precedence.
    export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

    # use GNU make instead of macOS make.
    export PATH="/opt/homebrew/libexec/gnubin:$PATH"
    ;;

  "Linux")
    # gtk (Linux specific).
    export GTK_THEME="Adwaita:dark"
    ;;

esac

# github — set after os-specific PATH so gh is guaranteed to be found.
# silently empty if gh is not installed or not authenticated.
export GH_TOKEN=$(gh auth token --hostname github.com 2>/dev/null || true)
