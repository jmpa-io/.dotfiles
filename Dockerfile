FROM ubuntu:24.04

# ─── Build args ────────────────────────────────────────────────────────────────
# CBA_PROXY: CBA Prisma Access proxy IP.
# Override if the IP changes: docker build --build-arg CBA_PROXY=http://NEW.IP:8080
# To find the current IP: nslookup cba.proxy.prismaaccess.com
ARG CBA_PROXY=http://144.125.160.185:8080

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    SHELL=/bin/zsh \
    http_proxy=${CBA_PROXY} \
    https_proxy=${CBA_PROXY} \
    HTTP_PROXY=${CBA_PROXY} \
    HTTPS_PROXY=${CBA_PROXY}

# ─── CBA root CA certs ─────────────────────────────────────────────────────────
# Extracted from the macOS System keychain by 'make extract-certs'.
# Run 'make extract-certs' before 'make docker-build'.
COPY dist/cba-certs/ /usr/local/share/ca-certificates/

# ─── packages ──────────────────────────────────────────────────────────────────
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      zsh git curl ca-certificates make unzip \
      fzf tmux neovim ripgrep jq \
 && update-ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# ─── starship ──────────────────────────────────────────────────────────────────
RUN curl -sSfL \
      --cacert /etc/ssl/certs/ca-certificates.crt \
      https://starship.rs/install.sh | sh -s -- -y

# ─── zsh-syntax-highlighting ───────────────────────────────────────────────────
RUN git clone --depth=1 \
      -c http.sslCAInfo=/etc/ssl/certs/ca-certificates.crt \
      https://github.com/zsh-users/zsh-syntax-highlighting.git \
      /usr/share/zsh/plugins/zsh-syntax-highlighting

# ─── gh CLI ────────────────────────────────────────────────────────────────────
RUN curl -fsSL \
      --cacert /etc/ssl/certs/ca-certificates.crt \
      https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
 && printf 'deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' \
      > /etc/apt/sources.list.d/github-cli.list \
 && apt-get update \
 && apt-get install -y gh \
 && rm -rf /var/lib/apt/lists/*

# ─── dotfiles ──────────────────────────────────────────────────────────────────
COPY . /root/.dotfiles

RUN cd /root/.dotfiles \
 && make configure-zsh configure-git configure-starship configure-tmux configure-common \
 && git config --global user.email "docker@local" \
 && git config --global user.name "Docker"

WORKDIR /root
CMD ["/bin/zsh"]
