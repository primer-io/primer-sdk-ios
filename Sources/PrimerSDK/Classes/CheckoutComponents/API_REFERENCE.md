# CheckoutComponents API Reference

Complete public API reference for the CheckoutComponents framework (iOS 15+).

---

## Entry Points

### PrimerCheckout (SwiftUI)

```swift
@available(iOS 15.0, *)
public struct PrimerCheckout: View {
  public init(
    clientToken: String,
    primerSettings: PrimerSettings = PrimerSettings(),
    primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    scope: ((PrimerCheckoutScope) -> Void)? = nil,
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  )
}
```

### PrimerCheckoutPresenter (UIKit)

```swift
@available(iOS 15.0, *)
public final class PrimerCheckoutPresenter {
  public static let shared: PrimerCheckoutPresenter
  public weak var delegate: PrimerCheckoutPresenterDelegate?
  public static var isAvailable: Bool
  public static var isPresenting: Bool

  // Present checkout
  public static func presentCheckout(
    clientToken: String,
    from viewController: UIViewController,
    primerSettings: PrimerSettings,
    primerTheme: PrimerCheckoutTheme,
    scope: ((PrimerCheckoutScope) -> Void)? = nil,
    completion: (() -> Void)? = nil
  )

  // Convenience overloads
  public static func presentCheckout(clientToken: String, completion: (() -> Void)? = nil)
  public static func presentCheckout(clientToken: String, from: UIViewController, completion: (() -> Void)? = nil)
  public static func presentCheckout(clientToken: String, from: UIViewController, primerSettings: PrimerSettings, completion: (() -> Void)? = nil)
  public static func presentCheckout(clientToken: String, primerSettings: PrimerSettings, completion: (() -> Void)? = nil)

  // Dismiss
  public static func dismiss(animated: Bool = true, completion: (() -> Void)? = nil)
}
```

### PrimerCheckoutPresenterDelegate

```swift
@available(iOS 15.0, *)
public protocol PrimerCheckoutPresenterDelegate: AnyObject {
  // Required
  func primerCheckoutPresenterDidCompleteWithSuccess(_ result: PaymentResult)
  func primerCheckoutPresenterDidFailWithError(_ error: PrimerError)
  func primerCheckoutPresenterDidDismiss()

  // Optional (3DS)
  func primerCheckoutPresenterWillPresent3DSChallenge(_ paymentMethodTokenData: PrimerPaymentMethodTokenData)
  func primerCheckoutPresenterDidDismiss3DSChallenge()
  func primerCheckoutPresenterDidComplete3DSChallenge(success: Bool, resumeToken: String?, error: Error?)
}
```

---

## Core Scopes

### PrimerPaymentMethodScope (Base Protocol)

All payment method scopes conform to this protocol.

```
Lifecycle: start() -> [user interaction] -> submit()  or  start() -> cancel()
```

```swift
@MainActor
public protocol PrimerPaymentMethodScope: AnyObject {
  associatedtype State: Equatable

  var state: AsyncStream<State> { get }
  var presentationContext: PresentationContext { get }   // default: .fromPaymentSelection
  var dismissalMechanism: [DismissalMechanism] { get }  // default: []

  func start()     // Initialize payment flow
  func submit()    // Validate and process payment
  func cancel()    // Terminate flow
  func onBack()    // Navigate back (default: calls cancel())
  func onDismiss() // Handle dismissal (default: calls cancel())
}
```

### PrimerCheckoutScope

Top-level scope for managing the checkout session.

```swift
@MainActor
public protocol PrimerCheckoutScope: AnyObject {
  var state: AsyncStream<PrimerCheckoutState> { get }
  var paymentMethodSelection: PrimerPaymentMethodSelectionScope { get }
  var paymentHandling: PrimerPaymentHandling { get }

  // Scope access
  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T?
  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T?
  func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T?
  func onDismiss()

  // Screen customization
  var container: ContainerComponent? { get set }
  var splashScreen: Component? { get set }
  var loadingScreen: Component? { get set }
  var errorScreen: ErrorComponent? { get set }
}
```

### PrimerPaymentMethodSelectionScope

Scope for the payment method selection screen.

```swift
@MainActor
public protocol PrimerPaymentMethodSelectionScope: AnyObject {
  var state: AsyncStream<PrimerPaymentMethodSelectionState> { get }
  var dismissalMechanism: [DismissalMechanism] { get }

  func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod)
  func cancel()
  func payWithVaultedPaymentMethod() async
  func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async
  func updateCvvInput(_ cvv: String)
  func showAllVaultedPaymentMethods()
  func showOtherWaysToPay()

  // Customization
  var screen: PaymentMethodSelectionScreenComponent? { get set }
  var paymentMethodItem: PaymentMethodItemComponent? { get set }
  var categoryHeader: CategoryHeaderComponent? { get set }
  var emptyStateView: Component? { get set }
}
```

---

## Payment Method Scopes

### PrimerCardFormScope

Comprehensive card form with field-level customization.

```swift
@MainActor
public protocol PrimerCardFormScope: PrimerPaymentMethodScope where State == PrimerCardFormState {
  var cardFormUIOptions: PrimerCardFormUIOptions? { get }
  var selectCountry: PrimerSelectCountryScope { get }

  // Field update methods
  func updateCardNumber(_ cardNumber: String)
  func updateCvv(_ cvv: String)
  func updateExpiryDate(_ expiryDate: String)
  func updateCardholderName(_ cardholderName: String)
  func updatePostalCode(_ postalCode: String)
  func updateCity(_ city: String)
  func updateState(_ state: String)
  func updateAddressLine1(_ addressLine1: String)
  func updateAddressLine2(_ addressLine2: String)
  func updatePhoneNumber(_ phoneNumber: String)
  func updateFirstName(_ firstName: String)
  func updateLastName(_ lastName: String)
  func updateEmail(_ email: String)
  func updateCountryCode(_ countryCode: String)
  func updateSelectedCardNetwork(_ network: String)
  func updateRetailOutlet(_ retailOutlet: String)
  func updateOtpCode(_ otpCode: String)
  func updateExpiryMonth(_ month: String)
  func updateExpiryYear(_ year: String)

  // Generic field access
  func updateField(_ fieldType: PrimerInputElementType, value: String)
  func getFieldValue(_ fieldType: PrimerInputElementType) -> String
  func setFieldError(_ fieldType: PrimerInputElementType, message: String, errorCode: String?)
  func clearFieldError(_ fieldType: PrimerInputElementType)
  func getFieldError(_ fieldType: PrimerInputElementType) -> String?
  func getFormConfiguration() -> CardFormConfiguration

  // Field configuration (InputFieldConfig)
  var cardNumberConfig: InputFieldConfig? { get set }
  var expiryDateConfig: InputFieldConfig? { get set }
  var cvvConfig: InputFieldConfig? { get set }
  var cardholderNameConfig: InputFieldConfig? { get set }
  var postalCodeConfig: InputFieldConfig? { get set }
  var countryConfig: InputFieldConfig? { get set }
  var cityConfig: InputFieldConfig? { get set }
  var stateConfig: InputFieldConfig? { get set }
  var addressLine1Config: InputFieldConfig? { get set }
  var addressLine2Config: InputFieldConfig? { get set }
  var phoneNumberConfig: InputFieldConfig? { get set }
  var firstNameConfig: InputFieldConfig? { get set }
  var lastNameConfig: InputFieldConfig? { get set }
  var emailConfig: InputFieldConfig? { get set }
  var retailOutletConfig: InputFieldConfig? { get set }
  var otpCodeConfig: InputFieldConfig? { get set }

  // Section customization
  var title: String? { get set }
  var screen: CardFormScreenComponent? { get set }
  var cardInputSection: Component? { get set }
  var billingAddressSection: Component? { get set }
  var submitButton: Component? { get set }
  var cobadgedCardsView: (([String], @escaping (String) -> Void) -> any View)? { get set }
  var errorScreen: ErrorComponent? { get set }
  var submitButtonText: String? { get set }
  var showSubmitLoadingIndicator: Bool { get set }

  // SDK field ViewBuilder methods
  func PrimerCardNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerExpiryDateField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCvvField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCardholderNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCountryField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerPostalCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerCityField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerStateField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerAddressLine1Field(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerAddressLine2Field(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerFirstNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerLastNameField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerEmailField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerPhoneNumberField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerRetailOutletField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func PrimerOtpCodeField(label: String?, styling: PrimerFieldStyling?) -> AnyView
  func DefaultCardFormView(styling: PrimerFieldStyling?) -> AnyView
}
```

### PrimerApplePayScope

```swift
@MainActor
public protocol PrimerApplePayScope: PrimerPaymentMethodScope where State == PrimerApplePayState {
  var state: AsyncStream<PrimerApplePayState> { get }

  func PrimerApplePayButton(action: @escaping () -> Void) -> AnyView

  var screen: ((_ scope: any PrimerApplePayScope) -> any View)? { get set }
  var applePayButton: ((_ action: @escaping () -> Void) -> any View)? { get set }
}
```

### PrimerPayPalScope

```swift
@MainActor
public protocol PrimerPayPalScope: PrimerPaymentMethodScope where State == PrimerPayPalState {
  var screen: PayPalScreenComponent? { get set }
  var payButton: PayPalButtonComponent? { get set }
  var submitButtonText: String? { get set }
}
```

### PrimerKlarnaScope

Multi-step flow: category selection -> authorization -> finalization.

```swift
@MainActor
public protocol PrimerKlarnaScope: PrimerPaymentMethodScope where State == PrimerKlarnaState {
  var paymentView: UIView? { get }

  func selectPaymentCategory(_ categoryId: String)
  func authorizePayment()
  func finalizePayment()

  var screen: KlarnaScreenComponent? { get set }
  var authorizeButton: KlarnaButtonComponent? { get set }
  var finalizeButton: KlarnaButtonComponent? { get set }
}
```

### PrimerAchScope

Multi-step flow: user details -> bank collection -> mandate acceptance.

```swift
@MainActor
public protocol PrimerAchScope: PrimerPaymentMethodScope where State == PrimerAchState {
  var bankCollectorViewController: UIViewController? { get }

  func updateFirstName(_ value: String)
  func updateLastName(_ value: String)
  func updateEmailAddress(_ value: String)
  func submitUserDetails()
  func acceptMandate()
  func declineMandate()

  var screen: AchScreenComponent? { get set }
  var userDetailsScreen: AchScreenComponent? { get set }
  var mandateScreen: AchScreenComponent? { get set }
  var submitButton: AchButtonComponent? { get set }
}
```

### PrimerWebRedirectScope

Web redirect payment methods (e.g., Twint). Redirects user to external page, then polls for result.

```
idle -> loading -> redirecting -> polling -> success | failure
```

```swift
@MainActor
public protocol PrimerWebRedirectScope: PrimerPaymentMethodScope where State == PrimerWebRedirectState {
  var paymentMethodType: String { get }
  var state: AsyncStream<PrimerWebRedirectState> { get }

  // Customization
  var screen: WebRedirectScreenComponent? { get set }
  var payButton: WebRedirectButtonComponent? { get set }
  var submitButtonText: String? { get set }
}
```

### PrimerFormRedirectScope

Form-based redirect payment methods (e.g., BLIK OTP code, MBWay phone number). Collects user input then completes payment in external app.

```
ready -> submitting -> awaitingExternalCompletion -> success | failure
```

```swift
@MainActor
public protocol PrimerFormRedirectScope: PrimerPaymentMethodScope where State == PrimerFormRedirectState {
  var state: AsyncStream<PrimerFormRedirectState> { get }
  var paymentMethodType: String { get }

  func updateField(_ fieldType: PrimerFormFieldState.FieldType, value: String)

  // Customization
  var screen: FormRedirectScreenComponent? { get set }        // Replaces both form and pending screens
  var formSection: FormRedirectFormSectionComponent? { get set }
  var submitButton: FormRedirectButtonComponent? { get set }
  var submitButtonText: String? { get set }
}
```

### PrimerQRCodeScope

QR code payment methods (e.g., PromptPay, Xfers). Displays a QR code and polls for completion. No user input needed.

```
loading -> displaying -> success | failure
```

```swift
@MainActor
public protocol PrimerQRCodeScope: PrimerPaymentMethodScope where State == PrimerQRCodeState {
  var state: AsyncStream<PrimerQRCodeState> { get }
  var screen: QRCodeScreenComponent? { get set }
}
```

### PrimerSelectCountryScope

```swift
@MainActor
public protocol PrimerSelectCountryScope {
  var state: AsyncStream<PrimerSelectCountryState> { get }

  func onCountrySelected(countryCode: String, countryName: String)
  func cancel()
  func onSearch(query: String)

  var screen: ((_ scope: PrimerSelectCountryScope) -> AnyView)? { get set }
  var searchBar: ((_ query: String, _ onQueryChange: @escaping (String) -> Void, _ placeholder: String) -> AnyView)? { get set }
  var countryItem: CountryItemComponent? { get set }
}
```

---

## State Types

### PrimerCheckoutState

```
initializing -> ready -> success | failure -> dismissed
```

```swift
public enum PrimerCheckoutState {
  case initializing
  case ready(totalAmount: Int, currencyCode: String)
  case success(PaymentResult)
  case dismissed
  case failure(PrimerError)
}
```

### PrimerPaymentMethodSelectionState

```swift
public struct PrimerPaymentMethodSelectionState {
  var paymentMethods: [CheckoutPaymentMethod]
  var isLoading: Bool
  var selectedPaymentMethod: CheckoutPaymentMethod?
  var searchQuery: String
  var filteredPaymentMethods: [CheckoutPaymentMethod]
  var error: String?
  var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  var isVaultPaymentLoading: Bool
  var requiresCvvInput: Bool
  var cvvInput: String
  var isCvvValid: Bool
  var cvvError: String?
  var isPaymentMethodsExpanded: Bool
}
```

### PrimerCardFormState

```swift
public struct PrimerCardFormState: Equatable {
  var configuration: CardFormConfiguration
  var data: FormData
  var fieldErrors: [FieldError]
  var isLoading: Bool
  var isValid: Bool
  var selectedCountry: PrimerCountry?
  var selectedNetwork: PrimerCardNetwork?
  var availableNetworks: [PrimerCardNetwork]
  var surchargeAmountRaw: Int?
  var surchargeAmount: String?
  var displayFields: [PrimerInputElementType]

  func hasError(for fieldType: PrimerInputElementType) -> Bool
  func errorMessage(for fieldType: PrimerInputElementType) -> String?
  mutating func setError(_ message: String, for fieldType: PrimerInputElementType, errorCode: String?)
  mutating func clearError(for fieldType: PrimerInputElementType)
}
```

### PrimerApplePayState

```swift
public struct PrimerApplePayState: Equatable {
  var isLoading: Bool
  var isAvailable: Bool
  var availabilityError: String?
  var buttonStyle: PKPaymentButtonStyle
  var buttonType: PKPaymentButtonType
  var cornerRadius: CGFloat

  static var `default`: PrimerApplePayState
  static func available(buttonStyle:buttonType:cornerRadius:) -> PrimerApplePayState
  static func unavailable(error:) -> PrimerApplePayState
  static var loading: PrimerApplePayState
}
```

### PrimerKlarnaState

```
loading -> categorySelection -> viewReady -> authorizationStarted -> awaitingFinalization
```

```swift
public struct PrimerKlarnaState: Equatable {
  public enum Step: Equatable {
    case loading
    case categorySelection
    case viewReady
    case authorizationStarted
    case awaitingFinalization
  }

  var step: Step
  var categories: [KlarnaPaymentCategory]
  var selectedCategoryId: String?
}
```

### PrimerPayPalState

```swift
public struct PrimerPayPalState: Equatable {
  public enum Step: Equatable {
    case idle
    case loading
    case redirecting
    case processing
    case success
    case failure(String)
  }

  var step: Step
  var paymentMethod: CheckoutPaymentMethod?
  var surchargeAmount: String?
}
```

### PrimerAchState

```
loading -> userDetailsCollection -> bankAccountCollection -> mandateAcceptance -> processing
```

```swift
public struct PrimerAchState: Equatable {
  public enum Step: Equatable {
    case loading
    case userDetailsCollection
    case bankAccountCollection
    case mandateAcceptance
    case processing
  }

  public struct UserDetails: Equatable {
    let firstName: String
    let lastName: String
    let emailAddress: String
  }

  public struct FieldValidation: Equatable {
    let firstNameError: String?
    let lastNameError: String?
    let emailError: String?
    var hasErrors: Bool
  }

  var step: Step
  var userDetails: UserDetails
  var fieldValidation: FieldValidation?
  var mandateText: String?
  var isSubmitEnabled: Bool
}
```

### PrimerWebRedirectState

```
idle -> loading -> redirecting -> polling -> success | failure
```

```swift
public struct PrimerWebRedirectState: Equatable {
  public enum Status: Equatable {
    case idle
    case loading
    case redirecting
    case polling
    case success
    case failure(String)
  }

  var status: Status
  var paymentMethod: CheckoutPaymentMethod?
  var surchargeAmount: String?
}
```

### PrimerFormRedirectState

```
ready -> submitting -> awaitingExternalCompletion -> success | failure
```

```swift
public struct PrimerFormRedirectState: Equatable {
  public enum Status: Equatable {
    case ready
    case submitting
    case awaitingExternalCompletion
    case success
    case failure(String)
  }

  var status: Status
  var fields: [PrimerFormFieldState]
  var isSubmitEnabled: Bool        // Computed: all fields non-empty and valid
  var pendingMessage: String?
  var surchargeAmount: String?

  // Convenience accessors
  var otpField: PrimerFormFieldState?    // First field with .otpCode type
  var phoneField: PrimerFormFieldState?  // First field with .phoneNumber type
  var isLoading: Bool              // status == .submitting
  var isTerminal: Bool             // success or failure
}
```

### PrimerFormFieldState

```swift
public struct PrimerFormFieldState: Equatable, Identifiable {
  public enum FieldType: String, Equatable, Sendable {
    case otpCode       // BLIK 6-digit code
    case phoneNumber   // MBWay phone number
  }

  public enum KeyboardType: Equatable, Sendable {
    case numberPad
    case phonePad
    case `default`
  }

  var id: String { fieldType.rawValue }
  let fieldType: FieldType
  var value: String
  var isValid: Bool
  var errorMessage: String?
  let placeholder: String
  let label: String
  let helperText: String?
  let keyboardType: KeyboardType
  let maxLength: Int?              // nil = unlimited
  var countryCodePrefix: String?   // Display prefix (e.g., "🇵🇹 +351")
  var dialCode: String?            // Dial code (e.g., "+351")
}
```

### PrimerQRCodeState

```
loading -> displaying -> success | failure
```

```swift
public struct PrimerQRCodeState: Equatable {
  public enum Status: Equatable {
    case loading
    case displaying
    case success
    case failure(String)
  }

  var status: Status
  var paymentMethod: CheckoutPaymentMethod?
  var qrCodeImageData: Data?       // PNG image data
}
```

### PrimerSelectCountryState

```swift
public struct PrimerSelectCountryState: Equatable {
  var countries: [PrimerCountry]
  var filteredCountries: [PrimerCountry]
  var searchQuery: String
  var isLoading: Bool
  var selectedCountry: PrimerCountry?
}
```

---

## Configuration

### PrimerCheckoutTheme

Design token overrides for the entire checkout UI.

```swift
public class PrimerCheckoutTheme {
  public init(
    colors: ColorOverrides? = nil,
    radius: RadiusOverrides? = nil,
    spacing: SpacingOverrides? = nil,
    sizes: SizeOverrides? = nil,
    typography: TypographyOverrides? = nil,
    borderWidth: BorderWidthOverrides? = nil
  )
}
```

**Override types**: `ColorOverrides`, `RadiusOverrides`, `SpacingOverrides`, `SizeOverrides`, `TypographyOverrides`, `BorderWidthOverrides`. See `CheckoutComponentsTheme.swift` for all token names.

### PrimerFieldStyling

Per-field styling overrides. All properties are optional and fall back to design token defaults.

```swift
public struct PrimerFieldStyling {
  // Typography
  let fontName: String?           // Custom font family for input text
  let fontSize: CGFloat?          // Font size for input text
  let fontWeight: CGFloat?        // Font weight for input text
  let labelFontName: String?      // Custom font family for labels
  let labelFontSize: CGFloat?     // Font size for labels
  let labelFontWeight: CGFloat?   // Font weight for labels

  // Colors
  let textColor: Color?           // Input text color
  let labelColor: Color?          // Label text color
  let backgroundColor: Color?     // Field background
  let borderColor: Color?         // Default border color
  let focusedBorderColor: Color?  // Border color when focused
  let errorBorderColor: Color?    // Border color on error
  let placeholderColor: Color?    // Placeholder text color

  // Layout
  let cornerRadius: CGFloat?      // Border corner radius
  let borderWidth: CGFloat?       // Border stroke width
  let padding: EdgeInsets?         // Inner content padding
  let fieldHeight: CGFloat?       // Fixed field height
}
```

### InputFieldConfig

Partial customization or full component replacement for individual form fields.

```swift
public struct InputFieldConfig {
  public init(
    label: String? = nil,
    placeholder: String? = nil,
    styling: PrimerFieldStyling? = nil,
    component: Component? = nil    // Full replacement — overrides all above
  )
}
```

---

## Data Types

### CheckoutPaymentMethod

```swift
public struct CheckoutPaymentMethod {
  let id: String
  let type: String                  // e.g., "PAYMENT_CARD", "PAYPAL"
  let name: String                  // Display name
  let icon: UIImage?
  let metadata: [String: Any]?
  let surcharge: Int?               // Minor units
  let hasUnknownSurcharge: Bool
  let formattedSurcharge: String?
  let backgroundColor: UIColor?
}
```

### PrimerCountry

```swift
public struct PrimerCountry: Equatable {
  let code: String      // ISO 3166-1 alpha-2 (e.g., "US")
  let name: String      // Localized name
  let flag: String?     // Flag emoji
  let dialCode: String? // Dialing code
}
```

### FieldError

```swift
public struct FieldError: Equatable, Identifiable {
  let id: UUID
  let fieldType: PrimerInputElementType
  let message: String
  let errorCode: String?
}
```

### CardFormConfiguration

```swift
public struct CardFormConfiguration: Equatable {
  let cardFields: [PrimerInputElementType]
  let billingFields: [PrimerInputElementType]
  let requiresBillingAddress: Bool
  var allFields: [PrimerInputElementType]
}
```

### FormData

```swift
public struct FormData: Equatable {
  subscript(fieldType: PrimerInputElementType) -> String { get set }
  var dictionary: [PrimerInputElementType: String]
}
```

### PresentationContext

```swift
public enum PresentationContext {
  case direct               // Show cancel button
  case fromPaymentSelection // Show back button
}
```

### DismissalMechanism

```swift
public enum DismissalMechanism {
  case gestures    // Swipe-down dismissal
  case closeButton // Close/cancel button
}
```

---

## Type Aliases

Component closures used for UI customization:

| Alias | Signature |
|---|---|
| `Component` | `() -> any View` |
| `ContainerComponent` | `(@escaping () -> any View) -> any View` |
| `ErrorComponent` | `(String) -> any View` |
| `PaymentMethodItemComponent` | `(CheckoutPaymentMethod) -> any View` |
| `CountryItemComponent` | `(PrimerCountry, @escaping () -> Void) -> any View` |
| `CategoryHeaderComponent` | `(String) -> any View` |
| `PaymentMethodSelectionScreenComponent` | `(PrimerPaymentMethodSelectionScope) -> any View` |
| `CardFormScreenComponent` | `(any PrimerCardFormScope) -> any View` |
| `KlarnaScreenComponent` | `(any PrimerKlarnaScope) -> any View` |
| `KlarnaButtonComponent` | `(any PrimerKlarnaScope) -> any View` |
| `PayPalScreenComponent` | `(any PrimerPayPalScope) -> any View` |
| `PayPalButtonComponent` | `(any PrimerPayPalScope) -> any View` |
| `AchScreenComponent` | `(any PrimerAchScope) -> any View` |
| `AchButtonComponent` | `(any PrimerAchScope) -> any View` |
| `WebRedirectScreenComponent` | `(any PrimerWebRedirectScope) -> any View` |
| `WebRedirectButtonComponent` | `(any PrimerWebRedirectScope) -> any View` |
| `FormRedirectScreenComponent` | `(any PrimerFormRedirectScope) -> any View` |
| `FormRedirectButtonComponent` | `(any PrimerFormRedirectScope) -> any View` |
| `FormRedirectFormSectionComponent` | `(any PrimerFormRedirectScope) -> any View` |
| `QRCodeScreenComponent` | `(any PrimerQRCodeScope) -> any View` |
