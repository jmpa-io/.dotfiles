
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
	install-starship \
	install-polybar \
	install-jq

configure: ## ** Configures ALL tools available for the operating system of this machine.
configure: \
	configure-zsh \
	configure-starship

setup: ## ** Installs AND configures ALL tools available for the operating system of this machine.
setup: \
	setup-zsh \
	setup-starship

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

# ---------- git ----------

# NOTE: git is assumed installed.

configure-git: ## Configure 'git'.
configure-git: .config/git
	for file in $(shell find .config/git -mindepth 1 -type f); do \
		ln -sf $(PWD)/$$file $(HOME)/; \
	done

setup-git: ## Install AND configure 'git'.
setup-git: install-git configure-git

# ----------- github-cli -----------

define install-github-cli-linux
	pacman -S github-cli
endef

define install-github-cli-darwin
	# TODO: is this the right command to install the gh cli on Darwin?
	# brew install gh
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

# ----------- awscli ----------

define install-awscli-linux
	curl -sSLo "dist/awscli/awscli.zip" "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"
	unzip "dist/awscli/awscli.zip" -d "dist/awscli/"
	dist/awscli/aws/install -i /usr/local/aws-cli -b /usr/local/bin --update
endef

define install-awscli-darwin
	curl -sSLo "dist/awscli/AWSCLIV2.pkg" "https://awscli.amazonaws.com/AWSCLIV2.pkg"
	installer -pkg "dist/awscli/AWSCLIV2.pkg" -target
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

# ---------- neovim ----------

define install-neovim-linux
	pacman -S neovim
endef

define install-neovim-darwin
	# TODO: is this the right way to install neovim on Darwin?
	# brew install neovim
endef

define install-neovim-for-os
	$(call install-neovim-$1)
endef

install-neovim: ## Install 'neovim'.
	$(call install-neovim-for-os,$(OS))

configure-neovim: ## Configure 'neovim'.
configure-neovim: .config/neovim $(HOME)/.config
	ln -sf $(PWD)/$</ $(HOME)/.config/nvim

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

# ---------- i3 ----------

# NOTE: i3 is assumed installed.

configure-i3: ## Configure 'i3'.
configure-i3: .config/i3
	ln -sf $(PWD)/$< $(HOME)/.i3

# ---------- common ----------

configure-common: ## Configure common files used across multiple tools.
configure-common: .config/common
	for file in $(shell find .config/common -mindepth 1 -type f); do \
		ln -sf $(PWD)/$$file $(HOME)/; \
	done

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
