#!/usr/bin/env bash
# Detects Flutter project + state-management + mocking/golden conventions
# already in use, so the skill matches existing choices instead of
# introducing a second competing library. Run from the project root.
set -euo pipefail

if [[ ! -f "pubspec.yaml" ]]; then
  echo "ERROR: pubspec.yaml not found in $(pwd). Run this from the Flutter project root." >&2
  exit 1
fi

if ! grep -qE '^\s*flutter:\s*$' pubspec.yaml || ! grep -qE '^\s*sdk:\s*flutter\s*$' pubspec.yaml; then
  echo "ERROR: pubspec.yaml exists but does not declare a 'flutter: sdk: flutter' dependency. This does not look like a Flutter project." >&2
  exit 1
fi

echo "== Flutter project confirmed =="

echo ""
echo "== State management (first match wins; codebase should use exactly one) =="
declare -A STATE_PKGS=(
  [flutter_bloc]="BLoC/Cubit"
  [flutter_riverpod]="Riverpod"
  [riverpod]="Riverpod"
  [provider]="Provider"
  [get]="GetX"
)
FOUND_STATE="none detected"
for pkg in flutter_bloc flutter_riverpod riverpod provider get; do
  if grep -qE "^\s*${pkg}:" pubspec.yaml; then
    FOUND_STATE="${pkg} (${STATE_PKGS[$pkg]})"
    echo "  FOUND: $FOUND_STATE"
    break
  fi
done
[[ "$FOUND_STATE" == "none detected" ]] && echo "  none detected -- ask the user or infer from lib/ imports"

echo ""
echo "== Mocking library =="
for pkg in mocktail mockito; do
  grep -qE "^\s*${pkg}:" pubspec.yaml && echo "  FOUND: $pkg"
done

echo ""
echo "== Golden test helpers =="
for pkg in golden_toolkit alchemist; do
  grep -qE "^\s*${pkg}:" pubspec.yaml && echo "  FOUND: $pkg"
done

echo ""
echo "== BLoC test helper =="
grep -qE "^\s*bloc_test:" pubspec.yaml && echo "  FOUND: bloc_test"

echo ""
echo "== Firebase fakes =="
for pkg in fake_cloud_firestore firebase_auth_mocks google_sign_in_mocks; do
  grep -qE "^\s*${pkg}:" pubspec.yaml && echo "  FOUND: $pkg"
done

echo ""
echo "== Native-interaction integration testing =="
grep -qE "^\s*patrol:" pubspec.yaml && echo "  FOUND: patrol"
grep -qE "^\s*integration_test:" pubspec.yaml && echo "  FOUND: integration_test"

echo ""
echo "== Existing test directory =="
if [[ -d "test" ]]; then
  TEST_COUNT=$(find test -name '*_test.dart' | wc -l | tr -d ' ')
  echo "  test/ exists with $TEST_COUNT existing *_test.dart file(s)"
  if [[ -d "lib" ]]; then
    SAMPLE=$(find lib -name '*.dart' | head -1)
    if [[ -n "$SAMPLE" ]]; then
      MIRRORED="test/${SAMPLE#lib/}"
      MIRRORED="${MIRRORED%.dart}_test.dart"
      [[ -f "$MIRRORED" ]] && echo "  test/ appears to mirror lib/ file-for-file (e.g. $MIRRORED)"
    fi
  fi
else
  echo "  no test/ directory yet -- will need to be created"
fi
