# Dotfiles — install and configure tools on macOS and Linux.


SHELL = /bin/bash

# Detected OS: darwin or linux.
OS := $(shell uname | tr '[:upper:]' '[:lower:]')

# Package manager per OS.
PKG_DARWIN  = brew install
PKG_LINUX   = sudo pacman -S --noconfirm

# i3 desktop packages (Arch and Manjaro). Manjaro's 'manjaro-i3-settings' used
# to pull i3, picom, dunst etc. in implicitly; list them so plain Arch gets them.
DESKTOP_PKGS = i3-wm picom dunst dmenu polybar rofi scrot xclip xorg-xrdb \
	xdg-user-dirs lightdm lightdm-slick-greeter \
	volumeicon pavucontrol arandr polkit-gnome pcmanfm ranger btop pulseaudio xorg-xrandr \
	ttf-firacode-nerd noto-fonts-emoji adwaita-cursors papirus-icon-theme
# AUR on Arch (some, like clipit and lightdm-settings, are only in Manjaro's repos).
DESKTOP_AUR_PKGS = i3lock-color xautolock clipit lightdm-settings

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

# Symlink one repo file to a destination: $(call link-file,<repo path>,<dest>).
# Never overwrites: links if <dest> is missing, or is a real file identical to
# the repo copy; otherwise leaves it alone and says so.
define link-file
	@mkdir -p "$$(dirname "$2")"; \
	if [ -L "$2" ] && [ "$$(readlink "$2")" = "$(PWD)/$1" ]; then \
		echo "  $2 already linked"; \
	elif [ ! -e "$2" ] && [ ! -L "$2" ]; then \
		ln -s "$(PWD)/$1" "$2" && echo "  linked $2"; \
	elif [ -f "$2" ] && [ ! -L "$2" ] && cmp -s "$2" "$(PWD)/$1"; then \
		ln -sf "$(PWD)/$1" "$2" && echo "  linked $2 (was identical)"; \
	else \
		echo "  $2 differs from the repo copy — skipped (see: diff $2 $(PWD)/$1)"; \
	fi
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
	install-desktop \
	install-wezterm \
	install-github-cli \
	install-fonts \
	install-tmux \
	install-terraform \
	install-kubectl \
	install-ripgrep \
	install-act
# NOTE: deno and ansible-lint are intentionally omitted here — Mason installs
# them automatically when Neovim first opens (they're in mason.lua ensure_installed).
# Mason's bin dir (~/.local/share/nvim/mason/bin) is on PATH via .zshenv.

.PHONY: configure
configure: ## Configure ALL tools.
configure: \
	configure-git \
	configure-github-cli \
	configure-ssh \
	configure-awscli \
	configure-zsh \
	configure-starship \
	configure-neovim \
	configure-wezterm \
	configure-btop \
	configure-polybar \
	configure-picom \
	configure-i3 \
	configure-i3lock \
	configure-system \
	configure-desktop \
	configure-iterm2 \
	configure-bin \
	configure-common \
	configure-dotfiles-d \
	configure-tmux \
	configure-vscode

.PHONY: setup
setup: ## Install AND configure ALL tools.
setup: \
	create-directories \
	setup-go \
	setup-git \
	setup-github-cli \
	setup-ssh \
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
	setup-btop \
	setup-picom \
	setup-pulsemixer \
	setup-brightnessctl \
	setup-fonts \
	configure-bin \
	setup-common \
	configure-dotfiles-d \
	setup-tmux \
	setup-i3 \
	setup-i3lock \
	setup-system \
	setup-desktop \
	setup-iterm2 \
	setup-vscode \
	install-terraform \
	install-kubectl \
	install-ripgrep \
	install-act
# NOTE: deno and ansible-lint are intentionally omitted here — Mason installs
# them automatically when Neovim first opens (they're in mason.lua ensure_installed).
# Mason's bin dir (~/.local/share/nvim/mason/bin) is on PATH via .zshenv.

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
	$(call pkg,go)

setup-go: install-go
# NOTE: go is also configured in .zshenv.

# ---------------------------------------------------------------
# git (assumed installed)
# ---------------------------------------------------------------

.PHONY: configure-git setup-git
configure-git: ## Configure 'git'.
configure-git: .config/git
	$(call cfg-home,.config/git)
	@if [ ! -f $(HOME)/.gitconfig-work ]; then \
		echo ""; \
		echo "  ⚠  ~/.gitconfig-work not found."; \
		echo "     Copy the example and fill in your details:"; \
		echo "     cp ~/.gitconfig-work.example ~/.gitconfig-work"; \
		echo ""; \
	fi

setup-git: configure-git

# ---------------------------------------------------------------
# github-cli
# ---------------------------------------------------------------

.PHONY: install-github-cli configure-github-cli setup-github-cli
install-github-cli: ## Install 'github-cli'.
	$(call pkg,gh,github-cli)

configure-github-cli: ## Configure 'github-cli'.
configure-github-cli: .config/gh
	mkdir -p $(HOME)/.config/gh
	ln -sf $(PWD)/.config/gh/config.yml $(HOME)/.config/gh/config.yml
	gh auth status &>/dev/null || gh auth login
	gh auth setup-git

setup-github-cli: install-github-cli configure-github-cli

# ---------------------------------------------------------------
# ssh (assumed installed)
# ---------------------------------------------------------------

.PHONY: configure-ssh setup-ssh
configure-ssh: ## Configure 'ssh'.
configure-ssh: .config/ssh
	mkdir -p $(HOME)/.ssh
	ln -sf $(PWD)/.config/ssh/config $(HOME)/.ssh/config

setup-ssh: configure-ssh

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
	unzip -o dist/awscli/awscli.zip -d dist/awscli/
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
	dist/starship/install.sh -y
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
# brightnessctl (Linux only — screen brightness; its udev rule grants the 'video' group write access)
# ---------------------------------------------------------------

.PHONY: install-brightnessctl setup-brightnessctl
install-brightnessctl: ## Install 'brightnessctl' and add the user to 'video' (Linux only).
ifeq ($(OS),linux)
	sudo pacman -S --noconfirm brightnessctl
	sudo usermod -aG video $(USER)
else
	@echo "Skipping brightnessctl installation (Linux only)."
endif

setup-brightnessctl: install-brightnessctl

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
# i3lock (Linux only)
# ---------------------------------------------------------------

.PHONY: configure-i3lock setup-i3lock
configure-i3lock: ## Configure 'i3lock' PAM auth (Linux only).
ifeq ($(OS),linux)
	@if [[ ! -f /etc/pam.d/i3lock ]]; then \
		echo "auth include login" | sudo tee /etc/pam.d/i3lock > /dev/null; \
		echo "  created /etc/pam.d/i3lock"; \
	else \
		echo "  /etc/pam.d/i3lock already exists — skipping"; \
	fi
else
configure-i3lock:
	@echo "Skipping i3lock configuration (Linux only)."
endif

setup-i3lock: configure-i3lock

# ---------------------------------------------------------------
# system (Linux only — files that live under /etc, mirrored in system/)
# ---------------------------------------------------------------

.PHONY: configure-system setup-system
configure-system: ## Install /etc config from system/ (Linux only).
ifeq ($(OS),linux)
	@cd system && for f in $$(find etc -type f); do \
		if cmp -s "$$f" "/$$f"; then \
			echo "  /$$f unchanged"; \
		else \
			diff -u "/$$f" "$$f" 2>/dev/null || true; \
			sudo install -Dm644 "$$f" "/$$f" \
				&& echo "  installed /$$f" \
				|| exit 1; \
		fi; \
	done
else
configure-system:
	@echo "Skipping system configuration (Linux only)."
endif

setup-system: configure-system

# ---------------------------------------------------------------
# desktop (Linux only — dunst, rofi, gtk, qt5ct, Kvantum, i3-scrot)
# ---------------------------------------------------------------

.PHONY: configure-desktop setup-desktop
configure-desktop: ## Link dunst/rofi/gtk/qt5ct/Kvantum/i3-scrot config (Linux only).
ifeq ($(OS),linux)
	$(call link-file,.config/dunst/dunstrc,$(HOME)/.config/dunst/dunstrc)
	$(call link-file,.config/dunst/org.freedesktop.Notifications.service,$(HOME)/.local/share/dbus-1/services/org.freedesktop.Notifications.service)
	$(call link-file,.config/dunst/xfce4-notifyd.desktop,$(HOME)/.config/autostart/xfce4-notifyd.desktop)
	$(call link-file,.config/rofi/config.rasi,$(HOME)/.config/rofi/config.rasi)
	$(call link-file,.config/gtk-3.0/gtk.css,$(HOME)/.config/gtk-3.0/gtk.css)
	$(call link-file,.config/gtk-3.0/settings.ini,$(HOME)/.config/gtk-3.0/settings.ini)
	$(call link-file,.config/qt5ct/qt5ct.conf,$(HOME)/.config/qt5ct/qt5ct.conf)
	$(call link-file,.config/Kvantum/kvantum.kvconfig,$(HOME)/.config/Kvantum/kvantum.kvconfig)
	$(call link-file,.config/i3-scrot.conf,$(HOME)/.config/i3-scrot.conf)
else
configure-desktop:
	@echo "Skipping desktop configuration (Linux only)."
endif

.PHONY: install-desktop install-desktop-aur install-yay configure-bin
install-desktop: ## Install the i3 desktop packages (Linux only; Arch + Manjaro).
ifeq ($(OS),linux)
	sudo pacman -S --needed --noconfirm $(DESKTOP_PKGS)
	@$(MAKE) --no-print-directory install-desktop-aur
else
	@echo "Skipping desktop installation (Linux only)."
endif

install-desktop-aur: ## Install the desktop's AUR packages via yay (Linux only).
ifeq ($(OS),linux)
	@command -v yay >/dev/null 2>&1 || $(MAKE) --no-print-directory install-yay
	yay -S --needed --noconfirm $(DESKTOP_AUR_PKGS)
else
	@echo "Skipping desktop AUR installation (Linux only)."
endif

# nitrogen (wallpaper picker) is opt-in: it is no longer in Arch's repos, and its
# AUR build compiles gtk2 and gtkmm from source (~30 min). Not part of install-desktop.
.PHONY: install-nitrogen
install-nitrogen: ## Install 'nitrogen' via the AUR (slow: builds gtk2 + gtkmm).
ifeq ($(OS),linux)
	@command -v yay >/dev/null 2>&1 || $(MAKE) --no-print-directory install-yay
	yay -S --needed --noconfirm nitrogen
else
	@echo "Skipping nitrogen installation (Linux only)."
endif

install-yay: ## Build and install the 'yay' AUR helper (Linux only).
ifeq ($(OS),linux)
	sudo pacman -S --needed --noconfirm base-devel git
	rm -rf dist/yay-bin
	@mkdir -p dist
	git clone https://aur.archlinux.org/yay-bin.git dist/yay-bin
	cd dist/yay-bin && makepkg -si --noconfirm
else
	@echo "Skipping yay installation (Linux only)."
endif

# Link ~/bin to the repo's bin dir if ~/bin doesn't exist yet. The i3 config calls
# scripts as ~/bin/system/<name>.sh, so a fresh machine needs this link.
configure-bin: ## Link ~/bin to the repo's bin directory (if absent).
	@if [ -e $(HOME)/bin ] || [ -L $(HOME)/bin ]; then \
		echo "  ~/bin already exists — leaving it alone"; \
	else \
		ln -s $(PWD)/.config/common/bin $(HOME)/bin && echo "  linked ~/bin"; \
	fi

setup-desktop: install-desktop configure-desktop

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
	brew install --cask docker
else
	sudo pacman -S --noconfirm docker docker-compose
endif

setup-docker: install-docker

# ---------------------------------------------------------------
# iterm2 (macOS only)
# ---------------------------------------------------------------

.PHONY: configure-iterm2 setup-iterm2
configure-iterm2: ## Configure 'iTerm2' profile (macOS only).
ifeq ($(OS),darwin)
	mkdir -p "$(HOME)/Library/Application Support/iTerm2/DynamicProfiles"
	ln -sfn $(PWD)/.config/iterm2/Default.json \
		"$(HOME)/Library/Application Support/iTerm2/DynamicProfiles/Default.json"
	@mkdir -p $(HOME)/bin
	@if [ -f "/Applications/iTerm.app/Contents/Resources/utilities/imgcat" ]; then \
		ln -sf /Applications/iTerm.app/Contents/Resources/utilities/imgcat $(HOME)/bin/imgcat; \
		echo "  linked imgcat -> ~/bin/imgcat"; \
	else \
		echo "  imgcat not found — is iTerm2 installed?"; \
	fi
else
	@echo "Skipping iTerm2 configuration (macOS only)."
endif

setup-iterm2: ## Install font and configure iTerm2 (macOS only).
setup-iterm2: configure-iterm2
	@[ "$(OS)" = "darwin" ] && brew install --cask font-fira-code-nerd-font || true

# ---------------------------------------------------------------
# vscode (macOS only)
# ---------------------------------------------------------------

.PHONY: configure-vscode setup-vscode
configure-vscode: ## Configure VS Code settings and extensions (macOS only).
ifeq ($(OS),darwin)
configure-vscode: .config/vscode
	@mkdir -p "$(HOME)/Library/Application Support/Code/User"
	@ln -sf $(PWD)/.config/vscode/settings.json \
		"$(HOME)/Library/Application Support/Code/User/settings.json"
	@ln -sf $(PWD)/.config/vscode/extensions.json \
		"$(HOME)/Library/Application Support/Code/User/extensions.json"
	@echo "  linked VS Code settings.json and extensions.json"
	@if command -v code >/dev/null 2>&1; then \
		echo "  installing recommended extensions..."; \
		jq -r '.recommendations[]' $(PWD)/.config/vscode/extensions.json 2>/dev/null | \
			grep -v '^\s*//' | \
			xargs -I{} code --install-extension {} --force; \
	else \
		echo "  VS Code CLI (code) not found — skipping extension install"; \
	fi
else
configure-vscode:
	@echo "Skipping VS Code configuration (macOS only)."
endif

setup-vscode: configure-vscode

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
# terraform
# ---------------------------------------------------------------

.PHONY: install-terraform
install-terraform: ## Install 'terraform'.
ifeq ($(OS),darwin)
	brew install hashicorp/tap/terraform
else
	sudo pacman -S --noconfirm terraform
endif

# ---------------------------------------------------------------
# kubectl
# ---------------------------------------------------------------

.PHONY: install-kubectl
install-kubectl: ## Install 'kubectl'.
	$(call pkg,kubernetes-cli,kubectl)

# ---------------------------------------------------------------
# ripgrep
# ---------------------------------------------------------------

.PHONY: install-ripgrep
install-ripgrep: ## Install 'ripgrep'.
	$(call pkg,ripgrep)

# ---------------------------------------------------------------
# act
# ---------------------------------------------------------------

.PHONY: install-act
install-act: ## Install 'act' (run GitHub Actions locally).
ifeq ($(OS),darwin)
	brew install act
else
	@echo "Install act manually on Linux: https://github.com/nektos/act"
endif

# ---------------------------------------------------------------
# rclone (used by obsidian-upload-to-google-drive script)
# ---------------------------------------------------------------

.PHONY: install-rclone
install-rclone: ## Install 'rclone'.
	$(call pkg,rclone)

# ---------------------------------------------------------------
# xautolock (Linux only — drives lock-screen idle timer)
# ---------------------------------------------------------------

.PHONY: install-xautolock
install-xautolock: ## Install 'xautolock' (Linux only).
ifeq ($(OS),linux)
	sudo pacman -S --noconfirm xautolock
else
	@echo "Skipping xautolock installation (Linux only)."
endif

# ansible-lint — installed by Mason (see .config/neovim/lua/configs/mason.lua).

# ---------------------------------------------------------------
# common
# ---------------------------------------------------------------

.PHONY: configure-common setup-common
configure-common: ## Configure common shell files.
configure-common: .config/common
	$(call cfg-home,.config/common)
	@mkdir -p $(HOME)/bin
	@for f in $$(find $(PWD)/.config/common/bin -type f -name "*.sh" ! -path "*/.tests/*"); do \
		rel=$${f#$(PWD)/.config/common/bin/}; \
		dir=$$(dirname $$rel); \
		dest=$(HOME)/bin/$$([ "$$dir" = "." ] && echo "" || echo "$$dir/")$$(basename $$rel .sh); \
		mkdir -p $$(dirname $$dest); \
		ln -sf $$f $$dest; \
		echo "  linked $$f -> $$dest"; \
	done

setup-common: configure-common

.PHONY: configure-dotfiles-d
configure-dotfiles-d: ## Symlink versioned shell files into ~/.dotfiles.d/.
	@mkdir -p $(HOME)/.dotfiles.d
	@ln -sf $(PWD)/.config/common/aliases $(HOME)/.dotfiles.d/aliases && echo "  linked aliases"
	@ln -sf $(PWD)/.config/common/.ai-aliases $(HOME)/.dotfiles.d/ai-aliases && echo "  linked ai-aliases"

.PHONY: configure-npmrc
configure-npmrc: ## Symlink .npmrc into home directory.
	@ln -sf $(PWD)/.config/common/.npmrc $(HOME)/.npmrc && echo "  linked .npmrc"

.PHONY: test-ai-aliases
test-ai-aliases: ## Test .ai-aliases shell functions.
	@zsh $(PWD)/.config/common/bin/.tests/test-ai-aliases.sh

# ---------------------------------------------------------------
# Housekeeping
# ---------------------------------------------------------------

.PHONY: clean
clean: ## Remove generated files.
	rm -rf dist

# ── tmux ──────────────────────────────────────────────────────────────────────

.PHONY: install-tmux configure-tmux setup-tmux test-tmux
install-tmux: ## Install 'tmux'.
	$(call pkg,tmux)

configure-tmux: ## Configure 'tmux'.
configure-tmux: .config/tmux $(HOME)/.config
	$(call cfg,.config/tmux)
	ln -sfn $(PWD)/.config/tmux $(HOME)/.tmux

setup-tmux: install-tmux configure-tmux

.PHONY: test-arch
test-arch: ## Test the dotfiles in a clean Arch Linux container (needs docker; screenshot in dist/arch-test/).
	docker build -q -t dotfiles-arch-test -f test/arch/Dockerfile test/arch
	@mkdir -p dist/arch-test
	docker run --rm -v "$(PWD):/src:ro" -v "$(PWD)/dist/arch-test:/out" \
		dotfiles-arch-test /src/test/arch/run-tests.sh

test-tmux: ## Test tmux session functions (pane counts + idempotency).
	@bash $(PWD)/.config/common/bin/.tests/test-tmux.sh


# ---------------------------------------------------------------

.PHONY: help
help: ## Print this help page.
	@echo "Available targets:"
	@awk '\
		/^[a-zA-Z\-\\_0-9%\/$$]+:/ { \
			target = $$1; \
			gsub("\\$$1", "%", target); \
			nb = sub(/^## /, "", helpMessage); \
			if (nb == 0) { \
				helpMessage = $$0; \
				nb = sub(/^[^:]*:.* ## /, "", helpMessage); \
			} \
			if (nb) printf "\033[33m%-35s\033[0m %s\n", target, helpMessage; \
		} { helpMessage = $$0 } \
	' $(MAKEFILE_LIST)
