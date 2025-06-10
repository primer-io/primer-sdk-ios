# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the Primer iOS SDK, a payment integration SDK that provides:
- Universal Checkout UI (Drop-in solution)
- Headless Checkout (API-driven solution)
- ComposableCheckout (SwiftUI component-based solution, iOS 15+)

The SDK supports iOS 13.1+ and can be integrated via CocoaPods or Swift Package Manager.

## Build and Development Commands

### Building the SDK

**CocoaPods Integration:**
```bash
bundle install
cd Debug\ App
bundle exec pod install
# Open PrimerSDK.xcworkspace in Xcode
```

**Swift Package Manager:**
```bash
# Open Package.swift in Xcode or use the SPM scheme
```

### Running Tests

**Unit Tests (SPM):**
```bash
bundle exec fastlane test_sdk
# Or in Xcode: Product > Test with scheme "PrimerSDKTests"
```

**Unit Tests (CocoaPods):**
```bash
bundle exec fastlane tests
# Or in Xcode: Product > Test with scheme "PrimerSDKTests" in workspace
```

**Debug App Tests:**
```bash
bundle exec fastlane test_debug_app
```

### Linting

SwiftLint is configured and runs automatically during Xcode builds. Configuration is in `Debug App/.swiftlint.yml`.

```bash
# Run SwiftLint manually from Debug App directory:
cd "Debug App"
swiftlint
# Or use Xcode's build phase which runs SwiftLint automatically
```

**SwiftLint Configuration:**
- **Line Length**: Warning at 150 characters (ignores function declarations, comments, interpolated strings, URLs)
- **Included**: `../Sources` directory
- **Excluded**: Third-party code (`../Sources/PrimerSDK/Classes/Third Party/PromiseKit`)
- **Type Names**: 3-40 characters (excludes generic type "T")
- **Identifier Names**: 3-40 characters (excludes "i" for loops and "id")
- **Disabled Rules**: `superfluous_disable_command`, `type_body_length`

**Common Violations to Avoid:**
- Lines longer than 150 characters - break into multiple lines
- Force try (`try!`) and force cast (`as!`) - use safe alternatives with guard statements
- Short identifier names (< 3 characters) except for allowed exceptions

### Building Debug App

```bash
# Build for simulator with CocoaPods
bundle exec fastlane build_cocoapods

# Build with SPM
bundle exec fastlane build_spm
```

## Architecture

### SDK Structure

The SDK has three main integration approaches:

1. **Drop-in (Traditional)**: `Sources/PrimerSDK/Classes/Core/Primer/`
   - Entry point: `Primer.swift`
   - Uses UIKit-based views
   - Delegate pattern: `PrimerDelegate`

2. **Headless**: `Sources/PrimerSDK/Classes/Core/PrimerHeadlessUniversalCheckout/`
   - Entry point: `PrimerHeadlessUniversalCheckout.swift`
   - API-driven, no UI
   - Delegate pattern: `PrimerHeadlessUniversalCheckoutDelegate`

3. **ComposableCheckout (New)**: `Sources/PrimerSDK/Classes/ComposableCheckout/`
   - Entry point: `PrimerCheckout.swift` (SwiftUI)
   - Component-based architecture
   - Uses modern DI container system

### Dependency Injection

The SDK uses two DI systems:

1. **Legacy DI**: `DependencyContainer` in `DependencyInjection.swift`
   - Used by Drop-in and Headless approaches
   - Simple property wrapper based system

2. **Modern DI**: `DIContainer` in `ComposableCheckout/Core/DI/`
   - Used by ComposableCheckout
   - Async/await based with health checks
   - SwiftUI environment integration

### Key Components

- **Analytics**: Event tracking system in `Core/Analytics/`
- **Networking**: API client in `Services/Network/PrimerAPIClient.swift`
- **Payment Services**: Various payment method integrations
- **Tokenization**: PCI-compliant card data handling in `PCI/`
- **3DS**: 3D Secure handling via external dependency

### Payment Method Architecture

Payment methods follow a consistent pattern:
- Tokenization components handle the payment flow
- View models manage UI state
- Managers coordinate between components
- Each payment method can have headless and/or UI implementations

### Testing

- Unit tests are in `Tests/` directory
- Tests use mocks extensively (see `Tests/Utilities/Mocks/`)
- Test utilities include JWT factory, SDK session helpers

### Important Notes

- Always check for existing payment method implementations before creating new ones
- The SDK supports multiple Package.swift variants for different feature sets (3DS, Klarna, NolPay, Stripe)
- Design tokens are managed separately in the `DesignTokens/` directory
- The current branch (`bn/feature/stepByStepDI`) appears to be working on DI improvements