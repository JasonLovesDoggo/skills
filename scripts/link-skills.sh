#!/usr/bin/env bash
# Symlinks every skill in this repo into the local harness skill directories,
# so edits here are live everywhere and `git pull` is the update.
#   ~/.claude/skills: Claude Code
#   ~/.agents/skills: Codex and other Agent Skills harnesses
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

for dest in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  mkdir -p "$dest"
  for src in "$REPO"/skills/*/; do
    src="${src%/}"
    target="$dest/$(basename "$src")"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "skip $target: a real directory is in the way, move it aside first" >&2
      continue
    fi
    ln -sfn "$src" "$target"
    echo "linked $target -> $src"
  done
done
