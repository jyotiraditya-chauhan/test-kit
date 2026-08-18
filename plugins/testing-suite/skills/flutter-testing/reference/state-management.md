# State Management Test Harness Patterns

Table of contents:
- [BLoC / Cubit](#bloc--cubit)
- [Riverpod](#riverpod)
- [Provider](#provider)
- [GetX](#getx)
- [Rule](#rule)

Detect the package from `pubspec.yaml` (`scripts/detect_stack.sh` does this)
before writing any business-logic test. The three patterns below are not
interchangeable — a BLoC-style test written against a Riverpod provider will
not compile.

## BLoC / Cubit

Use the `bloc_test` package. It tests the full *sequence* of emitted states,
which is the point of a state machine — strong for verifying explicit
transitions, more boilerplate than Riverpod.

```dart
blocTest<MyBloc, MyState>(
  'emits [Loading, Loaded] when FetchRequested is added',
  build: () => MyBloc(mockRepo),
  act: (bloc) => bloc.add(FetchRequested()),
  expect: () => [Loading(), Loaded(data)],
);
```

Mock the repository/service the bloc depends on with `mocktail`
(`class MockUserRepository extends Mock implements UserRepository {}`), not
the bloc itself.

## Riverpod

Use `ProviderContainer` with `overrides`. This runs completely headless — no
widget tree required — which is why Riverpod tests average 30-40% fewer
lines than the equivalent BLoC test for the same behavior.

```dart
final container = ProviderContainer(
  overrides: [userRepositoryProvider.overrideWithValue(mockRepo)],
);
addTearDown(container.dispose);

final result = await container.read(userProvider.future);
expect(result, expectedUser);
```

Always `addTearDown(container.dispose)` — a leaked container across tests is
a shared-mutable-state flakiness cause (see `verification.md`).

## Provider

`package:provider` resolves dependencies through `BuildContext`/
`InheritedWidget`, so isolating business logic from the widget tree for a
true unit test requires extra scaffolding — in practice this often becomes a
widget test where a pure unit test would otherwise suffice. If the project
already uses Provider, follow its existing pattern rather than introducing
Riverpod or BLoC as a second state-management library; note the added
friction in your test-plan step instead.

## GetX

Lower research depth here than the other three. `GetxController` methods are
generally testable as plain Dart via `Get.put`/`Get.find` in test setup, but
verify against the project's actual existing GetX test files first — if none
exist, ask before assuming a pattern.

## Rule

Never generate a BLoC-style test for a Riverpod provider or vice versa.
Never introduce a second state-management testing library into a project
that already has one in use — match what's there.
