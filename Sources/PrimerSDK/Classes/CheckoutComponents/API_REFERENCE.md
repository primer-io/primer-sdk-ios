# CheckoutComponents API Reference

Complete public API reference for the CheckoutComponents framework (iOS 15+).

---

## Entry Points

### PrimerCheckout (SwiftUI — managed modal)

Renders the SDK's default screens. To customize the UI, embed the composable views inline under `.primerCheckoutSession(_:theme:onCompletion:)`.

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

  /// Amount, currency, order, line items, fees and customer. Non-nil from `.ready` onwards.
  @Published public private(set) var clientSession: PrimerClientSession?

  public var onBeforePaymentCreate: BeforePaymentCreateHandler?
  public var idempotencyKey: @Sendable () -> String?

  public init(
    clientToken: String,
    settings: PrimerSettings = PrimerSettings(),
    theme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
    idempotencyKey: @escaping @Sendable () -> String? = { nil }
  )

  // Lifecycle. The modifier calls `start()` on appear and `cancel()` on disappear, so you
  // only call these yourself when you drive the session by hand.
  public func start() async
  public func refresh() async
  public func cancel()

  // Sub-sessions, non-nil once `phase == .ready`. Cached, so repeated reads return the same object.
  public var cardForm: PrimerCardFormSession? { get }
  public var selection: PrimerSelectionSession? { get }

  /// Formats minor units with the client session's currency and `PrimerSettings.localeData`.
  /// Returns nil before `.ready`.
  public func formatAmount(_ amountInMinorUnits: Int) -> String?
}

// Wire into view hierarchy:
extension View {
  func primerCheckoutSession(
    _ session: PrimerCheckoutSession,
    theme: PrimerCheckoutTheme? = nil,
    onCompletion: ((PrimerCheckoutState) -> Void)? = nil
  ) -> some View
}
```

`theme` overrides the one the session was built with and re-themes on every change, so an app
that switches appearance at runtime does not have to rebuild the session.

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

Renders the **selected** method only (the first saved one until the customer picks another), not the whole vault, and renders nothing when there are no saved methods. The default header's "Show all" opens the SDK's saved-methods screen — the only place a customer can delete a method. For a full inline list, iterate `PrimerSelectionSession.vaultedPaymentMethods` yourself.

The item slot marks; the submit slot pays. A card whose client session asks for CVV recapture
raises the SDK's own CVV screen on submit, so no slot has to make room for that field.

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

- **`CardFormDefaults`**: `cardDetails`, `billingAddress`, `submitButton` + 14 field building blocks: `cardNumber`, `expiryDate`, `cvv`, `cardholderName`, `cardNetwork`, `countryCode`, `firstName`, `lastName`, `addressLine1`, `addressLine2`, `city`, `state`, `postalCode`, `phoneNumber`. Each field building block self-hides unless its field is in `CardFormConfiguration.cardFields`/`billingFields`.
- **`PaymentMethodsDefaults`**: `header`, `method`, `emptyState`.
- **`VaultedPaymentMethodsDefaults`**: `header` (section title + "Show all"), `item`, `submitButton`.

### PrimerCheckoutPresenter (UIKit)

```swift
@available(iOS 15.0, *)
@objc public final class PrimerCheckoutPresenter: NSObject {
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

The composable views communicate with the SDK through observable sessions injected by the `.primerCheckoutSession(_:theme:onCompletion:)` modifier.

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

  /// Published, so a list you build yourself re-renders when the set changes. That covers
  /// `delete(_:)` and a delete made on the SDK's saved-methods screen.
  @Published public private(set) var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod]

  public func select(_ method: CheckoutPaymentMethod)
  public func cancel()

  /// Pays with a saved method. Call it from your pay button, not from a row tap.
  public func selectVaulted(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)

  public func delete(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) async throws
  public func showAll()
}
```

`selectVaulted(_:)` is the pay verb, matching Android's `PrimerVaultedPaymentMethodsController.select(method)`.
It returns at once and the payment runs on. The outcome arrives through the modifier's
`onCompletion`. Keep which row looks selected in your own view state. A card that needs CVV
recapture raises the SDK's CVV screen first, and that screen finishes the payment.

---

## State Types

### PrimerCheckoutState

```
initializing -> ready -> success | failure -> dismissed
```

`.ready` carries a snapshot taken when the checkout initializes, and again after `refresh()`. A
client-session update triggered mid-checkout (surcharge, billing address) does not re-emit it.
When switching on this enum, include a `default` case so future additions do not break the build.

```swift
public enum PrimerCheckoutState: Equatable {
  case initializing
  case ready(clientSession: PrimerClientSession)
  case success(PaymentResult)
  case dismissed
  case failure(PrimerError)
}
```

### PrimerPaymentMethodSelectionState

```swift
public struct PrimerPaymentMethodSelectionState: Equatable {
  var paymentMethods: [CheckoutPaymentMethod]
  var isLoading: Bool
  var selectedPaymentMethod: CheckoutPaymentMethod?
  var searchQuery: String
  var filteredPaymentMethods: [CheckoutPaymentMethod]
  var error: String?
  var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  var isVaultPaymentLoading: Bool
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
public struct PrimerCountry: Equatable, Identifiable {
  public var id: String { code }
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
public enum DismissalMechanism: String, Codable {
  case gestures = "GESTURES"       // Swipe-down dismissal
  case closeButton = "CLOSE_BUTTON" // Close/cancel button
}
```

Declared in `PrimerCore`, and passed to the SDK through `PrimerUIOptions`, not through
CheckoutComponents directly.

### PaymentResult

Delivered by `PrimerCheckoutState.success` and by the presenter delegate.

```swift
public struct PaymentResult: Sendable, Equatable {
  public let paymentId: String
  public let status: PaymentStatus
  public let token: String?
  public let redirectUrl: String?
  public let errorMessage: String?
  public let amount: Int?
  public let currencyCode: String?
  public let paymentMethodType: String?
}

public enum PaymentStatus: Sendable {
  case pending
  case success
  case failed
}
```

