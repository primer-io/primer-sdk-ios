# PrimerSDK iOS - Project Overview

## Purpose
PrimerSDK is Primer's official Universal Checkout iOS SDK that enables iOS applications to integrate payment processing capabilities. The SDK provides:

- Universal Checkout UI for payment experiences
- Support for multiple payment methods (Apple Pay, PayPal, Klarna, ACH, cards, etc.)
- 3DS 2.0 handling across processors for SCA compliance
- Payment method storage for recurring/repeat payments
- PCI compliance without redirecting customers
- Dynamic payment method configuration without code changes

## Target Platforms
- **Minimum iOS Version**: iOS 13.1+
- **Swift Version**: Swift 5.3+
- **Default Localization**: English (en)

## Tech Stack

### Primary Languages
- Swift (main language)
- Ruby (build tooling via Fastlane/CocoaPods)

### Build System & Dependencies
- **Swift Package Manager (SPM)**: Primary package management
- **CocoaPods**: Alternative package management (v1.15.0)
- **Fastlane**: CI/CD and automation tooling
- **Bundle**: Ruby dependency management

### Key Dependencies
- **Primer3DS**: 3D Secure 2.0 implementation (from primer-sdk-3ds-ios, version 2.4.4+)
- **IQKeyboardManagerSwift**: Keyboard management (Debug App only)
- **Various payment processor SDKs**: Klarna, Stripe, NolPay, iPay88 (optional)

### Development Tools
- **SwiftFormat**: Code formatting (installed via Homebrew)
- **Git hooks**: Pre-commit formatting automation
- **Danger**: PR automation and checks
- **SonarQube**: Code quality analysis

### Integration Methods
- CocoaPods installation
- Swift Package Manager
- Manual framework integration

## Repository Structure
- **Sources/PrimerSDK/**: Main SDK source code
- **Debug App/**: Demo application for testing SDK features
- **Tests/**: Unit and integration tests
- **BuildTools/**: SwiftFormat configuration and git hooks
- **Scripts/**: Utility scripts
- **fastlane/**: Fastlane automation configuration
- **Report Scripts/**: Reporting utilities

## Main Branch
- Default branch: `master`
- Development workflow: Feature branches merged to master via PRs
