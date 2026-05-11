SHELL = /bin/bash

# Detected OS: darwin or linux.
OS := $(shell uname | tr '[:upper:]' '[:lower:]')

# Package manager per OS.
PKG_DARWIN  = brew install
PKG_LINUX   = sudo pacman -S --noconfirm

# Generic install macro: $(call pkg,<darwin-pkg>,<linux-pkg>)
# Falls back to darwin pkg if linux pkg not specified.
define pkg
	$(if $(filter darwin,$(OS)), \
		$(PKG_DARWIN) $1, \
		$(PKG_LINUX) $(or $2,$1))
endef

# Symlink a config directory into ~/.config/.
define cfg
	ln -sfn $(PWD)/$1 $(HOME)/.config/
endef

# Symlink files from a directory directly into $HOME/.
define cfg-home
	for f in $$(find $1 -mindepth 1 -maxdepth 1 -type f); do \
		ln -sf $(PWD)/$$f $(HOME)/; \
	done
endef

.DEFAULT_GOAL := help

# ---------------------------------------------------------------
# Aggregate targets
# ---------------------------------------------------------------

.PHONY: install
install: ## Install ALL tools.
install: \
	create-directories \
	install-go \
	install-awscli \
	install-zsh \
	install-zsh-syntax-highlighting \
	install-fzf \
	install-neovim \
	install-bash \
	install-starship \
	install-polybar \
	install-jq \
	install-docker \
	install-deno \
	install-wezterm \
	install-github-cli \
	install-fonts \
	install-opencode

.PHONY: configure
configure: ## Configure ALL tools.
configure: \
	configure-git \
	configure-github-cli \
	configure-awscli \
	configure-zsh \
	configure-starship \
	configure-neovim \
	configure-wezterm \
	configure-btop \
	configure-polybar \
	configure-picom \
	configure-i3 \
	configure-iterm2 \
	configure-opencode \
	configure-common

.PHONY: setup
setup: ## Install AND configure ALL tools.
setup: \
	create-directories \
	setup-go \
	setup-git \
	setup-github-cli \
	setup-awscli \
	setup-zsh \
	setup-zsh-syntax-highlighting \
	setup-fzf \
	setup-neovim \
	setup-bash \
	setup-starship \
	setup-polybar \
	setup-jq \
	setup-docker \
	setup-deno \
	setup-wezterm \
	setup-btop \
	setup-picom \
	setup-pulsemixer \
	setup-fonts \
	setup-opencode \
	setup-common \
	setup-i3

.PHONY: update
update: ## Update all brew/pacman packages.
ifeq ($(OS),darwin)
	brew update && brew upgrade
else
	sudo pacman -Syu --noconfirm
endif

# ---------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------

.PHONY: create-directories
create-directories: ## Create required directories.
create-directories: $(HOME)/.config

$(HOME)/%:
	@mkdir -p "$@"

dist:
	@mkdir -p dist

dist/%: dist
	@mkdir -p dist/$*

# ---------------------------------------------------------------
# go
# ---------------------------------------------------------------

.PHONY: install-go setup-go
install-go: ## Install 'go'.
	$(call pkg,go,golang)

setup-go: install-go
# NOTE: go is also configured in .zshenv.

# ---------------------------------------------------------------
# git (assumed installed)
# ---------------------------------------------------------------

.PHONY: configure-git setup-git
configure-git: ## Configure 'git'.
configure-git: .config/git
	$(call cfg-home,.config/git)

setup-git: configure-git

# ---------------------------------------------------------------
# github-cli
# ---------------------------------------------------------------

.PHONY: install-github-cli configure-github-cli setup-github-cli
install-github-cli: ## Install 'github-cli'.
	$(call pkg,gh,github-cli)

configure-github-cli: ## Configure 'github-cli'.
	gh auth status &>/dev/null || gh auth login
	gh auth setup-git

setup-github-cli: install-github-cli configure-github-cli

# ---------------------------------------------------------------
# awscli
# ---------------------------------------------------------------

.PHONY: install-awscli configure-awscli setup-awscli
install-awscli: ## Install 'awscli'.
install-awscli: dist/awscli
ifeq ($(OS),darwin)
	brew install awscli
else
	arch=$$(uname -m); \
	if [[ "$$arch" == "aarch64" || "$$arch" == "arm64" ]]; then \
		curl -sSLo dist/awscli/awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip; \
	else \
		curl -sSLo dist/awscli/awscli.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip; \
	fi
	unzip dist/awscli/awscli.zip -d dist/awscli/
	dist/awscli/aws/install -i /usr/local/aws-cli -b /usr/local/bin --update
endif

configure-awscli: ## Configure 'awscli'.
	aws configure set region ap-southeast-2

setup-awscli: install-awscli configure-awscli

# ---------------------------------------------------------------
# zsh
# ---------------------------------------------------------------

.PHONY: install-zsh configure-zsh setup-zsh
install-zsh: ## Install 'zsh'.
	$(call pkg,zsh)

configure-zsh: ## Configure 'zsh'.
configure-zsh: .config/zsh
	$(call cfg-home,.config/zsh)

setup-zsh: install-zsh configure-zsh

# ---------------------------------------------------------------
# zsh-syntax-highlighting
# ---------------------------------------------------------------

.PHONY: install-zsh-syntax-highlighting setup-zsh-syntax-highlighting
install-zsh-syntax-highlighting: ## Install 'zsh-syntax-highlighting'.
	$(call pkg,zsh-syntax-highlighting)

setup-zsh-syntax-highlighting: install-zsh-syntax-highlighting

# ---------------------------------------------------------------
# fzf
# ---------------------------------------------------------------

.PHONY: install-fzf setup-fzf
install-fzf: ## Install 'fzf'.
	$(call pkg,fzf)

setup-fzf: install-fzf

# ---------------------------------------------------------------
# bash
# ---------------------------------------------------------------

.PHONY: install-bash setup-bash
install-bash: ## Install 'bash'.
	$(call pkg,bash)

setup-bash: install-bash

# ---------------------------------------------------------------
# starship
# ---------------------------------------------------------------

.PHONY: install-starship configure-starship setup-starship
install-starship: ## Install 'starship'.
install-starship: dist/starship
ifeq ($(OS),darwin)
	brew install starship
else
	curl -sSLo dist/starship/install.sh https://starship.rs/install.sh
	chmod +x dist/starship/install.sh
	dist/starship/install.sh -V -y
endif

configure-starship: ## Configure 'starship'.
configure-starship: .config/starship $(HOME)/.config
	$(call cfg,.config/starship)

setup-starship: install-starship configure-starship

# ---------------------------------------------------------------
# neovim
# ---------------------------------------------------------------

.PHONY: install-neovim configure-neovim setup-neovim
install-neovim: ## Install 'neovim'.
	$(call pkg,neovim)

configure-neovim: ## Configure 'neovim'.
configure-neovim: .config/neovim $(HOME)/.config
	git submodule update --init --recursive
	ln -sfn $(PWD)/.config/neovim/ $(HOME)/.config/nvim

setup-neovim: install-neovim configure-neovim

# ---------------------------------------------------------------
# wezterm
# ---------------------------------------------------------------

.PHONY: install-wezterm configure-wezterm setup-wezterm
install-wezterm: ## Install 'wezterm'.
ifeq ($(OS),darwin)
	brew install --cask wezterm
else
	sudo pacman -S --noconfirm wezterm
endif

configure-wezterm: ## Configure 'wezterm'.
configure-wezterm: .config/wezterm
	$(call cfg-home,.config/wezterm)

setup-wezterm: install-wezterm configure-wezterm

# ---------------------------------------------------------------
# btop (assumed installed)
# ---------------------------------------------------------------

.PHONY: configure-btop setup-btop
configure-btop: ## Configure 'btop'.
configure-btop: .config/btop $(HOME)/.config
	$(call cfg,.config/btop)

setup-btop: configure-btop

# ---------------------------------------------------------------
# polybar (Linux only)
# ---------------------------------------------------------------

.PHONY: install-polybar configure-polybar setup-polybar
install-polybar: ## Install 'polybar' (Linux only).
ifeq ($(OS),linux)
	sudo pacman -S --noconfirm polybar
else
	@echo "Skipping polybar installation (Linux only)."
endif

configure-polybar: ## Configure 'polybar' (Linux only).
ifeq ($(OS),linux)
configure-polybar: .config/polybar $(HOME)/.config
	$(call cfg,.config/polybar)
else
configure-polybar:
	@echo "Skipping polybar configuration (Linux only)."
endif

setup-polybar: install-polybar configure-polybar

# ---------------------------------------------------------------
# picom (Linux only, assumed installed)
# ---------------------------------------------------------------

.PHONY: configure-picom setup-picom
configure-picom: ## Configure 'picom' (Linux only).
ifeq ($(OS),linux)
configure-picom: .config/picom $(HOME)/.config
	$(call cfg,.config/picom)
else
configure-picom:
	@echo "Skipping picom configuration (Linux only)."
endif

setup-picom: configure-picom

# ---------------------------------------------------------------
# pulsemixer (Linux only — TUI audio control, works with PipeWire)
# ---------------------------------------------------------------

.PHONY: install-pulsemixer setup-pulsemixer
install-pulsemixer: ## Install 'pulsemixer' (Linux only).
ifeq ($(OS),linux)
	sudo pacman -S --noconfirm pulsemixer
else
	@echo "Skipping pulsemixer installation (Linux only)."
endif

setup-pulsemixer: install-pulsemixer

# ---------------------------------------------------------------
# i3 (Linux only, assumed installed)
# ---------------------------------------------------------------

.PHONY: configure-i3 setup-i3
configure-i3: ## Configure 'i3' (Linux only).
ifeq ($(OS),linux)
configure-i3: .config/i3
	ln -sfn $(PWD)/.config/i3 $(HOME)/.i3
else
configure-i3:
	@echo "Skipping i3 configuration (Linux only)."
endif

setup-i3: configure-i3

# ---------------------------------------------------------------
# jq
# ---------------------------------------------------------------

.PHONY: install-jq setup-jq
install-jq: ## Install 'jq'.
	$(call pkg,jq)

setup-jq: install-jq

# ---------------------------------------------------------------
# docker
# ---------------------------------------------------------------

.PHONY: install-docker setup-docker
install-docker: ## Install 'docker'.
ifeq ($(OS),darwin)
	brew install docker
else
	sudo pacman -S --noconfirm docker docker-compose
endif

setup-docker: install-docker

# ---------------------------------------------------------------
# deno (required for peek.nvim markdown preview)
# ---------------------------------------------------------------

.PHONY: install-deno setup-deno
install-deno: ## Install 'deno'.
ifeq ($(OS),darwin)
	brew install deno
else
	curl -fsSL https://deno.land/install.sh | sh
endif

setup-deno: install-deno

# ---------------------------------------------------------------
# iterm2 (macOS only)
# ---------------------------------------------------------------

.PHONY: configure-iterm2 setup-iterm2
configure-iterm2: ## Configure 'iTerm2' profile (macOS only).
ifeq ($(OS),darwin)
	mkdir -p "$(HOME)/Library/Application Support/iTerm2/DynamicProfiles"
	ln -sfn $(PWD)/.config/iterm2/Default.json \
		"$(HOME)/Library/Application Support/iTerm2/DynamicProfiles/Default.json"
else
configure-iterm2:
	@echo "Skipping iTerm2 configuration (macOS only)."
endif

setup-iterm2: ## Install font and configure iTerm2 (macOS only).
ifeq ($(OS),darwin)
setup-iterm2: configure-iterm2
	brew install --cask font-fira-code-nerd-font
else
setup-iterm2:
	@echo "Skipping iTerm2 setup (macOS only)."
endif

# ---------------------------------------------------------------
# fonts (Linux only)
# ---------------------------------------------------------------

.PHONY: install-fonts setup-fonts
install-fonts: ## Install fonts (Linux only).
ifeq ($(OS),linux)
	sudo pacman -S --noconfirm noto-fonts-emoji
	mkdir -p $(HOME)/.local/share/fonts
	cp $(PWD)/fonts/*.ttf $(PWD)/fonts/*.otf $(HOME)/.local/share/fonts/ 2>/dev/null || true
	fc-cache -fv
else
	@echo "Skipping font installation (Linux only — macOS uses brew cask)."
endif

setup-fonts: install-fonts

# ---------------------------------------------------------------
# opencode
# ---------------------------------------------------------------

.PHONY: install-opencode configure-opencode setup-opencode
install-opencode: ## Install 'opencode'.
	curl -fsSL https://opencode.ai/install | bash

configure-opencode: ## Configure 'opencode'.
configure-opencode: .config/opencode $(HOME)/.config
	$(call cfg,.config/opencode)

setup-opencode: install-opencode configure-opencode

# ---------------------------------------------------------------
# common
# ---------------------------------------------------------------

.PHONY: configure-common setup-common
configure-common: ## Configure common shell files.
configure-common: .config/common
	$(call cfg-home,.config/common)

setup-common: configure-common

# ---------------------------------------------------------------
# Housekeeping
# ---------------------------------------------------------------

.PHONY: clean
clean: ## Remove generated files.
	rm -rf dist

.PHONY: help
help: ## Print this help page.
	@echo "Available targets:"
	@awk_script='\
		/^[a-zA-Z\-\\_0-9%\/$$]+:/ { \
			target = $$1; \
			gsub("\\$$1", "%", target); \
			nb = sub(/^## /, "", helpMessage); \
			if (nb == 0) { \
				helpMessage = $$0; \
				nb = sub(/^[^:]*:.* ## /, "", helpMessage); \
			} \
			if (nb) print "\033[33m" target "\033[0m" helpMessage; \
		} { helpMessage = $$0 } \
	'; \
	awk "$$awk_script" $(MAKEFILE_LIST) | column -ts:
