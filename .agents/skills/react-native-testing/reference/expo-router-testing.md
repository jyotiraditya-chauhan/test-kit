# expo-router Testing

Table of contents:
- [The one hard rule: never test inside app/](#the-one-hard-rule-never-test-inside-app)
- [renderRouter](#renderrouter)
- [Custom matchers](#custom-matchers)
- [Deep links and initial URL](#deep-links-and-initial-url)

Only relevant when `scripts/detect_stack.sh` reports `expo-router` present.
Skip this file entirely for projects without it.

## The one hard rule: never test inside app/

expo-router treats every file inside the `app/` directory as a route
definition. A test file placed there gets picked up as a route by the
router itself, which breaks both the app and the test. Always put
route-level test files in `__tests__/` or a sibling directory outside
`app/`, importing the route module by its path.

## renderRouter

`renderRouter` from `expo-router/testing-library` renders a route within a
simulated file-based router, so navigation, params, and layout nesting all
behave as they would in the real app. It accepts three forms:

**Inline mock filesystem** — define routes directly in the test:

```tsx
import { renderRouter, screen } from 'expo-router/testing-library';

it('renders the profile screen for a given id', async () => {
  await renderRouter(
    {
      'app/_layout': () => null,
      'app/profile/[id]': require('../app/profile/[id]').default,
    },
    { initialUrl: '/profile/42' }
  );
  expect(screen.getByText(/profile 42/i)).toBeTruthy();
});
```

`renderRouter` is built on RNTL's `render`, so on `@testing-library/react-native`
v14+ it also returns a Promise and needs the `await` shown above — see
[component-testing.md](component-testing.md)'s RNTL v14+ note. Drop it
for a project on an older RNTL major.

**Array of route-name strings** — when only route presence/navigation
matters, not full component output:

```tsx
renderRouter(['index', 'profile/[id]'], { initialUrl: '/profile/42' });
```

**Fixture directory with overrides** — point at the real `app/` directory
on disk (read-only reference, the test file itself still lives outside
it), optionally overriding specific routes for the test:

```tsx
renderRouter('app', {
  initialUrl: '/settings',
});
```

## Custom matchers

`expo-router/testing-library` ships Jest matchers scoped to router state,
used after a `renderRouter` call:

```tsx
expect(router).toHavePathname('/profile/42');
expect(router).toHavePathnameWithParams('/profile/[id]?tab=posts');
expect(router).toHaveSegments(['profile', '[id]']);
expect(router).toHaveRouterState(/* expected state shape */);
```

Use these instead of manually inspecting router internals — they exist
specifically to avoid coupling tests to expo-router's internal state
shape.

## Deep links and initial URL

The `initialUrl` option simulates opening the app from a deep link or a
specific path, without an actual native linking event. Use it to test
that a route reads its params correctly, or that a guarded route redirects
when accessed directly (e.g. an auth-gated screen hit via deep link while
logged out):

```tsx
it('redirects to login when a protected route is opened while logged out', async () => {
  await renderRouter(
    { 'app/_layout': () => null, 'app/(protected)/settings': Settings },
    { initialUrl: '/settings' }
  );
  expect(router).toHavePathname('/login');
});
```
