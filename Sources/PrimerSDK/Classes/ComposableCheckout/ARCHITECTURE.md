# ComposableCheckout Architecture (iOS)

## Overview

iOS ComposableCheckout follows Android's clean architecture with a scope-based API pattern:

1. **Internal Components**: Sophisticated input fields (CardNumberInputField, etc.)
2. **Scope Extensions**: Public API via CardFormScope.PrimerCardNumberInput()

## Architecture Layers

### Domain Layer ✅
- **Interactors**: Business logic use cases
  - `GetPaymentMethodsInteractor`: Fetch available payment methods
  - `ProcessCardPaymentInteractor`: Process card payments
  - `ValidatePaymentDataInteractor`: Validate payment data
  - `GetRequiredFieldsInteractor`: Determine required fields dynamically
- **Models**: Domain entities

### Data Layer ✅
- **Repositories**: Data access abstractions
  - `PaymentMethodRepository`: Payment method data
  - `PaymentRepository`: Payment processing
  - `TokenizationRepository`: Card tokenization
  - `ConfigurationRepository`: App configuration
- **Services**: External service integrations

### Presentation Layer
- **Scopes**: Public API matching Android exactly
  - `CardFormScope`: Card form state and operations
  - `PaymentMethodSelectionScope`: Payment selection state
- **ViewModels**: Scope implementations with business logic
- **Views**: SwiftUI components

## Key Principles

### 1. Single Source of Truth
- All state flows through scope
- No callbacks in public API
- Use scope update methods exclusively

### 2. Dynamic Field Visibility
- Fields shown/hidden based on backend configuration
- `GetRequiredFieldsInteractor` determines required fields
- Components check field requirements before rendering

### 3. Scope-Based API
```swift
// Inside a view with scope access
scope.PrimerCardNumberInput(modifier: .fillMaxWidth())
scope.PrimerCardDetails() // Composite component
scope.PrimerBillingAddress() // Shows required billing fields
scope.PrimerSubmitButton(text: "Pay Now")
```

### 4. No Static API
- No `PrimerComponents.swift`
- No wrapper layers
- Direct scope-to-component connection

## Component Architecture

### Input Components
Each input component follows this pattern:
1. Scope extension method (public API)
2. Direct component usage (internal)
3. State updates through scope methods
4. No external callbacks

Example:
```swift
extension CardFormScope {
    func PrimerCardNumberInput(modifier: PrimerModifier = PrimerModifier()) -> some View {
        CardNumberInputField(
            label: InputLocalizable.cardNumberLabel,
            placeholder: InputLocalizable.cardNumberPlaceholder,
            onCardNumberChange: { self.updateCardNumber($0) }
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
}
```

### Composite Components
- `PrimerCardDetails`: Groups card input fields
- `PrimerBillingAddress`: Groups billing fields
- Visibility controlled by state.cardFields/billingFields

## State Management

### CardFormState
```swift
struct CardFormState {
    let inputFields: [ComposableInputElementType: String]
    let fieldErrors: [ComposableInputValidationError]
    let isLoading: Bool
    let isSubmitEnabled: Bool
    let cardNetwork: CardNetwork?
    let cardFields: [ComposableInputElementType]     // Dynamic from backend
    let billingFields: [ComposableInputElementType]  // Dynamic from backend
}
```

### State Flow
1. Backend configuration determines required fields
2. `GetRequiredFieldsInteractor` fetches field requirements
3. ViewModel initializes state with dynamic fields
4. Components render based on field lists
5. User input flows through scope update methods
6. Validation happens in real-time
7. Submit enabled when all required fields valid

## Navigation

iOS uses `CheckoutNavigator` pattern similar to Android:
- Navigation events dispatched via Combine
- Screens respond to navigation state
- Environment-based navigator access

## Localization

All strings extracted to `InputLocalizable.swift`:
- No hardcoded strings in components
- Centralized string management
- Easy to integrate with localization system

## Dependency Injection

Modern async/await DI container:
- Actor-based thread safety
- Three retention policies
- SwiftUI environment integration
- All dependencies registered in `CompositionRoot`

## Testing Strategy

1. **Unit Tests**: Test interactors and validators
2. **Integration Tests**: Test scope implementations
3. **UI Tests**: Test complete user flows
4. **Snapshot Tests**: Verify UI consistency

## Differences from Android (Acceptable)

1. **Component Implementation**: iOS components built from scratch (larger codebase)
2. **Navigation**: Custom `CheckoutNavigator` instead of Compose Navigation
3. **DI System**: Custom async/await container instead of Hilt/Koin
4. **Localization**: `InputLocalizable.swift` instead of string resources

## Usage Example

```swift
struct CardPaymentView: View {
    let scope: CardFormScope
    
    var body: some View {
        VStack {
            // Composite components
            scope.PrimerCardDetails()
            scope.PrimerBillingAddress()
            
            // Individual components with modifiers
            scope.PrimerSubmitButton(
                modifier: .fillMaxWidth().padding(16),
                text: "Complete Payment"
            )
        }
    }
}
```

## Migration Notes

When migrating from the old API:
1. Remove all `PrimerComponents` usage
2. Remove all wrapper components
3. Access components only through scope
4. Update state management to use scope methods
5. Let field visibility be controlled by backend