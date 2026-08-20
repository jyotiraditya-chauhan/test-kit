# React Testing Library Philosophy

Table of contents:
- [Core principle](#core-principle)
- [Query priority](#query-priority)
- [user-event over fireEvent](#user-event-over-fireevent)
- [Testing hooks](#testing-hooks)

## Core principle

RTL deliberately makes it awkward or impossible to query for internal
component state, private methods, or child components in isolation. This is
by design: "the more your tests resemble the way your software is used, the
more confidence they can give you." Assert on rendered output and
user-observable behavior, never on internal state.

## Query priority

Most-to-least preferred:

1. `getByRole` (and other accessibility-tree queries like `getByLabelText`).
   This matches what a screen-reader/assistive-tech user would perceive, and
   doubles as a free accessibility check.
2. `getByText`, which matches visible text content.
3. `getByTestId`, a last resort for when no accessible or semantic query is
   possible. A testid has no meaning to a real user; overusing it is a mild
   anti-pattern smell worth flagging if the codebase leans on it heavily.

## user-event over fireEvent

Use `@testing-library/user-event` (it simulates a real browser event
sequence: focus, then keydown, then input, then blur) over the lower-level
`fireEvent` (which dispatches a single synthetic event) wherever interaction
realism matters, which is most of the time:

```tsx
import userEvent from '@testing-library/user-event';

test('submits the form on click', async () => {
  const user = userEvent.setup();
  render(<LoginForm onSubmit={onSubmit} />);

  await user.type(screen.getByLabelText(/email/i), 'a@b.com');
  await user.click(screen.getByRole('button', { name: /log in/i }));

  expect(onSubmit).toHaveBeenCalledWith({ email: 'a@b.com' });
});
```

## Testing hooks

Custom hooks are tested via `renderHook`, which mounts the hook in a
minimal test harness component and exposes `result.current` to assert
against; wrap state-updating calls in `act()`.

```tsx
const { result } = renderHook(() => useCounter());
act(() => result.current.increment());
expect(result.current.count).toBe(1);
```

On React 19, `act` is exported from `react` itself, not
`react-dom/test-utils` (which no longer exports it). RTL's own
`render`/`renderHook`/`fireEvent`/`user-event` already wrap this
correctly internally, so this only matters if a project has older,
hand-rolled test utilities importing `act` from the old path -- those
will break on a React 19 upgrade and need the import path updated.
