# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the official iOS SDK for Primer - a payment processing platform that provides Universal Checkout and payment method integrations. The SDK is built using Swift and supports iOS 13.0+.

## Architecture Overview

The SDK follows a layered architecture:

- **Core Layer** (`Sources/PrimerSDK/Classes/Core/`): Contains fundamental services and utilities
  - Analytics, logging, networking, caching
  - Payment services, 3DS handling
  - Primer main class and delegate protocols
  
- **Headless Universal Checkout** (`PrimerHeadlessUniversalCheckout/`): Composable payment components
  - Payment method managers (Klarna, ACH, NolPay, Banks)
  - Raw data managers for custom integrations
  - Vault management for stored payment methods
  
- **Data Models** (`Data Models/`): Core data structures for payment methods, client sessions, and responses

- **UI Components**: Native UI components for payment forms and checkout flows

- **Payment Method Integrations**: Separate modules for different payment providers (Klarna, Stripe, Apple Pay, etc.)

## Build System

The project uses both CocoaPods and Swift Package Manager:

- **CocoaPods**: Main integration method with `PrimerSDK.podspec`
- **Swift Package Manager**: Alternative integration via `Package.swift`
- **Xcode Workspace**: `PrimerSDK.xcworkspace` for development

## Development Commands

### Testing
```bash
# Run all SDK tests (Swift Package Manager)
bundle exec fastlane test_sdk

# Run debug app tests (CocoaPods)
bundle exec fastlane test_debug_app

# Run unit tests with specific simulator version
bundle exec fastlane test_sdk sim_version:18.2

# Run tests via workspace (legacy)
bundle exec fastlane tests

# Run UI tests
bundle exec fastlane ui_tests
```

### Building
```bash
# Build using CocoaPods integration
bundle exec fastlane build_cocoapods

# Build using Swift Package Manager
bundle exec fastlane build_spm

# Build and upload to Appetize for testing
bundle exec fastlane appetize_build_and_upload

# QA release build (uploads to LambdaTest and Firebase)
bundle exec fastlane qa_release
```

### Setup
```bash
# Install Ruby dependencies
bundle install

# Install CocoaPods dependencies (for Debug App)
cd "Debug App"
bundle exec pod install
```

### Code Quality
```bash
# Run Danger checks (PR validation)
bundle exec fastlane danger_check
```

## Key Files and Directories

- `Sources/PrimerSDK/Classes/Core/Primer/Primer.swift`: Main SDK entry point
- `Sources/PrimerSDK/Classes/Core/Primer/PrimerDelegate.swift`: Main delegate protocol
- `Sources/PrimerSDK/Classes/Core/PrimerHeadlessUniversalCheckout/`: Headless checkout components
- `Sources/PrimerSDK/Classes/Data Models/`: Core data models
- `Debug App/`: Example app for testing and development
- `Tests/`: Comprehensive test suite organized by feature

## Testing Structure

Tests are organized by feature areas:
- Unit tests for individual components in `Tests/Primer/`
- Payment method specific tests in `Tests/Klarna/`, `Tests/Stripe/`, `Tests/NolPay/`
- 3DS authentication tests in `Tests/3DS/`
- Integration tests for payment flows
- Mock implementations for external dependencies in `Tests/Utilities/Mocks/`
- Test plans: `DebugAppTestPlan.xctestplan` and `UnitTestsTestPlan.xctestplan`

### Test Organization
- Each payment method has its own test directory
- `Tests/Utilities/` contains shared test helpers and mocks
- Test targets defined in both `Package.swift` (SPM) and workspace (CocoaPods)

## Payment Method Integration

When adding new payment methods:
1. Create component in `PrimerHeadlessUniversalCheckout/Composable/`
2. Add manager in `Managers/Payment Method Managers/`
3. Define data models in `Data Models/`
4. Add corresponding tests in `Tests/`

## External Dependencies

Key external SDKs integrated:
- PrimerKlarnaSDK: Klarna payment method
- Primer3DS: 3D Secure authentication
- PrimerStripeSDK: Stripe payment methods
- PrimerNolPaySDK: NolPay digital wallet
- PrimerIPay88MYSDK: iPay88 payment gateway

## Development Notes

- The SDK supports both UI and headless integrations
- Payment methods can be integrated as native UI components or headless components
- The SDK handles tokenization, 3DS authentication, and payment processing
- Comprehensive analytics and logging throughout the payment flow
- Multi-language support with localized resources
- Extensive error handling and validation

## SDK Integration Types

The SDK supports two main integration patterns:

### Drop-In UI Integration
- Use `Primer.shared.configure(delegate: self)` to set up the main delegate
- Call `Primer.shared.showUniversalCheckout(clientToken: token)` to present UI
- Delegate receives callbacks via `PrimerDelegate` protocol

### Headless Integration  
- Use `PrimerHeadlessUniversalCheckout.current` singleton
- Set `delegate` and `uiDelegate` for different callback types
- Manually handle payment method selection and data collection
- More flexibility for custom UI implementations

## SDK Architecture Patterns

### Component-Based Architecture
- Payment methods are implemented as composable components
- Each payment method has its own manager, data models, and UI components
- Components can be headless (data-only) or include native UI

### Service Layer
- `PrimerAPIClient`: Handles all network communication
- `TokenizationService`: Manages payment method tokenization
- `VaultService`: Handles stored payment method operations
- `Analytics.Service`: Tracks events and user interactions

### Error Handling Strategy
- `PrimerError`: Main error type with detailed error codes
- `PrimerValidationError`: Field validation errors
- Extensions provide user-friendly error messages
- Comprehensive error reporting with diagnostic IDs

## Working with Different Package Managers

### Swift Package Manager (Recommended for Development)
- Faster build times and dependency resolution
- Use `Package.swift` as the main package definition
- Test target excludes payment method specific tests to avoid external SDK dependencies

### CocoaPods (Main Distribution Method)  
- Defined in `PrimerSDK.podspec`
- Includes all external payment method SDKs as dependencies
- Used by the Debug App for full integration testing
- Required for testing payment methods like Klarna, Stripe, etc.

## Important Development Considerations

- When adding new components, follow the existing architecture patterns
- All UI components should support both programmatic and storyboard initialization
- Payment method managers must implement `PrimerPaymentMethodManagerProtocol`
- Analytics events should be added for all user interactions
- Localization strings must be added to all supported languages
- External dependencies are managed through separate podspecs and xcframeworks