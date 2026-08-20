#!/usr/bin/env bash
# Repo-maintenance script, not a skill script. Copies each canonical
# skill folder from plugins/testing-suite/skills/<name>/ into
# .agents/skills/<name>/ at the repository root, so tools that read
# .agents/skills/ directly (opencode, and others converging on the same
# path) get the same content Claude Code installs as a plugin, without
# the two copies drifting apart.
#
# Run this after changing any skill, before committing.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SRC="$SCRIPT_DIR/../skills"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS_DEST="$REPO_ROOT/.agents/skills"

if [[ ! -d "$SKILLS_SRC" ]]; then
  echo "ERROR: $SKILLS_SRC not found. Run this from within the test-kit repo." >&2
  exit 1
fi

mkdir -p "$SKILLS_DEST"

for skill_dir in "$SKILLS_SRC"/*/; do
  name="$(basename "$skill_dir")"
  dest="$SKILLS_DEST/$name"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$skill_dir." "$dest/"
  echo "synced: $name -> .agents/skills/$name/"
done

echo ""
echo "Done. .agents/skills/ now mirrors plugins/testing-suite/skills/ exactly."
