#!/usr/bin/env bash
# Shared formatting (fmt) and checking (chk) for the prediction-pies project.
#
# One policy, two modes: the file selection and all shared options live in this
# single script so the formatter and the checker can never drift apart. `fmt`
# fixes files in place; `chk` changes nothing and exits non-zero on any problem.
#
# Usage:
#   bash scripts/quality.sh fmt   # fix formatting
#   bash scripts/quality.sh chk   # verify only
set -euo pipefail

mode="${1:-}"
if [[ "$mode" != "fmt" && "$mode" != "chk" ]]; then
  echo "usage: $0 <fmt|chk>" >&2
  exit 2
fi

# cargo's sqlx! macros otherwise require a live, migrated Postgres to
# typecheck queries. The checked-in .sqlx cache makes fmt/chk work the same
# whether or not `devenv up` is running (including from the pre-commit hook).
export SQLX_OFFLINE=true

# Shared options — identical for both modes so fmt and chk agree.
md_options=(--wrap 88)
sh_options=(-ln bash -i 2 -ci)

# Tracked files in the working tree (real file contents, not the Git index)
# matching the given globs, NUL-separated for safe mapfile consumption.
collect_files() {
  git ls-files -z -- "$@"
}

mapfile -d '' -t md_files < <(collect_files '*.md' '*.markdown')
mapfile -d '' -t sh_files < <(collect_files '*.sh' '*.bash' '.envrc')

# Markdown: mdformat reformats in place; --check exits non-zero if changes are
# needed.
run_md() {
  [[ ${#md_files[@]} -eq 0 ]] && return 0
  if [[ "$mode" == "fmt" ]]; then
    mdformat "${md_options[@]}" "${md_files[@]}"
  else
    mdformat --check "${md_options[@]}" "${md_files[@]}"
  fi
}

# Shell: shfmt formats (-w) or diffs (-d); shellcheck lints (chk only, since
# linters never reformat).
run_sh() {
  [[ ${#sh_files[@]} -eq 0 ]] && return 0
  if [[ "$mode" == "fmt" ]]; then
    shfmt "${sh_options[@]}" -w "${sh_files[@]}"
  else
    shfmt "${sh_options[@]}" -d "${sh_files[@]}"
    # -s bash: .envrc has no extension for shellcheck to infer the dialect
    # from, and its shebang is dropped whenever pre-commit stashes unstaged
    # changes (it has no effect on execution either, since direnv always
    # sources it with bash). Same reasoning as shfmt's `-ln bash` above.
    shellcheck -s bash "${sh_files[@]}"
  fi
}

# Rust: rustfmt formats or checks; clippy lints in chk only. Both read the
# same (absent) rustfmt.toml, so there is no separate options array to drift.
run_rust() {
  if [[ "$mode" == "fmt" ]]; then
    cargo fmt
  else
    cargo fmt --check
    cargo clippy --all-targets -- -D warnings
  fi
}

run_md
run_sh
run_rust
