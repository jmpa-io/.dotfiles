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

# check os.
os=$(uname) \
    || die "failed to get operating system"
[[ $os == Linux || $os == Darwin ]] \
    || die "$os is not supported, missing implementation"

# check deps.
case "$os" in
  Darwin) deps=("curl" "brew") ;;
  Linux)  deps=("curl" "unzip") ;;
esac
for dep in "${deps[@]}"; do
    hash "$dep" 2>/dev/null || missing+=("$dep")
done
if [[ ${#missing[@]} -ne 0 ]]; then
    [[ ${#missing[@]} -gt 1 ]] && { s="s"; }
    die "missing dep${s}: ${missing[*]}"
fi

# setup cleanup.
cleanup() {
  case "$os" in
    Darwin)
      files=("./AWSCLIV2.pkg")
    ;;
    Linux)
      files=("./starship.sh")
    ;;
  esac
  for file in "${files[@]}"; do
    [[ -f "$file" ]] || { continue; }
    rm -rf "$file" \
      || die "failed to clean up $file"
  done
}
trap cleanup SIGTERM SIGINT EXIT

# setup .dotfiles.
if ! [[ -d "$HOME/.dotfiles" ]]; then
  ln -s "$PWD" "$HOME/.dotfiles" \
    || die "failed to create symlink for .dotfiles"
fi

# setup .zshrc files.
files=("zshenv" "zshrc")
for file in "${files[@]}"; do
  src="$PWD/zsh/$file"
  dest="$HOME/.$file"
  if ! [[ -L "$dest" ]]; then
    ln -s "$src" "$dest" \
      || die "failed to create symlink from $src to $dest"
  fi
done

# setup .gitconfig.
if ! [[ -f "$HOME/.gitconfig" ]]; then
  ln -s "$PWD/git/gitconfig" "$HOME/.gitconfig" \
    || die "failed to create symlink for gitconfig"
fi

# setup .local directory.
if ! [[ -d "$HOME/.local" ]]; then
  mkdir "$HOME/.local" \
    || die "failed to create local folder in $HOME"
fi

# install starship config.
if ! [[ -f "$HOME/.config/starship.toml" ]]; then
  dir="$HOME/.config"
  if ! [[ -d "$dir" ]]; then
    mkdir "$dir" \
      || die "failed to create $dir"
  fi
  ln -s "$PWD/starship/starship.toml" "$dir/starship.toml" \
    || die "failed to create symlink for starship config"
fi

# install zsh.
hash zsh &>/dev/null || {
  case "$os" in
    Darwin)
      brew install zsh \
        || die "failed to install zsh"
    ;;
    Linux)
      sudo apt-get install -y zsh \
        || die "failed to install zsh"
    ;;
  esac

  # switch default shell.
  chsh -s "$(which zsh)" \
    || die "failed to change default shell to zsh"
}

# install starship.
hash starship &>/dev/null || {
  case "$os" in
    Darwin)
      brew install starship \
        || die "failed to install starship"
    ;;
    Linux)
      file=starship.sh
      curl -sSLo "$file" https://starship.rs/install.sh  \
          || die "failed to download $file"
      chmod +x ./$file \
          || die "failed to grant execute permissions to $file"
      ./$file -V -y \
          || die "failed to install starship"
    ;;
  esac
}

# install go.
hash go &>/dev/null || {
  case "$os" in
    Darwin)
      brew install go \
        || die "failed to install go"
    ;;
    Linux)
      sudo apt-get install golang -y \
        || die "failed to install go"
    ;;
  esac
}

# install aws.
hash aws &>/dev/null || {
  case "$os" in
    Darwin)
      file="AWSCLIV2.pkg"
      curl -sSLo "$file" "https://awscli.amazonaws.com/AWSCLIV2.pkg" \
        || die "failed to download $file"
      sudo installer -pkg AWSCLIV2.pkg -target / \
        || die "failed to install awscli"
    ;;
    Linux)
      file="awscliv2.zip"
      curl -sSLo "$file" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
        || die "failed to download $file"
      unzip "$file" \
        || die "failed to unzip $file"
      sudo ./aws/install -i /usr/local/aws-cli -b /usr/local/bin \
        || doe "failed to install awscli"
    ;;
  esac

  # set default region.
  aws configure set region ap-southeast-2 \
    || die "failed to set the default aws region"
}

# install jq.
hash jq &>/dev/null || {
  case "$os" in
    Darwin)
      brew install jq \
        || die "failed to install jq"
    ;;
    Linux)
      sudo apt-get install jq -y \
        || die "failed to install jq"
    ;;
  esac
}
