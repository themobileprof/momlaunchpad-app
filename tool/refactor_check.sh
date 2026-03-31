#!/usr/bin/env bash
# Quick refactor-opportunity pass: analyzer + file size + loose-typing hints.
# Run from anywhere:  bash tool/refactor_check.sh
# Exits with flutter analyze's status (non-zero if infos/warnings/errors).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "== flutter analyze =="
set +e
flutter analyze
ANALYZE_EXIT=$?
set -e

echo ""
echo "== Largest Dart files under lib/ (line counts; last line may be total) =="
if compgen -G "lib/**/*.dart" > /dev/null 2>&1 || find lib -name '*.dart' -quit 2>/dev/null; then
  find lib -name '*.dart' -type f -print0 2>/dev/null | xargs -0 wc -l 2>/dev/null | sort -n | tail -22
else
  echo "(no lib/*.dart found)"
fi

echo ""
echo "== dynamic outside lib/models/ (candidates to tighten typing) =="
if command -v rg >/dev/null 2>&1; then
  rg '\bdynamic\b' lib --glob '*.dart' --glob '!lib/models/**' || true
else
  find lib -path 'lib/models' -prune -o -name '*.dart' -type f -print0 2>/dev/null \
    | xargs -0 grep -n '\bdynamic\b' 2>/dev/null || true
fi

echo ""
echo "Done."
exit "$ANALYZE_EXIT"
