# ComposablePrimer Usage Guide

This guide demonstrates how to use the new ComposablePrimer API for presenting the modern SwiftUI-based checkout experience.

## Requirements

- iOS 15.0+
- Swift 5.5+
- SwiftUI

## Basic Usage

### Present Checkout with Automatic View Controller Detection

```swift
// The simplest way - automatically finds the appropriate view controller
ComposablePrimer.presentCheckout(with: clientToken) {
    print("Checkout presented")
}
```

### Present Checkout from Specific View Controller

```swift
// Present from a specific view controller
ComposablePrimer.presentCheckout(
    with: clientToken,
    from: self
) {
    print("Checkout presented")
}
```

### Present Checkout with Custom Content

```swift
// Present with custom SwiftUI content
ComposablePrimer.presentCheckout(
    with: clientToken,
    from: self
) { scope in
    VStack {
        // Access payment methods
        ForEach(scope.paymentMethods(), id: \.id) { method in
            // Custom payment method UI
        }
        
        // Your custom content here
    }
}
```

## Delegate Integration

ComposablePrimer uses the same delegate as the main Primer SDK:

```swift
// Set the delegate
ComposablePrimer.delegate = self

// Implement PrimerDelegate
extension ViewController: PrimerDelegate {
    func primerDidCompleteCheckoutWithData(_ data: PrimerCheckoutData) {
        // Handle successful payment
    }
    
    func primerDidFailWithError(_ error: Error, data: PrimerCheckoutData?, decisionHandler: @escaping (PrimerErrorDecision) -> Void) {
        // Handle error
        decisionHandler(.fail(withErrorMessage: error.localizedDescription))
    }
}
```

## Dismissing Checkout

```swift
// Dismiss the checkout UI
ComposablePrimer.dismiss(animated: true) {
    print("Checkout dismissed")
}
```

## Checking Availability

```swift
if ComposablePrimer.isAvailable {
    // ComposablePrimer is available on this iOS version
    ComposablePrimer.presentCheckout(with: clientToken)
} else {
    // Fall back to traditional checkout
    Primer.showUniversalCheckout(with: clientToken)
}
```

## Migration from Direct PrimerCheckout Usage

### Before (Direct SwiftUI):
```swift
let checkoutView = PrimerCheckout(clientToken: clientToken)
let hostingController = UIHostingController(rootView: checkoutView)
present(hostingController, animated: true)
```

### After (ComposablePrimer API):
```swift
ComposablePrimer.presentCheckout(
    with: clientToken,
    from: self
)
```

## Integration with PrimerUIManager

When using PrimerUIManager with checkout style selection:

```swift
// Automatically chooses between Drop-in and ComposableCheckout
PrimerUIManager.shared.presentPaymentUI(checkoutStyle: .automatic)

// Force ComposableCheckout (iOS 15+ only)
PrimerUIManager.shared.presentPaymentUI(checkoutStyle: .composable)

// Force traditional Drop-in
PrimerUIManager.shared.presentPaymentUI(checkoutStyle: .dropIn)
```

## Best Practices

1. **Error Handling**: Always set a delegate to handle errors
2. **iOS Version**: Check `ComposablePrimer.isAvailable` or use `@available` checks
3. **Client Token**: Ensure you have a valid client token before presenting
4. **Memory Management**: The SDK handles cleanup automatically on dismissal

## Advanced Usage

### Custom Payment Method Selection

```swift
ComposablePrimer.presentCheckout(
    with: clientToken,
    from: self
) { scope in
    CustomPaymentMethodSelector(scope: scope)
}
```

### Programmatic Payment Method Selection

```swift
// In your custom content
Button("Select Card Payment") {
    Task {
        let cardMethod = // ... get card payment method
        await scope.selectPaymentMethod(cardMethod)
    }
}
```

## Troubleshooting

### Checkout doesn't appear
- Ensure you're on iOS 15+
- Check that the client token is valid
- Verify delegate error callbacks

### Delegate not called
- Ensure `ComposablePrimer.delegate` is set before presenting
- Check that your delegate conforms to `PrimerDelegate`

### Custom content not showing
- Verify your SwiftUI view is properly constructed
- Check for any runtime SwiftUI errors