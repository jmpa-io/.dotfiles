FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    SHELL=/bin/zsh

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      zsh git curl ca-certificates make unzip \
      fzf tmux neovim ripgrep jq \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN curl -sSfL https://starship.rs/install.sh | sh -s -- -y

RUN git clone --depth=1 \
      https://github.com/zsh-users/zsh-syntax-highlighting.git \
      /usr/share/zsh/plugins/zsh-syntax-highlighting

COPY . /root/.dotfiles

RUN cd /root/.dotfiles \
 && make configure-zsh configure-git configure-starship configure-tmux configure-common \
 && git config --global user.email "docker@local" \
 && git config --global user.name "Docker"

WORKDIR /root
CMD ["/bin/zsh"]
