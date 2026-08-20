# Native Module and Expo SDK Mocking

Table of contents:
- [What jest-expo already mocks](#what-jest-expo-already-mocks)
- [Mocking a custom or unmocked native module](#mocking-a-custom-or-unmocked-native-module)
- [Testing the delegation, not the native code](#testing-the-delegation-not-the-native-code)

## What jest-expo already mocks

`jest-expo` auto-mocks most Expo SDK native modules out of the box —
things like `expo-clipboard`, `expo-location`, `expo-notifications` come
with working fake implementations already wired into the Jest environment.
For these, write the test as if the module just works, and assert on your
own code's behavior around it (loading state, error handling, what gets
rendered), not on the native module internals.

Plain React Native CLI projects without `jest-expo` do not get this for
free — Expo SDK modules aren't relevant there, but the same pattern
applies to community native modules (`react-native-camera`, and similar):
mock at the module boundary, not deeper.

## Mocking a custom or unmocked native module

When a native module isn't auto-mocked (a custom native module, or an
Expo module jest-expo doesn't cover), add a mock file in a `mocks/`
directory matching the native module's name, e.g. `mocks/ExpoClipboard.ts`
for a module registered as `ExpoClipboard`:

```ts
// mocks/ExpoClipboard.ts
export default {
  getStringAsync: jest.fn(async () => 'mocked clipboard content'),
  setStringAsync: jest.fn(async () => true),
};
```

Wire it into Jest config so imports of the real native module resolve to
the mock during tests:

```json
{
  "jest": {
    "preset": "jest-expo",
    "moduleNameMapper": {
      "^expo-clipboard$": "<rootDir>/mocks/ExpoClipboard.ts"
    }
  }
}
```

For Expo modules specifically, `npx expo-modules-test-core
generate-ts-mocks` can auto-generate iOS-side mocks (requires
`sourcekitten` installed separately); Android-side mocks still need to be
written by hand. Only reach for this generator when hand-writing the mock
is genuinely nontrivial — most JS-facing mocks are a handful of async fake
functions and don't need it.

## Testing the delegation, not the native code

The native module itself is out of scope — it isn't JS, and this skill
doesn't write native (Swift/Kotlin) tests. What's in scope is your code's
delegation to it: does the component call the right method with the right
arguments, does it handle the async resolution and rejection paths
correctly.

```tsx
import * as Clipboard from 'expo-clipboard';

jest.mock('expo-clipboard');

it('copies the share link when the copy button is pressed', async () => {
  render(<ShareLinkButton link="https://example.com/x" />);
  fireEvent.press(screen.getByRole('button', { name: /copy link/i }));
  await waitFor(() =>
    expect(Clipboard.setStringAsync).toHaveBeenCalledWith(
      'https://example.com/x'
    )
  );
});

it('shows an error state if the clipboard write fails', async () => {
  (Clipboard.setStringAsync as jest.Mock).mockRejectedValueOnce(
    new Error('permission denied')
  );
  render(<ShareLinkButton link="https://example.com/x" />);
  fireEvent.press(screen.getByRole('button', { name: /copy link/i }));
  expect(await screen.findByText(/couldn't copy/i)).toBeTruthy();
});
```

This is boundary-only mocking applied to native modules specifically: the
component's own logic runs for real, only the native call underneath it is
faked.
