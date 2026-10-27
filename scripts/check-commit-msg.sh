#!/usr/bin/env bash
# commit-msg hook helper: validate the commit message with convco.
# Git passes the path to a file holding the prepared message as $1.
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "usage: $0 <commit-msg-file>" >&2
  exit 2
fi

msg_file="$1"
if [[ ! -f "$msg_file" ]]; then
  echo "commit message file not found: $msg_file" >&2
  exit 2
fi

# --from-stdin reads the message from standard input; --strip drops Git's
# leading comment lines and surrounding whitespace before checking the
# `type(scope): description` form.
convco check --from-stdin --strip <"$msg_file"
