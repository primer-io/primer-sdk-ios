# CheckoutComponents PR Review — Cross-Checked Findings (v1 + v2)

**Date:** 2026-03-31
**Method:** Two independent review cycles with swift-reviewer agents (Opus), cross-checked for consistency. Only findings confirmed in both rounds (or high-confidence new finds from v2) are included.
**Scope:** PRs #1630–#1645 (cc-02 through cc-15). PRs 01/16 skipped (no Swift).

---

## Confirmed Findings by Priority

### CRITICAL (must fix before review) — 7 items

| # | PR | File:Line | Finding | Confirmed |
|---|-----|-----------|---------|-----------|
| C1 | 03 | `PrimerDelegate.swift:382` | `preconditionFailure()` crash when `sdkIntegrationType == .checkoutComponents` in async `primerDidFailWithError`. Only `.headless` and `.dropIn` handled. | v1+v2 |
| C2 | 02 | `RetentionPolicyTests.swift:285-343` | Tests define private shadow `DIContainer` class — all 14 retention tests run against a local mock, providing zero coverage of real `Container`/`RetentionStrategy`. | v1+v2 |
| C3 | 10 | `PrimerPaymentMethodType+ImageName.swift:20` | Google Pay maps to `.appleIcon` — shows Apple icon for Google Pay. | v1+v2 |
| C4 | 06 | `PrimerPaymentMethodScope.swift:94-128` | `PaymentMethodProtocol` is `public` but exposes `ContainerProtocol` (DI internals) to merchants. Misleading API contract. | v1+v2 |
| C5 | 03 | `AnalyticsEvent.swift:767-769` | `SDKProperties.encode(to:)` encodes `sdkSettings` twice, never encodes `sdkIntegrationType`. Analytics can't distinguish CC sessions. | v1 only (v2 noted as LOW pre-existing) |
| C6 | 11 | `HeadlessRepositoryImpl.swift:614-629` | `selectCardNetwork` fires detached Task for `selectPaymentMethodIfNeeded` without awaiting. Race: payment may proceed before backend has network context. Comment says "CRITICAL for surcharge functionality." | v1+v2 |
| C7 | 07 | `DesignTokens.swift:255+` | Color decoding accesses array indices `[0]-[3]` without bounds check. Malformed JSON crashes with index-out-of-range. | v1+v2 |

### HIGH (should fix) — 35 items

#### Access Control (systemic — ~30 types)

| # | PRs | Finding |
|---|-----|---------|
| H1 | 02,04,05,06,08,13 | **`public` types in `Internal/` directories.** ~30+ types marked `public` that should be internal: all `Default*Scope` classes (PR 13), DI framework types (`Container`, `ContainerError`, `TypeKey`, `Factory`, `DependencyScope` — PR 02), `ValidationError`/`ValidationService` (PR 05), `PaymentResult`/`PaymentStatus` (PR 04), analytics models (`AnalyticsEnvironment`, `AnalyticsEventMetadata`, `AnalyticsSessionConfig` — PR 08), `FieldValidationStates` (PR 13). Bulk fix: grep `public` in `Internal/` paths. |

#### Bugs & Logic Errors

| # | PR | File:Line | Finding |
|---|-----|-----------|---------|
| H2 | 04 | `ProcessApplePayPaymentInteractor.swift:53` | `paymentResponse.id ?? ""` silently coerces nil payment ID to empty string. Should throw. |
| H3 | 04 | `InternalPaymentMethod.swift:69-74` | Custom `Equatable` ignores `configId`, `networkSurcharges`, `icon`, etc. Could mask real state changes. |
| H4 | 12 | `WebRedirectPaymentMethod.swift:51` | `repository` resolved with `try?` — nil silently passed to scope. Will crash on payment. |
| H5 | 12 | `QRCodePaymentMethod.swift:53-56` | Direct instantiation of `ProcessQRCodePaymentInteractorImpl` bypasses DI. Only method that does this. |
| H6 | 12 | `WebRedirectPaymentMethod.swift:80-88` | `createScope` always throws `PrimerError.invalidArchitecture`. Dead code. |
| H7 | 09 | `CheckoutSDKInitializer.swift:96-99` | Fire-and-forget `Task` for `DIContainer.clearContainer()`. Re-init before clear completes = race. |
| H8 | 11 | `HeadlessRepositoryImpl.swift:684-692` | Vault payment timeout Task (60s) never cancelled on success. Resource leak. |
| H9 | 11 | `HeadlessRepositoryImpl.swift:252-253` | Empty `catch` blocks silently swallow DI resolution failures. No logging. |
| H10 | 02 | `Container.swift:315-333` | `resolveBatch` concurrent tasks share `resolutionStack` — false circular dependency detection when `buildAsync` suspends. |

#### Thread Safety & Concurrency

| # | PR | File:Line | Finding |
|---|-----|-----------|---------|
| H11 | 04 | `ProcessAchPaymentInteractor.swift:29` | Not `@MainActor` despite calling `@MainActor`-isolated `AchRepository`. |
| H12 | 04 | `ProcessKlarnaPaymentInteractor.swift:19` | Same: not `@MainActor` but calls `@MainActor` `KlarnaRepository`. |
| H13 | 08 | `AnalyticsEventMetadata.swift`, `AnalyticsPayload.swift`, `AnalyticsSessionConfig.swift` | Missing `Sendable` conformance on types crossing actor boundaries. |
| H14 | 08 | `DefaultAnalyticsInteractor.swift:18-22` | Fire-and-forget `Task` in actor: errors swallowed, ordering lost, `async` misleading. |

#### Architecture & Design

| # | PR | File:Line | Finding |
|---|-----|-----------|---------|
| H15 | 13 | `DefaultCheckoutScope.swift:196` | Hardcoded 500ms `Task.sleep` in `loadPaymentMethods()`. Artificial delay on every checkout. |
| H16 | 13 | `DefaultCheckoutScope.swift:136-139` | Unstructured `Task` in `init`. Race: `loadPaymentMethods()` may run before `setupInteractors()` finishes. |
| H17 | 13 | `DefaultCheckoutScope.swift:438-457` | `navigationStateEquals` duplicates `NavigationState.==`. Will drift. |
| H18 | 06 | `PrimerCardFormScope.swift:55-78` | Protocol requirement duplication: re-declares `state`, `start()`, `submit()`, `cancel()`, `onBack()` from parent. |
| H19 | 14 | `PaymentMethodComponents.swift:75` | Downcasts `checkoutScope as? DefaultCheckoutScope` — breaks scope abstraction. |
| H20 | 14 | `CardFormScreen.swift:304-307` | Downcasts to `DefaultCardFormScope` to call `performSubmit()` bypassing public API. |
| H21 | 15 | `PrimerCheckoutPresenter.swift:443-448` | Two `delegate` properties (instance `PrimerCheckoutPresenterDelegate` vs static `PrimerDelegate`). Confusing. |
| H22 | 15 | `PrimerCheckout.swift:98` | `DIContainer.shared` reused across views — cross-contamination risk. |
| H23 | 03 | `PrimerLogger.swift:99-127` | Core logger hard-depends on CC DI types. Noisy `#if DEBUG` prints for non-CC. |
| H24 | 03 | `Primer.swift:56-59` | `FontRegistration.registerFonts()` in `Primer.init()` — runs for ALL SDK users. |
| H25 | 10 | Bridge vs Repo | `extractNetworkSurcharges`, `extractFromNetworksArray`, `extractFromNetworksDict`, `getRequiredInputElements` duplicated between `CheckoutComponentsPaymentMethodsBridge` and `HeadlessRepositoryImpl`. |
| H26 | 12 | All repositories | Mixed DI patterns: some use `DependencyContainer.resolve()`, some `PrimerSettings.current` directly. Should use `ComposableContainer`. |
| H27 | 05 | `ValidationService.swift:48` | `ValidationResultCache` singleton — 30-second TTL causes test pollution. |
| H28 | 03 | `PrimerDelegate.swift:167-170` | Incomplete `.checkoutComponents` handling — only `primerWillCreatePaymentWithData` handles it. Other proxy methods silently drop events. |

#### Duplicate Localization Keys (NEW in v2)

| # | PR | Finding |
|---|-----|---------|
| H29 | 09 | `CheckoutComponentsStrings.swift:174+615` — `primer_card_form_placeholder_cvv` used for `cvvPlaceholder` ("CVV") and `cvvStandardPlaceholder` ("123"). Different defaults, same key. |
| H30 | 09 | `CheckoutComponentsStrings.swift:257+679` — `primer_card_form_label_otp` used for `otpLabel` and `otpCodePlaceholder`. |
| H31 | 09 | `CheckoutComponentsStrings.swift:113+572` — `primer_common_button_pay_amount` shared between `paymentAmountTitle` and `paymentMethodDisplayName`. |
| H32 | 09 | `CheckoutComponentsStrings.swift:183+623` — `primer_card_form_placeholder_name` shared between `cardholderNamePlaceholder` and `fullNamePlaceholder`. |

#### New v2 Finds

| # | PR | File:Line | Finding |
|---|-----|-----------|---------|
| H33 | 03 | `PrimerSettings.swift:413` | `dismissalMechanism` decoded with `decode` (not `decodeIfPresent`). Will throw on missing key. |
| H34 | 03 | `PrimerSettings.swift:323-328` | `DismissalMechanism` auto-synthesized Codable uses integer indices. Case reorder = silent breaking change. |
| H35 | 11 | `HeadlessRepositoryImpl.swift:289-324` | Repository doesn't filter by `PaymentMethodRegistry` (bridge does). Returns unsupported methods. |

---

### MEDIUM (should fix, lower priority) — Top 30 (out of ~140)

| # | PRs | Finding |
|---|-----|---------|
| M1 | ALL | **Emoji in log messages** (~25 locations). Grep `[✅⚠️📊🌉⏭️]` in `.swift` files. |
| M2 | ALL | **Missing `final` on classes** (~15 classes): `WeakBox`, `SyncCache`, `ThreadSafeContainer`, `ContainerRegistrationBuilderImpl`, `PaymentCompletionHandler`, `MockCardFormScope`, test helpers. |
| M3 | 07+ | **Namespace structs should be caseless enums** (~12): `PrimerFont`, `PrimerSpacing`, `PrimerSize`, `PrimerRadius`, `PrimerComponentHeight`, `PrimerComponentWidth`, `PrimerIconSize`, `PrimerBorderWidth`, `PrimerScale`, `PrimerAnimationDuration`, `AnimationConstants`, `ApplePayRequestBuilder`. |
| M4 | 02 | `DIContainter+SwiftUI.swift` — Filename typo. |
| M5 | 02 | `SwiftUI+DI.swift` — Empty file. Delete. |
| M6 | 02 | `SwiftUIDITests.swift` — Empty test class. Delete. |
| M7 | 07 | `SlideInModifier.swift`, `AccessibilityConfigurable.swift`, `AccessibilityIdentifierProviding.swift` — Empty files. Delete. |
| M8 | 12 | `FormRedirectPaymentMethod.swift`, `DefaultWebRedirectScope.swift`, `DefaultFormRedirectScope.swift`, `VaultManagerProtocol.swift`, `WebRedirectRepositoryImpl.swift`, `PrimerFormRedirectState.swift` — 4-space indentation (rest uses 2-space). |
| M9 | 14 | `CardFormFieldsView.swift` and `CardFormScreen.swift` — Nearly identical `renderField` (~150 lines duplicated). |
| M10 | 12 | All 8 payment methods — Scope creation boilerplate duplicated (~16 lines each). Extract helper. |
| M11 | 12 | `BlikPaymentMethod` and `MBWayPaymentMethod` nearly identical. Consider shared factory. |
| M12 | 12 | `ApplePayPaymentMethod.swift:14` — Hardcoded `"APPLE_PAY"` instead of enum rawValue. |
| M13 | 12 | Inconsistent `ErrorHandler.handle` usage across repositories. |
| M14 | 05 | `ValidationService.swift:166` — Blanket `// swiftlint:disable all`. Scope to specific rule. |
| M15 | 05 | `CityRule`/`StateRule` defined but unused in main validation path (AddressFieldRule used instead). |
| M16 | 05 | Hardcoded error strings in `ExpiryDateInput.swift`, `CardValidationRules.swift`. |
| M17 | 07 | `DesignTokensManager.swift:48` — Redundant `MainActor.run` inside `@MainActor` class. |
| M18 | 08 | `LoggingSessionContext.shared` singleton conflicts with DI pattern. |
| M19 | 08 | `SensitiveDataMasker` card regex matches any 13-19 digit sequence (false positives). |
| M20 | 06 | `PrimerCheckoutScope.swift:38-39,85-86` — Leftover change note comments. |
| M21 | 06 | `PrimerSelectCountryScope.swift:34-38` — `searchBar` property is raw tuple closure. Define typealias. |
| M22 | 06 | `PrimerEnvironment.swift:63-64` — Doc example references `structuredState` (internal type). Won't compile for merchants. |
| M23 | 13 | `DefaultPaymentMethodSelectionScope.swift:113-118` — Throws `NSError` instead of `PrimerError`. |
| M24 | 14 | Mock utilities in source dir (`MockCardFormScope`, `MockDIContainer`) are `public`. Should be `#if DEBUG` and not `public`. |
| M25 | 05 | Duplicate `assertAllValid`/`assertAllInvalid` helpers across 8 test files. Extract shared. |
| M26 | 02 | `ContainerProtocol.swift:51-62` — `RegistrationBuilder` chainable methods lack `@discardableResult`. |
| M27 | 02 | `Container.swift:141-142` — `instances`/`weakBoxes` internal on actor. Should be `private` with accessors. |
| M28 | 11 | `OneShotContinuation` is general utility declared in repository file. Own file. |
| M29 | 06 | `PaymentMethodRegistry.reset()` has no `#if DEBUG` guard. |
| M30 | 08 | `AnalyticsPayloadBuilder.swift:20` — React Native detection via `NSClassFromString` on every event. Cache. |

---

### LOW (nice to have) — Top 15 (out of ~60)

| # | PRs | Finding |
|---|-----|---------|
| L1 | 12 | All 8 methods — `content()`/`defaultContent()` always `fatalError`. Make protocol methods optional. |
| L2 | 12 | `AchRepositoryImpl.swift:192`, `KlarnaRepositoryImpl.swift:325` — `UUID().uuidString` as fallback payment ID. |
| L3 | 04 | `TestData+Address.swift:91-92` — `valid4Digit` and `tooShort` are identical values. |
| L4 | 04 | `TestData+Config.swift:31` — `enum Locale` shadows `Foundation.Locale`. |
| L5 | 02 | `ContainerRetainPolicy` has `Codable` with no serialization use case. |
| L6 | 02 | `TypeKey` Codable: decoded keys use placeholder `ObjectIdentifier` — silent lookup failures. |
| L7 | 02 | `Container.swift:315` — Comment says "parallel" but actor serializes resolution. |
| L8 | 03 | `PrimerSettings.swift:399,448` — `!= nil ? x! : default` pattern. Use `?? default`. |
| L9 | 05 | `CountryCodeRule` accepts lowercase and non-alpha (`"!@"`). |
| L10 | 06 | `PrimerCheckoutTheme.swift:60-221` — `ColorOverrides` init with 34 params. Consider sub-structs. |
| L11 | 08 | `AnalyticsEnvironmentProviderTests.swift:220-232` — Test uses `print()`. |
| L12 | 09 | `ErrorMessageResolver.swift` — All static methods. Should be caseless `enum`. |
| L13 | 11 | `HeadlessRepositoryImpl.swift:785-806` — `Mirror`-based reflection for redirect URL. Fragile. |
| L14 | 13 | `DefaultCheckoutScope.swift:485-498` — `onDismiss()` creates unnecessary Task inside `@MainActor`. |
| L15 | 15 | `PrimerCheckout.swift:27-29` — Doc example references `DefaultCardFormScope` (internal type). |

---

## Quick-Win Fix Categories

| Category | Count | Effort | How |
|----------|-------|--------|-----|
| Remove `public` from `Internal/` types | ~30 | Low | Grep + bulk find-replace |
| Remove emoji from logs | ~25 | Low | Grep `[✅⚠️📊🌉⏭️]` in .swift |
| Add `final` to classes | ~15 | Low | Grep `class ` without `final` in CC files |
| Fix indentation (4→2 space) | ~6 files | Low | SwiftFormat |
| Delete empty files | 4 files | Trivial | Delete |
| Struct → caseless enum | ~12 | Low | Change `struct` to `enum` |

## Bugs Requiring Careful Fix

| Bug | Effort | Risk |
|-----|--------|------|
| C1: `preconditionFailure` crash | Low | High — production crash |
| C3: Google Pay → Apple icon | Low | High — visible UI bug |
| C5: Analytics encoding (duplicate sdkSettings) | Low | Medium — analytics gap |
| C6: selectCardNetwork race | Medium | High — surcharge incorrect |
| C7: Color array bounds crash | Low | Medium — crash on bad data |
| H4: WebRedirect `try?` swallowing | Low | High — payment fails silently |
| H29-32: Duplicate localization keys | Low | Medium — wrong translations |
