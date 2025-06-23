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

### Phase 2: Core Infrastructure (Next)
- Copy DI, Validation, Design Tokens from ComposableCheckout
- Setup navigation system
- Create container registrations

### Phase 3: Domain & Data Layers
- Create interactors for payment processing
- Integrate with headless SDK
- Implement repository pattern

### Phase 4: Presentation Components
- Reuse existing card input fields
- Convert billing address fields to SwiftUI
- Create composite components

### Phase 5: Scope Implementation
- Implement all scope classes
- Create screens
- Setup navigation flow

### Phase 6: Integration
- Add to PrimerUIManager
- Bridge configuration

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

### Basic Integration
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

### Custom Card Input
```swift
PrimerCheckout(
    clientToken: token,
    settings: settings,
    scope: { scope in
        scope.cardForm.cardNumberInput = { _ in
            CustomCardNumberField()
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