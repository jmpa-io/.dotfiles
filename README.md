<p align="center">
  <img src="./docs/logo.png">
</p>

# `.dotfiles`

```diff
+ Here are my dotfiles.
```

## New PC?

1. Using a terminal, run:
```sh
mkdir -p $HOME/.local/bin
```

2. [Install the `gh` cli](https://cli.github.com/).

3. [Setup the `gh` cli as a credential helper](https://cli.github.com/manual/gh_auth_setup-git).

4. Auth to your AWS account:
```sh
aws sso login --profile <your-profile>
# or if using SSO via the browser:
aws configure sso
```

5. Clone this repo.

6. Using a terminal, run:
```sh
cd /path/to/.dotfiles
make setup
```

7. You should be good to go! 🎉

## Tools

See [docs/tools.md](docs/tools.md) for a full inventory of every tool, CLI, plugin, and binary used in this repo — including a gap analysis of what's missing.

## Standards

See [docs/standards.md](docs/standards.md) for the design principles and conventions used in this repo — the two-layer install model, shell file responsibilities, Makefile conventions, and git workflow.

## Git identity

This repo does not commit a name or email to `.gitconfig`. Set your identity locally on each machine:

```sh
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

For work machines, copy the example and fill in your details:

```sh
cp ~/.gitconfig-work.example ~/.gitconfig-work
```

This sets your work identity and pins git credentials to your work GitHub account for all CBA repos automatically — no manual account switching needed.

## Machine-local config (`~/.dotfiles.d/work`)

`~/.dotfiles.d/work` is a machine-local shell file sourced by `.zshenv` on every shell start (interactive and non-interactive). It holds secrets and environment-specific config that must not be committed:

- Proxy settings
- AWS profile and CA bundle
- API tokens (Portkey, Atlassian, Artifactory, SonarQube, AAP)
- GitHub token cache
- Go private module config
- Docker host

This file is not tracked in dotfiles. On a new machine, create it manually or copy it from a secure backup.
