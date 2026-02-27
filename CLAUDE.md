# CLAUDE.md

Primer iOS SDK — Universal Checkout SDK for Primer's payment platform. iOS 13.0+ (CheckoutComponents: iOS 15.0+), Swift 6.0+.

See @PrimerSDK.podspec for current version.

## Code Quality

### SwiftFormat (CI-enforced, auto-fixes on commit)
Config: `BuildTools/.swiftformat` (`--swift-version 5.9`). Rules: `isEmpty`, `preferCountWhere`, `redundantExtensionACL`, `modifierOrder`, `consecutiveBlankLines`, `blankLineAfterImports`, `andOperator`, `elseOnSameLine`, `fileHeader`, `hoistPatternLet`, `leadingDelimiters`, `modifiersOnSameLine`, `preferKeyPath`, `redundantInternal`, `redundantReturn`, `sortImports`, `redundantOptionalBinding`, `redundantSelf`, `duplicateImports`, `conditionalAssignment`

```bash
swiftformat <file1.swift> <file2.swift> --config BuildTools/.swiftformat
```

### SwiftLint
Config: `Debug App/.swiftlint.yml`. Key limits: line 150, file 500/800, function body 60/100, cyclomatic 12/20.

Opt-in rules (CI warnings via Danger): `shorthand_optional_binding`, `implicit_return`, `empty_count`, `direct_return`, `redundant_type_annotation`, `final_test_case`, `contains_over_filter_count`, `first_where`, `redundant_self_in_closure`

```bash
swiftlint lint --fix --config "Debug App/.swiftlint.yml"
swiftlint lint --config "Debug App/.swiftlint.yml"
```

Hooks auto-run SwiftFormat + SwiftLint --fix on every file edit. Before committing, verify no warnings remain:
```bash
swiftlint lint --config "Debug App/.swiftlint.yml"
```

## Swift Coding Style

Coding style rules are in `.claude/rules/coding-style.md` — automatically loaded when working with `*.swift` files.

## Building and Testing

```bash
# Build Debug App
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "Debug App" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
  build

# Run all SDK unit tests
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
  test

# Run specific test class
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
  -testPlan "UnitTestsTestPlan" \
  -only-testing:"Tests/SomeClassTests" \
  test
```

Use `xcrun simctl list devices available` to find simulators. iOS version may vary by Xcode version.

## UI Verification

The `ios-simulator` MCP server (configured in `.mcp.json`) provides simulator tools. For UI changes, build the Debug App, then use MCP tools to boot the simulator, launch the Debug App (bundle ID: `com.primerapi.PrimerSDKExample`), navigate to the affected screen, and take screenshots to verify visually.

## Commit & PR Conventions

- **Conventional Commits**: `fix:`, `feat:`, `chore:`, `refactor:`, `ci:`, `docs:`, `test:`, `perf:`
- Sentence-case, imperative mood: `fix: Add retry logic for polling`
- PR template (`.github/pull_request_template.md`) requires Jira ticket (`CHKT-XXXX`)

## Context Rules

- Architecture, error handling, and public API patterns: `.claude/rules/architecture.md` (loaded when working in Sources)
- Testing patterns, mocks, and utilities: `.claude/rules/testing.md` (loaded when working in Tests)
- Accessibility and CheckoutComponents patterns: `.claude/rules/accessibility.md`, `.claude/rules/checkout-components.md` (loaded when working in CheckoutComponents)
- Localization rules: `.claude/rules/localization.md` (loaded when working with *.strings files)

## Localization

CheckoutComponents localization files: `Sources/PrimerSDK/Resources/CheckoutComponentsLocalizable/{LANG}.lproj/CheckoutComponentsStrings.strings`

When compacting a conversation, always preserve the list of modified files, test commands, and current task context.
