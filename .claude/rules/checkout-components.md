---
paths:
  - "Sources/PrimerSDK/Classes/CheckoutComponents/**/*.swift"
---

# CheckoutComponents (iOS 15+)

Payment checkout framework with SwiftUI, async/await, and UI customization through composable views. Mirrors Android v3's slot-based API.

> Full API signatures: `Sources/PrimerSDK/Classes/CheckoutComponents/API_REFERENCE.md`

## Entry Points

- **SwiftUI (managed modal)**: `PrimerCheckout(clientToken:primerSettings:primerTheme:onCompletion:)` — renders the SDK's default screens, no customization slots
- **SwiftUI (composable/inline)**: a `PrimerCheckoutSession` (held as `@StateObject`) wired in with the `.primerCheckoutSession(_:onCompletion:)` modifier, plus the composable views `PrimerCardForm`, `PrimerPaymentMethods`, `PrimerVaultedPaymentMethods`
- **UIKit**: `PrimerCheckoutPresenter.presentCheckout(clientToken:from:primerSettings:primerTheme:completion:)` (+ convenience overloads)
- **UIKit Delegate**: `PrimerCheckoutPresenterDelegate` — success, failure, dismiss, optional 3DS callbacks

## Public Surface

The scope protocols (`PrimerCheckoutScope`, `PrimerCardFormScope`, the per-method `Primer*Scope`, etc.) are **internal** — they are no longer part of the public API. Merchants integrate through:

- **Entry**: `PrimerCheckout` (modal) or `PrimerCheckoutSession` + `.primerCheckoutSession(_:onCompletion:)` (composable/inline)
- **Composable views**: `PrimerCardForm`, `PrimerPaymentMethods`, `PrimerVaultedPaymentMethods` — each exposes `@ViewBuilder` section slots and resolves its session from the environment
- **Observable sessions** (injected by the modifier): `PrimerCardFormSession`, `PrimerSelectionSession` — each bridges its scope's `AsyncStream<State>` into a `@Published state` and exposes the mutation surface (e.g. `updateCardNumber`, `submit`, `select`)
- **Defaults namespaces**: `CardFormDefaults`, `PaymentMethodsDefaults`, `VaultedPaymentMethodsDefaults` — default slot bodies plus per-field recomposition building blocks

This mirrors Android v3: the only public payment-method components are the card form and payment-method selection (incl. vaulted). The APM/aux scopes (Klarna, ApplePay, PayPal, Ach, WebRedirect, FormRedirect, QRCode, AdyenKlarna, BillingAddressRedirect, SelectCountry) are internal and rendered by the SDK; there are no public per-APM views.

## Internal Scope Hierarchy

Internal architecture (not public API), reached via `PrimerCheckoutSession`:

```
PrimerCheckoutScope (top-level, internal)
├── paymentMethodSelection: PrimerPaymentMethodSelectionScope
└── getPaymentMethodScope<T>() → per-method scopes:
    ├── PrimerCardFormScope          → PrimerCardFormState
    │   └── selectCountry: PrimerSelectCountryScope → PrimerSelectCountryState
    ├── PrimerApplePayScope          → PrimerApplePayState
    ├── PrimerPayPalScope            → PrimerPayPalState
    ├── PrimerKlarnaScope            → PrimerKlarnaState
    ├── PrimerAchScope               → PrimerAchState
    ├── PrimerWebRedirectScope       → PrimerWebRedirectState
    ├── PrimerFormRedirectScope      → PrimerFormRedirectState
    └── PrimerQRCodeScope            → PrimerQRCodeState
```

All payment method scopes extend `PrimerPaymentMethodScope` (base protocol with `start()`, `submit()`, `cancel()`, `onBack()`, `onDismiss()` and `state: AsyncStream<State>`). The public `PrimerCardFormSession` / `PrimerSelectionSession` wrap the card-form and selection scopes respectively.

## State Flows

**Checkout**: `initializing → ready(totalAmount, currencyCode) → success(PaymentResult) | failure(PrimerError) → dismissed`

**Per-method flows**:
- **Card**: Field-level state (`PrimerCardFormState`) with validation, co-badged networks, surcharge
- **Apple Pay**: `default → available | unavailable | loading`
- **PayPal**: `idle → loading → redirecting → processing → success | failure`
- **Klarna**: `loading → categorySelection → viewReady → authorizationStarted → awaitingFinalization`
- **ACH**: `loading → userDetailsCollection → bankAccountCollection → mandateAcceptance → processing`
- **Web Redirect**: `idle → loading → redirecting → polling → success | failure`
- **Form Redirect**: `ready → submitting → awaitingExternalCompletion → success | failure`
- **QR Code**: `loading → displaying → success | failure`

## Features

### Vaulting (Saved Payment Methods)
Via `PrimerPaymentMethodSelectionScope`:
- `payWithVaultedPaymentMethod()` — pay with saved card
- `payWithVaultedPaymentMethodAndCvv(_ cvv:)` — pay with CVV recapture
- `updateCvvInput(_ cvv:)` — update CVV field
- `showAllVaultedPaymentMethods()` — navigate to saved cards list
- State: `selectedVaultedPaymentMethod`, `requiresCvvInput`, `cvvInput`, `isCvvValid`, `cvvError`, `isVaultPaymentLoading`

### Surcharging
Per-payment-method and per-card-network surcharge amounts:
- `CheckoutPaymentMethod`: `surcharge: Int?` (minor units), `hasUnknownSurcharge`, `formattedSurcharge: String?`
- `PrimerCardFormState`: `surchargeAmountRaw: Int?`, `surchargeAmount: String?` (updates per selected network)
- `PrimerPayPalState`, `PrimerWebRedirectState`, `PrimerFormRedirectState`: `surchargeAmount: String?`

### Co-Badged Cards
- `PrimerCardFormState`: `selectedNetwork: PrimerCardNetwork?`, `availableNetworks: [PrimerCardNetwork]`
- `PrimerCardFormSession.selectCardNetwork(_ network:)` — select network
- `CardFormDefaults.cardNetwork(_:)` — standalone network selector building block (renders only when >1 network); the default `cardDetails` section already renders the selector

### Dynamic Billing Address
- `CardFormConfiguration.requiresBillingAddress` — API-driven
- Billing fields: firstName, lastName, email, addressLine1, addressLine2, city, state, postalCode, countryCode, phoneNumber, retailOutlet
- `CardFormDefaults.billingAddress(_:)` renders only when the configuration requires billing fields; each `CardFormDefaults.*` building block self-hides unless its field is in `CardFormConfiguration.cardFields`/`billingFields`

### 3DS
- Automatic handling via `PrimerCheckoutPresenterDelegate` optional callbacks:
  - `primerCheckoutPresenterWillPresent3DSChallenge(_:)`
  - `primerCheckoutPresenterDidDismiss3DSChallenge()`
  - `primerCheckoutPresenterDidComplete3DSChallenge(success:resumeToken:error:)`
- Configurable via `PrimerSettings.debugOptions.is3DSSanityCheckEnabled`

### BIN Detection
- `PrimerCardFormState.binData: PrimerBinData?` — network info from card BIN lookup

## Theming — `PrimerCheckoutTheme`

**NOT** `PrimerTheme`. Token-based system with optional overrides (nil = SDK defaults):

| Category | Type | Tokens |
|----------|------|--------|
| Colors | `ColorOverrides` | brand, 9 grays, semantic (green, red, blue), background, text (primary/secondary/placeholder/disabled/negative/link), borders (outlined 8 states, transparent 6 states), icons, focus, loader |
| Radius | `RadiusOverrides` | xsmall(2), small(4), medium(8), large(12), base(4) |
| Spacing | `SpacingOverrides` | xxsmall(2), xsmall(4), small(8), medium(12), large(16), xlarge(20), xxlarge(24), base(4) |
| Sizes | `SizeOverrides` | small(16), medium(20), large(24), xlarge(32), xxlarge(44), xxxlarge(56), base(4) |
| Typography | `TypographyOverrides` | titleXlarge, titleLarge, bodyLarge, bodyMedium, bodySmall — each with font, weight, size, letterSpacing, lineHeight |
| Border Width | `BorderWidthOverrides` | thin(1), medium(2), thick(3) |

Internal sources: `DesignTokens` (light), `DesignTokensDark` (dark), managed by `DesignTokensManager`.

## Customization (slot-based)

Customize by overriding a composable view's `@ViewBuilder` section slots, composing around the `*Defaults` building blocks. There is no field-config, section-closure, or screen-closure customization on scopes anymore — those properties were removed.

- **`PrimerCardForm`** — three slots: `cardDetails`, `billingAddress`, `submitButton` (each `(PrimerCardFormSession) -> some View`). Defaults: `CardFormDefaults.cardDetails/billingAddress/submitButton`. Recompose with the 15 field building blocks `CardFormDefaults.cardNumber/expiryDate/cvv/cardholderName/cardNetwork/countryCode/firstName/lastName/addressLine1/addressLine2/city/state/postalCode/phoneNumber/email`.
- **`PrimerPaymentMethods`** — three slots: `header`, `method (CheckoutPaymentMethod, onSelect)`, `emptyState`. Defaults: `PaymentMethodsDefaults.header/method/emptyState`.
- **`PrimerVaultedPaymentMethods`** — three `AnyView`-erased slots: `header`, `item (method, isSelected, onSelect)`, `submitButton (isLoading, isEnabled, onSubmit)`. Defaults: `VaultedPaymentMethodsDefaults.header/item/submitButton`.

Override a single slot with a **labeled** argument (a bare trailing closure binds to the last slot, `submitButton`):
```swift
PrimerCardForm(submitButton: { session in
    MyPayButton(isLoading: session.state.isLoading) { session.submit() }
})
```
`PrimerCheckout` (the managed modal) renders SDK defaults only — to customize, embed the composable views inline under `.primerCheckoutSession(_:)`.

Visual styling is theme-driven via `PrimerCheckoutTheme` (above), not per-field styling structs.

## Payment Methods (internal scopes)

Internal scope/state used by the SDK's own renderers (reached via `PrimerCheckoutSession`). Card and selection are surfaced publicly through the composable views above; the rest are internal-only.

| Directory | Scope (internal) | State | Key Actions |
|-----------|-------|-------|-------------|
| `Card/` | `PrimerCardFormScope` | `PrimerCardFormState` | ~19 field update methods, co-badged network selection; public via `PrimerCardForm` + `PrimerCardFormSession` |
| `ApplePay/` | `PrimerApplePayScope` | `PrimerApplePayState` | SDK-rendered Apple Pay button |
| `PayPal/` | `PrimerPayPalScope` | `PrimerPayPalState` | Submit button, redirect flow |
| `Klarna/` | `PrimerKlarnaScope` | `PrimerKlarnaState` | `selectPaymentCategory(_:)`, `authorizePayment()`, `finalizePayment()`, `paymentView: UIView?` |
| `Ach/` | `PrimerAchScope` | `PrimerAchState` | `updateFirstName/LastName/EmailAddress`, `submitUserDetails()`, `acceptMandate()`, `declineMandate()`, `bankCollectorViewController: UIViewController?` |
| `WebRedirect/` | `PrimerWebRedirectScope` | `PrimerWebRedirectState` | Submit + auto-redirect + polling (Twint, etc.) |
| `FormRedirect/` | `PrimerFormRedirectScope` | `PrimerFormRedirectState` | `updateField(_:value:)` for OTP/phone (BLIK, MBWay) |
| `QRCode/` | `PrimerQRCodeScope` | `PrimerQRCodeState` | Auto-polling after display (PromptPay, Xfers) |

## Architecture

- **DI**: `actor Container` provides async resolution and transient/singleton/weak retention (`ContainerRetainPolicy`), wrapped by the `final class ComposableContainer`
- **Navigation**: `CheckoutCoordinator` + `CheckoutNavigator` (state-driven via AsyncStream)
- **Registry**: `PaymentMethodRegistry.shared` — dynamic registration via `PaymentMethodProtocol`, three scope access patterns (metatype, enum, string)
- **Clean Architecture**: Domain (Interactors) → Data (Repositories, Mappers) → Presentation (Scopes, Views)
- **Validation**: `ValidationService` with `ValidationRule` protocol, `RulesFactory` creates per-field rules

## Conventions

- All scopes: `@MainActor`, `@available(iOS 15.0, *)`
- State observation: `for await state in scope.state { ... }` (AsyncStream)
- Use `func make...() -> some View` for extracted view pieces
- Register dependencies in container setup, resolve via `await container.resolve()`
- Scope access: `checkoutScope.getPaymentMethodScope(PrimerCardFormScope.self)`
- Payment handling: `.auto` (default) or `.manual` via `PrimerCheckoutScope.paymentHandling`
- Before-payment hook: `checkoutScope.onBeforePaymentCreate` — provides `PrimerCheckoutPaymentMethodData` and decision handler
- Presentation context: `.direct` (cancel button) vs `.fromPaymentSelection` (back button)
- Dismissal: `[DismissalMechanism]` — `.gestures`, `.closeButton`
