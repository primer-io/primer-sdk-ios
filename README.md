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

The iOS SDK is available with Cocoapods. Just add the PrimerSDK pod and run `pod install`.

```swift{:copy}
target 'MyApp' do
  # Other pods...

  # Add this to your Podfile
  pod 'PrimerSDK' # Add this line
end

```
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
- 🎉 _That's it!_

## 🔍 &nbsp;Initializing the SDK

Import the Primer SDK and set its delegate as shown in the following example:

```swift{:copy}
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
        // do something...
    }
}
```


**Note:** Check the [SDK API Reference](https://www.notion.so/primerio/API-Reference-f62b4be8f24642989e63c25a8fb5f0ba_) for more options to customize your SDK.


## 🔍 &nbsp;Rendering the checkout

Now you can use the client token that you generated on your backend.
Call the `showUniversalCheckout(clientToken)` function (as shown below) to present Universal Checkout.

```swift{:copy}
class MyViewController: UIViewController {
    func startUniversalCheckout() {
        Primer.shared.showUniversalCheckout(clientToken: self.clientToken)
    }
}
```
You should now be able to see Universal Checkout! The user can now interact with Universal Checkout, and the SDK will create the payment.
The payment’s data will be returned on `primerDidCompleteCheckoutWithData(:)`.

**Note:** There are more options which can be passed to Universal Checkout. Please refer to the section below for more information.


## Contributing guidelines:

[Contributing doc](Contributing.md)

### Make sure you've got CocoaPods installed

- At the root of this repo, open your Terminal
  - `cd Example`
  - `pod install`