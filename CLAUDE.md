# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Primer iOS SDK - A comprehensive payment integration SDK providing multiple integration approaches:
- **Drop-in**: Universal Checkout UI (traditional UIKit, iOS 13.1+)
- **Headless**: API-driven solution without UI
- **ComposableCheckout**: SwiftUI component-based solution (iOS 15+)
- **CheckoutComponents**: Newest scope-based API with exact Android parity (iOS 15+)

## Build and Development Commands

### Initial Setup

```bash
# CocoaPods setup
bundle install
cd Debug\ App
bundle exec pod install
# Open PrimerSDK.xcworkspace in Xcode

# Swift Package Manager
# Open Package.swift directly in Xcode
```

### Running Tests

```bash
# Unit tests via SPM
bundle exec fastlane test_sdk

# Unit tests via CocoaPods
bundle exec fastlane tests

# Debug app tests
bundle exec fastlane test_debug_app

# Run specific test in Xcode
# Select test in navigator, then Cmd+U
```

### Linting

```bash
# Manual SwiftLint (from Debug App directory)
cd "Debug App"
swiftlint

# Auto-fix SwiftLint issues
swiftlint --fix --format

# SwiftLint runs automatically during Xcode builds
```

**SwiftLint Key Rules:**
- Line length: 150 chars (warnings)
- Identifier names: 3-40 chars (exceptions: "i", "id", "T")
- No force unwrapping (`!`) or force casting (`as!`)
- Excluded: `Third Party/PromiseKit`

### Building

```bash
# Debug app with CocoaPods
bundle exec fastlane build_cocoapods

# Debug app with SPM
bundle exec fastlane build_spm
```

## Architecture Overview

### Integration Approaches

1. **Drop-in** (`Classes/Core/Primer/`)
   - Entry: `Primer.swift` → `Primer.shared.showUniversalCheckout()`
   - Delegate: `PrimerDelegate`
   - Full UI provided, minimal customization

2. **Headless** (`Classes/Core/PrimerHeadlessUniversalCheckout/`)
   - Entry: `PrimerHeadlessUniversalCheckout.swift`
   - Delegate: `PrimerHeadlessUniversalCheckoutDelegate`
   - No UI, complete control
   - RawDataManager for direct payment processing

3. **ComposableCheckout** (`Classes/ComposableCheckout/`)
   - Entry: `ComposablePrimer.presentCheckout()` (UIKit) or `PrimerCheckout()` (SwiftUI)
   - Scope-based architecture with `PaymentMethodProtocol`
   - Component customization via `@ViewBuilder`
   - Modern DI with actor-based container

4. **CheckoutComponents** (`Classes/CheckoutComponents/`) - **COMPLETED**
   - Entry: `CheckoutComponentsPrimer.presentCheckout()` (UIKit) or `PrimerCheckout()` (SwiftUI)
   - Exact Android API parity with scope-based architecture
   - Scopes: `PrimerCheckoutScope`, `PrimerCardFormScope`, `PrimerSelectCountryScope`, `PrimerPaymentMethodSelectionScope`
   - AsyncStream state management with reactive updates
   - Full UI customization per component with @ViewBuilder patterns
   - Layered architecture: Presentation → Interactors → Repositories → Network
   - Comprehensive validation system with rules-based validation

### Dependency Injection Systems

**Legacy DI** (Drop-in/Headless):
```swift
@Dependency private var apiClient: PrimerAPIClientProtocol
```

**Modern DI** (ComposableCheckout/CheckoutComponents):
```swift
// Actor-based async container
let service = try await diContainer.resolve(ServiceType.self)

// Registration with retention policies
await container.register(ServiceType.self, .singleton) { 
    ServiceImplementation() 
}
```

### Payment Method Implementation Patterns

**Legacy Pattern:**
```
PrimerPaymentMethod → Manager → TokenizationComponent → ViewModel → Completion
```

**Modern Pattern:**
```
PaymentMethodProtocol → Scope Protocol → ViewModel (Scope Implementation) → SwiftUI View
```

### Key Services

- **PrimerAPIClient**: Network layer with retry logic
- **AnalyticsService**: Event tracking (privacy-first)
- **PrimerHeadlessUniversalCheckout.RawDataManager**: Direct card tokenization
- **TokenizationService**: PCI-compliant payment processing
- **ClientSessionService**: Session management and caching

### Data Flow

1. **Client Token**: Backend creates, passed to SDK
2. **Configuration**: Fetched using client token
3. **Payment Methods**: Loaded based on configuration
4. **Selection**: User picks payment method
5. **Data Collection**: SDK collects payment details
6. **Tokenization**: Convert to payment token
7. **Completion**: Token returned via delegate/completion

## Common Development Tasks

### Adding a New Payment Method

**For Legacy (Drop-in/Headless):**
1. Create in `Core/PrimerHeadlessUniversalCheckout/Payment Methods/`
2. Implement `PrimerHeadlessUniversalCheckoutPaymentMethodTokenizationDelegate`
3. Add UI in `User Interface/TokenizationViewControllers/` if needed
4. Register in `PaymentMethodTokenizationFactory`
5. Add to `PrimerPaymentMethodType` enum

**For Modern (ComposableCheckout/CheckoutComponents):**
1. Create directory structure: `PaymentMethods/NewMethod/`
2. Define scope protocol extending base scope
3. Implement `PaymentMethodProtocol` with associated scope type
4. Create ViewModel implementing the scope
5. Build SwiftUI views with customization points
6. Register in DI container
7. Add validation rules if needed

**For CheckoutComponents Specifically:**
1. Create scope protocol with state and update methods
2. Implement DefaultScope class with AsyncStream state management
3. Create screen views with computed properties to avoid compilation timeouts
4. Add validation rules to `ValidationService` and `RulesFactory`
5. Use proper layered architecture: Scope → Interactor → Repository
6. Ensure exact Android API parity for cross-platform consistency

### Working with Different SDK Variants

The SDK supports multiple Package.swift files for different features:
- `Package.swift` - Standard with 3DS
- `Package.Klarna.swift` - Includes Klarna
- `Package.NolPay.swift` - Includes NolPay
- `Package.Stripe.swift` - Includes Stripe

### Debugging

1. Enable verbose logging:
   ```swift
   PrimerSettings.debugOptions.logger = PrimerLogging.shared.logger
   ```

2. Check analytics events:
   ```swift
   // Events logged to console when debugging enabled
   ```

3. Use Charles Proxy for network inspection

4. Common issues:
   - Missing client token → Check backend integration
   - Payment fails → Check payment method configuration
   - UI not showing → Verify view controller presentation
   - 3DS issues → Ensure URL schemes configured
   - Card validation failing → Check Luhn algorithm implementation in CardValidationRules.swift
   - Card input not responding → Verify ValidationService is properly resolved from DI container
   - Cursor position issues → Check cursor restoration logic in CardNumberTextField coordinator

### Testing Approach

- Unit tests: Extensive mocking with protocols
- Integration tests: Use test client tokens
- UI tests: Manual testing via Debug App
- Payment method tests: Mock tokenization responses

### Important Files

- `PrimerSettings.swift`: Global configuration
- `PrimerError.swift`: Error definitions
- `PrimerTheme.swift`: UI customization
- `PrimerPaymentMethodType.swift`: Supported payment methods
- `Debug App/`: Test application for development

**CheckoutComponents Key Files:**
- `PrimerCheckout.swift`: Main SwiftUI entry point
- `CheckoutComponentsPrimer.swift`: UIKit integration wrapper
- Scope protocols: `PrimerCardFormScope.swift`, `PrimerSelectCountryScope.swift`, etc.
- Default implementations: `DefaultCardFormScope.swift`, `DefaultCheckoutScope.swift`
- Validation system: `ValidationService.swift`, `RulesFactory.swift`, `CardValidationRules.swift`
- Input components: `CardNumberInputField.swift`, `ExpiryDateInputField.swift`, etc.
- Navigation system: `CheckoutNavigator.swift`, `CheckoutCoordinator.swift`, `CheckoutRoute.swift`
- Navigation utilities: `PaymentMethodConverter.swift`, `NavigationAnimationConfig.swift`

**Critical Implementation Details:**

**Card Number Input Field (`CardNumberInputField.swift`):**
- Production-ready UITextField wrapper with SwiftUI integration
- Proper deletion functionality (backspace, selection deletion)
- Automatic card number formatting with spaces (4242 4242 4242 4242)
- Cursor position management that restores correct position after formatting
- Card network detection (Visa, Mastercard, Amex, etc.) with visual indicators
- Debounced validation (0.5s delay) to avoid constant validation during typing
- Comprehensive debug logging for troubleshooting validation issues

**Validation System (`CardValidationRules.swift`):**
- **Fixed Luhn Algorithm**: Corrected implementation that properly validates test cards
- Position-based digit doubling (every second digit from right)
- Mathematical optimization: `(digit * 2) % 9` with special case handling for digit 9
- Validates card number format, length, and check digit
- Integration with ValidationService and caching system for performance

### Security Considerations

- Never log sensitive payment data
- All card data must go through PCI-compliant components
- Use `PrimerCardNumberFieldView` for card input
- Client tokens are short-lived and safe to expose
- Payment tokens are one-time use

### Platform Requirements

- iOS 13.1+ (Drop-in, Headless)
- iOS 15.0+ (ComposableCheckout, CheckoutComponents)
- Xcode 13.0+
- Swift 5.3+
- CocoaPods 1.10+ or Swift Package Manager

## Key Architectural Decisions

1. **Multiple Integration Approaches**: Flexibility for different merchant needs
2. **Scope-Based API**: Matches Android for cross-platform consistency
3. **Actor-Based DI**: Thread-safe dependency management for SwiftUI
4. **AsyncStream State**: Reactive programming without Combine dependency
5. **Protocol-Oriented**: Extensive use of protocols for testability
6. **Modular Payment Methods**: Each payment method is self-contained

## Development Workflow

1. Create feature branch from `master`
2. Implement changes following existing patterns
3. Run SwiftLint: `swiftlint --fix --format`
4. Run tests: `bundle exec fastlane test_sdk`
5. Test in Debug App with real payment flows
6. Update CLAUDE.md if architecture changes
7. Create PR with detailed description

## CheckoutComponents Implementation Status - COMPLETED ✅

The CheckoutComponents framework has been fully implemented with:

### Core Features Implemented ✅
- **Scope-based architecture** with exact Android API parity
- **AsyncStream state management** for reactive updates
- **Comprehensive validation system** with rules-based validation
- **Layered architecture** (Presentation → Interactors → Repositories)
- **Full UI customization** via @ViewBuilder patterns

### All Scopes Completed ✅
- `PrimerCheckoutScope`: Main navigation and state management
- `PrimerCardFormScope`: Card payment form with 15 update methods
- `PrimerSelectCountryScope`: Country selection with search
- `PrimerPaymentMethodSelectionScope`: Payment method grid/list

### Technical Achievements ✅
- **SwiftUI Compilation Fixes**: Broke down complex expressions into computed properties
- **Type Safety**: Proper protocol conformance and type erasure with AnyView
- **Validation Rules**: Complete validation system with EmailRule, ExpiryDateRule, etc.
- **Input Components**: All form fields with proper validation and formatting
- **Card Number Input Field**: Production-ready with proper deletion, cursor management, and validation
- **Luhn Algorithm Validation**: Correct implementation that validates test cards (4242424242424242)
- **Error Handling**: Comprehensive error display and state management
- **Navigation System**: Complete state-driven navigation with 6 navigation files, NO Combine usage
- **AsyncStream Navigation**: Navigation events via AsyncStream instead of Combine publishers
- **Cross-Scope Integration**: Proper navigation integration between all scopes and screens

### Architecture Patterns Used ✅
- **Scope Protocol Pattern**: Each scope defines its interface and customization points
- **Default Implementation Pattern**: DefaultScope classes implement business logic
- **Repository Pattern**: HeadlessRepositoryImpl handles SDK integration
- **Interactor Pattern**: Business logic separation from presentation
- **Reactive State Management**: AsyncStream for state updates
- **Navigation Coordinator Pattern**: State-driven navigation with CheckoutCoordinator and CheckoutNavigator
- **Route-Based Navigation**: NavigationRoute protocol with enum-based route definitions
- **Environment-Based Navigation**: SwiftUI Environment integration for navigation dependency injection

### Build Status ✅
- All compilation errors resolved
- SwiftLint compliant
- No type-checking timeouts
- Card number input field fully functional
- Validation system working correctly (test card 4242424242424242 passes)
- Navigation and UI interactions working properly
- Ready for Debug App testing and production use

### Recent Fixes (Latest Session)
- **Card Number Input Field**: Fixed deletion functionality, cursor management, and text formatting
- **Luhn Algorithm**: Corrected validation logic that was incorrectly failing valid test cards
- **Navigation**: Added global cancel button and proper dismissal handling
- **UI Polish**: Updated payment method selection to modern card design

The implementation provides a complete, production-ready checkout experience with full customization capabilities while maintaining exact parity with the Android SDK API. All major components are now fully functional and tested.