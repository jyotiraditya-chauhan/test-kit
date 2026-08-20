#!/usr/bin/env bash
# Detects a React Native project (Expo managed, Expo bare, or plain React
# Native CLI) and reports the existing test runner, RNTL, state-management
# library, expo-router presence, and E2E tooling already in use. Run from
# the project root.
set -euo pipefail

if [[ ! -f "package.json" ]]; then
  echo "ERROR: package.json not found in $(pwd). Run this from the project root." >&2
  exit 1
fi

if ! grep -q '"react-native"' package.json; then
  echo "ERROR: package.json does not declare 'react-native'. This does not look like a React Native project -- if it's a web React app, use react-testing instead." >&2
  exit 1
fi

echo "== React Native project confirmed =="

echo ""
echo "== Workflow =="
IS_EXPO=false
grep -q '"expo"' package.json && IS_EXPO=true
HAS_NATIVE_DIRS=false
[[ -d "ios" || -d "android" ]] && HAS_NATIVE_DIRS=true

if [[ "$IS_EXPO" == true && "$HAS_NATIVE_DIRS" == false ]]; then
  echo "  Expo MANAGED workflow (expo dependency present, no ios/android folders committed)."
  echo "  jest-expo is the correct preset; native folders are generated on build, not edited directly."
elif [[ "$IS_EXPO" == true && "$HAS_NATIVE_DIRS" == true ]]; then
  echo "  Expo BARE workflow (expo dependency present, ios/android folders are committed)."
  echo "  jest-expo still applies for JS-level testing; native code changes need native tooling."
elif [[ "$IS_EXPO" == false ]]; then
  echo "  Plain React Native CLI project (no expo dependency)."
  echo "  Use the standard 'react-native' Jest preset, not jest-expo."
fi

echo ""
echo "== expo-router =="
if grep -q '"expo-router"' package.json; then
  echo "  FOUND: expo-router -- see reference/expo-router-testing.md before testing anything"
  echo "  under app/. Never place test files inside app/ itself; expo-router treats"
  echo "  every file there as a route."
fi

echo ""
echo "== Test runner =="
if grep -Eq '"preset":[[:space:]]*"jest-expo"' package.json 2>/dev/null || { [[ -f "jest.config.js" ]] && grep -q "jest-expo" jest.config.js 2>/dev/null; }; then
  echo "  FOUND: jest-expo preset already configured"
elif grep -Eq '"preset":[[:space:]]*"react-native"' package.json 2>/dev/null; then
  echo "  FOUND: react-native Jest preset already configured"
else
  echo "  no existing Jest preset detected in package.json -- check jest.config.* manually"
fi

echo ""
echo "== React Native Testing Library =="
grep -q '"@testing-library/react-native"' package.json && echo "  FOUND: @testing-library/react-native"

echo ""
echo "== State management (first match wins; codebase should use exactly one) =="
declare -A STATE_PKGS=(
  [zustand]="Zustand"
  [@reduxjs/toolkit]="Redux Toolkit"
  [react-redux]="Redux"
  [jotai]="Jotai"
  [mobx-react]="MobX"
)
FOUND_STATE="none detected"
for pkg in zustand "@reduxjs/toolkit" react-redux jotai mobx-react; do
  if grep -q "\"${pkg}\":" package.json; then
    FOUND_STATE="${pkg} (${STATE_PKGS[$pkg]})"
    echo "  FOUND: $FOUND_STATE"
    break
  fi
done
[[ "$FOUND_STATE" == "none detected" ]] && echo "  none detected -- ask the user or infer from source imports"

echo ""
echo "== E2E tooling =="
grep -q '"detox"' package.json && echo "  FOUND: Detox (devDependency)"
[[ -f ".detoxrc.js" || -f ".detoxrc.json" ]] && echo "  FOUND: .detoxrc config file"
[[ -d ".maestro" ]] && echo "  FOUND: .maestro/ flow directory"
if ! grep -q '"detox"' package.json && [[ ! -d ".maestro" ]]; then
  echo "  no existing E2E tooling detected -- default to Maestro (zero in-repo setup) unless the user prefers Detox"
fi

echo ""
echo "== Existing test file convention =="
if find . -type d -iname '__tests__' -not -path '*/node_modules/*' 2>/dev/null | grep -q .; then
  echo "  convention: __tests__/ directories"
elif find . -not -path '*/node_modules/*' \( -name '*-test.tsx' -o -name '*-test.ts' -o -name '*.test.tsx' -o -name '*.test.ts' \) 2>/dev/null | grep -q .; then
  echo "  convention: co-located *-test.tsx / *.test.tsx next to source files"
else
  echo "  no existing test files found -- no convention to match yet"
fi
