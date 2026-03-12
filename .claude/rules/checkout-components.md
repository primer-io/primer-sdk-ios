---
paths:
  - "Sources/PrimerSDK/Classes/CheckoutComponents/**/*.swift"
---

# CheckoutComponents (iOS 15+)

Scope-based payment checkout framework with SwiftUI, async/await, and full UI customization. Exact Android API parity.

> Full API signatures: `Sources/PrimerSDK/Classes/CheckoutComponents/API_REFERENCE.md`

## Entry Points

- **SwiftUI**: `PrimerCheckout(clientToken:primerSettings:primerTheme:scope:onCompletion:)`
- **UIKit**: `PrimerCheckoutPresenter.presentCheckout(clientToken:from:primerSettings:primerTheme:scope:completion:)`
- **UIKit Delegate**: `PrimerCheckoutPresenterDelegate` — success, failure, dismiss, optional 3DS callbacks

## Scope Hierarchy

```
PrimerCheckoutScope (top-level)
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

All payment method scopes extend `PrimerPaymentMethodScope` (base protocol with `start()`, `submit()`, `cancel()`, `onBack()`, `onDismiss()` and `state: AsyncStream<State>`).

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
- `PrimerCardFormScope.updateSelectedCardNetwork(_ network:)` — select network
- `cobadgedCardsView` closure — custom network selection UI

### Dynamic Billing Address
- `CardFormConfiguration.requiresBillingAddress` — API-driven
- Billing fields: firstName, lastName, email, addressLine1, addressLine2, city, state, postalCode, countryCode, phoneNumber, retailOutlet
- `displayFields: [PrimerInputElementType]` — visible fields from API response

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

## Customization Levels

1. **Field-level**: `InputFieldConfig` — partial (label, placeholder, `PrimerFieldStyling`) or full replacement (`component` closure)
2. **Section-level**: Replace card/billing sections via scope closures (`cardInputSection`, `billingAddressSection`)
3. **Screen-level**: Replace entire screens per scope (`screen` closure on each scope)
4. **Checkout-level**: `container`, `splashScreen`, `loadingScreen`, `errorScreen` on `PrimerCheckoutScope`

`PrimerFieldStyling`: fontName, fontSize, fontWeight, labelFontName, labelFontSize, labelFontWeight, textColor, labelColor, backgroundColor, borderColor, focusedBorderColor, errorBorderColor, placeholderColor, cornerRadius, borderWidth, padding, fieldHeight.

## Payment Methods

| Directory | Scope | State | Key Actions |
|-----------|-------|-------|-------------|
| `Card/` | `PrimerCardFormScope` | `PrimerCardFormState` | 20 field update methods, co-badged selection, 16 `InputFieldConfig` properties, 16 `PrimerXxxField()` ViewBuilders |
| `ApplePay/` | `PrimerApplePayScope` | `PrimerApplePayState` | `PrimerApplePayButton(action:)` |
| `PayPal/` | `PrimerPayPalScope` | `PrimerPayPalState` | Submit button, redirect flow |
| `Klarna/` | `PrimerKlarnaScope` | `PrimerKlarnaState` | `selectPaymentCategory(_:)`, `authorizePayment()`, `finalizePayment()`, `paymentView: UIView?` |
| `Ach/` | `PrimerAchScope` | `PrimerAchState` | `updateFirstName/LastName/EmailAddress`, `submitUserDetails()`, `acceptMandate()`, `declineMandate()`, `bankCollectorViewController: UIViewController?` |
| `WebRedirect/` | `PrimerWebRedirectScope` | `PrimerWebRedirectState` | Submit + auto-redirect + polling (Twint, etc.) |
| `FormRedirect/` | `PrimerFormRedirectScope` | `PrimerFormRedirectState` | `updateField(fieldType:value:)` for OTP/phone (BLIK, MBWay) |
| `QRCode/` | `PrimerQRCodeScope` | `PrimerQRCodeState` | Auto-polling after display (PromptPay, Xfers) |

## Architecture

- **DI**: `ComposableContainer` — actor-based, async resolution, transient/singleton/weak retention
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
