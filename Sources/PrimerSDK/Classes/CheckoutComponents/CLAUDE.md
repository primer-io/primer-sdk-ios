# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in CheckoutComponents folder.

## Overview

CheckoutComponents is a modern, scope-based payment checkout framework for iOS 15+ that provides complete UI customization with exact Android API parity. It represents the newest integration approach in the Primer iOS SDK, using SwiftUI, async/await, and a hierarchical scope-based architecture.

## Key Architecture Patterns

### Scope-Based API

CheckoutComponents uses a hierarchical scope pattern where each major component exposes a scope interface:

- **`PrimerCheckoutScope`**: Main checkout lifecycle, navigation, and screen customization (Scope/PrimerCheckoutScope.swift:13)
- **`PrimerPaymentMethodSelectionScope`**: Payment method grid and selection UI
- **`PrimerCardFormScope`**: Comprehensive card form with field-level customization
- **`PrimerPaymentMethodScope`**: Base protocol for all payment method implementations

Each scope provides:
- State observation via AsyncStream
- UI component customization closures (ViewBuilder pattern)
- SDK component access methods
- Navigation and action methods

### Dependency Injection

CheckoutComponents uses a custom DI container framework (Internal/DI/Framework/):
- Actor-based implementation for thread safety
- Support for async/await resolution
- Three retention policies: Transient, Singleton, Weak
- Factory pattern support for parameterized object creation
- Scoped containers for feature isolation

**Registration**: ComposableContainer.swift:24 configures all dependencies
**Resolution**: Manual resolution with explicit error handling using `DIContainer.current` or `DIContainer.currentSync`

### Clean Architecture Layers

CheckoutComponents follows Clean Architecture:
```
Internal/
├── Domain/           # Business logic (Interactors, Models)
├── Data/             # Repositories, Mappers
├── Presentation/     # Scopes, ViewModels, UI Components
├── Core/             # Validation, Services
└── Navigation/       # CheckoutCoordinator, CheckoutNavigator
```

### Navigation System

- **CheckoutNavigator**: State publisher for navigation events (Internal/Navigation/CheckoutNavigator.swift)
- **CheckoutCoordinator**: Handles navigation stack management (Internal/Navigation/CheckoutCoordinator.swift:29)
- **CheckoutRoute**: Enum defining all possible routes with navigation behaviors
- State-driven navigation using AsyncStream

### Payment Method Registry

Dynamic payment method registration system:
- Payment methods register themselves on startup (e.g., CardPaymentMethod.register())
- Registry creates scopes dynamically via `PaymentMethodRegistry.shared.createScope()`
- Supports three access patterns: type-safe metatype, enum-based, string identifier

## Entry Points

### UIKit Integration
**CheckoutComponentsPrimer** (CheckoutComponentsPrimer.swift:64): Main UIKit entry point
- `presentCheckout(clientToken:from:completion:)`: Present default UI
- `presentCheckout(clientToken:from:primerSettings:primerTheme:scope:completion:)`: Present with scope-based customization
- Acts as bridge between UIKit and SwiftUI implementation

### SwiftUI Integration
**PrimerCheckout** view: Direct SwiftUI integration for pure SwiftUI apps

### Delegation, works only with UIKit Integration
**CheckoutComponentsDelegate** protocol (CheckoutComponentsPrimer.swift:13):
- `checkoutComponentsDidCompleteWithSuccess(_:)`: Payment successful
- `checkoutComponentsDidFailWithError(_:)`: Payment failed
- `checkoutComponentsDidDismiss()`: Checkout dismissed
- Optional 3DS lifecycle methods

## State Management

### Checkout State Flow
```swift
PrimerCheckoutState:
.initializing → .ready → .success(PaymentResult) | .failure(PrimerError) → .dismissed
```

### Card Form State
Structured state via `StructuredCardFormState` (Core/Data/StructuredCardFormState.swift):
- Field-level validation with specific error codes
- Co-badged card network detection and selection
- Dynamic billing address field configuration
- Surcharge information per network

### AsyncStream Observation
All scopes expose state as AsyncStream for reactive updates:
```swift
for await state in scope.state {
    // Handle state changes
}
```

## Customization Approaches

### 1. Field-Level Customization via InputFieldConfig
Customize individual fields with partial or full replacement via scope properties:
```swift
// Access card form scope and customize fields
if let cardFormScope = checkoutScope.getPaymentMethodScope(DefaultCardFormScope.self) {
    cardFormScope.cardNumberConfig = InputFieldConfig(
        label: "Card Number",
        placeholder: "0000 0000 0000 0000",
        styling: PrimerFieldStyling(borderColor: .blue)
    )
    cardFormScope.cvvConfig = InputFieldConfig(
        component: { MyCustomCVVField() }
    )
}
```

### 2. Section-Level Customization
Replace entire sections using scope section properties:
```swift
cardFormScope.cardInputSection = { scope in
    AnyView(MyCustomCardDetailsSection(scope: scope))
}
```

### 3. Full Screen Customization
Replace the entire card form screen:
```swift
cardFormScope.screen = { scope in
    AnyView(MyCustomCardFormScreen(scope: scope))
}
```

### 4. Checkout-Level Screen Customization
Customize checkout-level screens via scope properties:
```swift
// Custom splash screen (SDK initialization)
checkoutScope.splashScreen = {
    AnyView(MyCustomSplashScreen())
}

// Custom loading screen (payment processing) - matches Android's checkout.loading
checkoutScope.loading = {
    AnyView(MyCustomLoadingScreen())
}

// Custom error screen
checkoutScope.errorScreen = { message in
    AnyView(MyCustomErrorScreen(message: message))
}
```

## Validation System

### Validation Architecture
- **ValidationService** (Internal/Core/Validation/ValidationService.swift): Core validation engine
- **RulesFactory** (Internal/Core/Validation/RulesFactory.swift): Creates validation rules
- **ValidationRule** protocol (Internal/Core/Validation/ValidationRule.swift): Individual rule implementations
- **CardValidationRules** and **CommonValidationRules** (Internal/Core/Validation/Rules/)

### Field Validation
Each field state includes:
- `value`: Current field value
- `isValid`: Validation status
- `error`: Specific FieldError if invalid
- `isRequired`: Whether field is required
- `isVisible`: Whether field should be shown

## Testing Strategy

### Test Structure
Tests follow XCTest framework located in `/Tests/` directory:
- Unit tests for domain logic (interactors, validators)
- Integration tests for data layer (repositories)
- UI tests via Debug App

### Mock Container for Testing
```swift
let mockContainer = await DIContainer.createMockContainer()
await DIContainer.withContainer(mockContainer) {
    // Test with mock dependencies
}
```

## Important Implementation Notes

### Settings Integration
CheckoutComponents integrates with PrimerSettings via:
- **CheckoutComponentsSettingsService** (Internal/Services/CheckoutComponentsSettingsService.swift): Wraps PrimerSettings
- **SettingsObserver** (Internal/Services/SettingsObserver.swift): Dynamic settings updates
- Settings control screen visibility (init, success, error screens)
- `is3DSSanityCheckEnabled` critical for production security

### Presentation Context
`PresentationContext` enum controls navigation behavior:
- `.fromPaymentSelection`: Show back button (navigated from selection)
- `.direct`: Show cancel button (directly presented)

### 3DS Integration
- Automatic 3DS handling via delegate callbacks
- Sanity checks configurable via settings
- Lifecycle callbacks: willPresent, didPresent, willDismiss, didComplete

## Common Development Tasks

### Adding a New Payment Method
1. Create payment method class implementing `PrimerPaymentMethodScope`
2. Implement required scope methods (start, submit, state observation)
3. Register in `PaymentMethodRegistry`
4. Add registration call in DefaultCheckoutScope.registerPaymentMethods()

### Customizing UI Components
Use the scope's customization closures:
- For full control: Replace entire screens or sections
- For styling: Use ViewBuilder methods with PrimerFieldStyling
- For partial changes: Replace individual field closures

### Debugging Navigation
- Check CheckoutNavigator.navigationEvents AsyncStream
- Verify CheckoutCoordinator.navigationStack state
- Use `#if DEBUG` diagnostics in ComposableContainer.performHealthCheck()

### DI Container Issues
- Ensure `ComposableContainer.configure()` is called before use
- Check container diagnostics: `await container.getDiagnostics()`
- Verify registrations: `await container.performHealthCheck()`

## Design Tokens

CheckoutComponents uses a design token system (Internal/Tokens/):
- **DesignTokens**: Light mode tokens
- **DesignTokensDark**: Dark mode tokens
- **DesignTokensManager**: Manages token access and theme switching
- **PrimerFont**: Custom font support with fallbacks

## Key Files Reference

- Entry: CheckoutComponentsPrimer.swift, PrimerCheckout.swift
- Scope interfaces: Scope/PrimerCheckoutScope.swift, Scope/PrimerCardFormScope.swift
- Scope implementations: Internal/Presentation/Scope/DefaultCheckoutScope.swift
- DI setup: Internal/DI/ComposableContainer.swift
- Navigation: Internal/Navigation/CheckoutCoordinator.swift
- Validation: Internal/Core/Validation/
- Payment methods: PaymentMethods/Card/CardPaymentMethod.swift
