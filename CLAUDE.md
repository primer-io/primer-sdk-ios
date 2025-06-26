# CLAUDE.md - Primer iOS SDK

This file provides comprehensive guidance for working with the Primer iOS SDK repository.

## Repository Overview

**Primer iOS SDK** - A production-ready payment integration SDK for iOS applications providing multiple integration approaches with comprehensive payment method support, security compliance, and cross-platform API consistency.

### Integration Approaches
- **Drop-in**: Complete Universal Checkout UI (traditional UIKit, iOS 13.1+)
- **Headless**: API-driven solution with no UI components (iOS 13.1+)
- **CheckoutComponents**: Modern SwiftUI scope-based solution with exact Android API parity (iOS 15+)

## Repository Structure

### `/Sources/PrimerSDK/` - Core SDK Implementation
Main SDK source code with three distinct integration patterns:

#### `Classes/Core/` - Legacy Integrations
- **Drop-in** (`Classes/Core/Primer/`): Full UI solution with `Primer.swift` entry point
- **Headless** (`Classes/Core/PrimerHeadlessUniversalCheckout/`): API-only integration
- **Payment Services** (`Classes/Core/Payment Services/`): Shared payment processing logic
- **Data Models** (`Classes/Data Models/`): Core business entities and API models
- **Services** (`Classes/Services/`): Infrastructure layer (networking, parsing)
- **User Interface** (`Classes/User Interface/`): UIKit components for Drop-in
- **PCI** (`Classes/PCI/`): Payment Card Industry compliant secure data handling

#### `Classes/CheckoutComponents/` - Modern SwiftUI Framework ✨
**Production-ready scope-based API matching Android exactly**
- **Entry Points**: `CheckoutComponentsPrimer.swift` (UIKit bridge), `PrimerCheckout.swift` (SwiftUI)
- **Architecture**: Scope-based with exact Android API parity
- **Key Features**: AsyncStream state management, full UI customization, co-badged cards
- **Scopes**: `PrimerCheckoutScope`, `PrimerCardFormScope`, `PrimerSelectCountryScope`, `PrimerPaymentMethodSelectionScope`
- **DI System**: Modern actor-based async dependency injection
- **Payment Methods**: Self-contained implementations with protocol-based architecture
- **Validation**: Comprehensive rules-based validation system
- **Navigation**: State-driven navigation with AsyncStream (no Combine dependency)

### `/Debug App/` - Development and Testing Application
Complete test application for SDK development and integration testing:
- **Sources/**: Debug app source code with comprehensive test scenarios
- **View Controllers**: `MerchantSessionAndSettingsViewController.swift` - main configuration screen
- **Model**: API request/response models for client session creation
- **Storyboards**: Complete UI for testing all SDK features
- **Integration Examples**: Working examples of all three integration approaches

### `/Tests/` - Test Suite
Comprehensive test coverage for all SDK components:
- **Unit Tests**: Extensive mocking with protocol-based testing
- **Integration Tests**: End-to-end payment flow testing
- **Mock Infrastructure**: Complete mock services for isolated testing

### Build Configuration Files
- **Package.swift**: Standard Swift Package Manager configuration with 3DS
- **Package.Klarna.swift**: Includes Klarna payment method
- **Package.NolPay.swift**: Includes NolPay integration
- **Package.Stripe.swift**: Includes Stripe integration
- **Podfile**: CocoaPods dependency management
- **Fastlane**: Automated build and test pipelines

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

### Integration Patterns

#### 1. Drop-in Integration
- **Entry**: `Primer.swift` → `Primer.shared.showUniversalCheckout()`
- **Delegate**: `PrimerDelegate`
- **Pattern**: Complete UI provided, minimal customization
- **Target**: Traditional UIKit apps requiring minimal integration effort

#### 2. Headless Integration
- **Entry**: `PrimerHeadlessUniversalCheckout.swift`
- **Delegate**: `PrimerHeadlessUniversalCheckoutDelegate`
- **Pattern**: No UI, complete control over user experience
- **RawDataManager**: Direct payment processing for custom UI implementations

#### 3. CheckoutComponents Integration ✨
- **Entry**: `CheckoutComponentsPrimer.presentCheckout()` (UIKit) or `PrimerCheckout()` (SwiftUI)
- **Pattern**: Scope-based architecture with exact Android API parity
- **Customization**: Full component customization via `@ViewBuilder`
- **DI**: Modern actor-based container with AsyncStream state management

### Dependency Injection Systems

**Legacy DI** (Drop-in/Headless):
```swift
@Dependency private var apiClient: PrimerAPIClientProtocol
```

**Modern DI** (CheckoutComponents):
```swift
// Actor-based async container
let service = try await diContainer.resolve(ServiceType.self)

// Registration with retention policies
await container.register(ServiceType.self, .singleton) { 
    ServiceImplementation() 
}
```

### Payment Method Architecture

**Legacy Pattern** (Drop-in/Headless):
```
PrimerPaymentMethod → Manager → TokenizationComponent → ViewModel → Completion
```

**Modern Pattern** (CheckoutComponents):
```
PaymentMethodProtocol → Scope Protocol → ViewModel (Scope Implementation) → SwiftUI View
```

### Key Services and Infrastructure

- **PrimerAPIClient**: Network layer with automatic retry logic and exponential backoff
- **AnalyticsService**: Privacy-first event tracking and device information collection
- **PrimerHeadlessUniversalCheckout.RawDataManager**: Direct card tokenization for custom UIs
- **TokenizationService**: PCI-compliant payment processing with secure data handling
- **ClientSessionService**: Session management and configuration caching
- **ValidationService**: Comprehensive input validation with country-specific rules
- **ThemeService**: UI customization and consistent styling across components

## Data Flow and Payment Processing

### Standard Payment Flow
1. **Client Token**: Backend creates secure client token, passed to SDK
2. **Configuration**: SDK fetches payment configuration using client token
3. **Payment Methods**: Available methods loaded based on merchant configuration
4. **User Selection**: Customer chooses payment method from available options
5. **Data Collection**: SDK securely collects payment details via PCI-compliant components
6. **Tokenization**: Payment data converted to secure payment token
7. **Completion**: Payment token returned via delegate/completion handlers
8. **Backend Processing**: Merchant backend processes payment using token

### Billing Address Collection
Billing address collection is **backend-controlled** via checkout modules:
- Backend includes `BILLING_ADDRESS` checkout module in configuration response
- SDK automatically displays billing address fields when module is present
- No frontend configuration required - works across all integration approaches
- `PostalCodeOptions` specify which address fields to collect

## CheckoutComponents Implementation Status - COMPLETED ✅

The CheckoutComponents framework is **production-ready** with comprehensive features:

### Core Features Implemented ✅
- **Scope-based architecture** with exact Android API parity
- **AsyncStream state management** for reactive updates without Combine dependency
- **Comprehensive validation system** with rules-based validation and country-specific logic
- **Layered architecture** (Presentation → Interactors → Repositories → Network)
- **Full UI customization** via @ViewBuilder patterns and theme support
- **Self-contained integration** independent from Drop-in/Headless systems

### All Scopes Completed ✅
- `PrimerCheckoutScope`: Main navigation and payment orchestration
- `PrimerCardFormScope`: Card payment form with 15 update methods and co-badged card support
- `PrimerSelectCountryScope`: Country selection with search and filtering
- `PrimerPaymentMethodSelectionScope`: Payment method grid/list presentation

### Production Features ✅
- **Card Number Input Field**: Production-ready with proper deletion, cursor management, and formatting
- **Luhn Algorithm Validation**: Correct implementation that validates test cards (4242424242424242)
- **Co-badged Card Support**: Multiple network detection and user selection
- **3DS Authentication**: Complete 3DS flow with pure Swift protocol integration
- **Error Handling**: Comprehensive error display and state management with Android parity
- **Navigation System**: Complete state-driven navigation with 6 navigation files
- **Cross-Scope Integration**: Proper navigation integration between all scopes and screens
- **Country Selection**: Complete SwiftUI country selector with 250+ countries and search
- **Billing Address**: Production-ready billing address collection with field reordering
- **Validation Synchronization**: Real-time validation state communication between components

## Common Development Tasks

### Adding a New Payment Method

**For Legacy (Drop-in/Headless):**
1. Create in `Core/PrimerHeadlessUniversalCheckout/Payment Methods/`
2. Implement `PrimerHeadlessUniversalCheckoutPaymentMethodTokenizationDelegate`
3. Add UI in `User Interface/TokenizationViewControllers/` if needed
4. Register in `PaymentMethodTokenizationFactory`
5. Add to `PrimerPaymentMethodType` enum

**For CheckoutComponents:**
1. Create directory structure: `PaymentMethods/NewMethod/`
2. Define scope protocol extending base scope with associated types
3. Implement `PaymentMethodProtocol` with associated scope type
4. Create ViewModel implementing the scope with AsyncStream state management
5. Build SwiftUI views with customization points using @ViewBuilder
6. Register in DI container with appropriate retention policy
7. Add validation rules to `ValidationService` and `RulesFactory`

### Working with Different SDK Variants

The SDK supports multiple Package.swift configurations:
- `Package.swift` - Standard with 3DS authentication
- `Package.Klarna.swift` - Includes Klarna Buy Now Pay Later
- `Package.NolPay.swift` - Includes NolPay integration
- `Package.Stripe.swift` - Includes Stripe payment processing

### Debugging Common Issues

1. **Enable verbose logging**:
   ```swift
   PrimerSettings.debugOptions.logger = PrimerLogging.shared.logger
   ```

2. **Check analytics events**: Events logged to console when debugging enabled

3. **Use Charles Proxy** for network inspection and API debugging

4. **Common issues and solutions**:
   - Missing client token → Check backend integration and API key
   - Payment fails → Verify payment method configuration in dashboard
   - UI not showing → Check view controller presentation and constraints
   - 3DS issues → Ensure URL schemes configured and `is3DSSanityCheckEnabled: false` for debug/simulator
   - Card validation failing → Check Luhn algorithm implementation in CardValidationRules.swift
   - Card input not responding → Verify ValidationService properly resolved from DI container
   - Cursor position issues → Check cursor restoration logic in CardNumberTextField coordinator
   - CheckoutComponents 3DS failures → Ensure app respects `PrimerSettings.current.debugOptions.is3DSSanityCheckEnabled`
   - CocoaPods file organization → Files in subdirectories may need manual Xcode project inclusion
   - Missing showcase views → Ensure all showcase files are added to Debug App target in Xcode
   - Validation state mismatch → Check field-level validation communicates with form scope via `updateValidationState()`
   - Country picker issues → Verify CountryCode data integration and search functionality
   - Error message inconsistency → Use ErrorMessageResolver for centralized error formatting
   - Test card validation during typing → Ensure unknown networks allowed with Luhn validation

### Testing Approach

- **Unit tests**: Extensive mocking with protocol-based architecture
- **Integration tests**: Use test client tokens from Primer dashboard
- **UI tests**: Manual testing via Debug App with comprehensive test scenarios
- **Payment method tests**: Mock tokenization responses and validate data flow
- **Cross-platform testing**: Ensure Android API parity in CheckoutComponents

## Important Files and Locations

### Core Configuration
- `PrimerSettings.swift`: Global SDK configuration and feature flags
- `PrimerError.swift`: Comprehensive error definitions and diagnostics
- `PrimerTheme.swift`: UI customization and theming system
- `PrimerPaymentMethodType.swift`: Supported payment methods enumeration

### CheckoutComponents Key Files
- `PrimerCheckout.swift`: Main SwiftUI entry point for CheckoutComponents
- `CheckoutComponentsPrimer.swift`: UIKit integration wrapper with modal presentation and 3DS support
- **Scope protocols**: `PrimerCardFormScope.swift`, `PrimerSelectCountryScope.swift`, etc.
- **Default implementations**: `DefaultCardFormScope.swift`, `DefaultCheckoutScope.swift`, `DefaultSelectCountryScope.swift`
- **Validation system**: `ValidationService.swift`, `RulesFactory.swift`, `CardValidationRules.swift`, `BillingAddressValidationRules.swift`
- **Input components**: `CardNumberInputField.swift`, `ExpiryDateInputField.swift`, `CountryInputField.swift`, etc.
- **Navigation system**: `CheckoutNavigator.swift`, `CheckoutCoordinator.swift`, `CheckoutRoute.swift`
- **Error handling**: `ErrorMessageResolver.swift`, `CheckoutComponentsStrings.swift`
- **Country infrastructure**: `SelectCountryScreen.swift` with comprehensive country database integration

### Debug App Configuration
- `Debug App/Sources/View Controllers/MerchantSessionAndSettingsViewController.swift`: Main configuration screen
- `Debug App/Sources/View Controllers/CheckoutComponentsShowcase/`: Complete showcase implementation
- `Debug App/Sources/Model/CreateClientToken.swift`: API request models
- **UI Features**: Billing address collection switch, payment method selection, test scenario configuration
- **CheckoutComponents Showcase**: Comprehensive demo with 18 example components across 4 categories

## Security and Compliance

### PCI Compliance
- All card data processed through PCI-compliant components
- No sensitive payment data stored or logged
- Use `PrimerCardNumberFieldView` for secure card input
- Client tokens are short-lived and safe for frontend exposure
- Payment tokens are one-time use and cryptographically secure

### Security Best Practices
- Never log sensitive payment data in any environment
- All payment data flows through designated secure channels
- Use provided secure input components for card data collection
- Client tokens have limited scope and short expiration
- Payment tokens cannot be reverse-engineered to reveal card data

## Platform Requirements and Compatibility

- **iOS 13.1+** (Drop-in, Headless integrations)
- **iOS 15.0+** (CheckoutComponents - requires SwiftUI 3.0+)
- **Xcode 13.0+** with Swift 5.3+
- **CocoaPods 1.10+** or **Swift Package Manager**
- **Deployment targets**: Support for iOS 13.1+ ensures broad device compatibility


## Key Architectural Decisions

1. **Multiple Integration Approaches**: Provides flexibility for different merchant needs and technical requirements
2. **Scope-Based API**: CheckoutComponents matches Android SDK for true cross-platform consistency
3. **Actor-Based DI**: Thread-safe dependency management optimized for SwiftUI and async operations
4. **AsyncStream State**: Reactive programming without external dependencies like Combine
5. **Protocol-Oriented Design**: Extensive use of protocols for testability and modularity
6. **Modular Payment Methods**: Each payment method is self-contained with clear boundaries
7. **Security-First Architecture**: PCI compliance built into the foundation

## Recent Updates and Improvements

### Billing Address Collection Implementation ✅
- **Backend-controlled configuration**: Billing address collection configured via checkout modules
- **Debug App integration**: Added billing address collection switch with proper guidance
- **Cross-integration support**: Works automatically across Drop-in, Headless, and CheckoutComponents
- **Documentation**: Comprehensive setup guide in `BILLING_ADDRESS_SETUP.md`

### CheckoutComponents Production Readiness ✅
- **Complete implementation**: All scopes, validation, navigation, and UI components
- **3DS authentication**: Working properly in debug and production environments
- **Performance optimization**: Efficient DI container and state management
- **Error handling**: Comprehensive error scenarios with user-friendly messaging

### CheckoutComponents Recent Enhancements (June 26, 2025) ✅

#### Card Validation System Overhaul
- **Fixed validation disconnect**: Resolved critical issue where card validation errors displayed but payment button remained enabled
- **Synchronized validation states**: Field-level and form-level validation now communicate in real-time
- **Test card compatibility**: Fixed validation for cards like "9120 0000 0000 0006" during typing
- **Unknown network handling**: Improved Luhn validation for cards with unknown networks (13-19 digits)

#### 3DS Authentication Complete Implementation
- **Pure Swift protocol integration**: Added 3DS delegate methods to CheckoutComponentsPrimer
- **Proper flow separation**: Tokenization completes, 3DS handled at payment level
- **Centralized error messaging**: Added 3DS-specific error messages in CheckoutComponentsStrings
- **Full Drop-in parity**: Complete 3DS functionality while maintaining CheckoutComponents architecture

#### Country Selection and Billing Address Improvements
- **Complete country database**: Implemented 250+ countries with dial codes and comprehensive search
- **Diacritic-insensitive search**: Enhanced country filtering with accent-insensitive matching
- **Billing address field reordering**: Changed to Drop-in layout (Country → Address → Postal → State)
- **Automatic country selection**: Improved UX with proper scope-based navigation for sheet presentation

#### Android Parity Error Messaging System
- **Centralized error resolution**: Implemented ErrorMessageResolver for consistent error formatting
- **BillingAddressValidationRules**: Complete validation rules matching Android error structure
- **Extended RulesFactory**: Added billing address validation rule creation methods
- **Localized error strings**: Added missing localized strings for all validation scenarios

#### Country Picker Infrastructure
- **Real CountryCode data integration**: Replaced placeholder with production country data
- **Search functionality**: Added comprehensive search with filtering capabilities
- **Bug fixes**: Resolved string interpolation issues showing literal placeholders
- **UI improvements**: Enhanced country picker presentation and dismissal

### CheckoutComponents Showcase Implementation ✅
- **Comprehensive Demo Suite**: 18 demo components showcasing CheckoutComponents flexibility
- **Four Categories**: Layout Configurations, Styling Variations, Interactive Features, Advanced Customization
- **Modal Integration**: Seamless SwiftUI modal presentation from main Debug App
- **File Organization**: Clean separation with 18 dedicated showcase files in organized directory structure
- **Production Examples**: Real-world styling patterns including corporate, modern, colorful, and dark themes
- **Interactive Demonstrations**: Live state management, validation flows, and co-badged card support
- **Advanced Layouts**: Custom screen layouts including split-screen, carousel, stepped, and floating designs

## Memories and Conventions

- **CC** in messages refers to **CheckoutComponents**
- **Production-ready**: CheckoutComponents is fully functional and tested
- **API parity**: CheckoutComponents maintains exact parity with Android SDK APIs
- **Security-first**: All payment processing follows PCI compliance requirements
- **SwiftUI-native**: CheckoutComponents built with SwiftUI best practices and modern iOS patterns
- **Showcase Integration**: CheckoutComponents showcase accessible via purple "Show Component Showcase" button in InlineSwiftUICheckoutTestView
- **File Organization**: Showcase files organized in `/Debug App/Sources/View Controllers/CheckoutComponentsShowcase/` directory

## CheckoutComponents Showcase Structure

The showcase implementation demonstrates CheckoutComponents flexibility through:

### Directory Structure
```
Debug App/Sources/View Controllers/CheckoutComponentsShowcase/
├── CheckoutComponentsShowcaseView.swift          # Main showcase view
├── ShowcaseEnums.swift                           # Section definitions
├── ShowcaseSection.swift                         # Reusable section wrapper
├── ShowcaseDemo.swift                            # Individual demo container
├── CompactCardFormDemo.swift                     # Layout: Compact form
├── ExpandedCardFormDemo.swift                    # Layout: Expanded form
├── InlineCardFormDemo.swift                      # Layout: Inline form
├── GridCardFormDemo.swift                        # Layout: Grid layout
├── CorporateThemedCardFormDemo.swift             # Styling: Corporate theme
├── ModernThemedCardFormDemo.swift                # Styling: Modern theme
├── ColorfulThemedCardFormDemo.swift              # Styling: Colorful theme
├── DarkThemedCardFormDemo.swift                  # Styling: Dark theme
├── LiveStateCardFormDemo.swift                   # Interactive: Live state
├── ValidationCardFormDemo.swift                  # Interactive: Validation
├── CoBadgedCardFormDemo.swift                    # Interactive: Co-badged cards
├── ModifierChainsCardFormDemo.swift              # Advanced: Modifier chains
├── CustomScreenCardFormDemo.swift                # Advanced: Custom layouts
└── AnimatedCardFormDemo.swift                    # Advanced: Animations
```

### Integration Pattern
```swift
// In MerchantSessionAndSettingsViewController.swift
@State private var showingShowcase = false

Button("Show Component Showcase") {
    showingShowcase = true
}
.sheet(isPresented: $showingShowcase) {
    CheckoutComponentsShowcaseView(clientToken: clientToken, settings: settings)
}
```

This repository provides a comprehensive, production-ready payment SDK with multiple integration approaches, extensive customization capabilities, cross-platform API consistency, and a complete showcase demonstrating all CheckoutComponents features.