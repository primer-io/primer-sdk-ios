# CLAUDE.md - Core SDK Implementation

This directory contains the legacy (but stable) implementation of the Primer iOS SDK, supporting iOS 13.1+ with traditional UIKit patterns.

## Architecture Overview

### Integration Approaches

#### 1. Drop-in Integration (`Primer/`)
**When to use**: Quick integration with minimal customization
```swift
// Typical usage
Primer.showCheckout(with: clientToken, 
                   viewController: self, 
                   delegate: self)
```

**Key Components**:
- `Primer.swift`: Main SDK entry point
- `PrimerDelegate`: Callback interface
- `AppState.swift`: Global SDK state management
- `DependencyInjection.swift`: Legacy DI container

#### 2. Headless Integration (`PrimerHeadlessUniversalCheckout/`)
**When to use**: Custom UI with full control over UX
```swift
// Typical usage  
let headless = PrimerHeadlessUniversalCheckout()
headless.delegate = self
headless.start(with: clientToken)
```

**Key Components**:
- `PrimerHeadlessUniversalCheckout.swift`: Main headless controller
- `Managers/`: Payment method specific managers
- `Composable/`: Individual payment components

### Service Architecture

#### Payment Services (`Payment Services/`)
Core business logic for payment processing:

**CreateResumePaymentService**:
- Handles payment creation and continuation
- Manages 3DS flows and redirects
- Coordinates with backend APIs

**PayPalService**:
- PayPal-specific integration
- OAuth flow management
- Token exchange handling

**VaultService**:
- Stored payment method management
- Customer vault operations
- PCI-compliant data retrieval

#### Analytics (`Analytics/`)
Comprehensive tracking system:
- `AnalyticsService`: Event collection and transmission
- `AnalyticsEvent`: Strongly-typed event definitions
- `Device`: Hardware fingerprinting for fraud prevention

#### 3DS Support (`3DS/`)
3D Secure authentication:
- `3DSService`: Authentication flow coordination
- Mock services for testing
- API client extensions for 3DS endpoints

### Data Management

#### Models (`Models/`)
Domain objects and tokenization protocols:
- `TokenizationProtocols.swift`: Core interfaces for payment processing
- Component-specific models for each payment method

#### Cache (`Cache/`)
Configuration and data caching:
- `ConfigurationCache`: API configuration persistence
- Performance optimization for repeated requests

#### Keychain (`Keychain/`)
Secure storage for sensitive data:
- PCI-compliant credential storage
- SDK configuration persistence

### Dependencies and Utilities

#### DI Container Pattern
```swift
// Legacy DI registration
DependencyContainer.register(MyService.self) { resolver in
    MyServiceImpl(dependency: resolver.resolve(Dependency.self))
}

// Usage
let service: MyService = DependencyContainer.resolve()
```

#### Connectivity Monitoring
- Network reachability detection
- Automatic retry logic for failed requests
- Offline mode handling

#### Logging System
- `PrimerLogger`: Centralized logging
- `LogReporter` protocol: For components that need logging
- Configurable log levels and outputs

## Payment Method Integration Patterns

### Standard Flow
1. **Configuration**: Load payment method config from API
2. **Validation**: Validate user input against business rules
3. **Tokenization**: Convert sensitive data to secure tokens
4. **Processing**: Submit payment for authorization
5. **Result**: Handle success/failure/pending states

### Component Structure
Each payment method follows this pattern:
```
PaymentMethod/
├── Models/              # Data structures
├── Services/            # Business logic
├── Components/          # Headless components
└── UI/                 # Drop-in UI components
```

### Headless Components (`PrimerHeadlessUniversalCheckout/Composable/`)

#### ACH Components (`ACH/`)
Bank account payment processing:
- User details collection
- Mandate acceptance
- Stripe ACH integration

#### Form with Redirect (`FormWithRedirect/`)
Two-step payment flows:
- Form collection (bank selection, etc.)
- External redirect for authorization
- Return handling and completion

#### Native UI Components (`NativeUI/`)
Platform-native payment experiences:
- Apple Pay integration
- PayPal SDK integration
- Platform-specific optimizations

#### Klarna Components (`Klarna/`)
Buy-now-pay-later integration:
- Session management
- Category selection
- Payment authorization

#### NolPay Components (`NolPay/`)
NFC-based payment system:
- Card linking/unlinking
- Phone metadata collection
- Payment processing

## Best Practices

### Adding New Payment Methods
1. Create component directory following existing patterns
2. Implement required protocols (`TokenizationProtocols`)
3. Add to both Drop-in and Headless managers
4. Create comprehensive analytics events
5. Add mock implementations for testing

### Error Handling
- Use `PrimerError` for user-facing errors
- `PrimerInternalError` for SDK internal issues
- Always provide recovery paths where possible
- Log errors with appropriate detail level

### Performance Considerations
- Cache configuration data aggressively
- Use lazy loading for payment method components
- Minimize network requests during critical flows
- Implement proper memory management for view controllers

### Security Requirements
- All payment data must go through tokenization
- Never log sensitive information
- Use secure storage (Keychain) for persistent data
- Validate all inputs against injection attacks

### Testing Strategy
- Mock all external dependencies
- Test both success and failure paths
- Include edge cases (network failures, malformed data)
- Performance test critical payment flows

## Migration Notes

### To CheckoutComponents
When migrating payment methods to the modern CheckoutComponents:
1. Extract business logic from view controllers
2. Convert UIKit components to SwiftUI
3. Migrate to modern DI container
4. Update to async/await patterns
5. Maintain backward compatibility during transition

### Deprecation Strategy
- Legacy components remain supported
- New features prioritize CheckoutComponents
- Clear migration path provided for each component
- Documentation updated to reflect modern approach