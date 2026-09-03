# Debug App

The Debug App (bundle `com.primerapi.PrimerSDKExample`) hosts the SDK's Drop-in, Headless and CheckoutComponents integrations for manual testing and for the E2E suite. Build it with the `Debug App` scheme of `PrimerSDK.xcworkspace` (CocoaPods) or `Primer.io Debug App SPM.xcodeproj` (SwiftPM); the root `CLAUDE.md` has the exact `xcodebuild` commands.

## Deep link

A deep link pre-loads a client session and SDK settings, and can open a CheckoutComponents demo directly, so an automated run reaches a checkout surface without tapping through the UI.

```
primer://sdk-demo.primer.io/latest/ios?clientToken=<jwt>&settings=<base64 JSON>[&demo=<key>]
```

| Parameter | Required | Meaning |
|---|---|---|
| `clientToken` | yes | A client-session token minted by your backend (the E2E harness uses `POST /client-session`). Used verbatim. |
| `settings` | yes | Base64 of a JSON object in the React Native `PrimerSettings` shape (see below). Decoded into `PrimerSettings`. |
| `demo` | no | A CheckoutComponents demo key (see the table). Present: the demo is opened directly. Absent: the app stays on the settings screen in AppLink mode. |

Matching rules: the app routes on the host `sdk-demo.primer.io`; the scheme (`primer`, `merchant`, `ui-tests`) and the path (`/latest/ios`) are ignored on iOS. Universal links (`https://sdk-demo.primer.io/…`) take the same path. Android's apps register the `primer` scheme exactly, so cross-platform producers keep `primer://`.

### What happens

1. `SDKDemoUrlHandler` parses the link and keeps it as a pending payload, then posts `.appetizeURLHandled`.
2. `MerchantSessionAndSettingsViewController` consumes the payload — in `viewDidLoad` when the link launched the app, or from the notification when the app was already running. It stores the token and settings, switches to the **AppLink** segment (`RenderMode.deepLink`) and clears the error label.
3. With `demo`, the demo is presented as a modal `UIHostingController` once the screen is in a window (`viewDidAppear`), the same container the Examples list uses. Anything pushed on top is popped and anything presented is dismissed first, so a second link replaces the current demo.
4. Without `demo`, the Drop-in, Headless and CheckoutComponents buttons all run against the deep-linked token and settings.

The presented demo takes the deep-linked `PrimerSettings` straight into its `DemoConfiguration`; unlike the CheckoutComponents button it does not call `Primer.shared.configure(settings:)` or build a client session from the form — CheckoutComponents registers its settings through `PrimerCheckoutSession`/`PrimerCheckout`, and a token is already present.

Timing observed on a simulator: the first CheckoutComponents element is findable about 2 s after a link to a running app and about 5 s after a link that launched it. Wait for the demo's anchor instead of sleeping.

### Demo keys

The `demo` values are `DemoKey` raw values (`Sources/View Controllers/CheckoutComponents/DemoKey.swift`). They are a cross-platform contract shared byte-for-byte with Primer Studio (Android) and the E2E page objects — literals, never derived from a display name. The shared table with the Android column lives in the e2e-tests repo (`ui/docs/CC_DEEP_LINK_CONVENTION.md`); `DemoKeyContractTests` pins the iOS list and a Danger check keeps every key on exactly one registered demo.

| Key | Demo | Terminal state |
|---|---|---|
| `default_checkout` | Default Checkout (managed `PrimerCheckout`) | SDK success/error screens (`checkout_components_success_title`…); the sheet dismisses ~3 s after success |
| `inline_checkout` | Inline Checkout | Debug App alert |
| `inline_card_form` | Inline Card Form | Debug App alert |
| `card_form_sheet` | Card Form Sheet | Debug App alert |
| `custom_card_form` | Fully Custom Card Form | Debug App alert |
| `prefill_cardholder_name` | Prefill Cardholder Name | Debug App alert |
| `before_payment_gate` | Before Payment Gate | Debug App alert |
| `payment_method_list_only` | Payment Methods Only | Debug App alert |
| `custom_payment_methods` | Custom Payment Methods | Debug App alert |
| `custom_grid_payment_methods` | Custom Grid | Debug App alert |
| `radio_selection` | Radio Selection | Debug App alert |
| `vault_management` | Vault Management | Debug App alert |
| `vaulted_payment_methods` | Vaulted Methods (Custom) | Debug App alert |
| `vault_mode_inline` | Vault Mode Inline | Debug App alert |
| `dynamic_vault` | Dynamic Vault | Debug App alert |
| `merchant_navigation` | Merchant Navigation | Debug App alert |
| `custom_result_screens` | Custom Result Screens | Debug App alert |
| `custom_navigation` | Custom Navigation | Debug App alert |
| `custom_theme`, `red_theme`, `green_theme`, `purple_theme`, `no_radius_theme`, `small_sizes_theme`, `large_sizes_theme`, `light_typography_theme`, `bold_typography_theme`, `large_typography_theme`, `custom_font_theme` | Themed managed checkout | SDK success/error screens |
| `refresh_client_session` | Refresh Client Session | Debug App alert |

"Debug App alert" means the demo shows the outcome in its own SwiftUI alert ("Payment complete" / "Payment failed", Done) rather than the SDK's screens. `default_checkout` is therefore the surface for E2E scenarios that assert on the SDK's success or error screen; it lands on the payment-method list, so a card flow taps the card row first.

Each row in the Examples list carries `demo_row_<key>` for UI tests.

### Settings JSON

The `settings` object is decoded as `RNPrimerSettings` (`Sources/Model/TestSettings.swift`) and mapped by `RNPrimerSettingsMapper`. Fields that reach `PrimerSettings`: `paymentHandling` (`AUTO` | `MANUAL`), `localeData.languageCode` / `localeData.localeCode` (mapped to `regionCode`), `paymentMethodOptions.iOS.urlScheme`, `paymentMethodOptions.applePayOptions` (all fields), `paymentMethodOptions.klarnaOptions.recurringPaymentDescription`, `paymentMethodOptions.threeDsOptions.iOS.threeDsAppRequestorUrl`, `paymentMethodOptions.stripeOptions.publishableKey` / `mandateData`, `uiOptions.isInitScreenEnabled` / `isSuccessScreenEnabled` / `isErrorScreenEnabled` / `dismissalMechanism`, `debugOptions.is3DSSanityCheckEnabled`, `clientSessionCachingEnabled`, `apiVersion`. Absent fields keep the SDK defaults.

Known limitations:

- No theme, `appearanceMode` or `cardFormUIOptions` — the mapper sets `theme: nil`.
- Decoded but not mapped: `cardPaymentOptions`, `goCardlessOptions`, `klarnaOptions.webViewTitle`, Stripe `fullMandateStringResourceName`.
- Required sub-fields fail the whole object when their subtree is present: `applePayOptions.merchantIdentifier` and `isCaptureBillingAddressEnabled`, `cardPaymentOptions.is3DSOnVaultingEnabled`, `shippingOptions.requireShippingMethod`.
- The deep-linked settings carry a `urlScheme`, Apple Pay and Stripe options only if the JSON does; the settings form hardcodes `merchant://primer.io` and its Apple Pay/Stripe values. Redirect flows need `paymentMethodOptions.iOS.urlScheme` in the profile.
- The blob is standard base64. iOS tolerates `+`, `/` and `=` in the query string; Android does not (it drops the whole object), so producers should percent-encode or use base64url.

### Errors

A link that cannot be applied shows `deep_link_error_label` on the settings screen, in every render mode, with the text `deep link error: <reason>`; the label is hidden when there is no error and cleared when the next link arrives. Reasons: `clientToken missing`, `settings missing`, `settings decode failed`, `unknown demo key "<value>"`, `settings missing or invalid` (a demo or the CheckoutComponents button was requested without decodable settings), `CheckoutComponents requires iOS 15`. Whatever did decode is still applied, so the manual path stays usable. A UI test should race the demo's anchor against this label and fail with its text.

### Sending a link

```bash
# Simulator (cold or warm)
xcrun simctl openurl booted "primer://sdk-demo.primer.io/latest/ios?clientToken=$TOKEN&settings=$SETTINGS&demo=default_checkout"
```

```ts
// Appium (XCUITest) — how the E2E suite delivers it
await browser.execute("mobile: deepLink", { url, bundleId: "com.primerapi.PrimerSDKExample" });
```

Appetize builds read `clientToken` and `settings` from `UserDefaults` at launch instead; that path is unchanged and has no `demo`.

### Test identifiers on the settings screen

New identifiers are snake_case (`deep_link_error_label`, `deep_link_clear_button`, `demo_row_<key>`); the older storyboard ones keep their spaced Title Case (`Primer SDK Button`, `Universal Checkout Button`, `CheckoutComponents Button`).
