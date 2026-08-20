#!/usr/bin/env bash
# Detects a Swift/SwiftUI project and which test framework, snapshot
# library, and persistence layer are already in use. Xcode projects have
# no single manifest file like pubspec.yaml/package.json, so this greps
# project structure and source instead. Run from the project root.
set -euo pipefail

HAS_XCODEPROJ=false
HAS_PACKAGE_SWIFT=false
find . -maxdepth 3 -name '*.xcodeproj' -not -path '*/.build/*' 2>/dev/null | grep -q . && HAS_XCODEPROJ=true
find . -maxdepth 3 -name '*.xcworkspace' -not -path '*/.build/*' 2>/dev/null | grep -q . && HAS_XCODEPROJ=true
[[ -f "Package.swift" ]] && HAS_PACKAGE_SWIFT=true

if [[ "$HAS_XCODEPROJ" == false && "$HAS_PACKAGE_SWIFT" == false ]]; then
  echo "ERROR: no .xcodeproj/.xcworkspace or Package.swift found in $(pwd). This does not look like a Swift project." >&2
  exit 1
fi

echo "== Swift project confirmed =="
[[ "$HAS_XCODEPROJ" == true ]] && echo "  Xcode project/workspace present"
[[ "$HAS_PACKAGE_SWIFT" == true ]] && echo "  Package.swift present (SPM)"

# Search source and manifest files for framework/library signals, excluding
# build artifacts which can contain stale or third-party matches.
PRUNE='-path */.build/* -o -path */DerivedData/* -o -path */Pods/* -o -path */.git/*'

echo ""
echo "== Test framework already in use =="
# find -prune excludes build directories directly, avoiding a second grep
# stage. grep exits 1 on zero matches, which is a normal outcome here (not
# an error) -- `|| true` stops that from tripping `set -e` on an empty result.
SWIFT_TESTING_COUNT=$(find . \( -path '*/.build' -o -path '*/DerivedData' -o -path '*/Pods' -o -path '*/.git' \) -prune -o -name '*.swift' -print 2>/dev/null | xargs grep -lE '@Test(\(|\s|$)' 2>/dev/null | wc -l | tr -d ' ' || true)
XCTEST_COUNT=$(find . \( -path '*/.build' -o -path '*/DerivedData' -o -path '*/Pods' -o -path '*/.git' \) -prune -o -name '*.swift' -print 2>/dev/null | xargs grep -l 'XCTestCase' 2>/dev/null | wc -l | tr -d ' ' || true)
echo "  Swift Testing (@Test) found in $SWIFT_TESTING_COUNT file(s)"
echo "  XCTest (XCTestCase) found in $XCTEST_COUNT file(s)"
if [[ "$XCTEST_COUNT" -gt 0 && "$SWIFT_TESTING_COUNT" -gt 0 ]]; then
  echo "  BOTH frameworks are in use -- this is expected if UI automation (XCUITest) or"
  echo "  performance tests coexist with Swift Testing unit tests. Keep them in separate"
  echo "  files/targets; an assertion in one framework's style does not register in the other."
fi

echo ""
echo "== Snapshot / view-introspection libraries =="
grep -rq 'import SnapshotTesting' --include='*.swift' . 2>/dev/null && echo "  FOUND: swift-snapshot-testing"
grep -rq 'import ViewInspector' --include='*.swift' . 2>/dev/null && echo "  FOUND: ViewInspector"
[[ -f "Package.swift" ]] && grep -q 'swift-snapshot-testing' Package.swift 2>/dev/null && echo "  FOUND in Package.swift: swift-snapshot-testing"

echo ""
echo "== Persistence layer =="
grep -rq 'import CoreData' --include='*.swift' . 2>/dev/null && echo "  FOUND: Core Data"
grep -rq 'import SwiftData' --include='*.swift' . 2>/dev/null && echo "  FOUND: SwiftData"

echo ""
echo "== Existing test target =="
find . -maxdepth 3 -type d -iname '*Tests' -not -path '*/.build/*' 2>/dev/null | while read -r d; do
  echo "  test directory: $d"
done
