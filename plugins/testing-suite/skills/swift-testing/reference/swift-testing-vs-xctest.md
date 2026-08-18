# Swift Testing vs XCTest

Table of contents:
- [Which to use](#which-to-use)
- [Translation table](#translation-table)
- [What Swift Testing does not cover](#what-swift-testing-does-not-cover)
- [Keep them in separate files](#keep-them-in-separate-files)

## Which to use

Default to Swift Testing (`@Test`, `#expect`/`#require`) for new test code.
XCTest remains correct for existing test files, and no forced migration. If
`scripts/detect_stack.sh` reports an existing framework already dominates a
target, match it rather than introducing the other.

## Translation table

| XCTest | Swift Testing |
|---|---|
| `XCTAssertEqual(a, b)` | `#expect(a == b)` |
| `XCTAssertTrue(condition)` | `#expect(condition)` |
| `XCTAssertFalse(condition)` | `#expect(!condition)` |
| `XCTAssertNil(value)` | `#expect(value == nil)` |
| `XCTAssertNotNil(value)` | `#expect(value != nil)` |
| `XCTAssertThrowsError(try f())` | `#expect(throws: Error.self) { try f() }` |
| `class MyTests: XCTestCase { func testX() {...} }` | `@Test func x() { #expect(...) }` |

Swift Testing also supports human-readable test names and built-in
parameterization:

```swift
@Test("User can create account with valid email and password",
      arguments: ["a@b.com", "user@example.com"])
func createAccount(email: String) {
    #expect(isValidEmail(email))
}
```

## What Swift Testing does not cover

Swift Testing does NOT currently cover UI automation (`XCUIApplication`/
XCUITest) or performance testing (`XCTMetric`). Both remain XCTest-only. A
realistic modern iOS project uses both side by side: Swift Testing for
unit/integration/async/parameterized tests, XCTest specifically for
UI-automation and performance targets. Do not attempt to write a `@Test`
function that drives `XCUIApplication`. Route that to an XCTest UI test
target instead.

## Keep them in separate files

The two frameworks are NOT cross-compatible. An assertion made in one
framework's style inside a test written in the other framework's style will
not register as a failure. Never mix `XCTAssert*` calls inside a `@Test`
function or `#expect` inside an `XCTestCase` method.
