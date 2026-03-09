# CLAUDE.md

Primer iOS SDK — Universal Checkout SDK for Primer's payment platform. iOS 13.0+ (CheckoutComponents: iOS 15.0+), Swift 6.0+.

See @PrimerSDK.podspec for current version.

## Code Quality

### SwiftFormat (CI-enforced, auto-fixes on commit)
Config: `BuildTools/.swiftformat` (`--swift-version 5.9`).

```bash
swiftformat <file1.swift> <file2.swift> --config BuildTools/.swiftformat
```

### SwiftLint
Config: `Debug App/.swiftlint.yml`. Key limits: line 150, file 500/800, function body 60/100, cyclomatic 12/20.

```bash
swiftlint lint --fix --config "Debug App/.swiftlint.yml"
swiftlint lint --config "Debug App/.swiftlint.yml"
```

Before committing, run code quality checks on changed files:
```bash
swiftformat <file.swift> --config BuildTools/.swiftformat
swiftlint lint --fix --config "Debug App/.swiftlint.yml"
swiftlint lint --config "Debug App/.swiftlint.yml"
```

## Swift Coding Style

Coding style rules are in `.claude/rules/coding-style.md` — automatically loaded when working with `*.swift` files.

## Building and Testing

First, find an available simulator:
```bash
xcrun simctl list devices available
```

Pick a recent iPhone simulator (e.g., `iPhone 16`). Omit the OS version to use the latest installed:

```bash
# Build Debug App
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "Debug App" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  build

# Run all SDK unit tests
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  test

# Run specific test class
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16" \
  -testPlan "UnitTestsTestPlan" \
  -only-testing:"Tests/SomeClassTests" \
  test
```

## UI Verification

The `ios-simulator` MCP server (configured in `.mcp.json`) provides simulator tools. For UI changes, build the Debug App, then use MCP tools to boot the simulator, launch the Debug App (bundle ID: `com.primerapi.PrimerSDKExample`), navigate to the affected screen, and take screenshots to verify visually.

## Commit & PR Conventions

- **Conventional Commits**: `fix:`, `feat:`, `chore:`, `refactor:`, `ci:`, `docs:`, `test:`, `perf:`
- Aim for ~50 char subject lines and ~72 char body lines, but prioritize clarity over strict limits
- Sentence-case, imperative mood: `fix: Add retry logic for polling`
- PR template (`.github/pull_request_template.md`) requires Jira ticket (`ACC-XXXX`)

## Context Rules

- Architecture, error handling, and public API patterns: `.claude/rules/architecture.md` (loaded when working in Sources)
- Testing patterns, mocks, and utilities: `.claude/rules/testing.md` (loaded when working in Tests)
- Accessibility and CheckoutComponents patterns: `.claude/rules/accessibility.md`, `.claude/rules/checkout-components.md` (loaded when working in CheckoutComponents)
- Localization rules: `.claude/rules/localization.md` (loaded when working with *.strings files)

## Localization

CheckoutComponents localization files: `Sources/PrimerSDK/Resources/CheckoutComponentsLocalizable/{LANG}.lproj/CheckoutComponentsStrings.strings`

When compacting a conversation, always preserve the list of modified files, test commands, and current task context.
