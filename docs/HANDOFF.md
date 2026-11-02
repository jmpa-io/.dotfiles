# Handoff: lock screen + devbox work (for Claude to read later)

Last updated 2026-11-02. Nothing here has been pushed; no PRs, tags or releases. Commit locally only.

## Branch state

All three branches should be at the same commit (check with `git log --oneline -1` in each):

- `feat/install-yay-local-src`: `~/.dotfiles`
- `chore/repo-audit`: `~/go/src/github.com/jmpa-io/.dotfiles-audit`
- `feat/devbox-claude-test`: `~/go/src/github.com/jmpa-io/.dotfiles-devbox`

After committing on one, sync the others with `git merge --ff-only feat/install-yay-local-src`.
Open question: was `main` meant to be the merge target instead?

## Lock screen (`.config/common/bin/system/lock.sh`)

Done:
- Dracula style: ring, pink time, cyan date, green padlock above the clock, terminal-window info panel
  (user / locked / uptime) under the ring.
- Time is 12-hour with AM/PM. The timezone is shown on the `locked` row only, not on the date line.
- Wrong-password text is a plain "Wrong password" (the old "6 fails = 30s lockout" claim was false).
- `n/6` failed-attempt counter via the patched i3lock-color (`patches/i3lock-color-attempts-text.patch`;
  build steps in `docs/tools.md`). Falls back to the stock bare number when the binary is unpatched.
- Sizes scale with screen height (768px baseline) through `sc()` and `pct`.

Still to verify or do:
- Confirm the final scaled version renders correctly at 1366x768, 1920x1080 and 2560x1440 (check `docs` and
  screenshots in `~/devbox-proof/s-*`), then check the committed result matches.
- Unlock with the correct password on the latest version.
- The no-ImageMagick fallback path (plain `--blur 10`) on the latest version.
- Multi-monitor behaviour, the Caps Lock indicator (none is shown), and real hardware. Nothing has been tested
  outside the devbox container.
- Install the patched i3lock-color on the real machine; a `pacman` upgrade of `i3lock-color` overwrites it.
- Re-run `test/arch/devbox-check.sh`; it last passed before the circle redesign.

## Known issues / decisions

- **No lockout is enforced.** i3lock runs as the user, but `/run/faillock` is root-owned, so `pam_faillock`
  can't record failures. The counter only counts (it shows `7/6` after 7 tries). The repo documents
  `deny = 6`, `unlock_time = 30` in `system/etc/security/faillock.conf` (installed by `make configure-system`),
  which therefore has no effect on i3lock. Decide whether to fix this properly or leave it.
- Never use `i3lock --debug`: it logs the typed password to stderr.
- The ring's inside fill is opaque, so ImageMagick art drawn inside the ring is hidden; the padlock must be
  the greeter glyph.
- Invalid i3lock options make i3lock exit (the screen would not lock). Check option names with
  `strings $(which i3lock) | grep -E "^[a-z-]+$"`.
- ImageMagick `-annotate` interprets backslashes, and Fira Code ligates runs of `-` and `=`.

## Parked from earlier sessions

- CBA hostnames in this public repo: decide whether to scrub them.
- Typo `.cbai` at `.config/ssh/config` line 51.

## Devbox test harness

- Container `devbox` (Arch, VNC desktop), user `tester`, password `devbox`. No public internet.
- `~/.dotfiles/test/arch/.local-devbox/` is gitignored: never commit it.
- Copy the changed script into the container first:
  `docker cp .config/common/bin/system/lock.sh devbox:/home/tester/.dotfiles/.config/common/bin/system/lock.sh`
- Render all states: `docker exec -u tester devbox bash -c 'export PATH=$HOME/.local/bin:$PATH; bash /tmp/states.sh 1366x768 <tag>'`
  (`/tmp/states.sh` lives only inside the container and is lost if the container is rebuilt), then
  `docker cp devbox:/tmp/ls-<tag> ~/devbox-proof/<dir>`. The patched i3lock is at `/home/tester/.local/bin/i3lock`.
- `/tmp/lock7.log` in the container shows i3lock errors.
- Kill i3lock by PID; `pkill` is not allowed. macOS Make is 3.81 and `sed -i` needs a suffix.
- `make format` (shfmt) and `make lint-sh` before committing.

## User preferences

- Be direct and honest; never say "done" if it isn't. Prove things with screenshots.
- Dislikes unrequested additions (tree logo, ASCII padlock art, squircle). Likes the original thick ring.
- Never push or open PRs. Commit with the trailer
  `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>`.
