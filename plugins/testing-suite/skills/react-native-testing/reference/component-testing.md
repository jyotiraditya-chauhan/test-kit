# Component Testing with React Native Testing Library

Table of contents:
- [Setup](#setup)
- [Query priority](#query-priority)
- [Async state and interaction](#async-state-and-interaction)
- [Snapshot caution](#snapshot-caution)

## Setup

Official install path, run from the project root:

```
npx expo install jest-expo jest @types/jest --dev
npx expo install @testing-library/react-native --dev
```

For a plain React Native CLI project without Expo, install the same
`@testing-library/react-native` package but use the `react-native` Jest
preset instead of `jest-expo`:

```json
{
  "jest": {
    "preset": "react-native"
  }
}
```

For Expo (managed or bare), the preset is `jest-expo`:

```json
{
  "jest": {
    "preset": "jest-expo"
  }
}
```

`scripts/detect_stack.sh` reports which preset, if any, is already
configured. Match it; do not switch presets on an existing project.
`jest-expo/universal` also exists (runs the same suite across iOS/
Android/web/Node with per-platform snapshots) -- it's a real, current
option but changes snapshot behavior in a way that could surprise an
existing project, so only propose it if the user specifically wants
multi-platform coverage, not as a silent default upgrade.

## Query priority

React Native Testing Library (RNTL) is the React Native analogue of React
Testing Library, and shares the same philosophy: query the way a real user
or an accessibility service would, not by internal implementation detail.

Preferred order:
1. `getByRole` (with `name` where the component sets an accessible name)
2. `getByText` / `getByPlaceholderText` / `getByDisplayValue`
3. `getByTestId` — last resort, only when no accessible query reasonably
   applies (a bare `View` used purely as a layout container, for example)

```tsx
import { render, screen, fireEvent } from '@testing-library/react-native';
import { LoginButton } from './LoginButton';

it('calls onPress when tapped', async () => {
  const onPress = jest.fn();
  await render(<LoginButton onPress={onPress} />);
  await fireEvent.press(screen.getByRole('button', { name: /log in/i }));
  expect(onPress).toHaveBeenCalledTimes(1);
});
```

On `@testing-library/react-native` v14+ (current stable), `render`,
`renderHook`, `fireEvent`, and `act` all return Promises and must be
awaited, as shown above -- an un-awaited call can leave assertions
racing the update it depends on. Older versions (pre-v14) are
synchronous and don't need the `await`. Match whatever major version is
already installed per Step 1; don't force an upgrade to add `await`
calls to an existing test suite that hasn't migrated.

## Async state and interaction

Never wrap an assertion after an async state change in a raw `setTimeout`
or an unawaited promise. Use `waitFor` or the `findBy*` query variants,
and wrap state-triggering interactions in `act()` when RNTL doesn't already
do so for you (`fireEvent` and `userEvent` do this automatically; a manual
store dispatch or timer advance does not).

```tsx
it('shows the loaded profile name after fetch resolves', async () => {
  await render(<ProfileScreen userId="42" />);
  expect(await screen.findByText('Ada Lovelace')).toBeTruthy();
});
```

This is the single most common source of RN test flakiness: an assertion
that runs before the async update it depends on has actually landed. If
`scripts/detect_stack.sh` or the audit turns up existing tests using
`setTimeout`-based waits, flag it, don't silently propagate the pattern
into new tests.

## Snapshot caution

Full-component snapshot tests are cheap to write and expensive to
maintain: they fail on any unrelated markup change and get rubber-stamped
with `--ci=false -u` without being read. Prefer explicit assertions on the
specific text, role, or prop that matters. Reserve snapshots for small,
visually stable, low-churn presentational components, and treat a snapshot
diff as something to actually read, not to auto-accept.
