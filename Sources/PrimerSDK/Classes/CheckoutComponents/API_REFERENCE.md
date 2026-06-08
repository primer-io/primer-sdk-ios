# CheckoutComponents API Reference

Complete public API reference for the CheckoutComponents framework (iOS 15+).

---

## Entry Points

### PrimerCheckout (SwiftUI — managed modal)

Renders the SDK's default screens. To customize the UI, embed the composable views inline under `.primerCheckoutSession(_:onCompletion:)`.

```swift
@available(iOS 15.0, *)
public struct PrimerCheckout: View {
  public init(
    clientToken: String,
    primerSettings: PrimerSettings = PrimerSettings(),
    primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  )
}
```

### PrimerCheckoutSession + modifier (SwiftUI — composable/inline)

```swift
@available(iOS 15.0, *)
@MainActor
public final class PrimerCheckoutSession: ObservableObject {
  public enum Phase: Equatable { case initializing, ready }
  @Published public private(set) var phase: Phase

  public var onBeforePaymentCreate: BeforePaymentCreateHandler?
  public var idempotencyKey: @Sendable () -> String?

  public init(
    clientToken: String,
    settings: PrimerSettings = PrimerSettings(),
    theme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    idempotencyKey: @escaping @Sendable () -> String? = { nil }
  )
}

// Wire into view hierarchy:
extension View {
  func primerCheckoutSession(
    _ session: PrimerCheckoutSession,
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  ) -> some View
}
```

**Usage:**
```swift
@StateObject private var session = PrimerCheckoutSession(clientToken: token)

ScrollView {
    PrimerCardForm()
    PrimerPaymentMethods()
}
.primerCheckoutSession(session) { state in handle(state) }
```

### Composable Views

Composable views resolve their session from the environment and expose `@ViewBuilder` slots.

#### PrimerCardForm

Three slots: `cardDetails`, `billingAddress`, `submitButton` — each `(PrimerCardFormSession) -> some View`. Defaults: `CardFormDefaults.cardDetails/billingAddress/submitButton`.

```swift
@available(iOS 15.0, *)
public struct PrimerCardForm<CardDetails: View, Billing: View, Submit: View>: View {
  public init(
    @ViewBuilder cardDetails: @escaping (PrimerCardFormSession) -> CardDetails
      = { CardFormDefaults.cardDetails($0) },
    @ViewBuilder billingAddress: @escaping (PrimerCardFormSession) -> Billing
      = { CardFormDefaults.billingAddress($0) },
    @ViewBuilder submitButton: @escaping (PrimerCardFormSession) -> Submit
      = { CardFormDefaults.submitButton($0) }
  )
}
```

#### PrimerPaymentMethods

Three slots: `header`, `method (CheckoutPaymentMethod, onSelect)`, `emptyState`. Defaults: `PaymentMethodsDefaults.header/method/emptyState`.

```swift
@available(iOS 15.0, *)
public struct PrimerPaymentMethods<Header: View, Method: View, Empty: View>: View {
  public init(
    @ViewBuilder header: @escaping (PrimerSelectionSession) -> Header
      = { PaymentMethodsDefaults.header($0) },
    @ViewBuilder method: @escaping (CheckoutPaymentMethod, @escaping () -> Void) -> Method
      = { PaymentMethodsDefaults.method($0, onSelect: $1) },
    @ViewBuilder emptyState: @escaping (PrimerSelectionSession) -> Empty
      = { PaymentMethodsDefaults.emptyState($0) }
  )
}
```

#### PrimerVaultedPaymentMethods

Three `AnyView`-erased slots: `header`, `item (method, isSelected, onSelect)`, `submitButton (isLoading, isEnabled, onSubmit)`. Defaults: `VaultedPaymentMethodsDefaults.header/item/submitButton`.

```swift
@available(iOS 15.0, *)
public struct PrimerVaultedPaymentMethods: View {
  public init(
    header: @escaping (PrimerSelectionSession) -> AnyView
      = { AnyView(VaultedPaymentMethodsDefaults.header($0)) },
    item: @escaping (VaultedMethod, _ isSelected: Bool, _ onSelect: @escaping () -> Void) -> AnyView
      = { AnyView(VaultedPaymentMethodsDefaults.item($0, isSelected: $1, onSelect: $2)) },
    submitButton: @escaping (_ isLoading: Bool, _ isEnabled: Bool, _ onSubmit: @escaping () -> Void) -> AnyView
      = { AnyView(VaultedPaymentMethodsDefaults.submitButton(isLoading: $0, isEnabled: $1, onSubmit: $2)) }
  )
}
```

### Defaults Namespaces

Pre-built slot bodies and per-field building blocks for recomposition.

- **`CardFormDefaults`**: `cardDetails`, `billingAddress`, `submitButton` + 15 field building blocks: `cardNumber`, `expiryDate`, `cvv`, `cardholderName`, `cardNetwork`, `countryCode`, `firstName`, `lastName`, `addressLine1`, `addressLine2`, `city`, `state`, `postalCode`, `phoneNumber`, `email`. Each field building block self-hides unless its field is in `CardFormConfiguration.cardFields`/`billingFields`.
- **`PaymentMethodsDefaults`**: `header`, `method`, `emptyState`.
- **`VaultedPaymentMethodsDefaults`**: `header`, `item`, `submitButton`.

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
    completion: (() -> Void)? = nil
  )

  // Convenience overloads
  public static func presentCheckout(clientToken: String, from: UIViewController, completion: (() -> Void)? = nil)
  public static func presentCheckout(clientToken: String, from: UIViewController, primerSettings: PrimerSettings, completion: (() -> Void)? = nil)
  public static func presentCheckout(clientToken: String, from: UIViewController, primerSettings: PrimerSettings, primerTheme: PrimerCheckoutTheme, completion: (() -> Void)? = nil)

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

## Observable Sessions

The composable views communicate with the SDK through observable sessions injected by the `.primerCheckoutSession(_:onCompletion:)` modifier.

### PrimerCardFormSession

Bridges the card-form scope into an observable object consumed by `PrimerCardForm`.

```swift
@available(iOS 15.0, *)
@MainActor
public final class PrimerCardFormSession: ObservableObject {
  @Published public private(set) var state: PrimerCardFormState

  // Mutation surface
  public func updateCardNumber(_ value: String)
  public func updateCvv(_ value: String)
  public func updateExpiryDate(_ value: String)
  public func updateCardholderName(_ value: String)
  public func updatePostalCode(_ value: String)
  public func updateCountryCode(_ value: String)
  public func updateCity(_ value: String)
  public func updateState(_ value: String)
  public func updateAddressLine1(_ value: String)
  public func updateAddressLine2(_ value: String)
  public func updatePhoneNumber(_ value: String)
  public func updateFirstName(_ value: String)
  public func updateLastName(_ value: String)
  public func selectCardNetwork(_ network: PrimerCardNetwork)
  public func submit()
  public func cancel()
}
```

### PrimerSelectionSession

Bridges the payment-method selection scope into an observable object consumed by `PrimerPaymentMethods` and `PrimerVaultedPaymentMethods`.

```swift
@available(iOS 15.0, *)
@MainActor
public final class PrimerSelectionSession: ObservableObject {
  @Published public private(set) var state: PrimerPaymentMethodSelectionState
  public var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]

  public func select(_ method: CheckoutPaymentMethod)
  public func cancel()
  public func selectVaulted(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
  public func delete(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
  public func showAll()
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
  public internal(set) var binData: PrimerBinData?
  var displayFields: [PrimerInputElementType]

  func hasError(for fieldType: PrimerInputElementType) -> Bool
  func errorMessage(for fieldType: PrimerInputElementType) -> String?
  mutating func setError(_ message: String, for fieldType: PrimerInputElementType, errorCode: String?)
  mutating func clearError(for fieldType: PrimerInputElementType)
}
```

---

## Configuration

### PrimerCheckoutTheme

Design token overrides for the entire checkout UI.

```swift
public struct PrimerCheckoutTheme: Equatable {
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

**Override types**: `ColorOverrides`, `RadiusOverrides`, `SpacingOverrides`, `SizeOverrides`, `TypographyOverrides`, `BorderWidthOverrides`. See `Scope/PrimerCheckoutTheme.swift` for all token names.

---

## Data Types

### CheckoutPaymentMethod

```swift
public struct CheckoutPaymentMethod: Equatable, Identifiable {
  let id: String
  let type: String                  // e.g., "PAYMENT_CARD", "PAYPAL"
  let name: String                  // Display name
  let icon: UIImage?
  let surcharge: Int?               // Minor units
  let hasUnknownSurcharge: Bool
  let formattedSurcharge: String?
  let backgroundColor: UIColor?
  let buttonText: String?           // Custom button text (e.g., "Pay with Klarna")
  let textColor: UIColor?
  let borderColor: UIColor?
  let borderWidth: CGFloat?
  let cornerRadius: CGFloat?
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
  public var id: PrimerInputElementType { fieldType }
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

### DismissalMechanism

```swift
public enum DismissalMechanism {
  case gestures    // Swipe-down dismissal
  case closeButton // Close/cancel button
}
```

