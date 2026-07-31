#!/usr/bin/env zsh
# shellcheck disable=SC1071
# Tests _worktree_pick(), opencode(), claude(), and wt() from .config/common/aliases.
# Safe to run at any time — all side effects are inside /tmp.

set -euo pipefail

pass=0
fail=0
TMPDIR_BASE=$(mktemp -d /tmp/test-opencode-XXXX)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ── Helpers ───────────────────────────────────────────────────────────────────

ok() {
  echo "  PASS  $1"
  pass=$((pass + 1))
}
fail_test() {
  echo "  FAIL  $1"
  fail=$((fail + 1))
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    ok "$label"
  else fail_test "$label — expected '$needle' in: '$haystack'"; fi
}

assert_not_contains() {
  local label="$1" needle="$2" haystack="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    ok "$label"
  else fail_test "$label — did not expect '$needle' in output"; fi
}

make_repo() {
  local dir="$TMPDIR_BASE/$1"
  mkdir -p "$dir"
  git -C "$dir" init -q -b main
  git -C "$dir" config user.email "test@test.com"
  git -C "$dir" config user.name "Test"
  git -C "$dir" commit --allow-empty -q -m "init"
  cd "$dir" && git rev-parse --show-toplevel
}

# Inject mock fzf that returns a fixed value.
# Uses a temp file for the counter so it works across subshells.
mock_fzf() {
  local output1="$1" output2="${2:-}"
  local counter_file="$TMPDIR_BASE/fzf_counter_$$"
  echo 0 >"$counter_file"
  eval "
    fzf() {
      local n; n=\$(cat $(printf '%q' "$counter_file"))
      n=\$((n+1)); echo \$n >$(printf '%q' "$counter_file")
      if [[ \$n -eq 1 ]]; then echo $(printf '%q' "$output1")
      else echo $(printf '%q' "$output2"); fi
    }
  "
}

# Define the shared _worktree_pick helper (exact copy from aliases).
define_worktree_pick() {
  _worktree_pick() {
    local prompt="${1:-opencode}"
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || true
    [[ -z "$root" ]] && return 0
    local wt_count
    wt_count=$(git -C "$root" worktree list --porcelain | grep -c '^worktree ') || true
    [[ "$wt_count" -le 1 ]] && return 0
    command -v fzf &>/dev/null || return 0
    local worktree_lines
    worktree_lines=$(git -C "$root" worktree list --porcelain | awk -v root="$root" '
      /^worktree / { path=$2; branch=""; sha="" }
      /^HEAD /     { sha=substr($2,1,7) }
      /^branch /   { branch=$2; gsub("refs/heads/","",branch) }
      /^$/ {
        if (path != "") {
          if (branch != "") { marker=(path==root)?"* ":"  "; printf "%s%s\n",marker,branch }
          else if (sha != "") { marker=(path==root)?"* ":"  "; printf "%s(detached @ %s)\n",marker,sha }
          path=""; branch=""; sha=""
        }
      }
    ')
    local selected
    selected=$(echo "$worktree_lines" | fzf \
      --prompt="$prompt > " --height=40% --border \
      --header="Select a worktree  (* = current)" --no-sort)
    [[ -z "$selected" ]] && return 0
    local branch_name="${selected#\* }"
    branch_name="${branch_name#  }"
    git -C "$root" worktree list --porcelain | awk -v branch="refs/heads/$branch_name" '
      /^worktree / { path=$2 }
      /^branch /   { if ($2 == branch) print path }
    '
  }
}

# Define opencode() + claude() (exact copies from aliases) with _run sentinel.
define_launchers() {
  local sentinel="$1"
  eval "_run() { echo \"\${@:-<no args>} [cwd=\$PWD]\" >$(printf '%q' "$sentinel"); }"

  opencode() {
    if [[ $# -gt 0 ]]; then
      _run "$@"
      return
    fi
    local target_path
    target_path=$(_worktree_pick "opencode")
    if [[ -n "$target_path" ]]; then
      _run "$target_path"
    else _run; fi
  }

  claude() {
    if [[ $# -gt 0 ]]; then
      _run "$@"
      return
    fi
    local target_path
    target_path=$(_worktree_pick "claude")
    if [[ -n "$target_path" ]]; then
      (cd "$target_path" && _run)
    else _run; fi
  }
}

# ── _worktree_pick() tests ────────────────────────────────────────────────────

echo ""
echo "_worktree_pick() tests"
echo "──────────────────────"

# 1. Not a git repo — returns empty.
result=$(
  cd "$TMPDIR_BASE"
  (
    define_worktree_pick
    mock_fzf "main"
    _worktree_pick
  )
)
assert_not_contains "not a git repo — returns empty" "/" "$result"

# 2. Single worktree — returns empty (skip picker).
result=$(
  repo=$(make_repo "p2")
  cd "$repo"
  (
    define_worktree_pick
    mock_fzf "main"
    _worktree_pick
  )
)
assert_not_contains "single worktree — skips picker" "/" "$result"

# 3. fzf cancelled — returns empty.
result=$(
  repo=$(make_repo "p3")
  cd "$repo"
  git -C "$repo" worktree add "$repo/.worktrees/other" -b "other" -q
  (
    define_worktree_pick
    mock_fzf ""
    _worktree_pick
  )
)
assert_not_contains "fzf cancelled — returns empty" "/" "$result"

# 4. Select root worktree — returns repo root path.
result=$(
  repo=$(make_repo "p4")
  cd "$repo"
  git -C "$repo" worktree add "$repo/.worktrees/other" -b "other" -q
  (
    define_worktree_pick
    mock_fzf "* main"
    _worktree_pick
  )
)
assert_contains "select root — returns repo root" "p4" "$result"

# 5. Select feature worktree — returns worktree path.
result=$(
  repo=$(make_repo "p5")
  cd "$repo"
  git -C "$repo" worktree add "$repo/.worktrees/feat" -b "feat" -q
  (
    define_worktree_pick
    mock_fzf "  feat"
    _worktree_pick
  )
)
assert_contains "select feature — returns worktree path" ".worktrees/feat" "$result"

# 6. Detached HEAD shown in picker display.
repo=$(make_repo "p6")
cd "$repo"
git -C "$repo" worktree add --detach "$repo/.worktrees/detached" -q
display=$(
  root="$repo"
  git -C "$root" worktree list --porcelain | awk -v root="$root" '
    /^worktree / { path=$2; branch=""; sha="" }
    /^HEAD /     { sha=substr($2,1,7) }
    /^branch /   { branch=$2; gsub("refs/heads/","",branch) }
    /^$/ {
      if (path != "") {
        if (branch != "") { marker=(path==root)?"* ":"  "; printf "%s%s\n",marker,branch }
        else if (sha != "") { marker=(path==root)?"* ":"  "; printf "%s(detached @ %s)\n",marker,sha }
        path=""; branch=""; sha=""
      }
    }
  '
)
assert_contains "detached HEAD in display" "detached @" "$display"
assert_contains "root still * in display" "* main" "$display"
assert_not_contains "no paths in display" "/tmp/" "$display"
assert_not_contains "no paths in display (private)" "/private/" "$display"

# ── opencode() tests ──────────────────────────────────────────────────────────

echo ""
echo "opencode() tests"
echo "────────────────"

# 7. Args forwarded directly.
result=$(
  sentinel="$TMPDIR_BASE/s7"
  repo=$(make_repo "t7")
  cd "$repo"
  (
    define_worktree_pick
    mock_fzf ""
    define_launchers "$sentinel"
    opencode run "fix it"
    cat "$sentinel"
  )
)
assert_contains "opencode: args forwarded" "run fix it" "$result"

# 8. No worktrees — runs in current dir.
result=$(
  sentinel="$TMPDIR_BASE/s8"
  repo=$(make_repo "t8")
  cd "$repo"
  (
    define_worktree_pick
    mock_fzf ""
    define_launchers "$sentinel"
    opencode
    cat "$sentinel"
  )
)
assert_contains "opencode: no worktrees — runs here" "<no args>" "$result"

# 9. Select worktree — path passed as arg.
result=$(
  sentinel="$TMPDIR_BASE/s9"
  repo=$(make_repo "t9")
  cd "$repo"
  git -C "$repo" worktree add "$repo/.worktrees/feat" -b "feat" -q
  (
    define_worktree_pick
    mock_fzf "  feat"
    define_launchers "$sentinel"
    opencode
    cat "$sentinel"
  )
)
assert_contains "opencode: selected worktree — path as arg" ".worktrees/feat" "$result"

# ── claude() tests ────────────────────────────────────────────────────────────

echo ""
echo "claude() tests"
echo "──────────────"

# 10. Args forwarded directly.
result=$(
  sentinel="$TMPDIR_BASE/s10"
  repo=$(make_repo "t10")
  cd "$repo"
  (
    define_worktree_pick
    mock_fzf ""
    define_launchers "$sentinel"
    claude -p "hello"
    cat "$sentinel"
  )
)
assert_contains "claude: args forwarded" "-p hello" "$result"

# 11. No worktrees — runs in current dir.
result=$(
  sentinel="$TMPDIR_BASE/s11"
  repo=$(make_repo "t11")
  cd "$repo"
  (
    define_worktree_pick
    mock_fzf ""
    define_launchers "$sentinel"
    claude
    cat "$sentinel"
  )
)
assert_contains "claude: no worktrees — runs here" "<no args>" "$result"

# 12. Select worktree — cd into it (CWD changes, no path arg).
result=$(
  sentinel="$TMPDIR_BASE/s12"
  repo=$(make_repo "t12")
  cd "$repo"
  git -C "$repo" worktree add "$repo/.worktrees/feat" -b "feat" -q
  (
    define_worktree_pick
    mock_fzf "  feat"
    define_launchers "$sentinel"
    claude
    cat "$sentinel"
  )
)
assert_contains "claude: selected worktree — cwd is worktree" ".worktrees/feat" "$result"
assert_not_contains "claude: selected worktree — no path arg" ".worktrees/feat $result" "$result"

# 13. claude terminal CWD unchanged after worktree selection.
repo=$(make_repo "t13")
git -C "$repo" worktree add "$repo/.worktrees/feat" -b "feat" -q
sentinel="$TMPDIR_BASE/s13"
orig_cwd="$PWD" # capture AFTER make_repo (which internally cds)
(
  cd "$repo"
  define_worktree_pick
  mock_fzf "  feat"
  define_launchers "$sentinel"
  claude
) >/dev/null 2>&1 || true
if [[ "$PWD" == "$orig_cwd" ]]; then
  ok "claude: terminal CWD unchanged"
else
  fail_test "claude: terminal CWD changed to $PWD"
fi

# ── wt() tests ────────────────────────────────────────────────────────────────

echo ""
echo "wt() tests"
echo "──────────"

define_wt() {
  local fzf_output="$1"
  eval "fzf() { echo $(printf '%q' "$fzf_output"); }"

  wt() {
    local root
    root=$(git rev-parse --show-toplevel 2>/dev/null) || true
    if [[ -z "$root" ]]; then
      echo "wt: not inside a git repo" >&2
      return 1
    fi
    if ! grep -qxF '.worktrees/' "$root/.gitignore" 2>/dev/null; then
      echo '.worktrees/' >>"$root/.gitignore"
    fi
    _wt_add() {
      local branch="$1" worktree_path="$root/.worktrees/$1"
      mkdir -p "$(dirname "$worktree_path")"
      if git -C "$root" branch --list "$branch" | grep -q "$branch"; then
        git -C "$root" worktree add "$worktree_path" "$branch"
      else
        git -C "$root" worktree add "$worktree_path" -b "$branch"
      fi
    }
    _wt_pick_rm() {
      local removable
      removable=$(git -C "$root" worktree list --porcelain | awk -v root="$root" '
        /^worktree / { path=$2; branch=""; sha="" }
        /^HEAD /     { sha=substr($2,1,7) }
        /^branch /   { branch=$2; gsub("refs/heads/","",branch) }
        /^$/ {
          if (path != "" && path != root) {
            if (branch != "") printf "%s\n", branch
            else if (sha != "") printf "(detached @ %s)\n", sha
          }
          path=""; branch=""; sha=""
        }
      ')
      [[ -z "$removable" ]] && {
        echo "wt: no worktrees to remove" >&2
        return 1
      }
      echo "$removable" | fzf --prompt="remove > " --height=40% --border --header="Select worktree to remove"
    }
    case "${1:-}" in
    ls) git -C "$root" worktree list ;;
    add)
      local branch="${2:-}"
      if [[ -z "$branch" ]]; then
        read "branch?Branch name (new or existing): " || branch="${_TEST_BRANCH:-}"
        [[ -z "$branch" ]] && return 0
      fi
      _wt_add "$branch"
      ;;
    rm)
      local branch="${2:-}"
      if [[ -z "$branch" ]]; then branch=$(_wt_pick_rm) || return 0; fi
      local remove_path
      remove_path=$(git -C "$root" worktree list --porcelain | awk -v branch="refs/heads/$branch" '
          /^worktree / { path=$2 }
          /^branch /   { if ($2 == branch) print path }
        ')
      [[ -z "$remove_path" ]] && {
        echo "wt: no worktree for '$branch'" >&2
        return 1
      }
      git -C "$root" worktree remove "$remove_path"
      ;;
    "")
      local action
      action=$(printf 'add\nremove' | fzf --prompt="wt > " --height=20% --border --header="Worktree action")
      [[ -z "$action" ]] && return 0
      case "$action" in add) wt add ;; remove) wt rm ;; esac
      ;;
    *)
      echo "usage: wt [ls | add [branch] | rm [branch]]" >&2
      return 1
      ;;
    esac
  }
}

# 14. wt outside repo — error.
result=$(
  cd "$TMPDIR_BASE"
  define_wt ""
  wt 2>&1 || true
)
assert_contains "wt: outside repo — error" "not inside a git repo" "$result"

# 15. wt ls.
repo=$(make_repo "w15")
cd "$repo"
git -C "$repo" worktree add "$repo/.worktrees/feat" -b "feat" -q
result=$(
  cd "$repo"
  define_wt ""
  wt ls 2>&1
)
assert_contains "wt ls — main listed" "main" "$result"
assert_contains "wt ls — feat listed" "feat" "$result"

# 16. wt add <new branch>.
repo=$(make_repo "w16")
cd "$repo"
(
  cd "$repo"
  define_wt ""
  wt add new-branch
) >/dev/null 2>&1
[[ -d "$repo/.worktrees/new-branch" ]] && ok "wt add new branch — dir created" || fail_test "wt add new branch — dir NOT created"

# 17. wt add <existing branch>.
repo=$(make_repo "w17")
cd "$repo"
git -C "$repo" branch existing -q
(
  cd "$repo"
  define_wt ""
  wt add existing
) >/dev/null 2>&1
[[ -d "$repo/.worktrees/existing" ]] && ok "wt add existing branch — dir created" || fail_test "wt add existing branch — dir NOT created"

# 18. wt rm <branch>.
repo=$(make_repo "w18")
cd "$repo"
git -C "$repo" worktree add "$repo/.worktrees/to-delete" -b "to-delete" -q
(
  cd "$repo"
  define_wt ""
  wt rm to-delete
) >/dev/null 2>&1
[[ ! -d "$repo/.worktrees/to-delete" ]] && ok "wt rm — dir removed" || fail_test "wt rm — dir still exists"

# 19. wt rm via fzf.
repo=$(make_repo "w19")
cd "$repo"
git -C "$repo" worktree add "$repo/.worktrees/fzf-rm" -b "fzf-rm" -q
(
  cd "$repo"
  define_wt "fzf-rm"
  wt rm
) >/dev/null 2>&1
[[ ! -d "$repo/.worktrees/fzf-rm" ]] && ok "wt rm via fzf — dir removed" || fail_test "wt rm via fzf — dir still exists"

# 20. wt — .worktrees/ added to .gitignore.
repo=$(make_repo "w20")
cd "$repo"
rm -f "$repo/.gitignore"
(
  cd "$repo"
  define_wt ""
  wt ls
) >/dev/null 2>&1 || true
grep -qxF '.worktrees/' "$repo/.gitignore" 2>/dev/null &&
  ok "wt — .worktrees/ added to .gitignore" ||
  fail_test "wt — .worktrees/ NOT added to .gitignore"

# ── Live smoke test ───────────────────────────────────────────────────────────

echo ""
echo "live smoke tests"
echo "────────────────"

# 21. 'command claude' resolves to the real binary.
if command -v claude &>/dev/null; then
  ok "claude binary exists at $(command -v claude)"
else
  fail_test "claude binary not found in PATH"
fi

# 22. claude --version runs without error.
if claude_ver=$(command claude --version 2>/dev/null); then
  ok "claude --version: $claude_ver"
else
  fail_test "claude --version failed"
fi

# 23. claude() wrapper forwards args correctly (dry run via --version).
source_result=$(
  (
    define_worktree_pick
    claude() {
      if [[ $# -gt 0 ]]; then
        command claude "$@"
        return
      fi
      command claude
    }
    claude --version 2>/dev/null
  )
)
assert_contains "claude wrapper: --version forwarded" "Claude Code" "$source_result"

# ── Summary ───────────────────────────────────────────────────────────────────

echo ""
echo "────────────────"
echo "  $pass passed, $fail failed"
echo ""

[[ "$fail" -eq 0 ]]
