# CLAUDE.md

Guidance for Claude Code (claude.ai/code) and other AI agents working in this repo.

## What this is

Primer iOS SDK — Universal Checkout SDK for Primer's payment platform. iOS 13.0+, Swift 5. This is the flagship iOS SDK.

See @PrimerSDK.podspec for the current version.

## Repo structure

The SDK is a modular codebase:

- `Modules/` — independently-scoped modules, each with its own podspec:
  - `PrimerFoundation`, `PrimerCore`, `PrimerNetworking`, `PrimerResources`,
    `PrimerUI`, `PrimerStepResolver`, `PrimerBDCCore`, `PrimerBDCEngine`
- `Sources/PrimerSDK/` — umbrella SDK (`Classes/` has `Core`, `Services`, `Data Models`,
  `User Interface`, `PCI`, `BackendDrivenCheckout`, `Extensions & Utilities`, `Error Handler`)
- `Tests/` — unit/integration tests for the SDK
- `Debug App/` — example/host app used for manual + UI testing (bundle ID `com.primerapi.PrimerSDKExample`)
- `Packages/`, `Package*.swift` — SPM manifests (vanilla + optional integrations: 3DS, Klarna, NolPay, Stripe)
- Podspecs: `PrimerSDK.podspec` (umbrella) + one per module

**Release-managed — don't hand-edit:**
- `Sources/PrimerSDK/Classes/version.swift` — bumped by commitizen on release (`.cz.toml`), together with the podspecs.

## Setup & run

Open `PrimerSDK.xcworkspace`. On first clone and after switching branches, install pods — `Pods/` is gitignored, so the build fails without it:

```bash
bundle install
cd "Debug App" && bundle exec pod install && cd ..
```

Find an available simulator, then build the Debug App. CI pins `iPhone 17 Pro` on iOS 26.2 (`fastlane/Fastfile`); match it locally when you can:

```bash
xcrun simctl list devices available

xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "Debug App" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  build
```

For UI changes: build the Debug App, boot a simulator, launch the app, navigate to the affected screen, and verify with screenshots.

## Tests

Unit tests run via the `PrimerSDKTests` scheme; test plans live in `Debug App/Tests/`
(`UnitTestsTestPlan.xctestplan`, `DebugAppTestPlan.xctestplan`).

```bash
# All unit tests
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  test

# Single test class
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 17 Pro" \
  -testPlan "UnitTestsTestPlan" \
  -only-testing:"Tests/SomeClassTests" \
  test
```

## Acceptance gates (must pass before merge)

Danger runs on every PR (`Dangerfile.swift`) and is the main gate:

- **Conventional PR title** — Danger hard-fails titles that don't start with a conventional
  prefix (`fix`, `feat`, `chore`, `ci`, `refactor`, `docs`, `perf`, `test`, `build`, `revert`, `style`).
- **SwiftLint** — Danger lints changed files inline against `Debug App/.swiftlint.yml`; the only
  custom rule is `line_length: 150` (warning), the rest are SwiftLint defaults.
- **SwiftFormat** — CI-enforced, config `BuildTools/.swiftformat` (`--swift-version 5.3`).
- **Unit tests** green.
- **SonarCloud** — coverage / quality gate enforced server-side (no threshold in the repo).

Run quality checks on changed files before committing:

```bash
swiftformat <file.swift> --config BuildTools/.swiftformat
swiftlint lint --fix --config "Debug App/.swiftlint.yml"
swiftlint lint --config "Debug App/.swiftlint.yml"
```

## Conventions & guardrails

- **Conventional Commits**: `fix:`, `feat:`, `chore:`, `refactor:`, `ci:`, `docs:`, `test:`, `perf:`.
  Sentence-case, imperative subjects (~50 chars): `fix: Add retry logic for polling`.
- **PRs** use `.github/pull_request_template.md` and require a Jira ticket (`CHKT-XXXX`).
- **Access control**: prefer `public` for public API; don't spell out the default `internal`.
  For internal API that must cross module boundaries, use `@_spi(PrimerInternal) public` and
  consume it with `@_spi(PrimerInternal) import PrimerFoundation` (etc.) — not plain `public`.
- Prefer the shortest, clearest code; omit unneeded keywords.
- **Localization**: when adding a new string, add it to all supported languages and translate it.

## Where to find more

`README.md`, `Contributing.md`, the PR template in `.github/`, and the `Makefile`.
Per-module details live alongside each module under `Modules/`.

## CheckoutComponents (not yet on `master`)

**CheckoutComponents is not merged into `master` yet.** It lives on the
`bn/feature/checkout-components` branch and targets **iOS 15+**. When working on it, check
out that branch — its own `CLAUDE.md` files are the source of truth:

- `CLAUDE.md` (root, on that branch) — adds CheckoutComponents build/test/localization notes
- `Sources/PrimerSDK/Classes/CheckoutComponents/CLAUDE.md` — full CheckoutComponents guide
- `.claude/rules/*` (on that branch) — architecture, testing, accessibility, coding-style,
  checkout-components, localization rules

Summary of what CheckoutComponents is, for context:

- A modern, **slot-based SwiftUI** payment checkout framework with exact **Android API parity**,
  using async/await and composable views with `@ViewBuilder` section slots.
- **Entry points**: `PrimerCheckout` (managed SwiftUI modal), `PrimerCheckoutSession` +
  `.primerCheckoutSession(_:onCompletion:)` (composable/inline), `PrimerCheckoutPresenter` (UIKit).
- **Composable views**: `PrimerCardForm`, `PrimerPaymentMethods`, `PrimerVaultedPaymentMethods` —
  each exposes `@ViewBuilder` slots and resolves its session from the environment.
- **Observable sessions** (`PrimerCardFormSession`, `PrimerSelectionSession`) bridge internal
  scope `AsyncStream<State>` into `@Published` state; **`*Defaults`** namespaces provide default
  slot bodies and per-field building blocks for recomposition. Scope protocols are **internal**.
- **Internals**: custom actor-based DI container, Clean Architecture layers
  (Domain/Data/Presentation/Core/Navigation), state-driven navigation over `AsyncStream`,
  a rules-based validation system, and a `PrimerCheckoutTheme` design-token system (no per-field
  styling structs).

Until the merge lands, the branch files above are authoritative; this section is a pointer/summary.

---

When compacting a conversation, always preserve the list of modified files, test commands, and current task context.
