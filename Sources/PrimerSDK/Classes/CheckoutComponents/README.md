# CheckoutComponents

A modern, scope-based payment checkout framework for iOS 15+ that provides complete UI customization with exact Android API parity.

## Overview

CheckoutComponents is the newest payment integration approach in the Primer iOS SDK, designed to match the Android Composable API exactly. It provides a type-safe, scope-based architecture that allows complete customization of every UI component while maintaining sensible defaults.

### Key Features

- 🎯 **Exact Android API Parity**: Same methods, properties, and patterns across platforms
- 🎨 **Full UI Customization**: Replace any UI component while keeping others
- 🔄 **Reactive State Management**: AsyncStream-based state observation
- 💳 **Co-Badged Cards**: Automatic network detection with user selection
- 🏠 **Dynamic Billing Address**: API-driven field configuration
- 🔐 **Built-in 3DS**: Automatic 3D Secure handling
- 📱 **SwiftUI Native**: Modern Swift with async/await

## Requirements

- iOS 15.0+
- Swift 5.5+
- Xcode 13.0+

## Installation

CheckoutComponents is included in the main PrimerSDK. Follow the standard [SDK installation guide](https://primer.io/docs/sdk/ios).

## Quick Start

### UIKit Integration

```swift
import PrimerSDK

// Present with automatic view controller detection
CheckoutComponentsPrimer.presentCheckout(with: clientToken)

// Present from specific view controller
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController
)

// Set delegate for callbacks
CheckoutComponentsPrimer.delegate = self
```

### SwiftUI Integration

```swift
import SwiftUI
import PrimerSDK

struct ContentView: View {
    var body: some View {
        PrimerCheckout(
            clientToken: "your_client_token",
            settings: PrimerSettings()
        )
    }
}
```

## Customization

### Scope-Based Architecture

CheckoutComponents uses a scope-based API where each major component exposes a scope interface:

- `PrimerCheckoutScope`: Main checkout lifecycle and screens
- `PrimerCardFormScope`: Card payment form with validation
- `PrimerPaymentMethodSelectionScope`: Payment method selection
- `PrimerSelectCountryScope`: Country selection with search

### Customizing Individual Components

Replace specific UI components while keeping default behavior:

```swift
PrimerCheckout(
    clientToken: clientToken,
    settings: settings,
    scope: { checkoutScope in
        // Customize card number input
        checkoutScope.cardForm.cardNumberInput = { modifier in
            CustomCardNumberField(modifier: modifier)
        }
        
        // Customize loading screen
        checkoutScope.loadingScreen = {
            CustomLoadingView()
        }
        
        // Customize error screen
        checkoutScope.errorScreen = { error in
            CustomErrorView(message: error)
        }
    }
)
```

### Complete Custom UI

Replace the entire checkout UI while using the scope for logic:

```swift
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController
) { scope in
    VStack {
        // Custom header
        CustomHeaderView()
        
        // Use scope to show appropriate content
        switch scope.state {
        case .ready:
            // Access nested scopes
            CustomCardForm(scope: scope.cardForm)
        case .error(let error):
            CustomErrorView(error: error)
        default:
            ProgressView()
        }
    }
}
```

## Card Form Customization

The card form scope provides 15 update methods and 18 customizable UI components:

### Update Methods

```swift
let cardFormScope = checkoutScope.cardForm

// Update card details
cardFormScope.updateCardNumber("4111 1111 1111 1111")
cardFormScope.updateExpiryDate("12/25")
cardFormScope.updateCvv("123")
cardFormScope.updateCardholderName("John Doe")

// Update billing address
cardFormScope.updateFirstName("John")
cardFormScope.updateLastName("Doe")
cardFormScope.updateEmail("john@example.com")
cardFormScope.updatePhoneNumber("+1234567890")
cardFormScope.updateAddressLine1("123 Main St")
cardFormScope.updateAddressLine2("Apt 4B")
cardFormScope.updateCity("San Francisco")
cardFormScope.updateState("CA")
cardFormScope.updatePostalCode("94105")
cardFormScope.updateCountryCode("US")

// Submit the form
cardFormScope.submit()
```

### Customizable Components

```swift
scope.cardForm.cardNumberInput = { modifier in
    CustomCardNumberInput(modifier: modifier)
}

scope.cardForm.expiryDateInput = { modifier in
    CustomExpiryInput(modifier: modifier)
}

scope.cardForm.cvvInput = { modifier in
    CustomCVVInput(modifier: modifier)
}

// ... and 15 more components
```

## State Observation

Observe real-time state changes using AsyncStream:

```swift
Task {
    for await state in checkoutScope.state {
        switch state {
        case .initializing:
            print("Loading...")
        case .ready:
            print("Ready for payment")
        case .error(let error):
            print("Error: \(error)")
        case .dismissed:
            print("Checkout dismissed")
        }
    }
}

// Observe card form state
Task {
    for await cardState in checkoutScope.cardForm.state {
        print("Card valid: \(cardState.isValid)")
        print("Submitting: \(cardState.isSubmitting)")
        
        // Access all field states
        print("Card number: \(cardState.cardNumber)")
        print("Expiry: \(cardState.expiryDate)")
        // ... etc
    }
}
```

## Co-Badged Cards

CheckoutComponents automatically detects and handles co-badged cards:

```swift
// The framework automatically detects available networks
// and shows a selector when multiple networks are available

// Observe selected network
Task {
    for await state in checkoutScope.cardForm.state {
        if let network = state.selectedCardNetwork {
            print("Selected network: \(network)")
        }
    }
}
```

## Billing Address

Billing address fields are dynamically configured based on API response:

```swift
// Fields are automatically shown/hidden based on configuration
// The billing address is sent via Client Session Actions API
// separate from card tokenization

// Customize billing address section
scope.cardForm.billingAddressSection = { modifier in
    CustomBillingAddressView(
        scope: scope.cardForm,
        modifier: modifier
    )
}
```

## Payment Method Selection

Customize the payment method selection screen:

```swift
scope.paymentMethodSelectionScreen = { selectionScope in
    CustomPaymentMethodGrid(scope: selectionScope)
}

// Or customize individual components
scope.paymentMethodSelection.searchBar = { onSearch in
    CustomSearchBar(onSearch: onSearch)
}

scope.paymentMethodSelection.paymentMethodItem = { method in
    CustomPaymentMethodCell(method: method)
}
```

## Error Handling

CheckoutComponents integrates with the standard PrimerDelegate:

```swift
extension ViewController: PrimerDelegate {
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        // Payment successful
    }
    
    func primerDidFailWithError(_ error: PrimerError, data: PrimerCheckoutData?) -> PrimerErrorDecision {
        // Handle error
        return .fail(withMessage: error.localizedDescription)
    }
}
```

## Advanced Features

### 3D Secure

3DS is handled automatically by the framework:

```swift
// No additional code needed - 3DS challenges are presented
// automatically when required by the payment
```

### Custom Modifiers

Use PrimerModifier to style components consistently:

```swift
let customModifier = PrimerModifier(
    padding: EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20),
    background: .blue.opacity(0.1),
    cornerRadius: 12,
    border: (color: .blue, width: 1)
)

scope.cardForm.cardNumberInput = { _ in
    CardNumberInput()
        .primerModifier(customModifier)
}
```

### Future Support

Placeholders for upcoming features:

```swift
// Vaulting support (coming soon)
// scope.cardForm.saveCardToggle = { modifier in
//     SaveCardToggle(modifier: modifier)
// }

// Additional payment methods (coming soon)
// - Apple Pay
// - PayPal
// - Google Pay
// - Bank transfers
```

## Integration Examples

### Basic Integration

```swift
CheckoutComponentsPrimer.presentCheckout(with: token)
```

### Custom UI Integration

```swift
CheckoutComponentsPrimer.presentCheckout(with: token) { scope in
    // Your custom UI using scope for logic
}
```

## Best Practices

1. **State Observation**: Always use AsyncStream for state observation rather than polling
2. **Error Handling**: Implement PrimerDelegate for proper error handling
3. **Customization**: Start with default UI and customize only what you need
4. **Testing**: Test with various card types including co-badged cards
5. **Accessibility**: Maintain accessibility when creating custom components

## API Reference

For detailed API documentation, see:
- [PrimerCheckoutScope](Scope/PrimerCheckoutScope.swift)
- [PrimerCardFormScope](Scope/PrimerCardFormScope.swift)
- [PrimerPaymentMethodSelectionScope](Scope/PrimerPaymentMethodSelectionScope.swift)
- [PrimerSelectCountryScope](Scope/PrimerSelectCountryScope.swift)

## Support

For support, please refer to the [Primer documentation](https://primer.io/docs) or contact support@primer.io.