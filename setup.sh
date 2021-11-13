#!/usr/bin/env bash
# installs dotfiles & largely sets up a new PC.
# note: fonts should be installed manually.

# funcs.
die() { echo "$1" >&2; exit "${2:-1}"; }

# check bash version.
v=5; [[ ${BASH_VERSION:0:1} -lt "$v" ]] \
    && die "bash version $v required, please update"

# check root.
[[ -d .git ]] \
    || die "$0 must be run from the repository root directory"

# check deps.
deps=("curl" "unzip")
for dep in "${deps[@]}"; do
    hash "$dep" 2>/dev/null || missing+=("$dep")
done
if [[ ${#missing[@]} -ne 0 ]]; then
    [[ ${#missing[@]} -gt 1 ]] && { s="s"; }
    die "missing dep${s}: ${missing[*]}"
fi

# check os.
# TODO support darwin.
os=$(uname) \
    || die "failed to get operating system"
[[ $os == [Ll]inux ]] \
    || die "$os is not supported, missing implementation"

# setup cleanup.
cleanup() {
    files=("./starship.sh")
    for file in ${files[@]}; do
        [[ -f "$file" ]] || { continue; }
        rm -rf "$file" \
            || die "failed to clean up $file"
    done
}
trap cleanup SIGTERM SIGINT EXIT

# install zsh, if not installed.
if ! [[ -f /usr/bin/zsh ]]; then

    # install zsh.
    # TODO what if not running ubuntu / missing apt-get?
    sudo apt-get install -y zsh \
        || die "failed to install zsh"

    # switch default shell.
    chsh -s $(which zsh) \
        || die "failed to change default shell to zsh"
fi

# install starship, if not installed.
hash starship &>/dev/null || {

    # download starship.
    file=starship.sh
    curl -sSLo "$file" https://starship.rs/install.sh  \
        || die "failed to download $file"
    chmod +x ./$file \
        || die "failed to grant execute permissions to $file"

    # install starship.
    ./$file -V -y \
        || die "failed to install $file"

    # install config.
    dir="$HOME/.config"
    if ! [[ -d "$dir" ]]; then
        mkdir "$dir" \
            || die "failed to create $dir"
    fi
    ln -s "$PWD/starship/starship.toml" "$dir/starship.toml" \
        || die "failed to create symlink for starship config."
}

# setup directories.
dirs=("$HOME/.local" "$HOME/.local/bin")
for dir in "${dirs[@]}"; do
    [[ -d "$dir" ]] && { continue; }
    mkdir "$dir" \
        || die "failed to create $dir"
done

# setup .dotfiles in $HOME, if needed.
if ! [[ -d "$HOME/.dotfiles" ]]; then
    ln -s "$PWD" "$HOME/.dotfiles" \
        || die "failed to create symlink for .dotfiles"
fi

# setup .zshrc files, if needed.
files=("zshenv" "zshrc")
for file in "${files[@]}"; do
    src="$PWD/zsh/$file"
    dest="$HOME/.$file"
    if ! [[ -L "$dest" ]]; then
        ln -s "$src" "$dest" \
            || die "failed to create symlink from $src to $dest"
    fi
done

# install go, if needed.
hash go &>/dev/null || {
    sudo apt-get install golang -y \
        || die "failed to install go"
}

# install aws, if needed.
hash aws &>/dev/null || { 
    file="awscliv2.zip"
    curl -sSLo "$file" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        || die "failed to download $file"
    unzip "$file" \
        || die "failed to unzip $file"
    sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin \
        || doe "failed to install awscli"
}

# install gitconfig, if needed.
if ! [[ -f "$HOME/.gitconfig" ]]; then
    ln -s "$PWD/git/gitconfig" "$HOME/.gitconfig" \
        || die "failed to create symlink for gitconfig"
fi

# install git-credential-manager, if needed.
if ! [[ -f "$HOME/.local/bin/git-credential-manager" ]]; then
    ln -s "$PWD/git/git-credential-manager" "$HOME/.local/bin/git-credential-manager" \
        || die "failed to create symlink for git-credential-manager"
fi