# Firebase / Firestore Fakes

Table of contents:
- [Why fakes, not mocks](#why-fakes-not-mocks)
- [fake_cloud_firestore](#fake_cloud_firestore)
- [firebase_auth_mocks](#firebase_auth_mocks)
- [Security rules testing](#security-rules-testing)
- [When to use the real emulator instead](#when-to-use-the-real-emulator-instead)

## Why fakes, not mocks

Firebase SDKs need a real device/emulator connection to function normally,
which is wrong for a fast unit/widget test. The community-standard fix is
FAKES: working in-memory re-implementations of the real API surface, not
mocks in the strict test-double sense (they behave correctly, they're just
not production-grade).

## fake_cloud_firestore

```dart
final firestore = FakeFirebaseFirestore();
// pass firestore anywhere a real FirebaseFirestore instance is expected
await firestore.collection('users').doc('u1').set({'name': 'Ada'});
final doc = await firestore.collection('users').doc('u1').get();
expect(doc.data()!['name'], 'Ada');
```

Data persists in memory only, scoped to the instance. Use `.dump()` to
inspect the fake's current state while debugging a failing test.

## firebase_auth_mocks

```dart
final auth = MockFirebaseAuth(mockUser: MockUser(uid: 'u1', email: 'a@b.com'));
```

Simulates sign-in state and the `authStateChanges`/`userChanges` streams.
Can inject exceptions on specific auth operations to test error-handling
paths:

```dart
final auth = MockFirebaseAuth(
  signInWithCredentialException: FirebaseAuthException(code: 'wrong-password'),
);
```

Use this to cover the required error/exception-path case for any
auth-dependent unit under test.

## Security rules testing

Combine `fake_cloud_firestore` with `firebase_auth_mocks` to verify a given
user, per the project's actual deployed security rules string, is or isn't
allowed to read/write a given document. Only attempt this if the project
already has a rules-testing convention in place, or the user explicitly asks
for it in the elicitation step — it's an integration-level concern, not a
default for every Firestore-touching unit test.

## When to use the real emulator instead

Fakes are for unit/widget-level speed. The Firebase Local Emulator Suite
(`firebase emulators:start`) runs real Firestore/Auth/Functions logic
locally and catches things fakes structurally can't, such as real Firestore
query index requirements. Reserve it for a small set of true integration
tests, not the default for every test — same principle as
`golden-tests.md`'s guidance to keep the expensive layer small.
