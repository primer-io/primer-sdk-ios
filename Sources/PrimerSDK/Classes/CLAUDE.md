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
**NEW**: Modern SwiftUI-based architecture (iOS 15+)
- **Entry Point**: `ComposableCheckout/Core/PrimerCheckout/PrimerCheckout.swift`
- **Pattern**: Component-based with dependency injection
- **Architecture**: See `ComposableCheckout/CLAUDE.md` for details

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
Consistent pattern across all payment methods:
```
Entry Point → Manager → Component → Tokenization → Result
```

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
- Use SwiftUI and modern DI container
- Follow component-based architecture
- Leverage async/await for async operations

### Cross-Cutting Concerns
- **Theming**: Use `PrimerTheme` for consistent styling
- **Localization**: `UILocalizableUtil` for multi-language support
- **Security**: All payment data goes through PCI-compliant channels
- **Testing**: Extensive mock infrastructure in `Tests/`

## Common Workflows

### Adding a New Payment Method
1. Create tokenization component in appropriate directory
2. Implement `PaymentMethodTokenizationViewModel`
3. Add UI components (UIKit for legacy, SwiftUI for modern)
4. Register in appropriate DI container
5. Add analytics events
6. Create comprehensive tests

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