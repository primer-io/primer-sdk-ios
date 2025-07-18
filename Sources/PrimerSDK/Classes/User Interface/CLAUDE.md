# CLAUDE.md - User Interface (Legacy UIKit)

This directory contains the legacy UIKit-based user interface components for the traditional Drop-in integration approach. These components support iOS 13.1+ and provide a complete payment experience with minimal integration effort.

## Overview

The UI module provides ready-to-use view controllers and components that merchants can integrate with minimal code changes. This is the "Drop-in" solution that handles the entire payment flow.

## Architecture

### Integration Pattern
```swift
// Typical Drop-in integration
Primer.showCheckout(
    with: clientToken,
    viewController: self,
    delegate: self
)
```

### Core Components

#### Root View Controllers (`Root/`)
Main entry points for different payment flows:

**PrimerUniversalCheckoutViewController**:
- Main checkout coordinator
- Handles payment method selection
- Manages navigation flow between steps

**PrimerRootViewController**:
- Base class for all Primer view controllers
- Common navigation and theming logic
- Lifecycle management and cleanup

**PrimerContainerViewController**:
- Container for embedded payment forms
- Handles presentation modes (modal, push, embed)
- Manages keyboard handling and layout

**Specialized Controllers**:
- `PrimerLoadingViewController`: Loading states and progress indication
- `PrimerFormViewController`: Generic form-based payment methods
- `PrimerInputViewController`: Input-heavy payment flows
- `CVVRecaptureViewController`: CVV re-entry for stored cards

#### Navigation System (`Root/`)
**PrimerNavigationController**:
- Custom navigation with Primer theming
- Consistent navigation bar styling
- Integration with SDK-wide navigation patterns

**PrimerNavigationBar**:
- Customizable navigation bar component
- Theme-aware styling
- Action button management

### Payment Method Specific UI

#### Tokenization View Controllers (`TokenizationViewControllers/`)
Payment method specific implementations:

**QRCodeViewController**:
- QR code display for bank transfers and wallet payments
- Auto-refresh and timeout handling
- Status polling integration

#### Tokenization View Models (`TokenizationViewModels/`)
Business logic for payment-specific UI:

**PaymentMethodTokenizationViewModel**:
- Base class for all payment method view models
- Common validation and processing logic
- Error handling and user feedback

**Specialized View Models**:
- `ApplePayTokenizationViewModel`: Apple Pay integration
- `PayPalTokenizationViewModel`: PayPal OAuth flow
- `KlarnaTokenizationViewModel`: Klarna BNPL integration
- `WebRedirectPaymentMethodTokenizationViewModel`: Browser-based flows

### Input Components

#### Text Fields (`Text Fields/`)
Secure and validated input components:

**Core Text Fields**:
- `PrimerTextFieldView`: Base text field with validation
- `PrimerCardNumberFieldView`: Card number with real-time validation
- `PrimerCVVFieldView`: CVV input with masking
- `PrimerExpiryDateFieldView`: Smart date input

**Address Fields**:
- `PrimerAddressLineFieldView`: Street address input
- `PrimerCityFieldView`: City input with suggestions
- `PrimerPostalCodeFieldView`: Postal/ZIP code validation
- `PrimerStateFieldView`: State/province selection
- `PrimerCountryFieldView`: Country selection

**Personal Information**:
- `PrimerFirstNameFieldView`: First name input
- `PrimerLastNameFieldView`: Last name input

#### Generic Components (`Text Fields/Generic/`)
Reusable input components:

**PrimerGenericTextFieldView**:
- Configurable text field for various inputs
- Built-in validation support
- Consistent styling and behavior

### Specialized UI Components

#### Banks (`Banks/`)
Bank selection and banking-related UI:
- `BankSelectorViewController`: Bank list and selection
- `BankTableViewCell`: Individual bank display
- Integration with banking APIs

#### Countries (`Countries/`)
Country and region selection:
- `CountrySelectorViewController`: Country picker
- `CountryTableViewCell`: Country display with flags
- Localized country names

#### OAuth (`OAuth/`)
Web-based authentication flows:
- `PrimerWebViewController`: In-app browser for OAuth
- SSL certificate validation
- Redirect handling and deep linking

### Apple Pay Integration
**ApplePayPresentationManager**:
- Apple Pay button presentation
- Payment sheet configuration
- Transaction handling and callbacks

### Reusable Components (`Components/`)

**Core Components**:
- `PrimerFormView`: Generic form container
- `HeaderFooterLabelView`: Section headers and footers
- `PrimerSearchTextField`: Search input with filtering
- `PrimerResultViewController`: Payment result display

**Result Handling**:
- `PrimerCustomResultViewController`: Custom result pages
- `PrimerResultPaymentStatusView`: Payment status display
- `PrimerResultComponentView`: Modular result components

### Theme and Styling

#### Theme Integration
All UI components support the `PrimerTheme` system:

```swift
// Apply theme to view controller
viewController.applyTheme(theme)

// Theme-aware component creation
let textField = PrimerTextFieldView(theme: currentTheme)
```

#### Accessibility
- VoiceOver support for all interactive elements
- Dynamic Type support for text components
- High contrast mode compatibility
- Keyboard navigation support

### UI Management

#### PrimerUIManager
Central coordinator for UI operations:
- View controller presentation management
- Theme application and updates
- Keyboard handling coordination
- Loading state management
- **NEW**: CheckoutComponents integration via `presentCheckoutComponents()`
- Checkout style selection (`.dropIn`, `.checkoutComponents`, `.automatic`)

#### CheckoutComponents Integration
PrimerUIManager now supports presenting the modern SwiftUI-based checkout:
```swift
// Present with automatic style selection
PrimerUIManager.shared.presentPaymentUI(checkoutStyle: .automatic)

// Force CheckoutComponents (iOS 15+)
PrimerUIManager.shared.presentPaymentUI(checkoutStyle: .checkoutComponents)

// Force traditional Drop-in
PrimerUIManager.shared.presentPaymentUI(checkoutStyle: .dropIn)
```

The integration uses `CheckoutComponentsPrimer.presentCheckout()` internally and maintains compatibility with existing delegate patterns.

#### UI Utilities (`UIUtils.swift`)
Helper functions for common UI operations:
- Animation utilities
- Layout calculations
- Color manipulation
- Responsive design helpers

### Vault Management

#### Vault UI (`Vault/`)
Stored payment method management:

**VaultPaymentMethodViewController**:
- Display saved payment methods
- Add/remove payment methods
- CVV recapture for stored cards

**VaultPaymentMethodViewModel**:
- Business logic for vault operations
- Payment method metadata management
- Security validation for stored methods

### Testing and Development

#### Test Payment Methods (`TestPaymentMethods/`)
Development and testing utilities:
- `PrimerTestPaymentMethodViewController`: Test payment flows
- `FlowDecisionTableViewCell`: Decision flow testing
- Mock payment method implementations

## Usage Patterns

### Basic Integration
```swift
class MerchantViewController: UIViewController {
    func showCheckout() {
        Primer.showCheckout(
            with: clientToken,
            viewController: self,
            delegate: self
        )
    }
}

extension MerchantViewController: PrimerDelegate {
    func primerDidCompleteCheckout(with data: PrimerCheckoutData) {
        // Handle successful payment
    }
    
    func primerDidFailWithError(error: PrimerError) {
        // Handle payment error
    }
}
```

### Custom Theming
```swift
var theme = PrimerTheme()
theme.colors.primary = UIColor.systemBlue
theme.typography.body = UIFont.systemFont(ofSize: 16)

Primer.setTheme(theme)
```

### Advanced Configuration
```swift
var settings = PrimerSettings()
settings.uiOptions.isVaultManagerEnabled = true
settings.uiOptions.isInitScreenEnabled = false

Primer.configure(with: settings)
```

## Best Practices

### Performance
1. **Lazy Loading**: Load payment method UIs on demand
2. **Memory Management**: Proper view controller cleanup
3. **Image Optimization**: Efficient loading and caching
4. **Animation Performance**: 60fps smooth animations

### Accessibility
1. **VoiceOver Labels**: Descriptive accessibility labels
2. **Dynamic Type**: Support for user font size preferences
3. **Color Contrast**: Meet WCAG accessibility guidelines
4. **Keyboard Navigation**: Full keyboard accessibility

### Error Handling
1. **User-Friendly Messages**: Convert technical errors to user language
2. **Recovery Options**: Provide clear paths to resolve issues
3. **Fallback UI**: Graceful degradation when services fail
4. **Validation Feedback**: Real-time input validation

### Security
1. **No Sensitive Logging**: Never log payment information
2. **Secure Text Fields**: Use secure input for sensitive data
3. **Screenshot Protection**: Prevent sensitive data in screenshots
4. **Memory Cleanup**: Clear sensitive data from memory

## Migration Strategy

### To CheckoutComponents
When migrating to the modern SwiftUI-based CheckoutComponents:

1. **Extract Business Logic**: Move view model logic to shared services
2. **Create SwiftUI Equivalents**: Convert UIKit views to SwiftUI
3. **Update Navigation**: Migrate to SwiftUI navigation patterns
4. **Preserve Functionality**: Maintain feature parity during migration
5. **Gradual Migration**: Migrate one payment method at a time

### Backward Compatibility
- Legacy UI components remain supported
- New features prioritize CheckoutComponents
- Clear deprecation timeline for legacy components
- Migration tools and documentation provided

## Troubleshooting

### Common Issues
1. **Theme Not Applied**: Ensure theme is set before presenting UI
2. **Memory Leaks**: Check for retain cycles in delegates
3. **Layout Issues**: Verify Auto Layout constraints
4. **Navigation Problems**: Check view controller hierarchy

### Debug Tools
1. **UI Debugging**: Use Xcode's view debugger
2. **Theme Inspector**: Built-in theme validation
3. **Performance Monitoring**: Memory and CPU usage tracking
4. **Accessibility Auditing**: VoiceOver and accessibility testing

This legacy UI system provides a robust, tested foundation for payment experiences while the SDK transitions to modern SwiftUI patterns in CheckoutComponents.