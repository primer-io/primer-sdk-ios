# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in CheckoutComponents folder.

## Overview

CheckoutComponents is a modern, slot-based payment checkout framework for iOS 15+ that provides complete UI customization with exact Android API parity. It represents the newest integration approach in the Primer iOS SDK, using SwiftUI, async/await, and composable views with `@ViewBuilder` section slots.

## Key Architecture Patterns

### Slot-Based Public API

The public API is composed of:

- **Entry points**: `PrimerCheckout` (managed SwiftUI modal) or `PrimerCheckoutSession` + `.primerCheckoutSession(_:onCompletion:)` modifier (composable/inline); `PrimerCheckoutPresenter` for UIKit
- **Composable views**: `PrimerCardForm`, `PrimerPaymentMethods`, `PrimerVaultedPaymentMethods` — each exposes `@ViewBuilder` section slots and resolves its session from the environment
- **Observable sessions**: `PrimerCardFormSession`, `PrimerSelectionSession` — bridge internal scope `AsyncStream<State>` into `@Published state` and expose the mutation surface
- **Defaults namespaces**: `CardFormDefaults`, `PaymentMethodsDefaults`, `VaultedPaymentMethodsDefaults` — default slot bodies and per-field building blocks for recomposition

The scope protocols (`PrimerCheckoutScope`, `PrimerCardFormScope`, etc.) are **internal** — not part of the public API.

### Dependency Injection

CheckoutComponents uses a custom DI container framework (Internal/DI/Framework/):
- Actor-based implementation for thread safety
- Support for async/await resolution
- Three retention policies: Transient, Singleton, Weak
- Factory pattern support for parameterized object creation
- Scoped containers for feature isolation

**Registration**: ComposableContainer.swift:20 configures all dependencies
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
- **CheckoutCoordinator**: Handles navigation stack management (Internal/Navigation/CheckoutCoordinator.swift:20)
- **CheckoutRoute**: Enum defining all possible routes with navigation behaviors
- State-driven navigation using AsyncStream

### Payment Method Registry

Dynamic payment method registration system:
- Payment methods register themselves on startup (e.g., CardPaymentMethod.register())
- Registry creates scopes dynamically via `PaymentMethodRegistry.shared.createScope()`
- Supports three access patterns: type-safe metatype, enum-based, string identifier

## Entry Points

### UIKit Integration
**PrimerCheckoutPresenter** (PrimerCheckoutPresenter.swift): Main UIKit entry point
- `presentCheckout(clientToken:from:completion:)`: Present default UI
- `presentCheckout(clientToken:from:primerSettings:primerTheme:completion:)`: Present with settings and theme
- Acts as bridge between UIKit and SwiftUI implementation

### SwiftUI Integration
**PrimerCheckout**: Managed modal — renders SDK defaults with no customization slots.
**PrimerCheckoutSession** + `.primerCheckoutSession(_:onCompletion:)`: Composable/inline — embed `PrimerCardForm`, `PrimerPaymentMethods`, `PrimerVaultedPaymentMethods` in your own layout.

### Delegation, works only with UIKit Integration
**PrimerCheckoutPresenterDelegate** protocol (PrimerCheckoutPresenter.swift:11):
- `primerCheckoutPresenterDidCompleteWithSuccess(_:)`: Payment successful
- `primerCheckoutPresenterDidFailWithError(_:)`: Payment failed
- `primerCheckoutPresenterDidDismiss()`: Checkout dismissed
- Optional 3DS lifecycle methods

## State Management

### Checkout State Flow
```swift
PrimerCheckoutState:
.initializing → .ready(totalAmount:currencyCode:) → .success(PaymentResult) | .failure(PrimerError) → .dismissed
```

### Card Form State
Structured state via `PrimerCardFormState` (Core/Data/PrimerCardFormState.swift):
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

### Slot Override
Pass a labeled `@ViewBuilder` argument to replace one slot while keeping others as defaults:
```swift
PrimerCardForm(submitButton: { session in
    MyPayButton(isLoading: session.state.isLoading) { session.submit() }
})
```

### Recomposition with Building Blocks
Use `CardFormDefaults.*` field building blocks inside a slot:
```swift
PrimerCardForm(cardDetails: { session in
    CardFormDefaults.cardNumber(session)
    HStack {
        CardFormDefaults.expiryDate(session)
        CardFormDefaults.cvv(session)
    }
    CardFormDefaults.cardholderName(session)
    MyPromoBanner()
})
```

### Full Slot Replacement
Provide entirely custom content; `session` gives access to state and mutation methods:
```swift
PrimerCardForm(cardDetails: { session in
    MyFullyCustomCardSection(
        state: session.state,
        onCardNumber: session.updateCardNumber,
        onExpiry: session.updateExpiryDate,
        onCvv: session.updateCvv
    )
})
```

Visual styling is theme-driven via `PrimerCheckoutTheme` (design tokens). There are no per-field styling structs.

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
let mockContainer = MockDIContainer()
await DIContainer.withContainer(mockContainer) {
    // Test with mock dependencies
}
```

## Important Implementation Notes

### Settings Integration
CheckoutComponents integrates with PrimerSettings via:
- **CheckoutSDKInitializer** (Internal/Services/CheckoutSDKInitializer.swift): Holds PrimerSettings and bridges it into the DI container (via ComposableContainer and the core SDK's DependencyContainer)
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
Use the composable view's slot arguments:
- For full control: Replace the entire slot content
- For styling: Use `PrimerCheckoutTheme` design token overrides
- For partial changes: Compose with `*Defaults` building blocks and add custom views around them

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

- Entry (UIKit): PrimerCheckoutPresenter.swift
- Entry (SwiftUI managed): PrimerCheckout.swift
- Entry (SwiftUI composable): Session/PrimerCheckoutSession.swift, Session/PrimerCheckoutSessionModifier.swift
- Composable views: PrimerCardForm.swift, PrimerPaymentMethods.swift, PrimerVaultedPaymentMethods.swift
- Observable sessions: Session/PrimerCardFormSession.swift, Session/PrimerSelectionSession.swift
- Defaults: Defaults/CardFormDefaults.swift, Defaults/PaymentMethodsDefaults.swift
- Scope implementations (internal): Internal/Presentation/Scope/DefaultCheckoutScope.swift
- DI setup: Internal/DI/ComposableContainer.swift
- Navigation: Internal/Navigation/CheckoutCoordinator.swift
- Validation: Internal/Core/Validation/
- Payment methods: PaymentMethods/Card/CardPaymentMethod.swift
