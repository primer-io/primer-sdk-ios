# CLAUDE.md - CheckoutComponents

This file provides context for the CheckoutComponents module, a modern SwiftUI-based payment checkout framework.

## Overview

CheckoutComponents is a new payment integration approach for iOS 15+ that provides:
- **Scope-based API**: Type-safe scoped interfaces matching Android's Composable architecture
- **Full customization**: Every UI component can be replaced while maintaining defaults
- **Modern Swift**: Uses async/await, SwiftUI, and Swift 6 features
- **Cross-platform parity**: Exact API match with Android for consistent integration

## Architecture

### Public API Structure

```
CheckoutComponents/
├── PrimerCheckout.swift          # Main entry point (SwiftUI View)
└── Scope/                        # Public scope interfaces
    ├── PrimerCheckoutScope       # Main checkout lifecycle and screens
    ├── PrimerCardFormScope       # Card form with 15 update methods
    ├── PrimerPaymentMethodSelectionScope  # Payment method selection
    └── PrimerSelectCountryScope  # Country selection with search
```

### Internal Structure

```
Internal/
├── Domain/              # Business logic layer
│   ├── Interactors/    # Use cases (single responsibility)
│   ├── Models/         # Domain entities
│   └── Repositories/   # Repository interfaces
├── Data/               # Data access layer
│   ├── Repositories/   # Headless SDK integration
│   └── Mappers/        # Data transformation
├── Presentation/       # UI layer
│   ├── Screens/        # Full screen views
│   ├── Components/     # Reusable UI elements
│   ├── Scope/          # Scope implementations
│   └── Theme/          # Styling utilities
├── DI/                 # Dependency injection
├── Tokens/             # Design tokens
├── Core/               # Shared utilities
└── Navigation/         # State-driven navigation
```

## Key Design Patterns

### 1. Scope-Based API
Every major component exposes a scope interface for customization:
```swift
public protocol PrimerCardFormScope: AnyObject {
    var state: AsyncStream<State> { get }
    
    // 15 update methods matching Android exactly
    func updateCardNumber(_ cardNumber: String)
    func updateCvv(_ cvv: String)
    // ... etc
    
    // 18 customizable UI components
    var cardNumberInput: (@ViewBuilder (_ modifier: PrimerModifier) -> any View)? { get set }
    // ... etc
}
```

### 2. State Management
- **Public API**: AsyncStream for reactive state observation
- **Internal**: @Published properties for SwiftUI reactivity
- **No Combine**: Uses SwiftUI's built-in state management

### 3. Dependency Injection
Actor-based async DI container system:
```swift
@globalActor
actor DIContainer {
    func resolve<T>(_ type: T.Type) async throws -> T
    func register<T>(_ type: T.Type, factory: @escaping () async throws -> T)
}
```

### 4. Payment Processing
Uses existing RawDataManager for card payments:
```swift
let rawDataManager = try PrimerHeadlessUniversalCheckout.RawDataManager(
    paymentMethodType: "PAYMENT_CARD",
    delegate: self
)
```

## Implementation Status

### Phase 1: Foundation & Public API ✅
- Created directory structure
- Defined all public scope protocols
- Created PrimerCheckout entry point
- Exact Android API parity achieved

### Phase 2: Core Infrastructure ✅
- Copied complete DI framework (actor-based, async/await)
- Copied validation framework with rules and validators
- Copied design tokens system (DesignTokensManager)
- Copied navigation system (CheckoutNavigator)
- Created ComposableContainer for dependency registration
- All infrastructure ready for domain implementation

### Phase 3: Domain & Data Layers ✅
- Created domain models (InternalPaymentMethod, PrimerInputElementType, PaymentResult)
- Created all interactors (GetPaymentMethods, ProcessCardPayment, TokenizeCard, ValidateInput)
- Created HeadlessRepository protocol and implementation
- Created PaymentMethodMapper for data transformation
- Added comprehensive validation rules for all input types

### Phase 4: Presentation Components ✅
- Adapted card input fields from ComposableCheckout (simplified versions)
- Created billing address SwiftUI components (all fields)
- Created composite components (CardDetailsView, BillingAddressView)
- Added co-badged cards network selector UI
- Created InputConfigsWrapper for dynamic field configuration

### Phase 5: Scope Implementation ✅
- Implemented DefaultCheckoutScope with AsyncStream state publishing
- Created DefaultCardFormScope with RawDataManager integration
- Implemented DefaultPaymentMethodSelectionScope with search and categorization
- Created DefaultSelectCountryScope with country search
- Created all screens (Loading, Error, Success, CardForm, PaymentMethodSelection, SelectCountry)
- Setup CheckoutNavigator with state-driven navigation
- Integrated 3DS handling via RawDataManager delegate

### Phase 6: Integration ✅
- Created CheckoutComponentsPrimer as main entry point (follows Primer.shared pattern)
- Integrated with existing PrimerDelegate and PrimerSettings infrastructure
- Uses PrimerDelegateProxy for delegate callbacks
- Automatic view controller detection with manual override
- Support for custom SwiftUI content
- Proper DI container initialization and cleanup

## Key Features

### Co-Badged Cards
Supports multiple card networks with user selection:
- Detect available networks from BIN
- Show network selector dropdown
- Update payment based on selection

### Billing Address
Dynamic field configuration from API:
- Fields shown based on API response
- Sent separately via Client Session Actions
- Not part of card tokenization

### 3DS Handling
Automatic 3D Secure flow:
- Handled internally by RawDataManager
- SafariViewController for web redirects
- State updates during process

## Usage Examples

### Basic UIKit Integration
```swift
// Present with automatic view controller detection
CheckoutComponentsPrimer.presentCheckout(with: clientToken)

// Present from specific view controller
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController
)

// Dismiss
CheckoutComponentsPrimer.dismiss()
```

### SwiftUI Integration
```swift
struct CheckoutView: View {
    var body: some View {
        PrimerCheckout(
            clientToken: "your_token",
            settings: PrimerSettings()
        )
    }
}
```

### Custom Components
```swift
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController
) { scope in
    VStack {
        // Custom header
        Text("Custom Checkout")
        
        // Use scope to access card form
        if let cardForm = scope.cardFormScreen {
            cardForm(scope.cardForm)
        }
    }
}
```

### Scope Customization
```swift
PrimerCheckout(
    clientToken: token,
    settings: settings,
    scope: { scope in
        // Customize card number input
        scope.cardForm.cardNumberInput = { _ in
            CustomCardNumberField()
        }
        
        // Customize loading screen
        scope.loadingScreen = {
            CustomLoadingView()
        }
    }
)
```

### Observing State
```swift
Task {
    for await state in scope.cardForm.state {
        print("Card number: \(state.cardNumber)")
        print("Is valid: \(state.isSubmitting)")
    }
}
```

## Development Guidelines

### Adding New Components
1. Define in appropriate scope protocol
2. Implement in Internal/Presentation/Components
3. Register in DI container if needed
4. Follow existing validation patterns

### Working with DI Container
1. Register dependencies in ComposableContainer
2. Use async/await for resolution
3. Prefer singleton for services, transient for ViewModels
4. Use factory pattern for parameterized creation

### Validation System
1. Create rule classes extending ValidationRule
2. Register validators in container
3. Use ValidationService for field validation
4. Follow existing patterns from copied framework

### State Updates
- All state changes go through scope methods
- Components read state, don't modify directly
- Use AsyncStream for external observation

### Error Handling
- Use existing PrimerError types
- Log through LogReporter protocol
- Show errors via scope.errorScreen

### Testing Approach
- Manual testing through Debug App
- Use PrimerUIManager integration
- Unit tests deferred to post-beta

## Important Notes

1. **iOS 15+ Required**: Uses modern Swift concurrency
2. **No Combine Import**: SwiftUI state management only
3. **Exact Android Parity**: All methods/properties match
4. **Internal Access**: Everything under Internal/ is internal
5. **Reuse Components**: Card inputs from ComposableCheckout