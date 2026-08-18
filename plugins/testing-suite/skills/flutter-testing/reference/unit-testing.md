# Unit Testing

Table of contents:
- [Scope](#scope)
- [File convention](#file-convention)
- [Basic pattern](#basic-pattern)
- [Mocking a dependency](#mocking-a-dependency)

## Scope

Pure Dart logic — services, repositories, use-cases, formatters, view-model
logic that doesn't touch the widget tree. No Flutter framework dependency
required; these are plain `package:test` tests and the fastest, cheapest
layer. If the code under test imports `package:flutter/material.dart` only
for types and never actually builds a widget, it can usually still be unit
tested directly.

## File convention

`test/` mirrors `lib/` file-for-file:

```
lib/services/auth_service.dart  ->  test/services/auth_service_test.dart
```

`scripts/scaffold_test_file.sh lib/services/auth_service.dart` creates this
mirrored file (with the right package import already filled in) if it
doesn't already exist.

## Basic pattern

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/services/order_pricing_service.dart';

void main() {
  group('OrderPricingService.calculateTotal', () {
    late OrderPricingService service;

    setUp(() {
      service = OrderPricingService();
    });

    test('sums item prices with no discount', () {
      expect(service.calculateTotal([10, 20, 30]), 60);
    });

    test('returns zero for an empty list', () {
      expect(service.calculateTotal([]), 0);
    });

    test('applies a percentage discount', () {
      expect(service.calculateTotal([100], discountPercent: 20), 80);
    });
  });
}
```

## Mocking a dependency

Use `mocktail` (or the project's existing mocking library — see Step 1 of
SKILL.md) only when the unit under test has a real dependency to isolate,
never for a class with no external collaborators:

```dart
class MockUserRepository extends Mock implements UserRepository {}

test('returns the cached user when the repository throws', () async {
  final mockRepo = MockUserRepository();
  when(() => mockRepo.fetchUser(any())).thenThrow(NetworkException());

  final service = UserService(mockRepo, cache: FakeCache(seedUser: testUser));
  final result = await service.getUser('u1');

  expect(result, testUser);
  verify(() => mockRepo.fetchUser('u1')).called(1);
});
```
