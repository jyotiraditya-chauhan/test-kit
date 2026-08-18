#!/usr/bin/env bash
# Creates a correctly-mirrored, minimal stub test file for a given lib/
# source file. Deterministic and non-destructive: never overwrites an
# existing test file. Optional convenience -- not a required step.
# Usage: scripts/scaffold_test_file.sh lib/services/auth_service.dart
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "ERROR: expected exactly one argument (a lib/ file path)." >&2
  echo "Usage: scripts/scaffold_test_file.sh lib/path/to/file.dart" >&2
  exit 1
fi

SRC="$1"

if [[ "$SRC" != lib/* ]]; then
  echo "ERROR: '$SRC' does not start with 'lib/'. This script mirrors lib/ into test/." >&2
  exit 1
fi

if [[ "$SRC" != *.dart ]]; then
  echo "ERROR: '$SRC' does not end in .dart." >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "ERROR: '$SRC' does not exist." >&2
  exit 1
fi

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: pubspec.yaml not found. Run this from the project root." >&2
  exit 1
fi

PACKAGE_NAME=$(grep -E '^name:' pubspec.yaml | head -1 | sed -E 's/^name:[[:space:]]*//')
if [[ -z "$PACKAGE_NAME" ]]; then
  echo "ERROR: could not read 'name:' from pubspec.yaml." >&2
  exit 1
fi

REL="${SRC#lib/}"             # services/auth_service.dart
REL_NO_EXT="${REL%.dart}"     # services/auth_service
TEST_PATH="test/${REL_NO_EXT}_test.dart"

if [[ -f "$TEST_PATH" ]]; then
  echo "SKIPPED: $TEST_PATH already exists -- not overwriting."
  exit 0
fi

mkdir -p "$(dirname "$TEST_PATH")"

cat > "$TEST_PATH" <<EOF
import 'package:flutter_test/flutter_test.dart';
import 'package:${PACKAGE_NAME}/${REL}';

void main() {
  group('${REL_NO_EXT}', () {
  });
}
EOF

echo "CREATED: $TEST_PATH"
