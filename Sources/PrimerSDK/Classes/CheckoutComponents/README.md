# CheckoutComponents

A modern, scope-based payment checkout framework for iOS 15+ that provides complete UI customization with exact Android API parity.

## Overview

CheckoutComponents is the newest payment integration approach in the Primer iOS SDK, designed to match the Android Composable API exactly. It provides a type-safe, scope-based architecture that allows complete customization of every UI component while maintaining sensible defaults.

### Key Features

- 🎯 **Exact Android API Parity**: Same methods, properties, and patterns across platforms
- 🎨 **Full UI Customization**: Replace any UI component while keeping others
- 🔄 **Reactive State Management**: AsyncStream-based state observation
- 💳 **Co-Badged Cards**: Automatic network detection with user selection and surcharge support
- 🏠 **Dynamic Billing Address**: API-driven field configuration with smart visibility
- 🔐 **Built-in 3DS**: Automatic 3D Secure handling with delegate callbacks
- 📱 **SwiftUI Native**: Modern Swift with async/await and ViewBuilder patterns
- 🎯 **Type-Safe API**: Structured state management with comprehensive field validation
- 🧩 **Modular Architecture**: Mix and match SDK components with custom UI
- 🚀 **Smart Navigation**: Context-aware presentation and dismissal

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

let settings = PrimerSettings(
    debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false),
    uiOptions: PrimerUIOptions(
        appearanceMode: .dark
    )
)

// Present default checkout UI
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController,
    primerSettings: settings
) {
    // Optional completion
}

// Present with custom UI
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController,
    primerSettings: settings,
    customContent: { scope in
        // Your custom SwiftUI content using the scope
        CustomCheckoutView(scope: scope)
    }
)

// Present card form directly
CheckoutComponentsPrimer.presentCardForm(
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
        // Use the checkout scope directly in your SwiftUI view
        CheckoutView(clientToken: "your_client_token")
    }
}
```

### Theme Customization

CheckoutComponents supports separate theme configuration for Android API parity:

```swift
// Create a custom theme
let customTheme = PrimerTheme()
customTheme.colorScheme.primaryColor = .purple
customTheme.cornerRadius = 12

// UIKit: Pass theme separately from settings
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: self,
    primerSettings: PrimerSettings(),
    primerTheme: customTheme
)

// SwiftUI: Pass theme to PrimerCheckout
PrimerCheckout(
    clientToken: clientToken,
    primerSettings: PrimerSettings(),
    primerTheme: customTheme
)

// Theme overrides the theme in settings if both are provided
let settings = PrimerSettings()
settings.uiOptions.theme = defaultTheme

CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: self,
    primerSettings: settings,
    primerTheme: customTheme  // ← This takes precedence
)
```

## Customization

### Scope-Based Architecture

CheckoutComponents uses a hierarchical scope-based API where each major component exposes a scope interface:

- **`PrimerCheckoutScope`**: Main checkout lifecycle, navigation, and screen customization
- **`PrimerPaymentMethodSelectionScope`**: Payment method grid and selection UI
- **`PrimerCardFormScope`**: Comprehensive card form with field-level customization
- **`PrimerPaymentMethodScope`**: Base protocol for all payment method implementations

Each scope provides:
- State observation via AsyncStream
- UI component customization closures
- SDK component access via ViewBuilder methods
- Navigation and action methods

### Customizing Individual Components

Replace specific UI components while keeping default behavior:

```swift
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController,
    customContent: { checkoutScope in
        // Default UI with customizations
        VStack {
            // Access payment method scopes dynamically
            if let cardScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) as? PrimerCardFormScope {
                // Customize individual fields
                cardScope.cardNumberField = { label, styling in
                    AnyView(CustomCardNumberField(
                        label: label,
                        styling: styling,
                        onChange: cardScope.updateCardNumber
                    ))
                }
                
                // Or use SDK components with custom styling
                cardScope.PrimerCardNumberField(
                    label: "Card Number",
                    styling: PrimerFieldStyling(
                        backgroundColor: .gray.opacity(0.1),
                        cornerRadius: 12
                    )
                )
            }
        }
    }
)
```

### Using SDK Components with Custom Styling

The ViewBuilder pattern allows you to use SDK components with custom styling:

```swift
// Inside your custom content
cardScope.PrimerCardNumberField(
    label: "Card Number",
    styling: PrimerFieldStyling(
        font: .system(size: 16),
        textColor: .primary,
        backgroundColor: .gray.opacity(0.05),
        borderColor: .gray.opacity(0.3),
        focusedBorderColor: .blue,
        errorBorderColor: .red,
        cornerRadius: 8,
        borderWidth: 1,
        padding: EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16),
        fieldHeight: 56
    )
)
.overlay(alignment: .trailing) {
    // Add custom overlays
    cardScope.state.detectedCardNetwork.map { network in
        Image(network.logo)
            .padding(.trailing, 16)
    }
}
```

### Complete Custom UI

Replace the entire checkout UI while using the scope for logic:

```swift
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController,
    customContent: { scope in
        VStack {
            // Custom header with navigation
            HStack {
                Button("Cancel") {
                    scope.onCancel()
                }
                Spacer()
                Text("Checkout")
                Spacer()
            }
            
            // Use scope state for content
            switch scope.state {
            case .initializing:
                ProgressView("Loading payment methods...")
            
            case .ready:
                // Show payment method selection
                if let selectionScope = scope.paymentMethodSelection {
                    CustomPaymentMethodGrid(scope: selectionScope)
                }
                
            case .error(let error):
                CustomErrorView(error: error) {
                    scope.retry()
                }
                
            case .dismissed:
                EmptyView()
            }
        }
    }
)
```

## Card Form Customization

The card form scope provides comprehensive customization with:
- Type-safe update methods for all fields
- Field-level and section-level UI customization
- Built-in validation and error handling
- Dynamic field visibility based on configuration

### Update Methods

```swift
// Access card form scope
if let cardScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) as? PrimerCardFormScope {
    // Update card details
    cardScope.updateCardNumber("4111 1111 1111 1111")
    cardScope.updateExpiryDate("12/25")
    cardScope.updateCvv("123")
    cardScope.updateCardholderName("John Doe")
    
    // Update billing address
    cardScope.updateFirstName("John")
    cardScope.updateLastName("Doe")
    cardScope.updateEmail("john@example.com")
    cardScope.updatePhoneNumber("+1234567890")
    cardScope.updateAddressLine1("123 Main St")
    cardScope.updateAddressLine2("Apt 4B")
    cardScope.updateCity("San Francisco")
    cardScope.updateState("CA")
    cardScope.updatePostalCode("94105")
    cardScope.updateCountryCode("US")
    
    // Select card network for co-badged cards
    cardScope.selectCardNetwork(.visa)
    
    // Submit the form
    cardScope.submit()
}
```

### Customizable Components

CheckoutComponents provides three approaches for customization:

#### 1. Field-Level Customization (Replace Individual Fields)

```swift
if let cardScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) as? PrimerCardFormScope {
    // Replace card number field with custom implementation
    cardScope.cardNumberField = { label, styling in
        AnyView(CustomCardNumberInput(
            label: label,
            styling: styling,
            onChange: cardScope.updateCardNumber,
            validation: cardScope.state.cardNumber
        ))
    }
    
    // Replace expiry date field
    cardScope.expiryDateField = { label, styling in
        AnyView(CustomExpiryInput(
            label: label,
            styling: styling,
            onChange: cardScope.updateExpiryDate,
            validation: cardScope.state.expiryDate
        ))
    }
}
```

#### 2. Section-Level Customization (Group Multiple Fields)

```swift
// Customize entire card input section
cardScope.cardInputSection = { modifier in
    CustomCardSection(
        scope: cardScope,
        modifier: modifier
    )
}

// Customize billing address section
cardScope.billingAddressSection = { modifier in
    CustomBillingSection(
        scope: cardScope,
        modifier: modifier,
        fields: cardScope.state.configuration.billingAddressFields
    )
}
```

#### 3. SDK Components with Custom Styling

```swift
// Use SDK components with ViewBuilder pattern
VStack(spacing: 16) {
    cardScope.PrimerCardNumberField(
        label: "Card Number",
        styling: customStyling
    )
    
    HStack(spacing: 12) {
        cardScope.PrimerExpiryDateField(
            label: "Expiry",
            styling: customStyling
        )
        
        cardScope.PrimerCvvField(
            label: "CVV",
            styling: customStyling
        )
    }
    
    // Conditional fields based on configuration
    if cardScope.state.configuration.isCardholderNameRequired {
        cardScope.PrimerCardholderNameField(
            label: "Name on Card",
            styling: customStyling
        )
    }
}
```

All customizable fields include:
- Card fields: cardNumberField, expiryDateField, cvvField, cardholderNameField
- Billing fields: firstNameField, lastNameField, emailField, phoneNumberField
- Address fields: addressLine1Field, addressLine2Field, cityField, stateField, postalCodeField, countryField
- UI elements: cardNetworkSelector, countrySelector, submitButton, cardInputSection, billingAddressSection

## State Observation

Observe real-time state changes using AsyncStream:

### Checkout State

```swift
Task {
    for await state in checkoutScope.state {
        switch state {
        case .initializing:
            print("Loading payment methods...")
        case .ready:
            print("Payment methods loaded")
        case .error(let error):
            print("Error: \(error.localizedDescription)")
        case .dismissed:
            print("Checkout dismissed")
        }
    }
}
```

### Card Form State

The card form provides a structured state with comprehensive field information:

```swift
Task {
    for await formState in cardScope.state {
        // Overall form state
        print("Form valid: \(formState.isValid)")
        print("Submitting: \(formState.isSubmitting)")
        print("Submit enabled: \(formState.isSubmitEnabled)")
        
        // Field-specific validation
        if let error = formState.cardNumber.error {
            print("Card number error: \(error.localizedDescription)")
        }
        
        // Co-badged card information
        if !formState.detectedCardNetworks.isEmpty {
            print("Available networks: \(formState.detectedCardNetworks)")
            print("Selected: \(formState.selectedCardNetwork ?? "None")")
        }
        
        // Surcharge information
        if let surcharge = formState.surcharge {
            print("Surcharge: \(surcharge.amount) \(surcharge.currency)")
        }
        
        // Dynamic field configuration
        print("Cardholder name required: \(formState.configuration.isCardholderNameRequired)")
        print("Billing fields: \(formState.configuration.billingAddressFields)")
    }
}
```

### Field State Structure

Each field in the form state includes:
```swift
struct FieldState<T> {
    let value: T?              // Current field value
    let isValid: Bool          // Validation status
    let error: FieldError?     // Specific error if invalid
    let isRequired: Bool       // Whether field is required
    let isVisible: Bool        // Whether field should be shown
}
```

## Co-Badged Cards

CheckoutComponents automatically detects and handles co-badged cards with network selection and surcharge support:

```swift
// Observe co-badged card state
Task {
    for await state in cardScope.state {
        // Multiple networks detected
        if state.detectedCardNetworks.count > 1 {
            print("Co-badged card detected: \(state.detectedCardNetworks)")
            
            // Network-specific surcharges
            for network in state.detectedCardNetworks {
                if let surcharge = state.getNetworkSurcharge(for: network) {
                    print("\(network): +\(surcharge.amount) \(surcharge.currency)")
                }
            }
        }
    }
}

// Programmatically select network
cardScope.selectCardNetwork(.mastercard)

// Customize network selector UI
cardScope.cardNetworkSelector = { networks, selected, onSelect in
    AnyView(CustomNetworkPicker(
        networks: networks,
        selected: selected,
        onSelect: onSelect
    ))
}
```

## Billing Address

Billing address fields are dynamically configured based on API response:

```swift
// Check which fields are required
let config = cardScope.state.configuration
print("Required billing fields: \(config.billingAddressFields)")

// Fields can include: firstName, lastName, email, phoneNumber,
// addressLine1, addressLine2, city, state, postalCode, countryCode

// Customize billing address section
cardScope.billingAddressSection = { modifier in
    VStack(alignment: .leading, spacing: 12) {
        Text("Billing Address")
            .font(.headline)
        
        // Only show required fields
        ForEach(config.billingAddressFields, id: \.self) { field in
            switch field {
            case .email:
                cardScope.PrimerEmailField(
                    label: "Email",
                    styling: customStyling
                )
            case .countryCode:
                cardScope.PrimerCountryField(
                    label: "Country",
                    styling: customStyling
                )
            // ... handle other fields
            default:
                EmptyView()
            }
        }
    }
    .primerModifier(modifier)
}

// Country selection with search
cardScope.countrySelector = { countries, selected, onSelect in
    AnyView(CustomCountryPicker(
        countries: countries,
        selected: selected,
        onSelect: onSelect,
        searchEnabled: true
    ))
}
```

## Payment Method Selection

Customize the payment method selection screen:

```swift
// Access payment method selection scope
if let selectionScope = checkoutScope.paymentMethodSelection {
    // Replace entire selection screen
    selectionScope.screen = { scope in
        AnyView(CustomPaymentMethodGrid(
            methods: scope.state.paymentMethods,
            onSelect: scope.onPaymentMethodSelected
        ))
    }
    
    // Or customize individual components
    selectionScope.paymentMethodItem = { method in
        AnyView(CustomPaymentMethodCell(
            method: method,
            showSurcharge: method.surcharge != nil
        ))
    }
    
    // Custom category headers
    selectionScope.categoryHeader = { category in
        AnyView(
            Text(category.displayName)
                .font(.headline)
                .padding(.vertical, 8)
        )
    }
    
    // Empty state when no methods available
    selectionScope.emptyStateView = {
        AnyView(
            VStack {
                Image(systemName: "creditcard.slash")
                Text("No payment methods available")
            }
        )
    }
}

// Observe selection state
Task {
    for await state in selectionScope.state {
        print("Available methods: \(state.paymentMethods.count)")
        print("Categories: \(state.categories)")
    }
}
```

## Error Handling

CheckoutComponents uses the CheckoutComponentsDelegate protocol:

```swift
extension ViewController: CheckoutComponentsDelegate {
    func checkoutComponentsDidCompletePayment(with data: PrimerCheckoutData) {
        print("Payment successful: \(data.payment.id)")
        // Handle successful payment
    }
    
    func checkoutComponentsDidFailWithError(_ error: PrimerError, data: PrimerCheckoutData?) -> PrimerErrorDecision {
        switch error.errorCode {
        case .paymentFailed:
            // Allow retry
            return .retry
        case .userCancelled:
            // Dismiss checkout
            return .fail()
        default:
            // Show error message
            return .fail(withMessage: error.localizedDescription)
        }
    }
    
    func checkoutComponentsDidDismiss() {
        print("Checkout dismissed")
    }
    
    // 3DS handling
    func checkoutComponentsWillPresent3DS() {
        print("3DS challenge will be presented")
    }
    
    func checkoutComponentsDidPresent3DS() {
        print("3DS challenge presented")
    }
    
    func checkoutComponentsWillDismiss3DS() {
        print("3DS challenge will be dismissed")
    }
    
    func checkoutComponentsDidComplete3DS(with result: ThreeDSResult) {
        print("3DS completed: \(result)")
    }
}

// Set the delegate
CheckoutComponentsPrimer.delegate = self
```

## Advanced Features

### 3D Secure

3DS is handled automatically with delegate callbacks for tracking:

```swift
// Implement delegate methods for 3DS lifecycle
extension ViewController: CheckoutComponentsDelegate {
    func checkoutComponentsWillPresent3DS() {
        // Prepare UI for 3DS presentation
    }
    
    func checkoutComponentsDidComplete3DS(with result: ThreeDSResult) {
        switch result {
        case .success:
            print("3DS authentication successful")
        case .failure(let error):
            print("3DS failed: \(error)")
        case .cancelled:
            print("3DS cancelled by user")
        }
    }
}
```

### Dynamic Settings Updates

For advanced use cases where settings need to be updated during an active checkout session, use the `updateSettings` API:

```swift
// Update settings mid-session (rare use case)
let updatedSettings = PrimerSettings()
updatedSettings.uiOptions.theme = darkModeTheme
updatedSettings.uiOptions.isSuccessScreenEnabled = false

await CheckoutComponentsPrimer.updateSettings(updatedSettings)
```

**When to use dynamic updates:**
- Switching themes based on user preference during checkout
- Enabling/disabling screens dynamically based on flow
- Updating debug options for testing

**Which settings can be updated mid-session:**
- UI options (theme, screen visibility, dismissal mechanism)
- Debug options (3DS sanity check)
- Payment method options (Apple Pay configuration, URL schemes)

**Important notes:**
- This is a rare use case - most merchants should pass settings once at initialization
- Settings changes take effect immediately for components that observe them
- Not all settings changes make sense mid-session (e.g., changing fundamental payment configuration)
- If no active checkout session exists, the update will fail gracefully with an error

**Best practice:**
```swift
// ✅ Recommended: Set settings at initialization
let settings = PrimerSettings()
settings.uiOptions.theme = customTheme
CheckoutComponentsPrimer.presentCheckout(with: clientToken, from: self, settings: settings)

// ❌ Avoid unless necessary: Updating settings mid-session
// Only use when you have a specific requirement to change settings after checkout has started
```

### Navigation and Presentation Context

CheckoutComponents supports smart navigation based on presentation context:

```swift
// Direct presentation
CheckoutComponentsPrimer.presentCardForm(
    with: clientToken,
    from: viewController
)

// The framework tracks presentation context
// and adjusts navigation behavior accordingly:
// - Back button shows when navigating from payment selection
// - Cancel button shows for direct presentation
```

### Dynamic Payment Method Registration

The framework supports dynamic payment method registration:

```swift
// Payment methods are registered automatically based on configuration
// Each payment method type has its own scope implementation
// Access dynamically via:
let paymentMethodScope = checkoutScope.getPaymentMethodScope(for: paymentMethodType)
```

### Field Validation

Comprehensive field validation with specific error codes:

```swift
enum FieldError {
    case required
    case invalidFormat
    case invalidCardNumber
    case invalidExpiryDate
    case invalidCvv
    case invalidEmail
    case custom(String)
}

// Access field errors
if let error = cardScope.state.cardNumber.error {
    switch error {
    case .invalidCardNumber:
        showError("Please enter a valid card number")
    case .required:
        showError("Card number is required")
    default:
        showError(error.localizedDescription)
    }
}
```

### Surcharge Support

Display payment method and network-specific surcharges:

```swift
// Payment method surcharge
if let surcharge = paymentMethod.surcharge {
    Text("+ \(surcharge.amount) \(surcharge.currency)")
}

// Network-specific surcharges for co-badged cards
cardScope.state.detectedCardNetworks.forEach { network in
    if let surcharge = cardScope.state.getNetworkSurcharge(for: network) {
        print("\(network): +\(surcharge.formatted)")
    }
}
```

## Integration Examples

### Basic Integration

```swift
// Simplest integration - default UI
CheckoutComponentsPrimer.delegate = self
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController
)
```

### Custom Card Form

```swift
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController,
    customContent: { scope in
        if let cardScope = scope.getPaymentMethodScope(for: .paymentCard) as? PrimerCardFormScope {
            VStack(spacing: 20) {
                // Custom header
                CustomHeaderView()
                
                // Mix SDK and custom components
                cardScope.PrimerCardNumberField(
                    label: "Card Number",
                    styling: customStyling
                )
                
                HStack {
                    cardScope.PrimerExpiryDateField(styling: customStyling)
                    cardScope.PrimerCvvField(styling: customStyling)
                }
                
                // Custom billing section
                if !cardScope.state.configuration.billingAddressFields.isEmpty {
                    CustomBillingAddressView(scope: cardScope)
                }
                
                // Submit button with loading state
                Button(action: cardScope.submit) {
                    if cardScope.state.isSubmitting {
                        ProgressView()
                    } else {
                        Text("Pay \(cardScope.state.amount.formatted)")
                    }
                }
                .disabled(!cardScope.state.isSubmitEnabled)
            }
        }
    }
)
```

### Complete Custom Checkout

```swift
struct CustomCheckoutView: View {
    let scope: PrimerCheckoutScope
    
    var body: some View {
        NavigationView {
            switch scope.state {
            case .initializing:
                LoadingView()
                
            case .ready:
                if let selectionScope = scope.paymentMethodSelection {
                    PaymentMethodGrid(
                        methods: selectionScope.state.paymentMethods,
                        onSelect: { method in
                            selectionScope.onPaymentMethodSelected(method)
                        }
                    )
                }
                
            case .error(let error):
                ErrorView(error: error) {
                    scope.retry()
                }
                
            case .dismissed:
                EmptyView()
            }
        }
    }
}

// Present with custom view
CheckoutComponentsPrimer.presentCheckout(
    with: clientToken,
    from: viewController,
    customContent: { scope in
        CustomCheckoutView(scope: scope)
    }
)
```

## Best Practices

1. **State Observation**: Use AsyncStream for reactive state updates
   ```swift
   Task {
       for await state in scope.state {
           updateUI(for: state)
       }
   }
   ```

2. **Error Handling**: Implement CheckoutComponentsDelegate for comprehensive error handling
   ```swift
   func checkoutComponentsDidFailWithError(_ error: PrimerError, data: PrimerCheckoutData?) -> PrimerErrorDecision {
       // Return .retry for recoverable errors
       // Return .fail() for terminal errors
   }
   ```

3. **Customization Strategy**: 
   - Start with default UI
   - Use SDK components with custom styling for quick customization
   - Replace individual fields only when needed
   - Build complete custom UI only for unique requirements

4. **Performance**:
   - Reuse scope references instead of repeatedly calling `getPaymentMethodScope`
   - Batch state updates when possible
   - Use structured state properties instead of parsing raw values

5. **Testing Considerations**:
   - Test with various card types including co-badged cards
   - Verify dynamic field visibility with different configurations
   - Test error states and recovery flows
   - Validate 3DS flows with test cards

6. **Accessibility**:
   - Maintain VoiceOver support in custom components
   - Use semantic colors that respect Dark Mode
   - Provide clear error messages with actionable guidance
   - Ensure touch targets meet minimum size requirements

## Migration Guide

For teams migrating from other Primer checkout solutions:

1. **From Drop-In Checkout**: CheckoutComponents offers the same ease of integration with added customization options
2. **From Headless Checkout**: Use the scope-based API for similar programmatic control with better type safety
3. **From Raw API**: CheckoutComponents handles tokenization, 3DS, and validation automatically

## API Reference

For detailed API documentation, see:
- [CheckoutComponentsPrimer](CheckoutComponentsPrimer.swift)
- [PrimerCheckoutScope](Scope/PrimerCheckoutScope.swift)
- [PrimerCardFormScope](Scope/PrimerCardFormScope.swift)
- [PrimerPaymentMethodSelectionScope](Scope/PrimerPaymentMethodSelectionScope.swift)
- [StructuredCardFormState](State/StructuredCardFormState.swift)

## Support

For support, please refer to the [Primer documentation](https://primer.io/docs) or contact support@primer.io.
