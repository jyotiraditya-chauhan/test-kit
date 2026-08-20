# E2E Testing: Maestro and Detox

Table of contents:
- [Default choice](#default-choice)
- [Maestro](#maestro)
- [Detox](#detox)
- [Testing pyramid for this layer](#testing-pyramid-for-this-layer)

## Default choice

Default to **Maestro** when a project has no E2E tooling yet — it needs no
in-repo package installation, drives the app through its accessibility
tree the way a real user would, and has built-in tolerance for the async
timing issues that make RN E2E tests flaky. This mirrors the same
low-friction-default reasoning react-testing uses for Playwright.

Use **Detox** instead when the project already has it configured
(`scripts/detect_stack.sh` reports a `detox` devDependency or a
`.detoxrc.js`/`.detoxrc.json` file), or when the user specifically wants
the lowest possible flake rate on a pure React Native app and is willing
to take on Detox's heavier native-level setup for it.

A common hybrid in mature codebases: Maestro for fast smoke coverage
across the whole app, Detox for a smaller set of deep regression flows on
the highest-risk paths. Only propose this split if the project's E2E
surface is large enough to justify running two tools.

## Maestro

Install (no `package.json` entry, no build config changes):

```
curl -fsSL "https://get.maestro.mobile.dev" | bash
```

Requires Java 17+ on the machine running it. Flows are plain YAML files,
typically under a `.maestro/` directory:

```yaml
# .maestro/login.yaml
appId: com.example.app
---
- launchApp
- tapOn: "Email"
- inputText: "user@example.com"
- tapOn: "Password"
- inputText: "correct-horse-battery-staple"
- tapOn: "Log in"
- assertVisible: "Welcome back"
```

Run with `maestro test .maestro/login.yaml`. Maestro auto-waits for
elements to appear/become interactive, which is why it tolerates RN's
async rendering and animation timing better than a naive record-and-replay
tool. Cross-platform: the same tool drives iOS, Android, and (for this
plugin's purposes) both Expo and plain RN CLI apps identically.

## Detox

Gray-box: written in JS/TS alongside the rest of the test suite, and
synchronizes with the JS thread, native run loop, network requests,
timers, and animations to minimize flakiness by design, at the cost of a
heavier setup — native module integration, Xcode/Gradle build config
changes, and a `.detoxrc.js` config tightly coupled to specific RN/Xcode
versions.

```js
// e2e/login.test.js
describe('Login flow', () => {
  beforeEach(async () => {
    await device.reloadReactNative();
  });

  it('logs in with valid credentials', async () => {
    await element(by.id('email-input')).typeText('user@example.com');
    await element(by.id('password-input')).typeText('correct-horse-battery-staple');
    await element(by.id('login-button')).tap();
    await expect(element(by.text('Welcome back'))).toBeVisible();
  });
});
```

For a genuinely looping animation that never settles (a spinner, a
continuous background effect), Detox's automatic synchronization can hang
waiting for it to finish. The escape hatch is
`device.disableSynchronization()` around just that interaction, re-enabled
immediately after.

## Testing pyramid for this layer

Roughly 70% unit tests (Jest + RNTL), 20% component/integration tests, 10%
E2E — this holds for React Native the same way it does for the other
platform skills. E2E is the right layer for a small number of
business-critical flows (login, checkout, onboarding), not for coverage of
individual components or screens; those belong in the component-testing
layer, which is faster and far less flaky by construction.
