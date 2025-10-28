# NOTES:
# - The way things are installed and configured and setup has a lot of duplicate code - this can be refactored and simplified.
# - A configure isn't run by OS, so tools are being configured that don't really need to be configured.

# The shell to use for executing commands.
SHELL = /bin/sh

# The operating system the Makefile is being executed on.
OS := $(shell uname | tr '[:upper:]' '[:lower:]')

# The default command executed when running `make`.
.DEFAULT_GOAL:=	help

# Targets.
create-directories: ## ** Creates ALL directories required by any 'install-*' targets.
create-directories: \
	$(HOME)/.config

install: ## ** Installs ALL tools available for the operating system of this machine.
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
	install-docker

configure: ## ** Configures ALL tools available for the operating system of this machine.
configure: \
	configure-git \
	configure-github-cli \
	configure-awscli \
	configure-zsh \
	configure-starship \
	configure-neovim \
	configure-wezterm \
	configure-common

setup: ## ** Installs AND configures ALL tools available for the operating system of this machine.
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
	setup-wezterm \
	setup-common

---: ## ---

# Creates directories under $HOME.
$(HOME)/%:
	@mkdir -p "$@"

# Creates the root output directory.
dist:
	@mkdir -p dist

# Creates the output directory, for a given service.
dist/%: dist
	@mkdir -p dist/$*

# ---------- go ----------

define install-go-linux
	pacman -S golang
endef

define install-go-darwin
	brew install go
endef

define install-go-for-os
	$(call install-go-$1)
endef

install-go: ## Install 'go'.
	$(call install-go-for-os,$(OS))

# NOTE: go is also being configured in the `.zshenv` file.

setup-go: ## Install 'go' (no configuration needed).
setup-go: install-go

# ---------- git ----------

# NOTE: git is assumed installed.

configure-git: ## Configure 'git'.
configure-git: .config/git
	for file in $(shell find .config/git -mindepth 1 -type f); do \
		ln -sf $(PWD)/$$file $(HOME)/; \
	done

setup-git: ## Install AND configure 'git'.
setup-git: configure-git

# ----------- github-cli -----------

define install-github-cli-linux
	pacman -S github-cli
endef

define install-github-cli-darwin
	brew install gh
endef

define install-github-cli-for-os
	$(call install-github-cli-$1)
endef

install-github-cli: ## Install 'github-cli'.
	$(call install-github-cli-for-os,$(OS))

configure-github-cli: ## Configure 'github-cli'.

	# login, if required.
	gh auth status &>/dev/null || gh auth login

	# setup 'github-cli' as a credential helper.
	gh auth setup-git

setup-github-cli: ## Install AND configure 'github-cli'.
setup-github-cli: install-github-cli configure-github-cli

# ----------- awscli ----------

define install-awscli-linux
	curl -sSLo "dist/awscli/awscli.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
	unzip "dist/awscli/awscli.zip" -d "dist/awscli/"
	dist/awscli/aws/install -i /usr/local/aws-cli -b /usr/local/bin --update
endef

define install-awscli-darwin
	brew install awscli
endef

define install-awscli-for-os
	$(call install-aws-$1)
endef

install-awscli: ## Install 'awscli'.
install-awscli: dist/awscli
	$(call install-awscli-for-os,$(OS))

configure-awscli: ## Configure 'awscli'.

	# set default region.
	aws configure set region ap-southeast-2

setup-awscli: ## Install AND configure 'awscli'.
setup-awscli: install-awscli configure-awscli

# ----------- zsh ----------

define install-zsh-linux
	pacman -S zsh
endef

define install-zsh-darwin
	brew install zsh
endef

define install-zsh-for-os
	$(call install-zsh-$1)
endef

install-zsh: ## Install 'zsh'.
	$(call install-zsh-for-os,$(OS))

configure-zsh: ## Configure 'zsh'.
configure-zsh: .config/zsh
	for file in $(shell find .config/zsh -mindepth 1 -type f); do \
		ln -sf $(PWD)/$$file $(HOME)/; \
	done

setup-zsh: ## Install AND configure 'zsh'.
setup-zsh: install-zsh configure-zsh

# ---------- starship ----------

define install-starship-linux
	curl -sSLo "dist/starship/install.sh" "https://starship.rs/install.sh"
	chmod +x dist/starship/install.sh
	dist/starship/install.sh -V -y
endef

define install-starship-darwin
	brew install starship
endef

define install-starship-for-os
	$(call install-starship-$1)
endef

install-starship: ## Install 'starship'.
install-starship: dist/starship
	$(call install-starship-for-os,$(OS))

# NOTE: starship is also being configured in the `.zshenv` file.
configure-starship: ## Configure 'starship'.
configure-starship: .config/starship $(HOME)/.config
	ln -sf $(PWD)/$< $(HOME)/.config/

setup-starship: ## Install AND configure 'starship'.
setup-starship: install-starship configure-starship

# ---------- polybar ----------

define install-polybar-linux
	pacman -S polybar
endef

define install-polybar-darwin
	# do nothing.
endef

define install-polybar-for-os
	$(call install-polybar-$1)
endef

install-polybar: ## Install 'polybar'.
	$(call install-polybar-for-os,$(OS))

setup-polybar: ## Install 'polybar' (no configuration needed).
setup-polybar: install-polybar

# ---------- neovim ----------

define install-neovim-linux
	pacman -S neovim
endef

define install-neovim-darwin
	brew install neovim
endef

define install-neovim-for-os
	$(call install-neovim-$1)
endef

install-neovim: ## Install 'neovim'.
	$(call install-neovim-for-os,$(OS))

configure-neovim: ## Configure 'neovim'.
configure-neovim: .config/neovim $(HOME)/.config
	ln -sf $(PWD)/$</ $(HOME)/.config/nvim

setup-neovim: ## Install AND configure 'neovim'.
setup-neovim: install-neovim configure-neovim

# ---------- wezterm ----------

define install-wezterm-linux
	pacman -S wezterm
endef

define install-wezterm-darwin
	# do nothing.
endef

define install-wezterm-for-os
	$(call install-neovim-$1)
endef

install-wezterm: ## Install 'wezterm'.
	$(call install-wezterm-for-os,$(OS))

configure-wezterm: ## Configure 'wezterm'.
configure-wezterm: .config/wezterm
	for file in $(shell find .config/wezterm -mindepth 1 -type f); do \
		ln -sf $(PWD)/$$file $(HOME)/; \
	done

setup-wezterm: ## Install AND configure 'wezterm'.
setup-wezterm: install-wezterm configure-wezterm

# ---------- i3 ----------

# NOTE: i3 is assumed installed.

configure-i3: ## Configure 'i3'.
configure-i3: .config/i3
	ln -sf $(PWD)/$< $(HOME)/.i3

# ---------- common ----------

configure-common: ## Configure common files used across multiple tools.
configure-common: .config/common
	for file in $(shell find .config/common -mindepth 1 -maxdepth 1); do \
		ln -sf $(PWD)/$$file $(HOME)/; \
	done

setup-common: ## Install 'common' (no configuration needed).
setup-common: configure-common

# ---------- jq ----------

define install-jq-linux
	pacman -S jq
endef

define install-jq-darwin
	brew install jq
endef

define install-jq-for-os
	$(call install-jq-$1)
endef

install-jq: ## Install 'jq'.
	$(call install-jq-for-os,$(OS))

setup-jq: ## Install 'jq' (no configuration needed).
setup-jq: install-jq

# ---------- zsh-syntax-highlighting ----------

define install-zsh-syntax-highlighting-linux
	pacman -S zsh-syntax-highlighting
endef

define install-zsh-syntax-highlighting-darwin
	brew install zsh-syntax-highlighting
endef

define install-zsh-syntax-highlighting-for-os
	$(call install-zsh-syntax-highlighting-$1)
endef

install-zsh-syntax-highlighting: ## Install 'zsh-syntax-highlighting'.
	$(call install-zsh-syntax-highlighting-for-os,$(OS))

setup-zsh-syntax-highlighting: ## Install 'zsh-syntax-highlighting' (no configuration needed).
setup-zsh-syntax-highlighting: install-zsh-syntax-highlighting

# ---------- fzf ----------

define install-fzf-linux
	pacman -S fzf
endef

define install-fzf-darwin
	brew install fzf
endef

define install-fzf-for-os
	$(call install-fzf-$1)
endef

install-fzf: ## Install 'fzf'.
	$(call install-fzf-for-os,$(OS))

setup-fzf: ## Install 'fzf' (no configuration needed).
setup-fzf: install-fzf

# ---------- bash ----------

define install-bash-linux
	pacman -S bash
endef

define install-bash-darwin
	brew install bash
endef

define install-bash-for-os
	$(call install-bash-$1)
endef

install-bash: ## Install 'bash'.
	$(call install-bash-for-os,$(OS))

setup-bash: ## Install 'bash' (no configuration needed).
setup-bash: install-bash

# ---------- docker ----------

define install-docker-linux
	pacman -S docker docker-compose
endef

define install-docker-darwin
	brew install docker
endef

define install-docker-for-os
	$(call install-docker-$1)
endef

install-docker: ## Install 'docker'.
	$(call install-docker-for-os,$(OS))

setup-docker: ## Install 'docker' (no configuration needed).
setup-docker: install-docker

# ----------------------

.PHONY: clean
clean: ## Removes generated files and folders, resetting this repository back to its initial clone state.
	rm -rf dist

.PHONY: help
help: ## Prints this help page.
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
