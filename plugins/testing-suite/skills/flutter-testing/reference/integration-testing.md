# Integration Testing

Table of contents:
- [What this layer is](#what-this-layer-is)
- [Basic pattern](#basic-pattern)
- [When Patrol is needed](#when-patrol-is-needed)
- [Scope: reserve for critical flows](#scope-reserve-for-critical-flows)

## What this layer is

`integration_test` (bundled with the Flutter SDK, successor to the older
`flutter_driver`) runs the full app end-to-end on a real device or
emulator. There is no separate "E2E tool" the way web has Playwright or
Cypress as a distinct category — `integration_test`, together with Patrol
where needed, fills that role for Flutter. This is the slowest, most
expensive layer, and by design should have the fewest tests.

## Basic pattern

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('user can log in and reach the home screen', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
    await tester.enterText(find.byKey(const Key('password_field')), 'secret123');
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home_screen')), findsOneWidget);
  });
}
```

Run with `flutter test integration_test/` (only when the user has opted
into running/verifying tests — see Step 7 of SKILL.md) — this launches a
real app instance, unlike widget tests which never leave the simulated
test environment.

## When Patrol is needed

Plain `integration_test` cannot reach native-OS-level interactions outside
the Flutter widget tree: OS permission dialogs, biometric prompts, native
payment sheets, notification interaction. The community package `patrol`
layers on top of `integration_test` specifically to handle these. Only
introduce it if the flow under test genuinely needs one of these
native-level interactions, or if the project already depends on it (check
`scripts/detect_stack.sh`'s output) — don't add it as a default dependency
for an ordinary in-app flow that plain `integration_test` already covers.

## Scope: reserve for critical flows

Reserve integration tests for revenue-critical or otherwise
irreversible-if-broken flows: login, checkout/payment, onboarding. This is
the most expensive layer by a wide margin — smallest test count by design.
See [reference/ci-and-distribution.md](ci-and-distribution.md) for the
recommended proportion relative to unit/widget/golden tests, and for why
these specifically warrant macOS CI runners (for iOS) while every other
layer runs on cheaper Linux runners.
