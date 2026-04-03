# CheckoutComponents PR Review — Final Consolidated Report (v1+v2+v3)

**Date:** 2026-04-02
**Method:** 3 review rounds: v1 (8 per-PR agents), v2 (8 per-PR agents, different prompts), v3 (18 specialist agents — thread safety, API surface, test quality, breaking changes, encoding, error handling, protocol design, state management, continuation safety, data flow, DI consistency, repository correctness, scope lifecycle, container wiring, code duplication, accessibility). Only findings confirmed across multiple rounds or high-confidence specialist finds included.
**Total agents used:** 34

---

## Executive Summary

| Severity | Count | Top Themes |
|----------|-------|------------|
| **CRITICAL** | 12 | Crashes, data races, accessibility barriers, dead test coverage |
| **HIGH** | 45+ | Public API leak, breaking change risk, DI inconsistencies, continuation hangs |
| **MEDIUM** | 60+ | Code duplication, style violations, missing annotations |
| **LOW** | 30+ | Minor style, naming, optimization |

---

## CRITICAL FINDINGS (12)

### C1. `preconditionFailure()` crash in PrimerDelegate [PR 03]
**File:** `PrimerDelegate.swift:382`
**Confirmed:** v1, v2, v3-errors, v3-breaking (5x)
Async `primerDidFailWithError` crashes when `sdkIntegrationType == .checkoutComponents`. Only `.headless` and `.dropIn` handled. Currently masked by RawDataManager overwriting to `.headless`, but any code path before RawDataManager init or after teardown hits this.

### C2. RetentionPolicyTests test shadow mock — zero real coverage [PR 02]
**File:** `RetentionPolicyTests.swift:284-344`
**Confirmed:** v1, v2, v3-tests (3x)
File defines its own `DIContainer` class that shadows the real one. All 11 tests exercise this mock, not the production `Container`/`RetentionStrategy`/`SingletonStrategy`.

### C3. Google Pay maps to Apple icon [PR 10]
**File:** `PrimerPaymentMethodType+ImageName.swift:20`
**Confirmed:** v1, v2, v3 (3x)
`case .googlePay: .appleIcon` — shows Apple icon for Google Pay.

### C4. `resolveBatch` false circular dependency detection [PR 02]
**File:** `Container.swift:315-333`
**Confirmed:** v1, v2, v3-threads (3x)
`resolutionStack` is per-actor global state but should be per-call-chain. Actor reentrancy during `buildAsync` suspension causes interleaved resolves to see each other's keys and throw false `circularDependency` errors. Fix: use `TaskLocal` or pass stack as parameter.

### C5. `resolveSync` cooperative thread pool deadlock [PR 02]
**File:** `Container.swift:268-312`
**Confirmed:** v3-threads (specialist deep analysis)
`DispatchSemaphore.wait()` blocks the calling thread. `Task.detached` may not find a free cooperative thread. 0.5s timeout converts legitimate resolution into spurious failure.

### C6. `PrimerCardFormState` Equatable broken by NSObject reference types [PR 06]
**File:** `PrimerCardFormState.swift:192`
**Confirmed:** v3-states (specialist find)
Auto-synthesized `Equatable` uses `NSObject` identity for `PrimerCardNetwork` and `PrimerBinData` (which don't override `isEqual:`). Every state mutation appears "changed" → spurious AsyncStream emissions → unnecessary SwiftUI re-renders.

### C7. KVC crash in `extractRedirectURL` [PR 11]
**File:** `HeadlessRepositoryImpl.swift:790-794`
**Confirmed:** v3-dataflow (specialist find)
`NSObject.value(forKey:)` raises `NSUnknownKeyException` (fatal crash) when subclass doesn't have the property. On analytics path — non-essential telemetry crashing the app.

### C8. `PaymentCompletionHandler` not retained during card payment [PR 11]
**File:** `HeadlessRepositoryImpl.swift:423-426`
**Confirmed:** v3-continuations, v3-dataflow (2x)
Handler held only by weak delegates. After `submit()` returns, ARC may dealloc handler → continuation never resumes → app hangs. Vault path correctly retains via `self.vaultPaymentCompletionHandler`.

### C9. `processCardPayment` has no timeout [PR 11]
**File:** `HeadlessRepositoryImpl.swift:410-445`
**Confirmed:** v3-continuations, v3-dataflow (2x)
Unlike `processVaultedPayment` (60s timeout), card payment has none. If delegate callbacks never fire, continuation hangs forever.

### C10. Card input fields block VoiceOver text entry [PR 14]
**File:** `CardNumberInputField.swift:126-134`, `CVVInputField.swift:74-82`, `ExpiryDateInputField.swift:74-82`
**Confirmed:** v3-a11y (specialist find)
`combinesChildren: true` (default) hides inner `SecureTextField`/`UITextField` from VoiceOver. Missing `.isTextField` trait. NameInput/EmailInput correctly use `combinesChildren: false`.

### C11. Color array bounds crash in DesignTokens [PR 07]
**File:** `DesignTokens.swift:255+`
**Confirmed:** v1, v2, v3 (3x)
Array indices `[0]-[3]` accessed without bounds check. Malformed JSON crashes.

### C12. `sdkIntegrationType` overwritten by RawDataManager to `.headless` [PR 03]
**File:** `RawDataManager.swift:121`
**Confirmed:** v3-errors (specialist find)
CC sets `.checkoutComponents` but RawDataManager immediately overwrites to `.headless`. The `.checkoutComponents` branch in `primerWillCreatePaymentWithData` is dead code. Analytics report "HEADLESS" during CC payment flows.

---

## HIGH FINDINGS — Top 25

### API Surface & Breaking Changes

| # | PR | Finding |
|---|-----|---------|
| H1 | 02,04,05,06,08,13 | **~60+ `public` types in `Internal/` directories.** Full inventory in v3-api agent. Bulk fix: remove `public`. |
| H2 | 06 | **`PaymentMethodProtocol` public, exposes `ContainerProtocol` (DI internals) to merchants.** |
| H3 | 06 | **8 public enums** (`PrimerCheckoutState`, `PaymentStatus`, 6 `Step`/`Status` enums) without `@unknown default` guidance. Adding cases is source-breaking for merchants. |
| H4 | 06 | **`PrimerCardFormScope` re-declares lifecycle methods from parent** (only child that does). All 8 children redundantly re-declare `var state`. |
| H5 | 03 | **`DismissalMechanism` Codable encodes as `{"gestures":{}}` not `"gestures"`.** Backend may not expect this format. |
| H6 | 03 | **`dismissalMechanism` decoded with `decode` not `decodeIfPresent`.** Will throw on missing key from older SDK data. |

### Continuation & Concurrency

| # | PR | Finding |
|---|-----|---------|
| H7 | 11 | **Vault timeout Task (60s) never cancelled on success.** Resource leak. |
| H8 | 11 | **Empty `catch` blocks silently swallow DI errors** in `injectSettings`/`injectConfigurationService`. |
| H9 | 02 | **Singleton double-factory execution.** TOCTOU race: two concurrent resolves both execute factory, discarded instance may hold resources. |
| H10 | 02 | **`ContainerRegistrationBuilderImpl` `@unchecked Sendable` with unsynchronized mutable state.** |
| H11 | 08 | **Missing `Sendable`** on `AnalyticsEventMetadata`, `AnalyticsPayload`, `AnalyticsSessionConfig` crossing actor boundaries. |
| H12 | 03 | **Callback `primerDidFailWithError` silently drops CC errors** → `raisePrimerDidFailWithError` continuation hangs forever. |

### DI & Architecture

| # | PR | Finding |
|---|-----|---------|
| H13 | 12 | **QRCode directly instantiates interactor, bypassing DI.** Only payment method that does this. |
| H14 | 12 | **WebRedirect resolves repository with `try?`** — nil silently passed to scope. Payment will fail. |
| H15 | 12 | **Klarna/ACH use legacy `DependencyContainer.resolve()`** instead of `ComposableContainer`. Different settings instance. |
| H16 | 12 | **5 repositories access `PrimerSettings.current` directly** bypassing DI. |
| H17 | 13 | **`GetPaymentMethodsInteractor` registered but never resolved** — dead wiring. Bridge used instead. |
| H18 | 13 | **`HeadlessRepository` transient creates multiple instances per session.** Should be singleton. |
| H19 | 13 | **8 of 32 container registrations (25%) are dead code** — never resolved. |

### Scope & Lifecycle

| # | PR | Finding |
|---|-----|---------|
| H20 | 13 | **500ms `Task.sleep` NOT guarded by `isInitScreenEnabled`** — always executes. |
| H21 | 13 | **No state machine guard** — terminal `.dismissed` can be overwritten by `.failure`. |
| H22 | 14 | **4 locations downcast to `DefaultCheckoutScope`/`DefaultPaymentMethodSelectionScope`** breaking scope abstraction. |

### Analytics & Encoding

| # | PR | Finding |
|---|-----|---------|
| H23 | 03 | **`sdkIntegrationType` never encoded** in `SDKProperties.encode(to:)`. `sdkSettings` encoded twice. |
| H24 | 09 | **4 duplicate localization keys** — cvv, otp, pay amount, cardholder name. Different defaults, same key. |
| H25 | 03 | **`PrimerCheckoutPresenter` error routing broken** — error goes through `PrimerDelegateProxy` which silently swallows for CC. |

---

## MEDIUM FINDINGS — Top 20

| # | PRs | Finding |
|---|-----|---------|
| M1 | ALL | **Emoji in ~25 log locations.** Grep `[✅⚠️📊🌉⏭️]` in .swift. |
| M2 | ALL | **~15 classes missing `final`.** |
| M3 | 07+ | **~12 namespace structs should be caseless enums.** |
| M4 | 14 | **CardFormScreen vs CardFormFieldsView** — 160+ lines of `renderField` duplicated + 3 identical helpers (56 lines). |
| M5 | 14 | **Header section duplicated across 6 screens** despite `CheckoutHeaderView` existing. |
| M6 | 14 | **Submit button pattern duplicated across 5 screens.** |
| M7 | 10,11 | **130 lines of surcharge extraction duplicated** between Bridge and HeadlessRepository. |
| M8 | 12 | **Scope creation boilerplate duplicated 8x** (~16 lines each). |
| M9 | 12 | **ErrorHandler.handle missing in 4/6 repositories** (Klarna, ACH, PayPal, QRCode). |
| M10 | 12 | **Klarna/ACH/PayPal hardcode `.success`** instead of checking API response status. |
| M11 | 12 | **UUID fallback payment IDs** in Klarna, ACH, PayPal mask server errors. |
| M12 | 12 | **WebRedirect hardcoded `"WEB_REDIRECT"`** in payment service — wrong error messages for Twint/iDEAL. |
| M13 | 12 | **ACH uses `invalidClientToken` error** for non-token failures (semantic misuse). |
| M14 | 06 | **`FieldError.id = UUID()`** — SwiftUI destroys/recreates rows on every update. `PrimerCountry` same. |
| M15 | 06 | **Theme structs not `Equatable`** — SwiftUI can't skip re-renders. |
| M16 | 06 | **`fontWeight` CGFloat vs Font.Weight** inconsistency between `PrimerFieldStyling` and theme. |
| M17 | 14 | **VaultedCardCVVInput uses plain `TextField`** not `SecureField` for CVV. |
| M18 | 14 | **Hardcoded English "Done" button** on keyboard accessory. Not localized. |
| M19 | 14 | **Delete button 36x36pt** — below 44pt minimum tap target. |
| M20 | 14 | **Missing `@FocusState`** on billing address fields — no keyboard tab navigation. |

---

## Files Reference

All review artifacts preserved:
- `pr-review-findings-v1.md` — Round 1 (8 agents, per-PR)
- `pr-review-findings-v2.md` — Round 2 cross-checked (8 agents, per-PR)
- `pr-review-findings.md` — This file (final consolidated, all 3 rounds)

V3 specialist agent outputs available in `/private/tmp/claude-501/.../tasks/` (18 files).
