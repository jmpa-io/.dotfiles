# Dotfiles — Standards

## What this repo is

Personal dotfiles for macOS (Apple Silicon) and Arch Linux. Sets up a machine
cleanly and reproducibly. Simplicity is the primary design goal — every tool
and layer should earn its place.

## Two-layer install model

**Makefile** owns system tools and apps — things that must exist before Neovim
opens, or that live outside the Neovim ecosystem entirely:
- Language runtimes: Go, Python, Java
- System apps: Neovim itself, WezTerm, iTerm2, tmux, Docker, zsh, fzf, starship
- CLIs Mason cannot package: awscli, gh, kubectl, ripgrep, act, terraform (the
  CLI — not the LSP), jq
- Linux desktop: i3, polybar, picom, pulsemixer, fonts

**Mason** owns everything editor-related — LSPs, formatters, linters, debuggers,
and any CLI it packages (deno, ansible-lint, shellcheck, prettier, etc).
Mason auto-installs all tools in `mason.lua ensure_installed` when Neovim
first opens. Mason's bin dir (`~/.local/share/nvim/mason/bin`) is on PATH via
`.zshenv` so these tools are available system-wide, not just inside Neovim.

**The rule:** if Mason can install it, Mason owns it. Do not add Makefile
targets for tools that are in `mason.lua ensure_installed`. Do not add Mason
entries for things that are system apps or runtimes.

## What does NOT belong here

- Runtime version management (mise, asdf, nvm) — solves a per-project problem,
  not a machine-setup problem. If a project needs a specific runtime version,
  that belongs in the project repo, not here.
- Per-project tooling or config.
- Secrets — `~/work` is machine-specific and never committed.

## Neovim submodule

The Neovim config lives at `.config/neovim` and is a git submodule pointing to
`https://github.com/jmpa-io/NvChad` (a fork of NvChad v2.5). Changes to
Neovim config must be committed inside the submodule first, then the parent
repo bumped. The submodule is on NvChad v2.5 — do not chase upstream versions
without a specific reason.

## Shell standards

- `.zshenv` — environment variables, PATH, exports. Sourced by every process
  including non-interactive ones (cron, SSH). Keep it fast and side-effect free.
  `~/work` is sourced here so secrets are available to all processes.
- `.zshrc` — interactive shell setup only (completions, plugins, prompt).
- `aliases` — sourced by `.zshrc`. Contains all aliases and shell functions.
  Uses zsh-specific syntax throughout. shellcheck disables are in place at the
  file level for known zsh-vs-bash differences.
- `~/work` — machine-specific secrets (PORTKEY_API_KEY, AWS_PROFILE, GOPRIVATE,
  CDPATH). Never committed. Never duplicated in dotfiles.

## Makefile conventions

- `$(call pkg, darwin-pkg, linux-pkg)` macro abstracts Homebrew vs pacman.
- `install-*` targets install a tool. `configure-*` targets symlink config.
  `setup-*` targets do both.
- `install`, `configure`, and `setup` are aggregate targets that run everything.
- Do not use `realpath --relative-to` — use pure shell string ops instead
  (`${var#prefix}`). The GNU version breaks on stock macOS.
- All new targets must be added to `.PHONY`.

## Git workflow

- Always work on a feature branch — never commit directly to main.
- The neovim submodule is a separate git repo — changes need two commits:
  one inside the submodule, then a bump commit in the parent repo.
- Conventional commits: `feat`, `fix`, `chore`, `docs`, `perf`, `refactor`.
