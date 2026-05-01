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

## Git identity

This repo does not commit a name or email to `.gitconfig`. Set your identity locally on each machine:

```sh
git config --global user.name "Your Name"
git config --global user.email "your@email.com"
```

For work machines, create `~/.gitconfig-work` instead — it will be picked up automatically for any repo inside `~/work/`:

```ini
[user]
  name = Your Work Name
  email = your.email@work.com
```
