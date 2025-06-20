# CLAUDE.md - PrimerSDK Classes

This file provides context for the main PrimerSDK Classes directory structure and architecture patterns.

## Directory Overview

### Core/ - Legacy SDK Implementation
The main iOS SDK implementation with three integration approaches:

#### Drop-in Integration (`Core/Primer/`)
- **Entry Point**: `Primer.swift`
- **Pattern**: Delegate-based UIKit views
- **Usage**: `PrimerDelegate` protocol for callbacks
- **Target**: iOS 13.1+ with traditional UIKit approach

#### Headless Integration (`Core/PrimerHeadlessUniversalCheckout/`)
- **Entry Point**: `PrimerHeadlessUniversalCheckout.swift`
- **Pattern**: API-driven, no UI components
- **Usage**: `PrimerHeadlessUniversalCheckoutDelegate` for events
- **Target**: Custom UI implementations

#### Payment Processing Core (`Core/Payment Services/`)
- **CreateResumePaymentService**: Handle payment lifecycle
- **PayPalService**: PayPal-specific integrations
- **VaultService**: Stored payment methods

### ComposableCheckout/ - Modern SwiftUI Implementation
**MODERN**: SwiftUI-based scope architecture (iOS 15+)
- **Main Entry Point**: `ComposableCheckout/ComposablePrimer.swift` - UIKit-friendly API
- **SwiftUI Entry**: `ComposableCheckout/Core/PrimerCheckout/PrimerCheckout.swift`
- **Pattern**: Scope-based component architecture with async/await DI
- **Key Features**: PaymentMethodProtocol with associated types, AsyncStream reactive patterns
- **Public API**: Similar to Android Compose scopes with SwiftUI integration
- **Bridge Services**: LegacyConfigurationBridge and LegacyTokenizationBridge for SDK integration
- **Architecture**: See `ComposableCheckout/CLAUDE.md` for complete details

### Data Models/ - Domain Objects
Core business entities and API models:
- **API/**: Network request/response models
- **Currency/**: Multi-currency support with caching
- **PCI/**: Payment card industry compliant data handling
- **Theme/**: UI theming and customization

### Services/ - Infrastructure Layer
- **Network/**: API client and networking infrastructure
- **Parser/**: Data transformation utilities

### User Interface/ - Legacy UI Components
UIKit-based UI components for Drop-in integration:
- **Root/**: Main view controllers
- **Components/**: Reusable UI elements
- **TokenizationViewControllers/**: Payment method specific UIs

### PCI/ - Secure Payment Data Handling
Payment Card Industry compliant secure data processing:
- **Checkout Components/**: Secure form handling
- **Services/**: Tokenization and secure transmission
- **User Interface/**: PCI-compliant input fields

## Architecture Patterns

### 1. Dependency Injection
Two DI systems coexist:
- **Legacy**: `DependencyInjection.swift` - Property wrapper based
- **Modern**: `ComposableCheckout/Core/DI/` - Actor-based async DI

### 2. Payment Method Integration

**Legacy Pattern** (Drop-in/Headless):
```
Entry Point → Manager → Component → Tokenization → Result
```

**Modern Pattern** (ComposableCheckout):
```
PaymentMethodProtocol → Scope (Protocol) → ViewModel (Implementation) → View → DI Resolution
```
- Uses associated types for type-safe scope relationships
- Each payment method exposes a specific scope interface
- ViewModels implement scope protocols and manage state
- Views use `@ViewBuilder` for customization

### 3. Error Handling
Layered error management:
- **PrimerError**: User-facing errors
- **PrimerInternalError**: SDK internal errors
- **PrimerServerError**: API/network errors

### 4. Networking
RESTful API client with:
- **Automatic retry**: Exponential backoff
- **Request/Response factories**: Consistent data transformation
- **Protocol-based**: Easy mocking and testing

### 5. Analytics
Comprehensive event tracking:
- **AnalyticsService**: Event collection and transmission
- **Device**: Hardware and OS information
- **Privacy-first**: Configurable data collection

## Integration Notes

### For Legacy Integrations (Drop-in/Headless)
- Use existing `DependencyContainer` for dependencies
- Follow UIKit patterns for UI components
- Implement delegate protocols for callbacks

### For Modern Integrations (ComposableCheckout)
- Use SwiftUI with scope-based architecture
- Follow PaymentMethodProtocol pattern with associated types
- Leverage async/await DI container for dependency resolution
- Implement scope protocols for payment method behavior
- Use AsyncStream for reactive state management

### Cross-Cutting Concerns
- **Theming**: Use `PrimerTheme` for consistent styling
- **Localization**: `UILocalizableUtil` for multi-language support
- **Security**: All payment data goes through PCI-compliant channels
- **Testing**: Extensive mock infrastructure in `Tests/`

## Common Workflows

### Adding a New Payment Method

**For Legacy (Drop-in/Headless):**
1. Create tokenization component in appropriate directory
2. Implement `PaymentMethodTokenizationViewModel`
3. Add UIKit UI components
4. Register in legacy `DependencyContainer`
5. Add analytics events
6. Create comprehensive tests

**For ComposableCheckout:**
1. Create payment method following Card pattern in `PaymentMethods/NewMethod/`
2. Implement `PaymentMethodProtocol` with associated `ScopeType`
3. Create scope protocol (e.g., `NewMethodScope`)
4. Implement scope in ViewModel with state management
5. Create SwiftUI view with `@ViewBuilder` customization support
6. Register ViewModel in modern DI container
7. Add validation rules if needed
8. Create comprehensive tests with DI mocking

### Modifying Core SDK Behavior
1. Check both legacy and modern implementations
2. Update appropriate service layer
3. Ensure backward compatibility
4. Update integration documentation

### Debugging Issues
1. Enable debug logging via `PrimerLogging`
2. Check analytics events for user flow tracking
3. Use DI container diagnostics for dependency issues
4. Leverage extensive test mocks for isolated testing

This architecture supports multiple integration patterns while maintaining security, scalability, and developer experience.