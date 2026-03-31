#!/usr/bin/env bash
# Point Git at the repo's hooks directory (one-time per clone).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

git config core.hooksPath tool/git-hooks
chmod +x tool/git-hooks/pre-commit 2>/dev/null || true

echo "Git hooks path set to tool/git-hooks"
echo "pre-commit will run: flutter test"
echo "Skip when needed: git commit --no-verify"
