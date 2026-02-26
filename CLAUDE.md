# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Primer iOS SDK - Official Universal Checkout SDK for Primer's payment platform. Supports iOS 13.0+ with Swift 5+.

## Code Quality

### SwiftLint
Configuration in `Debug App/.swiftlint.yml`:
- Line length: 150 (warning)
- File length: 500 (warning), 800 (error)
- Function body length: 60 (warning), 100 (error)
- Cyclomatic complexity: 12 (warning), 20 (error)
- Excluded: `Sources/PrimerSDK/Classes/Third Party/PromiseKit`

### SwiftFormat (CI-enforced, auto-fixes on commit)
Configuration in `BuildTools/.swiftformat` (`--swift-version 5.9`) — these rules run in CI and auto-fix via pre-commit hook:
`isEmpty`, `preferCountWhere`, `redundantExtensionACL`, `modifierOrder`, `consecutiveBlankLines`, `blankLineAfterImports`, `andOperator`, `elseOnSameLine`, `fileHeader`, `hoistPatternLet`, `leadingDelimiters`, `modifiersOnSameLine`, `preferKeyPath`, `redundantInternal`, `redundantReturn`, `sortImports`, `redundantOptionalBinding`, `redundantSelf`, `duplicateImports`, `conditionalAssignment`

### SwiftLint opt-in rules (CI warnings via Danger)
These opt-in rules are enabled in `Debug App/.swiftlint.yml` and surface as PR warnings:
`shorthand_optional_binding`, `implicit_return`, `empty_count`, `direct_return`, `redundant_type_annotation`, `final_test_case`, `contains_over_filter_count`, `first_where`, `redundant_self_in_closure`

### Running before commit
**Always run both tools on modified files before committing and fix all issues found.**

Auto-fix formatting (SwiftFormat) on specific files:
```bash
swiftformat <file1.swift> <file2.swift> --config BuildTools/.swiftformat
```

Auto-fix formatting on all sources:
```bash
swiftformat Sources/ --config BuildTools/.swiftformat
```

Lint with SwiftLint (reports warnings/errors to fix manually):
```bash
swiftlint lint --config "Debug App/.swiftlint.yml"
```

Auto-fix SwiftLint autocorrectable violations:
```bash
swiftlint lint --fix --config "Debug App/.swiftlint.yml"
```

## Swift Coding Style

Coding style rules are in `.claude/rules/coding-style.md` — automatically loaded when working with `*.swift` files.

## Architecture

### Entry Points
- **`Primer.swift`**: Main SDK singleton (`Primer.shared`)
  - Configure with `configure(settings:delegate:)`
  - Present checkout with `showUniversalCheckout(clientToken:)`
- **`PrimerDelegate.swift`**: Primary callback protocol for checkout lifecycle events

### Checkout Integration Approaches

1. **Drop-In UI (Universal Checkout)**
   - Location: `Sources/PrimerSDK/Classes/User Interface/Root/PrimerUniversalCheckoutViewController.swift`
   - Fully managed UI with minimal integration
   - Entry: `Primer.shared.showUniversalCheckout(clientToken:)`

2. **Headless**
   - Location: `Sources/PrimerSDK/Classes/Core/PrimerHeadlessUniversalCheckout/`
   - Custom UI with SDK payment logic
   - Entry: `PrimerHeadlessUniversalCheckout`

3. **CheckoutComponents (Modern - iOS 15+)**
   - Location: `Sources/PrimerSDK/Classes/CheckoutComponents/`
   - SwiftUI-based modular components with exact Android API parity
   - Scope-based architecture with full UI customization
   - SwiftUI Entry: `PrimerCheckout(clientToken: clientToken, primerSettings: primerSettings, primerTheme: primerTheme, scope: scopeClosure, onCompletion: onCompletion)`
   - UIKit Entry: `PrimerCheckoutPresenter.presentCheckout(clientToken:from:primerSettings:primerTheme:scope:completion:)` - UIKit-ready wrapper around SwiftUI
   - Key scopes: `PrimerCheckoutScope`, `PrimerCardFormScope`, `PrimerPaymentMethodSelectionScope`
   - Features: AsyncStream state observation, co-badged cards, dynamic billing address, built-in 3DS

### Core Structure
```
Sources/PrimerSDK/Classes/
├── Core/
│   ├── Primer/                          # Main SDK entry point and delegates
│   ├── PrimerHeadlessUniversalCheckout/ # Headless integration API
│   ├── 3DS/                             # 3D Secure integration
│   ├── Analytics/                       # Event tracking
│   ├── Payment Services/                # API communication
│   └── Models/                          # Core data models
├── CheckoutComponents/                  # Modern SwiftUI components (iOS 15+)
│   ├── Core/                            # Dependency injection container
│   ├── Scope/                           # Scope-based APIs
│   ├── PaymentMethods/                  # Payment method implementations
│   └── Internal/                        # Internal UI components
├── User Interface/                      # Drop-In UI components
│   ├── Root/                            # Universal Checkout ViewController
│   └── Components/                      # Reusable UI elements
├── Data Models/                         # API models and responses
├── Extensions & Utilities/              # Helper extensions
└── PCI/                                 # Tokenization and secure data handling
```

### Payment Flow
1. Generate client token from backend (create client session)
2. Initialize SDK with `Primer.shared.configure(delegate:)`
3. Present checkout UI or use headless/components
4. SDK handles tokenization, 3DS (if required), and payment processing
5. Receive result via `PrimerDelegate` callbacks

### 3D Secure Integration
- Wrapped around Netcetera SDK (via `primer-sdk-3ds-ios` dependency)
- Automatic handling for supported payment methods
- Environment-based configuration (non-production uses test certificates)

## Accessibility Integration (CheckoutComponents)

CheckoutComponents has comprehensive WCAG 2.1 Level AA accessibility support (VoiceOver, Dynamic Type, keyboard navigation, automated testing). All features are automatically applied.

### Quick Reference

**Key Patterns**:
- **Identifiers**: `checkout_components_{screen}_{component}_{element}` (snake_case, API contract)
- **Strings**: `a11y.` prefix in Localizable.strings (41 languages)
- **Fonts**: Use `PrimerFont` methods for automatic Dynamic Type scaling
- **Logging**: `logger.debug(message: "[A11Y] ...")` for debug-only accessibility logs

**Apply Accessibility (SwiftUI)**:
```swift
TextField("Label", text: $value)
    .accessibility(config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.CardForm.field,
        label: CheckoutComponentsStrings.a11y_label,
        hint: CheckoutComponentsStrings.a11y_hint,
        traits: [.isTextField]
    ))
```

**VoiceOver Announcements**:
```swift
// Resolve from DI container
let service: AccessibilityAnnouncementService = await container.resolve()

// Announce errors, state changes, layout changes, screen changes
service.announceError("Invalid card number")
```

**Keyboard Navigation**:
```swift
@FocusState private var focusedField: PrimerInputElementType?

TextField("Card Number", text: $cardNumber)
    .focused($focusedField, equals: .cardNumber)
    .onSubmit { focusedField = .expiry }
```

**Resources**: See `specs/001-checkout-components-accessibility/quickstart.md` for detailed integration guide and testing instructions.

## Debug App

Located in `Debug App/` directory:
- Two Xcode projects: `Primer.io Debug App.xcodeproj` (CocoaPods) and `Primer.io Debug App SPM.xcodeproj` (SPM)
- Use for manual testing of SDK features

## Building and Testing

### Workspace
The project uses `PrimerSDK.xcworkspace` which contains multiple schemes:
- **Debug App**: Main app for manual SDK testing (CocoaPods)
- **Debug App SPM**: Debug app using Swift Package Manager
- **PrimerSDKTests**: SDK unit tests
- **DebugAppTests**: Debug app tests
- **PrimerSDK**: The SDK framework itself

### Build Commands

**Build Debug App** (for manual testing):
```bash
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "Debug App" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
  build
```

**Run SDK Unit Tests**:
```bash
xcodebuild -workspace PrimerSDK.xcworkspace \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.6" \
  test
```

### Notes
- Use `xcrun simctl list devices available` to find available simulators
- iOS version may vary depending on installed Xcode version (check available simulators)
- The workspace resolves SPM dependencies automatically (Primer3DS)

## Distribution

### CocoaPods
```ruby
pod 'PrimerSDK'
```
Podspec: `PrimerSDK.podspec`
Current version defined in podspec (e.g., 2.41.1)

### Swift Package Manager
Add package: `https://github.com/primer-io/primer-sdk-ios.git`

## CI/CD

GitHub Actions workflows in `.github/workflows/`:
- `test-and-code-quality.yml`: Unit tests and code quality checks
- `build-test-upload.yml`: Build and upload to testing platforms
- `ui-tests.yml`: UI testing
- `pod_lint.yml`: CocoaPods validation
- `xcode-versions-build.yml`: Multi-version Xcode builds

### Version Updates
- Update `PrimerSDK.podspec` version
- Update `CHANGELOG.md`
- Tag release in git

## Important Notes

- **Minimum iOS version**: 13.0 (main SDK), 15.0 (CheckoutComponents)
- **Swift version**: 6.0+
- **3DS minimum iOS**: 13.0
- **Default test simulator**: iPhone 16 with iOS 18.4
- CheckoutComponents provides exact Android API parity for cross-platform consistency

## Active Technologies
- Swift 6.0+, Xcode 15+ + SwiftUI, UIKit (UIAccessibility APIs), existing CheckoutComponents DI framework (001-checkout-components-accessibility)
- N/A (accessibility metadata stored in memory only) (001-checkout-components-accessibility)
- Swift 6.0+ + SwiftUI (UI), existing SDK core (tokenization, polling, JWT decoding) (004-checkout-components-qr-code)
- N/A (no local persistence) (004-checkout-components-qr-code)

## Localization

### CheckoutComponents Translations
Localization files are located at: `Sources/PrimerSDK/Resources/CheckoutComponentsLocalizable/{LANG}.lproj/CheckoutComponentsStrings.strings`

### Armenian (hy) Translation Note
When translating strings to Armenian, do NOT write Armenian characters directly in the code/tool output as they may get corrupted. Instead, use a Python script with Unicode escape sequences:

```python
python3 << 'PYEOF'
# Armenian translations using Unicode escape sequences
translations = {
    "primer_ach_title": "\u0532\u0561\u0576\u056f\u0561\u0575\u056b\u0576 \u0570\u0561\u0577\u056b\u057e",  # Բdelays delays delays delays delays delays delays delays
    "primer_ach_button_continue": "\u0547\u0561\u0580\u0578\u0582\u0576\u0561\u056f\u0565\u056c",  # Delays delays delays delays delays
    # ... add more translations
}

import re
file_path = 'Sources/PrimerSDK/Resources/CheckoutComponentsLocalizable/hy.lproj/CheckoutComponentsStrings.strings'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

for key, value in translations.items():
    content = re.sub(f'"{key}" = "[^"]*";', f'"{key}" = "{value}";', content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
PYEOF
```

Common Armenian Unicode escape sequences:
- Բdelays delays delays delays delays delays delays delays = \u0532\u0561\u0576\u056f\u0561\u0575\u056b\u0576 \u0570\u0561\u0577\u056b\u057e
- Delays delays delays delays delays = \u0547\u0561\u0580\u0578\u0582\u0576\u0561\u056f\u0565\u056c
- Delays delays delays = \u0549\u0565\u0572\u0561\u0580\u056f\u0565\u056c
- Delays delays delays delays delays delays delays delays delays delays = \u0539\u0578\u0582\u0575\u056c\u0561\u057f\u057e\u0578\u0582\u0569\u0575\u0578\u0582\u0576
- Delays delays delays delays delays delays delays = \u0540\u0561\u0574\u0561\u0571\u0561\u0575\u0576 \u0565\u0574

## Recent Changes
- 004-checkout-components-qr-code: Added Swift 6.0+ + SwiftUI (UI), existing SDK core (tokenization, polling, JWT decoding)
- 001-checkout-components-accessibility: Added Swift 6.0+, Xcode 15+ + SwiftUI, UIKit (UIAccessibility APIs), existing CheckoutComponents DI framework
