# Golden Test Conventions

Table of contents:
- [Scope: primitives, not screens](#scope-primitives-not-screens)
- [Basic pattern](#basic-pattern)
- [Flakiness causes and fixes](#flakiness-causes-and-fixes)
- [Updating goldens](#updating-goldens)

## Scope: primitives, not screens

Limit golden tests to design-system primitives and small, stable components:
a button, a card, a badge, an empty-state. Do NOT generate a golden test for
a full screen unless the user explicitly asks for one and accepts the
tradeoff. Full-screen goldens fail on every minor Flutter SDK bump, every
font update, and every unrelated layout tweak elsewhere on the screen, and
the failure gives almost no localized signal about what actually changed. A
golden for `PrimaryButton` or `ProductCard` is durable and cheap; a golden
of the entire checkout screen is a maintenance sinkhole.

## Basic pattern

```dart
testWidgets('PrimaryButton matches golden', (tester) async {
  await tester.pumpWidget(
    MaterialApp(home: PrimaryButton(label: 'Continue', onPressed: () {})),
  );
  await expectLater(
    find.byType(PrimaryButton),
    matchesGoldenFile('goldens/primary_button.png'),
  );
});
```

## Flakiness causes and fixes

- **Font rendering differences across machines/CI runners.** Bundle fonts
  explicitly into the test environment rather than relying on host defaults.
- **Device-pixel-ratio differences.** Pin DPR explicitly in the test:
  ```dart
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetDevicePixelRatio);
  ```
- **Unpinned locale/timezone in the widget under test.** Set explicit
  locale/`Directionality` in the pumped widget tree rather than relying on
  ambient defaults, if the widget's appearance depends on either.

## Updating goldens

Regenerate reference images with:

```
flutter test --update-goldens
```

Never run this to silence a failing golden without first confirming the
visual change was intentional. An unreviewed `--update-goldens` defeats the
entire point of the test.
