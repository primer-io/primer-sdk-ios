# CLAUDE.md - Payment Methods

This directory would contain various payment method implementations. Currently focused on CheckoutComponents payment methods with modern SwiftUI architecture.

## Current Structure

### Card Payments (`Card/`)
Modern card payment implementation using the CheckoutComponents architecture:

**Core Components**:
- `CardPaymentMethod.swift`: Implements `PaymentMethodProtocol`
- `CardPaymentMethodScope.swift`: DI scope for card-specific dependencies
- `CardViewModel.swift`: Business logic and state management
- `CardPaymentView.swift`: SwiftUI presentation layer

**Validation System** (`Validation/`):
- Field-specific validators following the validation framework
- `PaymentFormValidator.swift`: Coordinates multiple field validations
- `ValidationRules/`: Individual validation rules for each field type

**UI Components** (`View/`):
- `CardNumberInputField.swift`: Secure card number input
- `CVVInputField.swift`: CVV input with smart masking
- `ExpiryDateInputField.swift`: Date picker with validation
- `CardholderNameInputField.swift`: Name input field

### Apple Pay (`ApplePay/`)
**Status**: Placeholder for Apple Pay implementation
**TODO**: Implement using CheckoutComponents patterns

### PayPal (`PayPal/`)
**Status**: Placeholder for PayPal implementation
**TODO**: Implement using CheckoutComponents patterns

## Architecture Patterns

### Payment Method Implementation Pattern
Each payment method should follow this consistent structure:

```
PaymentMethodName/
├── PaymentMethodNamePaymentMethod.swift     # PaymentMethodProtocol implementation
├── PaymentMethodNameScope.swift            # DependencyScope for method-specific deps
├── PaymentMethodNameViewModel.swift        # Business logic and state management
├── PaymentMethodNameView.swift            # SwiftUI presentation
├── PaymentMethodNameUiState.swift         # UI state management (if complex)
├── Validation/                            # Input validation (if needed)
│   ├── PaymentMethodNameValidator.swift
│   └── ValidationRules/
│       └── PaymentMethodNameRule.swift
└── View/                                  # Reusable UI components
    └── PaymentMethodNameInputField.swift
```

### Core Protocol Implementation
All payment methods must implement `PaymentMethodProtocol`:

```swift
@MainActor
final class CardPaymentMethod: PaymentMethodProtocol {
    let id = "payment_method_id"
    let name = "Payment Method Name"
    let icon = "payment.icon"
    
    func process() async throws -> PaymentResult {
        // Implementation for processing payment
    }
    
    func createView() -> AnyView {
        AnyView(PaymentMethodView())
    }
}
```

### Dependency Scope Pattern
Each payment method should define its own dependency scope:

```swift
@MainActor
final class CardPaymentMethodScope: DependencyScope {
    let id = "card_payment_scope"
    
    func configure(container: any ContainerProtocol) async throws {
        // Register method-specific dependencies
        _ = try await container.register(CardValidator.self)
            .asSingleton()
            .with { resolver in
                CardValidatorImpl()
            }
    }
}
```

### ViewModel Pattern
ViewModels handle business logic and state management:

```swift
@MainActor
class PaymentMethodViewModel: ObservableObject {
    @Published var state: PaymentMethodUiState = .initial
    @Published var validationErrors: [ValidationError] = []
    
    private let validator: PaymentMethodValidator
    private let paymentService: PaymentService
    
    init(validator: PaymentMethodValidator, paymentService: PaymentService) {
        self.validator = validator
        self.paymentService = paymentService
    }
    
    func processPayment() async {
        // Business logic implementation
    }
}
```

### SwiftUI View Pattern
Views are presentation-only and leverage the validation framework:

```swift
struct PaymentMethodView: View {
    @StateObject private var viewModel: PaymentMethodViewModel
    @Environment(\.diContainer) private var container
    
    var body: some View {
        VStack {
            // Use PrimerInputField for consistent validation UI
            PrimerInputField(
                validator: viewModel.fieldValidator,
                placeholder: "Enter payment details"
            )
            
            Button("Process Payment") {
                Task {
                    await viewModel.processPayment()
                }
            }
        }
    }
}
```

## Validation Integration

### Using the Validation Framework
All payment methods should leverage the common validation system:

1. **Create Validation Rules**:
```swift
struct CardNumberRule: ValidationRule {
    let id = "card_number"
    let errorMessage = "Invalid card number"
    
    func validate(_ value: String) -> Bool {
        // Luhn algorithm validation
        return LuhnValidator.validate(value)
    }
}
```

2. **Implement Field Validators**:
```swift
class CardNumberValidator: BaseInputFieldValidator {
    override var rules: [ValidationRule] {
        [
            CardNumberRule(),
            LengthRule(minLength: 13, maxLength: 19)
        ]
    }
}
```

3. **Use in UI Components**:
```swift
PrimerInputField(
    validator: CardNumberValidator(),
    placeholder: "Card Number",
    keyboardType: .numberPad
)
```

## Design Token Integration

### Using Design Tokens
All payment method UIs should use the design token system:

```swift
struct PaymentMethodView: View {
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        VStack {
            // Use design tokens for consistent styling
            Text("Payment Details")
                .font(tokens.typography.heading)
                .foregroundColor(tokens.colors.primary)
        }
        .padding(tokens.spacing.medium)
        .background(tokens.colors.surface)
    }
}
```

## Testing Strategy

### Unit Testing
Each payment method should have comprehensive tests:

1. **ViewModel Tests**: Business logic and state management
2. **Validation Tests**: Input validation rules
3. **Integration Tests**: Full payment flow testing
4. **UI Tests**: SwiftUI component behavior

### Mock Implementation
Use the DI system for easy mocking:

```swift
// In tests
_ = try await container.register(PaymentService.self)
    .asTransient()
    .with { resolver in
        MockPaymentService()
    }
```

## Adding New Payment Methods

### Step-by-Step Guide

1. **Create Directory Structure**:
   ```
   PaymentMethods/NewMethod/
   ├── NewMethodPaymentMethod.swift
   ├── NewMethodScope.swift
   ├── NewMethodViewModel.swift
   ├── NewMethodView.swift
   └── Validation/
   ```

2. **Implement Core Protocol**:
   - PaymentMethodProtocol for the main implementation
   - DependencyScope for method-specific dependencies

3. **Create Business Logic**:
   - ViewModel with @Published properties
   - Integration with validation framework
   - Error handling and state management

4. **Design UI Components**:
   - SwiftUI views using design tokens
   - Reusable input fields
   - Consistent user experience

5. **Register in ComposableContainer**:
   ```swift
   _ = try? await container.register((any PaymentMethodProtocol).self)
       .named("new_method")
       .asTransient()
       .with { resolver in
           return await NewMethodPaymentMethod()
       }
   ```

6. **Add Comprehensive Tests**:
   - Unit tests for all components
   - Integration tests for full flow
   - UI tests for user interactions

### Integration Checklist
- [ ] Implements PaymentMethodProtocol
- [ ] Creates dedicated DependencyScope
- [ ] Uses validation framework for input validation
- [ ] Leverages design tokens for consistent UI
- [ ] Includes comprehensive test coverage
- [ ] Follows SwiftUI best practices
- [ ] Handles errors gracefully
- [ ] Supports accessibility features
- [ ] Documents usage patterns

## Future Enhancements

### Planned Payment Methods
1. **Apple Pay**: Native iOS payment integration
2. **PayPal**: Web-based OAuth flow
3. **Google Pay**: Android-style integration for cross-platform
4. **Bank Transfers**: Direct bank account integration
5. **Buy Now Pay Later**: Klarna, Afterpay, etc.
6. **Cryptocurrency**: Bitcoin, Ethereum support
7. **Digital Wallets**: Various regional wallet integrations

### Architecture Improvements
1. **Dynamic Loading**: Load payment methods on demand
2. **Configuration-Driven**: Payment methods configured via API
3. **Plugin System**: Third-party payment method plugins
4. **Offline Support**: Handle offline payment scenarios
5. **Biometric Authentication**: Enhanced security features