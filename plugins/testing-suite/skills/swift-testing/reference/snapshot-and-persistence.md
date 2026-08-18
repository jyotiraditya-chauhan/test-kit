# Snapshot Testing and In-Memory Persistence

Table of contents:
- [Snapshot testing with swift-snapshot-testing](#snapshot-testing-with-swift-snapshot-testing)
- [Scope and flakiness](#scope-and-flakiness)
- [Core Data / SwiftData in-memory store](#core-data--swiftdata-in-memory-store)

## Snapshot testing with swift-snapshot-testing

Because there is no view-tree introspection (see
[view-model-testing.md](view-model-testing.md)), snapshot testing is
effectively the only viable way to verify a SwiftUI view's actual rendered
appearance, as opposed to its underlying view-model state. The de facto
standard is Point-Free's `swift-snapshot-testing` package:

```swift
import SnapshotTesting

@Test func productCardMatchesSnapshot() {
    let view = ProductCard(title: "Widget", price: "$9.99")
    assertSnapshot(of: UIHostingController(rootView: view), as: .image)
}
```

`UIHostingController` wraps the SwiftUI view to produce a snapshot-able
image. Failures show baseline, current, and diff images as Xcode test
attachments. It's device-agnostic: render and snapshot for a specific
device size/trait collection from one simulator, without a device farm.
It also supports overriding environment values to snapshot the SAME view
across dark mode, accessibility text sizes, and locale/RTL variants from
one test, which is genuinely useful for catching layout breakage across
accessibility settings.

## Scope and flakiness

This is functionally identical to Flutter's golden-test concept: scope
snapshots to small, stable components (a card, a button, a badge) rather
than full screens, for the same reasons (an unrelated layout tweak
elsewhere breaks a full-screen snapshot with no localized signal). The same
flakiness causes apply: font rendering and simulator-version differences
across machines/CI runners. Run snapshot tests on a pinned simulator
version in CI, not "whatever's installed."

## Core Data / SwiftData in-memory store

For any test touching persistence, configure an in-memory persistent
store/container scoped specifically to the test target rather than the real
on-disk store. It's the same "fake, not mock, fast, isolated" property as
`fake_cloud_firestore` in Flutter:

```swift
let container = try ModelContainer(
    for: Item.self,
    configurations: ModelConfiguration(isStoredInMemoryOnly: true)
)
```

For Core Data, use an `NSPersistentContainer` configured with
`NSInMemoryStoreType` in test setup instead of the real store description.
