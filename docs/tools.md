# Tool Inventory & Gap Analysis

Complete breakdown of every tool, CLI, plugin, and binary used in this dotfiles repo — plus identified gaps.

---

## Package Managers

| Tool | Platform | Purpose |
|------|----------|---------|
| [Homebrew](https://brew.sh) | macOS | Primary install mechanism for all Darwin targets |
| [pacman](https://wiki.archlinux.org/title/pacman) | Arch Linux | Linux install fallback |

---

## Shell

| Tool | Purpose |
|------|---------|
| [zsh](https://www.zsh.org) | Primary interactive shell |
| [bash](https://www.gnu.org/software/bash/) | All scripts |
| [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Syntax colouring on the command line |
| [starship](https://starship.rs) | Cross-shell prompt with git/language context |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy finder — completion, worktree picker, tmux session switcher |

---

## Terminal Emulators

| Tool | Platform | Purpose |
|------|----------|---------|
| [WezTerm](https://wezfurlong.org/wezterm/) | Both | Primary terminal — GPU-accelerated, FiraCode Nerd Font + Dracula |
| [iTerm2](https://iterm2.com) | macOS | Secondary terminal, DynamicProfiles config |

---

## Editors

| Tool | Purpose |
|------|---------|
| [Neovim](https://neovim.io) | Primary editor — full LSP/DAP/formatter/linter stack |
| [VS Code](https://code.visualstudio.com) | Secondary — aliased as `dotfiles` opener on macOS |

---

## Neovim — Core Framework

| Tool | Purpose |
|------|---------|
| [lazy.nvim](https://github.com/folke/lazy.nvim) | Plugin manager |
| [NvChad v2.5](https://github.com/NvChad/NvChad) | Config framework (base46 themes, UI, volt, menu, minty) |

---

## Neovim — LSP Infrastructure

| Tool | Purpose |
|------|---------|
| [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | LSP configuration |
| [mason.nvim](https://github.com/williamboman/mason.nvim) | In-editor tool installer |
| [mason-lspconfig](https://github.com/williamboman/mason-lspconfig.nvim) | Mason ↔ lspconfig bridge |
| [mason-tool-installer](https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim) | Auto-installs all tools on startup |
| [schemastore.nvim](https://github.com/b0o/schemastore.nvim) | JSON/YAML schemas for jsonls + yamlls |
| [lsp_signature.nvim](https://github.com/ray-x/lsp_signature.nvim) | Function signature hints while typing |
| [inlay-hints.nvim](https://github.com/MysticalDevil/inlay-hints.nvim) | Inline LSP inlay hints |

---

## Neovim — Language Servers

| Server | Language | Notes |
|--------|----------|-------|
| bashls | Bash/Shell | |
| ansiblels | Ansible | |
| jdtls | Java | Per-project workspace cache |
| gopls | Go | |
| golangci-lint-langserver | Go | Meta-linting via LSP |
| clangd | C/C++ | |
| omnisharp | C# | Roslyn analysers enabled |
| lua_ls | Lua | |
| html | HTML | |
| cssls | CSS | |
| ts_ls | TypeScript/JavaScript | |
| eslint | ESLint-as-LSP | Auto-fixes on save |
| pyright | Python | |
| powershell_es | PowerShell | |
| rust_analyzer | Rust | |
| dockerls | Dockerfile | |
| jsonls | JSON | |
| yamlls | YAML | |
| marksman | Markdown | |
| terraformls | Terraform | |
| sqlls | SQL | |
| taplo | TOML | |
| groovyls | Groovy/Gradle | Skipped if not installed |

---

## Neovim — Formatters (conform.nvim)

| Tool | Language(s) |
|------|------------|
| [shfmt](https://github.com/mvdan/sh) | Shell |
| [google-java-format](https://github.com/google/google-java-format) | Java |
| [goimports-reviser](https://github.com/incu6us/goimports-reviser) | Go imports |
| [golines](https://github.com/segmentio/golines) | Go long-line breaking |
| [gofmt](https://pkg.go.dev/cmd/gofmt) | Go |
| [csharpier](https://csharpier.com) | C# |
| [stylua](https://github.com/JohnnyMorganz/StyLua) | Lua |
| [prettier](https://prettier.io) | JS/TS/CSS/HTML/JSON/YAML/Markdown |
| [sql-formatter](https://github.com/sql-formatter-org/sql-formatter) | SQL |
| [rustfmt](https://github.com/rust-lang/rustfmt) | Rust |
| [terraform_fmt](https://developer.hashicorp.com/terraform/cli/commands/fmt) | Terraform |
| [ansible-lint](https://ansible-lint.readthedocs.io) | Ansible |
| [ruff](https://docs.astral.sh/ruff/) | Python |

---

## Neovim — Linters (nvim-lint)

| Tool | Language(s) |
|------|------------|
| [shellcheck](https://www.shellcheck.net) | Shell |
| [ansible-lint](https://ansible-lint.readthedocs.io) | Ansible |
| [golangci-lint](https://golangci-lint.run) | Go |
| [checkstyle](https://checkstyle.org) | Java |
| [cpplint](https://github.com/cpplint/cpplint) | C++ |
| [mypy](https://mypy.readthedocs.io) | Python |
| [hadolint](https://github.com/hadolint/hadolint) | Dockerfile |
| [markdownlint](https://github.com/DavidAnson/markdownlint) | Markdown |
| [tflint](https://github.com/terraform-linters/tflint) | Terraform |
| [sqlfluff](https://sqlfluff.com) | SQL |
| [actionlint](https://github.com/rhysd/actionlint) | GitHub Actions |

---

## Neovim — Debug Adapters (nvim-dap)

| Tool | Language(s) |
|------|------------|
| [debugpy](https://github.com/microsoft/debugpy) | Python |
| [codelldb](https://github.com/vadimcn/codelldb) | C/C++/Rust |
| [cpptools](https://github.com/microsoft/vscode-cpptools) | C/C++ |
| [netcoredbg](https://github.com/Samsung/netcoredbg) | C# |
| [js-debug-adapter](https://github.com/microsoft/vscode-js-debug) | JS/TypeScript |
| [java-debug-adapter](https://github.com/microsoft/java-debug) | Java |
| [java-test](https://github.com/microsoft/vscode-java-test) | Java |

**DAP plugins:** [nvim-dap](https://github.com/mfussenegger/nvim-dap), [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui), [nvim-dap-virtual-text](https://github.com/theHamsta/nvim-dap-virtual-text), [nvim-nio](https://github.com/nvim-neotest/nvim-nio)

---

## Neovim — Completion

| Tool | Purpose |
|------|---------|
| [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) | Completion engine |
| cmp-nvim-lsp, cmp-buffer, cmp-async-path, cmp-nvim-lua | Completion sources |
| [LuaSnip](https://github.com/L3MON4D3/LuaSnip) + [friendly-snippets](https://github.com/rafamadriz/friendly-snippets) | Snippet engine + community library |
| [copilot.lua](https://github.com/zbirenbaum/copilot.lua) + [copilot-cmp](https://github.com/zbirenbaum/copilot-cmp) | GitHub Copilot inline completion |

---

## Neovim — Navigation & UI

| Tool | Purpose |
|------|---------|
| [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) + [telescope-fzf-native](https://github.com/nvim-telescope/telescope-fzf-native.nvim) | Fuzzy finder for files, buffers, LSP symbols |
| [nvim-tree](https://github.com/nvim-tree/nvim-tree.lua) | File explorer sidebar |
| [nvim-spectre](https://github.com/nvim-pack/nvim-spectre) | Project-wide find & replace |
| [which-key.nvim](https://github.com/folke/which-key.nvim) | Keybind popup on `<leader>` |
| [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Inline git hunks, blame, staging |
| [diffview.nvim](https://github.com/sindrets/diffview.nvim) | Full-screen git diff/merge UI |
| [todo-comments.nvim](https://github.com/folke/todo-comments.nvim) | Highlights TODO/FIXME/HACK/NOTE |
| [indent-blankline.nvim](https://github.com/lukas-reineke/indent-blankline.nvim) | Indentation guides |
| [nvim-autopairs](https://github.com/windwp/nvim-autopairs) | Auto-closes brackets/quotes |
| [better-escape.nvim](https://github.com/max397574/better-escape.nvim) | `jk` → `<Esc>` |
| [sort.nvim](https://github.com/sQVe/sort.nvim) | Sort lines/selections |
| [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) | Syntax parsing (23 grammars) |
| [nvim-web-devicons](https://github.com/nvim-tree/nvim-web-devicons) | File type icons |

---

## Neovim — Language-Specific

| Tool | Purpose |
|------|---------|
| [gopher.nvim](https://github.com/olexsmir/gopher.nvim) | Go struct tags, test generation |
| [peek.nvim](https://github.com/toppair/peek.nvim) | Markdown preview in browser (requires Deno) |
| [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | Hosts OpenCode in a vertical split (`<leader>oc`) |

---

## AI Tools

| Tool | Purpose |
|------|---------|
| [Claude Code](https://claude.ai/code) (`claude`) | Primary AI coding assistant — worktree-aware launcher |
| [opencode](https://opencode.ai) | Secondary AI assistant — runs in Neovim split |
| [GitHub Copilot](https://github.com/features/copilot) | Inline completion fallback via copilot-cmp |

---

## Tmux

| Tool | Purpose |
|------|---------|
| [tmux](https://github.com/tmux/tmux) | Terminal multiplexer — 7 named session layouts |
| [TPM](https://github.com/tmux-plugins/tpm) | Plugin manager |
| [dracula/tmux](https://github.com/dracula/tmux) | Dracula statusline theme |
| [tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) | Save/restore sessions across reboots |
| [tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) | Auto-saves every 15 mins, auto-restores on startup |

---

## Version Control & GitHub

| Tool | Purpose |
|------|---------|
| [git](https://git-scm.com) | VCS — extensively wrapped with custom functions in aliases |
| [gh](https://cli.github.com) | GitHub CLI for auth, credentials, PRs, identity switching |

---

## Cloud / Infrastructure

| Tool | Purpose |
|------|---------|
| [awscli](https://aws.amazon.com/cli/) | SSO login, ECR auth, SSM, CloudFront, STS |
| [terraform](https://www.terraform.io) | IaC — formatter invoked directly by conform |
| [tailscale](https://tailscale.com) | VPN, DNS nameserver queries |
| [docker](https://www.docker.com) + docker-compose | Container runtime |

---

## Language Runtimes

| Tool | Purpose |
|------|---------|
| [Go](https://go.dev) | Primary language — GOPATH configured |
| [Deno](https://deno.land) | Required by peek.nvim Markdown preview |
| Python 3 | Ansible LSP + debugpy |
| Java | Required by jdtls + groovyls |
| [Rust](https://www.rust-lang.org) / rustup | rustfmt formatter |

---

## Utility CLIs

| Tool | Purpose |
|------|---------|
| [jq](https://jqlang.github.io/jq/) | JSON processing |
| [curl](https://curl.se) | HTTP downloads in Makefile installers |
| [rclone](https://rclone.org) | Syncs Obsidian vault to Google Drive |
| [act](https://github.com/nektos/act) | Runs GitHub Actions locally in Docker |
| [imgcat](https://iterm2.com/documentation-images.html) | Displays images inline in iTerm2 |
| [shellcheck](https://www.shellcheck.net) | Shell linting (CI + Mason) |

---

## Linux Desktop (Arch Linux only)

| Tool | Purpose |
|------|---------|
| [i3](https://i3wm.org) | Tiling window manager |
| [i3lock](https://i3wm.org/i3lock/) | Screen locker with blur + clock |
| [polybar](https://polybar.github.io) | Status bar |
| [picom](https://github.com/yshui/picom) | X11 compositor |
| [xautolock](https://github.com/l0b0/xautolock) | Auto-lock after idle timeout |
| [pulsemixer](https://github.com/GeorgeFilipkin/pulsemixer) | TUI audio mixer (PipeWire) |
| [scrot](https://github.com/dreamer/scrot) | Screenshots |
| [tty-clock](https://github.com/xorg62/tty-clock) | Terminal clock |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info (aliased as `neofetch`) |
| [pcmanfm](https://wiki.lxde.org/en/PCManFM) | GUI file manager |

---

## Fonts

| Font | Where Used |
|------|-----------|
| FiraCode Nerd Font Mono | WezTerm |
| FiraCode Nerd Font | iTerm2, i3lock greeter |
| Font Awesome 6 | Linux polybar icons |
| noto-fonts-emoji | Linux emoji support |

---

## Gap Analysis

### No test runner integration

There is no test runner in Neovim at all. Tests across Go (`go test`), Python (`pytest`), TypeScript (`jest`/`vitest`), and Java (JUnit) have to be run from a terminal. `gopher.nvim` provides some Go helpers but not test running.

**Fix:** Add [neotest](https://github.com/nvim-neotest/neotest) with adapters: [neotest-go](https://github.com/nvim-neotest/neotest-go), [neotest-python](https://github.com/nvim-neotest/neotest-python), [neotest-jest](https://github.com/haydenmeade/neotest-jest).

---

### Previously fixed

| Gap | Fix applied |
|-----|-------------|
| Go debugger missing | `delve` added to mason.lua; `nvim-dap-go` plugin added |
| C/C++ formatter not wired | `c`/`cpp` entries added to conform.lua |
| PowerShell no formatter/linter | `psscriptanalyzer` wired in mason.lua and lint.lua |
| Rust using `cargo check` not clippy | `rust_analyzer` config updated with `check.command = "clippy"` |
| Generic YAML no linter | `yamllint` added to mason.lua and lint.lua |
| `act` aliased but not installed | `install-act` added to Makefile |
| `terraform` CLI not in Makefile | `install-terraform` added to Makefile |
| `ansible-lint` in Makefile | Removed — Mason owns it |
| `kubectl` absent | `install-kubectl` added to Makefile; `k` alias added |
| `ripgrep` not tracked | `install-ripgrep` added to Makefile |
