# general.
export DOTFILES="$HOME/.dotfiles"
export ROOT="$HOME"
export PATH="$PATH:$ROOT/bin"
export EDITOR="nvim"
export BROWSER="firefox"

# zsh.
export HISTFILE="$HOME/.zhistory" # history filepath.
export HISTSIZE=10000             # maximum events for internal history.
export SAVEHIST=10000             # maximum events in history file.

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

# grep.
export GREP_COLOR='mt=01;34'

# gcc.
export PATH="$PATH:/usr/local/osx-ndk-x86/bin"

# gtk.
export GTK_THEME="Adwaita:dark"

# mason.
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"
