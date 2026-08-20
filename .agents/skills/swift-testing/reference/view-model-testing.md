# Testing SwiftUI: View Model First, ViewInspector Second

Table of contents:
- [The core problem](#the-core-problem)
- [Recommended default: test the view model](#recommended-default-test-the-view-model)
- [Secondary option: ViewInspector](#secondary-option-viewinspector)
- [Async/await and Combine](#asyncawait-and-combine)

## The core problem

SwiftUI, by design, does not expose its view tree publicly. There is no
built-in API to walk into a `some View` and inspect its children, text
content, or modifiers the way you can inspect a rendered DOM in React or a
widget tree in Flutter. This is why SwiftUI testing looks structurally
different from the other platforms this plugin covers.

## Recommended default: test the view model

In a well-architected SwiftUI app (MVVM), the `ObservableObject`/
`@Observable` view model holds essentially all the logic and state that
drives what the view renders. Thoroughly unit-testing the view model, with
plain Swift Testing `@Test` functions and no rendering involved at all,
implicitly verifies the overwhelming majority of the view's actual
behavior, at unit-test speed, with none of SwiftUI's introspection
limitations. This is the same "extract and test the plain logic" pattern
used for Riverpod providers in Flutter and extracted data-fetching
functions in Next.js.

```swift
@Observable
final class LoginViewModel {
    var email = ""
    var errorMessage: String?

    func submit() {
        guard email.contains("@") else {
            errorMessage = "Enter a valid email"
            return
        }
        errorMessage = nil
        // ...
    }
}

@Test func submitRejectsInvalidEmail() {
    let vm = LoginViewModel()
    vm.email = "not-an-email"
    vm.submit()
    #expect(vm.errorMessage == "Enter a valid email")
}
```

When the target code is a view with logic embedded directly in its body
(no separate view model), propose extracting that logic into a testable
type as part of the test plan, rather than trying to test the view
directly.

## Secondary option: ViewInspector

`ViewInspector` adds runtime introspection into a SwiftUI view's structure
for more traditional-feeling assertions against a view's actual rendered
content. It requires conforming views to an `Inspectable`-style protocol.
Only reach for it when the project already uses it, or when the user
specifically needs to assert on view structure/content itself (not just the
view model driving it) and extraction isn't practical for that case.

## Async/await and Combine

Both Swift Testing and XCTest support `async` test functions natively:

```swift
@Test func fetchUserSucceeds() async throws {
    let user = try await service.fetchUser(id: "1")
    #expect(user.name == "Ada")
}
```

Combine publishers are typically tested by subscribing within the test and
collecting emitted values into an array to assert against.
