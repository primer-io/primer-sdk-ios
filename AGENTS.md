# Repository Guidelines

## Project Structure & Module Organization
- Core SDK source lives in `Sources/PrimerSDK/Classes`, grouped by scopes (`Core`, `CheckoutComponents`, `User Interface`, `PCI`).
- Shared resources (localization, assets, JSON fixtures) sit in `Sources/PrimerSDK/Resources`.
- XCTest targets live under `Tests/`, mirroring feature areas (for example `Tests/Stripe`).
- Sample integration code is inside `Debug App/`, with CocoaPods and SPM variants for manual QA.
- Tooling and automation scripts are in `BuildTools/`, `Scripts/`, and `fastlane/`.

## Build, Test, and Development Commands
- `make hook` installs the SwiftFormat pre-commit hook defined in `BuildTools/.swiftformat`.
- `bundle install && cd Debug\ App && bundle exec pod install` prepares CocoaPods dependencies for the debug app.
- `bundle exec fastlane tests` runs the primary unit test suite via the `PrimerSDKTests` scheme on iPhone 16 simulator.
- `bundle exec fastlane test_sdk` executes the Swift Package test target with coverage output to `./test_output`.
- Open `PrimerSDK.xcworkspace` in Xcode to build the SDK or debug app interactively.

## Coding Style & Naming Conventions
- Swift files must format with SwiftFormat (pre-commit hook uses `BuildTools/.swiftformat` rules such as `modifierOrder` and `blankLineAfterImports`).
- SwiftLint enforces limits (`line_length: 150`, `function_body_length: 60/100`, `cyclomatic_complexity: 12/20`) via `Debug App/.swiftlint.yml`.
- Prefer descriptive type and identifier names (3–40 characters); `i` and `id` are the only short-name exceptions.
- Use four-space indentation and favor `camelCase` for methods/properties, `PascalCase` for types, and uppercase snake case for constants.

## Testing Guidelines
- Unit tests use XCTest; keep new tests beside the feature they cover (e.g., `Tests/Stripe` for Stripe-related flows).
- Name tests with intent-revealing suffices, e.g., `testHeadlessCheckoutEmitsToken()`.
- For coverage-aware runs or CI parity, invoke `bundle exec fastlane test_sdk --sim_version 18.4`.
- Ensure new payment flows include 3DS and error handling cases where applicable.

## Commit & Pull Request Guidelines
- Follow the repository convention of short, intent-focused commit prefixes (`feat:`, `fix:`, `chore:`, `ci:`) and write in imperative mood.
- Squash unrelated changes; keep commits scoped to a single concern.
- PRs should include a concise summary, linked Jira/GitHub issue, test evidence (`fastlane` output or screenshots for UI), and call out any config toggles.
- Request reviews from SDK maintainers and confirm localization or asset updates are reflected in `Resources/` when applicable.

## Security & Configuration Tips
- Never commit real client tokens, API keys, or Firebase credentials; use the demo endpoints from `fastlane/Fastfile` for local testing.
- When adding new payment integrations, verify sensitive logic stays within `Sources/PrimerSDK/Classes/PCI` and avoid logging PII.
