# CheckoutComponents

A modern, scope-based payment checkout framework for iOS 15+ that provides complete UI customization.

## Overview

CheckoutComponents is the newest payment integration approach in the Primer iOS SDK. It provides a type-safe, slot-based architecture that allows complete customization of every UI component while maintaining sensible defaults.

### Key Features

- 🎨 **Slot-Based Customization**: Override any section `@ViewBuilder` slot while keeping others
- 🔄 **Reactive State Management**: `@Published` state observation via observable sessions
- 💳 **Co-Badged Cards**: Automatic network detection with user selection and surcharge support
- 🏠 **Dynamic Billing Address**: API-driven field configuration with smart visibility
- 🔐 **Built-in 3DS**: Automatic 3D Secure handling with delegate callbacks
- 📱 **SwiftUI Native**: Modern Swift with async/await and ViewBuilder patterns
- 🎯 **Type-Safe API**: Structured state management with comprehensive field validation
- 🧩 **Modular Architecture**: Compose SDK building blocks with custom UI
- 🚀 **Smart Navigation**: Context-aware presentation and dismissal

## Requirements

- iOS 15.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

CheckoutComponents is included in the main PrimerSDK. Follow the standard [SDK installation guide](https://primer.io/docs/sdk/ios).

## Quick Start

### UIKit Integration

```swift
import PrimerSDK

// Set delegate for result callbacks
PrimerCheckoutPresenter.shared.delegate = self

// Present default checkout UI
PrimerCheckoutPresenter.presentCheckout(
    clientToken: clientToken,
    from: viewController,
    primerSettings: PrimerSettings(
        debugOptions: PrimerDebugOptions(is3DSSanityCheckEnabled: false)
    )
)
```

### SwiftUI Integration — Managed Modal

```swift
import SwiftUI
import PrimerSDK

struct ContentView: View {
    var body: some View {
        PrimerCheckout(
            clientToken: "your_client_token",
            primerSettings: PrimerSettings(),
            onCompletion: { state in
                // Handle checkout result
            }
        )
    }
}
```

### SwiftUI Integration — Composable/Inline

Embed the composable views in your own layout and wire them with `.primerCheckoutSession(_:onCompletion:)`:

```swift
import SwiftUI
import PrimerSDK

struct CheckoutView: View {
    @StateObject private var session = PrimerCheckoutSession(clientToken: "your_client_token")

    var body: some View {
        ScrollView {
            PrimerPaymentMethods()
            PrimerCardForm()
        }
        .primerCheckoutSession(session) { state in
            // Handle checkout state: .success, .failure, .dismissed
        }
    }
}
```

### Theme Customization

Visual styling is token-driven via `PrimerCheckoutTheme`:

```swift
let theme = PrimerCheckoutTheme(
    colors: ColorOverrides(primerColorBrand: .purple),
    radius: RadiusOverrides(primerRadiusBase: 12)
)

// UIKit
PrimerCheckoutPresenter.presentCheckout(
    clientToken: clientToken,
    from: self,
    primerSettings: PrimerSettings(),
    primerTheme: theme
)

// SwiftUI
PrimerCheckout(
    clientToken: clientToken,
    primerTheme: theme
)
```

## Customization

### Slot-Based Architecture

CheckoutComponents uses composable views with `@ViewBuilder` section slots. Each view exposes named slots; pass custom content to override one slot while keeping the others as defaults.

- **`PrimerCardForm`**: three slots — `cardDetails`, `billingAddress`, `submitButton`, each `(PrimerCardFormSession) -> some View`
- **`PrimerPaymentMethods`**: three slots — `header`, `method (CheckoutPaymentMethod, onSelect)`, `emptyState`
- **`PrimerVaultedPaymentMethods`**: three `AnyView`-erased slots — `header`, `item (method, isSelected, onSelect)`, `submitButton (isLoading, isEnabled, onSubmit)`

Visual styling is theme-driven via `PrimerCheckoutTheme` (design tokens), not per-field styling structs.

### Customizing a Single Slot

Always use a **labeled** argument — a bare trailing closure binds to the last slot (`submitButton`):

```swift
PrimerCardForm(submitButton: { session in
    MyPayButton(isLoading: session.state.isLoading) { session.submit() }
})
```

### Recomposing a Section with Building Blocks

The `CardFormDefaults` namespace provides 15 per-field building blocks (`cardNumber`, `expiryDate`, `cvv`, `cardholderName`, `cardNetwork`, `countryCode`, `firstName`, `lastName`, `addressLine1`, `addressLine2`, `city`, `state`, `postalCode`, `phoneNumber`, `email`). Each self-hides unless its field is present in `CardFormConfiguration`:

```swift
PrimerCardForm(cardDetails: { session in
    VStack {
        CardFormDefaults.cardNumber(session)
        HStack {
            CardFormDefaults.expiryDate(session)
            CardFormDefaults.cvv(session)
        }
        CardFormDefaults.cardholderName(session)
        MyPromoBanner()
    }
})
```

### Custom Payment Method Row

```swift
PrimerPaymentMethods(method: { method, onSelect in
    MyBrandRow(name: method.name, surcharge: method.formattedSurcharge, action: onSelect)
})
```

## Card Form Customization

`PrimerCardFormSession` exposes the full mutation surface and publishes `PrimerCardFormState`. Access it inside any slot closure:

```swift
PrimerCardForm(submitButton: { session in
    Button("Pay \(session.state.surchargeAmount ?? "")") {
        session.submit()
    }
    .disabled(!session.state.isValid || session.state.isLoading)
})
```

Programmatic field updates (e.g. for custom text fields connected to `PrimerCardFormSession`):

```swift
session.updateCardNumber("4111111111111111")
session.updateExpiryDate("12/25")
session.updateCvv("123")
session.updateCardholderName("Jane Doe")
session.updateFirstName("Jane")
session.updateLastName("Doe")
session.updatePhoneNumber("+1234567890")
session.updateAddressLine1("123 Main St")
session.updateCity("San Francisco")
session.updateState("CA")
session.updatePostalCode("94105")
session.updateCountryCode("US")
session.selectCardNetwork(.visa)
```

Customizable sections via `CardFormDefaults` building blocks:
- Card fields: `cardNumber`, `expiryDate`, `cvv`, `cardholderName`, `cardNetwork`
- Billing fields: `firstName`, `lastName`, `email`, `phoneNumber`, `addressLine1`, `addressLine2`, `city`, `state`, `postalCode`, `countryCode`

## State Observation

The composable views observe state automatically via `@ObservedObject`. For custom logic outside a slot, read from the session directly:

### Card Form State

```swift
// Inside a slot closure — session is already @ObservedObject via PrimerCardForm.Bound
PrimerCardForm(cardDetails: { session in
    VStack {
        CardFormDefaults.cardDetails(session)
        if let surcharge = session.state.surchargeAmount {
            Text("Surcharge: \(surcharge)")
        }
        if session.state.availableNetworks.count > 1 {
            CardFormDefaults.cardNetwork(session)
        }
    }
})
```

`PrimerCardFormState` key properties:
- `isValid: Bool` — form is ready to submit
- `isLoading: Bool` — payment in progress
- `selectedNetwork: PrimerCardNetwork?`, `availableNetworks: [PrimerCardNetwork]`
- `surchargeAmountRaw: Int?`, `surchargeAmount: String?`
- `configuration: CardFormConfiguration` — which fields to show
- `fieldErrors: [FieldError]` — per-field validation errors

## Co-Badged Cards

CheckoutComponents automatically detects and handles co-badged cards with network selection and surcharge support.

Once the user selects a network, that choice is pinned and won't be overwritten by auto-detection as long as it remains in `availableNetworks` (implemented via `userSelectedNetwork` in `DefaultCardFormScope`).

The default `cardDetails` slot already renders the network selector when `availableNetworks.count > 1`. To override just the selector, replace the `cardDetails` slot using `CardFormDefaults.cardNetwork`:

```swift
PrimerCardForm(cardDetails: { session in
    CardFormDefaults.cardNumber(session)
    HStack {
        CardFormDefaults.expiryDate(session)
        CardFormDefaults.cvv(session)
    }
    if session.state.availableNetworks.count > 1 {
        MyNetworkPicker(
            networks: session.state.availableNetworks,
            selected: session.state.selectedNetwork,
            onSelect: session.selectCardNetwork
        )
    }
})
```

## Billing Address

Billing address fields are dynamically configured based on the API response (`CardFormConfiguration.requiresBillingAddress`, `.billingFields`). Each `CardFormDefaults.*` billing building block self-hides unless its field is in the configuration.

The default `billingAddress` slot handles this automatically. To recompose it:

```swift
PrimerCardForm(billingAddress: { session in
    if session.state.configuration.requiresBillingAddress {
        CardFormDefaults.firstName(session)
        CardFormDefaults.lastName(session)
        CardFormDefaults.email(session)
        CardFormDefaults.addressLine1(session)
        CardFormDefaults.city(session)
        CardFormDefaults.postalCode(session)
        CardFormDefaults.countryCode(session)
    }
})
```

## Payment Method Selection

Customize the payment method list via `PrimerPaymentMethods` slots:

```swift
PrimerPaymentMethods(
    header: { session in
        Text("Choose a payment method")
            .font(.headline)
    },
    method: { method, onSelect in
        CustomPaymentMethodRow(
            name: method.name,
            surcharge: method.formattedSurcharge,
            action: onSelect
        )
    },
    emptyState: { _ in
        VStack {
            Image(systemName: "creditcard.slash")
            Text("No payment methods available")
        }
    }
)
```

## Error Handling

CheckoutComponents uses `PrimerCheckoutPresenterDelegate` for UIKit integrations and the `onCompletion` closure for SwiftUI.

```swift
extension ViewController: PrimerCheckoutPresenterDelegate {
    // Required
    func primerCheckoutPresenterDidCompleteWithSuccess(_ result: PaymentResult) {
        print("Payment successful: \(result.paymentId)")
    }

    func primerCheckoutPresenterDidFailWithError(_ error: PrimerError) {
        print("Payment failed: \(error.localizedDescription)")
    }

    func primerCheckoutPresenterDidDismiss() {
        print("Checkout dismissed")
    }

    // Optional — 3DS lifecycle
    func primerCheckoutPresenterWillPresent3DSChallenge(_ paymentMethodTokenData: PrimerPaymentMethodTokenData) { }
    func primerCheckoutPresenterDidDismiss3DSChallenge() { }
    func primerCheckoutPresenterDidComplete3DSChallenge(success: Bool, resumeToken: String?, error: Error?) { }
}

PrimerCheckoutPresenter.shared.delegate = self
```

For SwiftUI, outcomes are delivered via `onCompletion`:

```swift
.primerCheckoutSession(session) { state in
    switch state {
    case .success(let result): handleSuccess(result)
    case .failure(let error): handleError(error)
    case .dismissed: dismiss()
    default: break
    }
}
```

## Advanced Features

### 3D Secure

3DS is handled automatically. The optional delegate methods let you track the lifecycle:

```swift
extension ViewController: PrimerCheckoutPresenterDelegate {
    func primerCheckoutPresenterWillPresent3DSChallenge(_ paymentMethodTokenData: PrimerPaymentMethodTokenData) {
        // Prepare UI for 3DS
    }
    func primerCheckoutPresenterDidDismiss3DSChallenge() { }
    func primerCheckoutPresenterDidComplete3DSChallenge(success: Bool, resumeToken: String?, error: Error?) {
        print("3DS completed: success=\(success)")
    }
}
```

Enable/disable the sanity check via `PrimerSettings.debugOptions.is3DSSanityCheckEnabled`.

### Field Validation

Field errors are available via `PrimerCardFormState.fieldErrors` and helper methods:

```swift
PrimerCardForm(cardDetails: { session in
    CardFormDefaults.cardDetails(session)
    if session.state.hasError(for: .cardNumber) {
        Text(session.state.errorMessage(for: .cardNumber) ?? "Invalid card number")
            .foregroundColor(.red)
    }
})
```

### Surcharge Support

Payment-method surcharges are exposed on `CheckoutPaymentMethod.surcharge`/`formattedSurcharge`, and card-network surcharges on `PrimerCardFormState.surchargeAmount`:

```swift
// Payment method row
PrimerPaymentMethods(method: { method, onSelect in
    HStack {
        Text(method.name)
        if let surcharge = method.formattedSurcharge {
            Text(surcharge).foregroundColor(.secondary)
        }
    }
    .onTapGesture(perform: onSelect)
})

// Card form
PrimerCardForm(submitButton: { session in
    Button("Pay \(session.state.surchargeAmount ?? "")") { session.submit() }
})
```

## Integration Examples

### Basic Integration (UIKit)

```swift
PrimerCheckoutPresenter.shared.delegate = self
PrimerCheckoutPresenter.presentCheckout(
    clientToken: clientToken,
    from: viewController
)
```

### Custom Card Form (SwiftUI)

```swift
@StateObject private var session = PrimerCheckoutSession(clientToken: token)

var body: some View {
    ScrollView {
        CustomHeaderView()
        PrimerCardForm(
            cardDetails: { session in
                VStack(spacing: 12) {
                    CardFormDefaults.cardNumber(session)
                    HStack {
                        CardFormDefaults.expiryDate(session)
                        CardFormDefaults.cvv(session)
                    }
                    CardFormDefaults.cardholderName(session)
                }
            },
            submitButton: { session in
                Button("Pay Now") { session.submit() }
                    .disabled(!session.state.isValid)
            }
        )
    }
    .primerCheckoutSession(session) { state in handle(state) }
}
```

### Custom Payment Selection (SwiftUI)

```swift
@StateObject private var session = PrimerCheckoutSession(clientToken: token)

var body: some View {
    PrimerPaymentMethods(method: { method, onSelect in
        HStack {
            if let icon = method.icon {
                Image(uiImage: icon).frame(width: 32, height: 32)
            }
            Text(method.name)
            Spacer()
            if let surcharge = method.formattedSurcharge {
                Text(surcharge).foregroundColor(.secondary)
            }
        }
        .onTapGesture(perform: onSelect)
    })
    .primerCheckoutSession(session) { state in handle(state) }
}
```

## Best Practices

1. **Customization Strategy**:
   - Start with default UI (`PrimerCheckout` managed modal)
   - Override one slot at a time using labeled arguments
   - Compose with `*Defaults` building blocks rather than rebuilding from scratch

2. **Error Handling**: Implement `PrimerCheckoutPresenterDelegate` (UIKit) or read the `onCompletion` state (SwiftUI)

3. **Performance**:
   - Hold `PrimerCheckoutSession` as `@StateObject` — never recreate it on each render
   - Slot closures receive the session directly; no need to capture it externally

4. **Testing**:
   - Test with various card types including co-badged cards
   - Verify dynamic field visibility with different configurations
   - Validate 3DS flows with test cards

5. **Accessibility**:
   - Maintain VoiceOver support in custom slot content
   - Use semantic colors that respect Dark Mode
   - Ensure touch targets meet minimum size requirements

## Migration Guide

For teams migrating from other Primer checkout solutions:

1. **From Drop-In Checkout**: CheckoutComponents offers the same ease of integration with added customization options
2. **From Headless Checkout**: Use the scope-based API for similar programmatic control with better type safety
3. **From Raw API**: CheckoutComponents handles tokenization, 3DS, and validation automatically

## API Reference

For the full API reference, see [API_REFERENCE.md](API_REFERENCE.md).

Key source files:
- [PrimerCheckoutPresenter](PrimerCheckoutPresenter.swift) — UIKit entry point
- [PrimerCheckout](PrimerCheckout.swift) — SwiftUI managed modal
- [PrimerCheckoutSession](Session/PrimerCheckoutSession.swift) — composable session owner
- [PrimerCardForm](PrimerCardForm.swift) — card form composable view
- [PrimerPaymentMethods](PrimerPaymentMethods.swift) — payment method list composable view
- [PrimerVaultedPaymentMethods](PrimerVaultedPaymentMethods.swift) — saved payment methods composable view
- [CardFormDefaults](Defaults/CardFormDefaults.swift) — field building blocks
- [PrimerCardFormState](Core/Data/PrimerCardFormState.swift)

## Support

For support, please refer to the [Primer documentation](https://primer.io/docs) or contact support@primer.io.
