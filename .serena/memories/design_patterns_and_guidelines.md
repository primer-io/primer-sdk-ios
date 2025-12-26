# Design Patterns and Guidelines

## Architectural Patterns

### Delegation Pattern
The SDK heavily uses the delegation pattern:
- `PrimerDelegate`: Main SDK delegate for checkout events
- Various component-specific delegates (e.g., `PrimerTextFieldViewDelegate`, `ACHMandateDelegate`, `ReloadDelegate`)

Example from main SDK interface:
```swift
public final class Primer {
    public weak var delegate: PrimerDelegate?
    // ...
}
```

### MVVM (Model-View-ViewModel)
Payment methods follow MVVM architecture:
- Models: Data structures in `Data Models/`
- ViewModels: `*ViewModel.swift` files (e.g., `PaymentMethodTokenizationViewModel`)
- Views: UI components in `User Interface/`

### Protocol-Oriented Programming
Extensive use of protocols for abstraction:
- Service protocols: `NetworkServiceProtocol`, `PrimerAPIClientProtocol`
- Component protocols: `PaymentMethodTokenizationModelProtocol`
- Feature protocols: `NativeUIValidateable`, `NativeUIPresentable`

### Dependency Injection
- `DependencyInjection.swift`: Centralized DI container
- Protocols define dependencies, implementations injected at runtime

## Component Architecture

### Composable Components
The SDK uses a composable architecture for payment methods:
- Base: `PrimerHeadlessComposable`
- Implementations in `Core/PrimerHeadlessUniversalCheckout/Composable/`
  - Klarna components
  - ACH/Stripe components
  - NolPay components
  - FormWithRedirect components

### Tokenization Components
Payment tokenization follows a consistent pattern:
- Builder pattern: `PrimerRawCardDataTokenizationBuilder`
- Service pattern: `TokenizationService`
- ViewModel pattern: `*TokenizationViewModel`

## Coding Guidelines

### Error Handling
Structured error handling with custom error types:
- `PrimerError`: Main SDK error enum
- `PrimerValidationError`: Validation-specific errors
- `PrimerServerError`: Server response errors
- `PrimerInternalError`: Internal SDK errors
- Domain-specific errors: `PrimerKlarnaError`, `PrimerIPay88Error`

Error handler: `ErrorHandler.swift` for centralized error processing

### Logging
Centralized logging system:
- `PrimerLogger`: Main logger interface
- `PrimerLogging`: Logging protocol
- `LogReporter`: Log reporting service

### Analytics
Event tracking infrastructure:
- `Analytics.swift`: Main analytics service
- `AnalyticsEvent`: Event definitions
- `AnalyticsService`: Event processing
- `AnalyticsStorage`: Event persistence

Domain-specific analytics:
- `KlarnaAnalyticsEvents`
- `ACHAnalyticsEvents`
- `BanksAnalyticsEvent`

### Threading
- Use of `DispatchQueue` for thread management
- Main thread for UI updates
- Background threads for network/processing

### Memory Management
- Weak references for delegates to prevent retain cycles
- Example: `public weak var delegate: PrimerDelegate?`

## UI Patterns

### Custom View Components
Base classes for consistent UI:
- `PrimerViewController`: Base view controller
- `PrimerButton`: Themed buttons
- `PrimerImageView`: Image views with SDK theming
- `PrimerStackView`: Stack views
- `PrimerNibView`: XIB-based views

### Theme System
Centralized theming:
- `PrimerTheme`: Main theme interface
- `PrimerThemeData`: Public theme configuration
- Theme extensions: Colors, Buttons, Inputs, Views, Borders, TextStyles

### Text Fields
Specialized text field hierarchy:
- Base: `PrimerTextFieldView`
- PCI-compliant: `PrimerCardNumberFieldView`, `PrimerCVVFieldView`, `PrimerExpiryDateFieldView`
- Generic: `PrimerGenericTextFieldView`

## Service Patterns

### Network Layer
- `PrimerAPIClient`: Main API client
- Protocol-based API organization:
  - `PrimerAPIClientAnalyticsProtocol`
  - `PrimerAPIClientVaultProtocol`
  - `PrimerAPIClientPayPalProtocol`
  - Etc.
- `Endpoint`: Type-safe endpoint definitions
- `RetryConfiguration`: Configurable retry logic
- `RetryHandler`: Retry handling service

### Request/Response
- `Request`: Base request model
- `Response`: Base response model
- Factory patterns: `NetworkRequestFactory`, `NetworkResponseFactory`

### Caching
- `Cache`: Generic caching protocol
- `ConfigurationCache`: SDK configuration caching

## Data Flow

### Client Session
1. Client token obtained from backend
2. `ClientSession` created and validated
3. Configuration loaded and cached
4. Payment methods filtered and presented

### Payment Processing
1. User selects payment method
2. Tokenization builder creates payment instrument
3. API client sends tokenization request
4. Response handled and delegate notified
5. 3DS flow if required
6. Final payment completion

## Testing Patterns

### Test Mode
- `TEST` flag for test environment detection
- `PrimerTestPaymentMethodViewController`: Test payment methods
- Mock services: `Mock3DSService`

### Debug Configuration
- Multiple package configurations for different test scenarios
- Debug App for SDK integration testing
- Test settings: `TestSettings.swift`

## Extension Organization

Extensions are organized by:
1. **Functionality**: `UIColor+Extension.swift` adds color utilities
2. **Domain**: `ApplePayPaymentRequest+PK.swift` adds PassKit helpers
3. **Feature**: `PrimerTheme+Colors.swift` adds theme color support

## Best Practices

### File Organization
- Group related files in directories
- Use extensions for protocol conformances
- Separate public and internal APIs

### Naming
- Descriptive names reflecting purpose
- Consistent prefixing with `Primer` for public types
- Suffix patterns: `*ViewModel`, `*Service`, `*Manager`, `*Builder`, `*Component`

### Documentation
- Public APIs should have documentation comments
- Complex logic should have inline explanations
- README and CONTRIBUTING provide high-level guidance

### Version Management
- `version.swift`: Centralized version information
- Semantic versioning (major.minor.patch)
- CHANGELOG.md for release notes

### Localization
- Default: English (`en`)
- Resources in `Sources/PrimerSDK/Resources`
- `UILocalizableUtil`: Localization utilities
- Configuration: `phrase_config.yml`

## Security Considerations

### PCI Compliance
- Separate PCI module for card handling
- Secure text fields for sensitive data
- Tokenization instead of raw card storage
- Keychain for secure local storage

### Data Protection
- Keychain wrapper: `Keychain.swift`
- No sensitive data in logs
- Secure network communication (HTTPS)

## Platform-Specific

### macOS (Darwin) Considerations
- Darwin-specific commands in Makefile
- Homebrew for tool installation
- Xcode integration (workspace, schemes)
- Simulator testing
