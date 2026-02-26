<h1 align="center"><img src="./Readme Resources/assets/primer-logo.png?raw=true" height="24px"> Primer iOS SDK</h1>

<div align="center">
  <h3 align="center">

[Primer's](https://primer.io) Official Universal Checkout iOS SDK

  </h3>
</div>

<br/>

<div align="center"><img src="./Readme Resources/assets/checkout-banner.gif?raw=true"  width="50%"/></div>

<br/>
<br/>

# 💪 Features of the iOS SDK

<p>💳 &nbsp; Create great payment experiences with our highly customizable Universal Checkout</p>
<p>🧩 &nbsp; Connect and configure any new payment method without a single line of code</p>
<p>✅ &nbsp; Dynamically handle 3DS 2.0 across processors and be SCA ready</p>
<p>♻️ &nbsp; Store payment methods for recurring and repeat payments</p>
<p>🔒 &nbsp; Always PCI compliant without redirecting customers</p>


# 📚 Documentation

Consider looking at the following resources:

- [Documentation](https://primer.io/docs)
- [Client session creation](https://primer.io/docs/accept-payments/manage-client-sessions/#create-a-client-session)
- [API reference](https://apiref.primer.io/docs)
- [Changelogs](https://primer.io/docs/changelog/sdk-changelog/ios)
- [Detailed iOS Documentation](https://www.notion.so/primerapi/iOS-SDK-ebbf44a733624d17bfd0c3a746f171a2)


# 💡 Support

For any support or integration related queries, feel free to [Contact Us](mailto:https://support@primer.io).


## 🚀 Quick start

Take a look at our [Quick Start Guide](https://primer.io/docs/get-started/ios) for accepting your first payment with Universal Checkout.

<br/>

# 🧱 Installation

## With CocoaPods

The iOS SDK is available via Cocoapods. Add the PrimerSDK to your Podfile:

```ruby
target 'MyApp' do
  # Other pods...

  # Add this to your Podfile
  pod 'PrimerSDK' # Add this line
end
```

Then, at the root of this repo, open your terminal and run
  - `bundle install`
  - `cd Debug\ App`
  - `bundle exec pod install`

For specific versions of the SDK, please refer to the changelog.

## With Swift Package Manager

The Swift Package Manager is a tool for automating the distribution of Swift code and is integrated into Xcode. In order to add PrimerSDK with Swift Package Manager;

1. Select your project, and then navigate to Package Dependencies
2. Click on the + button at the bottom-left of the Packages section
3. Paste https://github.com/primer-io/primer-sdk-ios.git into the Search Bar
4. Press Add Package
5. Let Xcode download the package and set everything up


<img src="./Readme Resources/assets/spm-3.png" />

<br/>

# 👩‍💻 Usage

## 📋 Prerequisites

- 🔑 Generate a client token by [creating a client session](https://primer.io/docs/accept-payments/manage-client-sessions) in your backend.
- 📱 **iOS 15.0+** for CheckoutComponents (modern SwiftUI integration)
- 📱 **iOS 13.0+** for Universal Checkout (traditional UIKit integration)
- 🎉 _That's it!_

## 🚀 Modern Integration: CheckoutComponents (iOS 15+)

CheckoutComponents is our modern, SwiftUI-based checkout solution with full UI customization and scope-based architecture. It provides exact Android API parity for cross-platform consistency.

### 📱 Pure SwiftUI Integration

For SwiftUI apps, use `PrimerCheckout` directly in your views:

```swift
import SwiftUI
import PrimerSDK

struct PaymentView: View {
    let clientToken: String

    var body: some View {
        PrimerCheckout(
            clientToken: clientToken,
            primerSettings: PrimerSettings()
        )
    }
}
```

### 🔄 UIKit Integration (Wrapper)

For UIKit apps, use `PrimerCheckoutPresenter` to present the checkout:

```swift
import PrimerSDK

class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the delegate to receive checkout events
        PrimerCheckoutPresenter.shared.delegate = self
    }

    func startCheckout() {
        PrimerCheckoutPresenter.presentCheckout(
            clientToken: clientToken,
            from: self
        )
    }
}

extension MyViewController: PrimerCheckoutPresenterDelegate {

    func primerCheckoutPresenterDidCompleteWithSuccess(_ result: PaymentResult) {
        // Payment completed successfully
        print("Payment ID: \(result.paymentId)")
    }

    func primerCheckoutPresenterDidFailWithError(_ error: PrimerError) {
        // Handle payment failure
        print("Payment failed: \(error)")
    }

    func primerCheckoutPresenterDidDismiss() {
        // Checkout was dismissed without completion
    }
}
```

### 🎨 Custom UI & Styling

Customize the checkout experience using scope-based APIs:

```swift
PrimerCheckout(
    clientToken: clientToken,
    primerSettings: PrimerSettings(),
    scope: { checkoutScope in
        // Customize the card form
        if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {

            // Custom styling for card number field
            cardFormScope.cardNumberField = { label, styling in
                AnyView(
                    cardFormScope.PrimerCardNumberField(
                        label: "Card Number",
                        styling: PrimerFieldStyling(
                            font: .system(.body, design: .monospaced),
                            backgroundColor: Color.blue.opacity(0.05),
                            borderColor: .blue,
                            cornerRadius: 8,
                            borderWidth: 2
                        )
                    )
                )
            }

            // Customize container/navigation
            checkoutScope.container = { content in
                AnyView(
                    NavigationView {
                        content()
                            .navigationBarTitle("Custom Checkout", displayMode: .inline)
                    }
                )
            }
        }
    }
)
```

### 📊 State Observation

Observe checkout state changes using AsyncStream:

```swift
// In your scope customization
if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {

    // Observe card form state
    Task {
        for await state in cardFormScope.state {
            print("Form valid: \(state.isValid)")
            print("Card network: \(state.cardNetwork?.displayName ?? "Unknown")")

            // Access individual field states
            if let cardNumberState = state.cardNumber {
                print("Card number valid: \(cardNumberState.isValid)")
            }
        }
    }
}
```

### 🧩 Scope-Based Customization

CheckoutComponents provides different scopes for granular customization:

- **`PrimerCheckoutScope`**: Main checkout lifecycle, container, and navigation
- **`PrimerCardFormScope`**: Card form with field-level customization
- **`PrimerPaymentMethodSelectionScope`**: Payment method selection UI

```swift
// Example: Complete screen replacement
if let cardFormScope: DefaultCardFormScope = checkoutScope.getPaymentMethodScope(for: .paymentCard) {
    cardFormScope.screen = { presentationContext in
        // Return your completely custom card form screen
        CustomCardFormView(scope: cardFormScope)
    }
}
```

**Note:** Check the [Detailed iOS Documentation](https://www.notion.so/primerapi/iOS-SDK-ebbf44a733624d17bfd0c3a746f171a2) for complete API reference and advanced customization options.

---

## 📱 Traditional Integration: Universal Checkout (iOS 13+)

For traditional UIKit-based integration, use the Universal Checkout flow:

### Initializing the SDK

```swift
import PrimerSDK

class MyViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Initialize the SDK with the default settings.
        Primer.shared.configure(delegate: self)
    }
}

extension MyViewController: PrimerDelegate {

    func primerDidCompleteCheckoutWithData(_ data: CheckoutData) {
        // Primer checkout completed with data
        print("Payment completed: \(data)")
    }
}
```

### Presenting Universal Checkout

```swift
class MyViewController: UIViewController {
    func startUniversalCheckout() {
        Primer.shared.showUniversalCheckout(clientToken: self.clientToken)
    }
}
```

The user can now interact with Universal Checkout, and the SDK will create the payment. The payment data will be returned via `primerDidCompleteCheckoutWithData(:)`.


## Contributing guidelines:

[Contributing doc](Contributing.md)

## Style
Once cloned, please ensure you run `make hook` in the root of the repo to format your contribution in alignment with our style guide.

## Using the Debug App

The Debug App provides you with tools to test your Primer configuration and interact with different payment methods and Universal Checkout features
