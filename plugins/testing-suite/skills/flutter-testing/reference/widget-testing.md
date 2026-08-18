# Widget Testing

Table of contents:
- [Core pattern](#core-pattern)
- [Finder strategy](#finder-strategy)
- [pump vs pumpAndSettle](#pump-vs-pumpandsettle)
- [Common interactions](#common-interactions)
- [Assert on observable output, not internal state](#assert-on-observable-output-not-internal-state)

## Core pattern

Render a single widget (or small widget tree) in a simulated environment —
no real device/emulator needed — via `WidgetTester`:

```dart
testWidgets('shows a success message after tapping submit', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: LoginForm(onSubmit: (_) async {})),
  );

  await tester.enterText(find.byKey(const Key('email_field')), 'a@b.com');
  await tester.tap(find.byKey(const Key('submit_button')));
  await tester.pumpAndSettle();

  expect(find.text('Success'), findsOneWidget);
});
```

## Finder strategy

Prefer, in this order:
1. `find.byKey` — stable and explicit, survives copy/text/localization changes.
2. `find.byType` — fine when only one instance of a type is expected in scope.
3. `find.text` — last resort; breaks the moment copy changes or the app is
   localized into a language your test didn't anticipate.

This mirrors React Testing Library's query priority (accessible/stable
queries first, text last) — assert on what makes the widget identifiable
and durable, not on incidental content.

## pump vs pumpAndSettle

- `tester.pump()` — advances exactly one frame. Use after an action whose
  effect is synchronous or completes within one frame.
- `tester.pump(duration)` — advances by a specific duration. Use for
  animations with a known, fixed length.
- `tester.pumpAndSettle()` — pumps repeatedly until there are no more
  pending frames (animations finished, futures resolved). Use after an
  action that triggers an animation or an async operation you need to wait
  out completely — but never as a substitute for correctly awaiting a
  specific future; an over-reliance on `pumpAndSettle` alone to paper over
  timing issues is a documented flakiness cause (see `reference/verification.md`
  and the fault-injection guidance in SKILL.md for how a non-deterministic
  test gets caught, not just avoided).

## Common interactions

```dart
await tester.tap(find.byKey(const Key('button')));
await tester.enterText(find.byKey(const Key('field')), 'hello');
await tester.drag(find.byType(ListView), const Offset(0, -300));
await tester.longPress(find.byKey(const Key('item')));
```

## Assert on observable output, not internal state

Widget tests are Flutter's analogue of React's component tests via Testing
Library, and should follow the same philosophy: assert on what a user
would actually see or interact with — rendered text, presence/absence of a
widget, an enabled/disabled control — not on a private field of the
`State` object. If a test needs to reach into private state to make an
assertion, that's usually a sign the behavior belongs in a unit test on an
extracted, directly-testable class instead (see
[reference/unit-testing.md](unit-testing.md) and
[reference/state-management.md](state-management.md)).
