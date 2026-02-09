# Research: Bank Selector Scope for CheckoutComponents

**Feature Branch**: `003-bank-selector`
**Date**: 2026-02-09

## R1: CheckoutComponents Payment Method Registration Pattern

**Decision**: Follow the existing `PaymentMethodProtocol` + `PaymentMethodRegistry` pattern used by Card, PayPal, ApplePay, and Klarna.

**Rationale**: The registry pattern is already established and provides dynamic view resolution without modifying core navigation code. `PaymentMethodScreen` in `CheckoutScopeObserver` uses `PaymentMethodRegistry.shared.getView(for:checkoutScope:)` to render any registered payment method.

**Alternatives considered**:
- Custom routing in `CheckoutScopeObserver` — rejected because it requires modifying shared code and breaks the registry pattern
- Subclassing existing scopes — rejected because bank selector has a fundamentally different flow (fetch → select → redirect) than card (fill form → submit)

**Key findings**:
- `PaymentMethodProtocol` requires: `paymentMethodType`, `createScope()`, `createView()`, `register()`
- Registration happens in `DefaultCheckoutScope.registerPaymentMethods()`
- DI dependencies registered in `ComposableContainer.registerDomain()` and `registerData()`
- `createScope()` resolves dependencies via `diContainer.resolveSync()`

## R2: Bank List API Reuse Strategy

**Decision**: Create a `BankSelectorRepository` that wraps the existing `PrimerAPIClientBanksProtocol.listAdyenBanks()` and `TokenizationService.tokenize()` APIs.

**Rationale**: The existing API infrastructure is well-tested and handles auth tokens, error mapping, and network configuration. Creating a repository wrapper follows the CheckoutComponents pattern (HeadlessRepository, PayPalRepository, KlarnaRepository) while keeping the scope layer decoupled from core SDK internals.

**Alternatives considered**:
- Directly calling `PrimerAPIClient` from the interactor — rejected because it breaks the repository abstraction pattern and makes unit testing harder
- Reusing `BankSelectorTokenizationProviding` protocol directly — rejected because it couples to Drop-In/Headless ViewModel patterns (`PaymentMethodTokenizationViewModel` inheritance) which is incompatible with CheckoutComponents scope architecture
- Using `BanksTokenizationComponent` (standalone) — rejected for same coupling reasons

**Key findings**:
- `listAdyenBanks()` takes `DecodedJWTToken` + `Request.Body.Adyen.BanksList`
- Payment method type mapping: `ADYEN_IDEAL` → `"ideal"`, `ADYEN_DOTPAY` → `"dotpay"`
- Config ID comes from `PrimerPaymentMethod.id` (available from API configuration)
- Response: `BanksListSessionResponse.result: [AdyenBank]` with `id`, `name`, `iconUrlStr`, `disabled`
- Tokenization uses `OffSessionPaymentInstrument` with `BankSelectorSessionInfo(issuer: bankId)`

## R3: State Management Pattern

**Decision**: Use `@Published` internal state + `AsyncStream` exposure, following the PayPal scope pattern. State limited to loading/ready/selected per clarification.

**Rationale**: PayPal scope provides the closest architectural match — a simple state model without complex form fields. Bank selector adds bank list management and search but follows the same lifecycle.

**Alternatives considered**:
- `StructuredCardFormState` pattern (subscript-based field access) — rejected because bank selector doesn't have input fields
- Combine-based state — rejected because CheckoutComponents explicitly avoids Combine dependencies

**Key findings**:
- `@Published private var internalState` drives the `AsyncStream`
- State struct conforms to `Equatable`
- Status enum covers scope-specific phases only; checkout scope handles processing/success/failure
- `checkoutScope?.handlePaymentSuccess(result)` and `checkoutScope?.handlePaymentError(error)` bridge to checkout-level navigation

## R4: Default UI Screen Pattern

**Decision**: Create a `BankSelectorScreen` SwiftUI view following the PayPal/Card screen pattern with search bar, scrollable bank list, and customization hooks.

**Rationale**: All payment method screens follow a consistent pattern: header (back/cancel) → content → `.onAppear { observeState() }`. The bank selector screen is closest to a list-based UI with search filtering.

**Key findings**:
- Screens receive the scope as an init parameter
- State observed via `for await state in scope.state` in a Task
- Screen-level customization: `scope.screen` replaces entire screen with closure
- Component-level customization via typealias closures (e.g., `BankSelectorScreenComponent`, `BankItemComponent`)
- `PresentationContext` determines back vs cancel button
- `DismissalMechanism` controls close button visibility

## R5: Interactor and Repository Layer Design

**Decision**: Create `ProcessBankSelectorPaymentInteractor` (protocol + impl) and `BankSelectorRepository` (protocol + impl) following the PayPal interactor/repository pattern.

**Rationale**: Clean architecture separation allows unit testing of business logic (interactor) independently from API/SDK calls (repository). This matches the established pattern in CheckoutComponents.

**Key findings**:
- Interactor handles orchestration: fetch banks → filter → tokenize with selected bank
- Repository handles data access: wraps `PrimerAPIClient` for bank list + `TokenizationService` for tokenization
- Both registered as `.asTransient()` in DI container to avoid stale state
- Interactor resolved in `createScope()` via `diContainer.resolveSync()`

## R6: Multi-Payment-Method Registration

**Decision**: Register ADYEN_IDEAL and ADYEN_DOTPAY as separate `BankSelectorPaymentMethod` instances sharing the same scope type.

**Rationale**: The `PaymentMethodRegistry` uses `paymentMethodType` string as the key. Each APM needs its own registration entry to appear correctly in payment method selection. However, both share the same `DefaultBankSelectorScope` type and UI.

**Alternatives considered**:
- Single registration covering both types — rejected because the registry requires unique type keys for each APM
- Bulk registration method like `BankSelectorPaymentMethod.registerAll()` — this is the approach; a static helper registers each supported type

**Key findings**:
- `CardPaymentMethod.paymentMethodType` is a single string (`"PAYMENT_CARD"`)
- For bank selector, we need one entry per supported APM type
- The `createScope()` can receive the payment method type and pass it to the interactor for correct API mapping

## R7: Accessibility Patterns in CheckoutComponents

**Decision**: Follow the existing `AccessibilityIdentifiers` enum + `AccessibilityConfiguration` + `.accessibility(config:)` View extension pattern.

**Rationale**: All CC screens use this established pattern. Bank selector should be consistent.

**Key findings**:
- Identifiers defined in `AccessibilityIdentifiers.swift` as nested enums: `checkout_components_{screen}_{component}_{element}` (snake_case for Android parity)
- Applied via `.accessibility(config: AccessibilityConfiguration(identifier:label:hint:traits:))` View extension
- `AccessibilityConfiguration` supports: identifier, label, hint, value, traits, isHidden, sortPriority
- VoiceOver labels/hints come from `CheckoutComponentsStrings` with `a11y_` prefix
- Existing screen examples: CardForm (container, fields, submit button), PayPal (container, submit), Klarna (container, category buttons)

**Bank selector needs**:
- `AccessibilityIdentifiers.BankSelector` enum: container, searchBar, bankItem (dynamic with bank ID), loadingIndicator, emptyState, backButton, cancelButton
- VoiceOver labels for bank items should include bank name and disabled status

## R8: Translation Patterns in CheckoutComponents

**Decision**: Add bank selector strings to `CheckoutComponentsStrings.swift` using the established `NSLocalizedString` pattern.

**Rationale**: All CC UI text is centralized in `CheckoutComponentsStrings` with `tableName: "CheckoutComponentsStrings"` and `bundle: Bundle.primerResources`. Supports 41 languages.

**Key findings**:
- Strings use underscore_case keys: `primer_{feature}_{element}` for UI, `accessibility_{feature}_{element}` for VoiceOver
- All strings require entries in `.strings` files for localization
- Dynamic strings use `String(format:)` with `%@` placeholders
- English serves as base language with `value:` parameter as fallback

**Bank selector strings needed**:
- `primer_bank_selector_title` — "Choose your bank"
- `primer_bank_selector_search_placeholder` — "Search banks"
- `primer_bank_selector_empty_state` — "No banks found"
- `primer_bank_selector_bank_unavailable` — "Unavailable"
- `accessibility_bank_selector_search_label` — "Search banks"
- `accessibility_bank_selector_search_hint` — "Enter bank name to filter the list"
- `accessibility_bank_selector_bank_item_hint` — "Double-tap to select this bank"
- `accessibility_bank_selector_bank_item_disabled` — "%@ bank, unavailable"
- `accessibility_bank_selector_loading` — "Loading banks, please wait"
- `accessibility_bank_selector_empty_state` — "No banks match your search"

## R9: Analytics Event Patterns in CheckoutComponents

**Decision**: Reuse existing `AnalyticsEventType` cases via `CheckoutComponentsAnalyticsInteractorProtocol`. No new event types needed.

**Rationale**: The existing event types (`paymentMethodSelection`, `paymentSubmitted`, `paymentRedirectToThirdParty`) cover all bank selector user actions. Adding bank-selector-specific events would break cross-platform parity.

**Key findings**:
- Events tracked via `analyticsInteractor?.trackEvent(.eventType, metadata: .payment(...))` — fire-and-forget
- `AnalyticsEventMetadata.payment(PaymentEvent(paymentMethod:paymentId:))` carries the payment method type
- Events already defined that bank selector should use:
  - `paymentMethodSelection` — when bank selector screen appears
  - `paymentSubmitted` — when a bank is tapped (equivalent to user completing their selection)
  - `paymentRedirectToThirdParty` — when web redirect begins
- Tracked in scope, not in screen — follows existing pattern where scopes own analytics

## R10: CheckoutComponents Test Patterns

**Decision**: Create minimum high-value test suite following the Klarna/ApplePay/PayPal test patterns: interactor tests, scope tests, state tests.

**Rationale**: These three test layers cover the most critical business logic. Repository tests are valuable but lower priority since the repository is a thin wrapper.

**Key findings**:
- Test directory: `Tests/Primer/CheckoutComponents/`
- Mock pattern: configurable `Result` properties + call tracking (`callCount`, captured args) + optional closures for complex behavior
- Scope tests use `@MainActor`, `Task.sleep` for async coordination
- State tests validate default init, equality, factory methods
- Interactor tests validate orchestration, error propagation, data mapping
- Shared test utilities in `TestSupport/` (TestData.swift, ContainerTestHelpers.swift)

**Minimum test set for bank selector** (~20 tests):
1. `ProcessBankSelectorPaymentInteractorTests` — fetchBanks mapping (AdyenBank→Bank), execute delegation, error propagation
2. `DefaultBankSelectorScopeTests` — state transitions (loading→ready→selected), search filtering (case/diacritics), disabled bank rejection, error delegation, empty bank list handling
3. `BankSelectorStateTests` — default initialization, status enum equality, property verification

## R11: Empty Bank List Handling in Drop-In

**Decision**: CheckoutComponents should explicitly handle empty bank lists, improving on the Drop-In behavior.

**Rationale**: Drop-In has no explicit empty state handling — it shows a broken minimal UI (120pt height, no rows, no message). Headless is better, using `PrimerValidationError.banksNotLoaded()`. CheckoutComponents should show a proper empty state view.

**Key findings**:
- Drop-In `BankSelectorViewController` calculates height as `120 + (banks.count * rowHeight)` — empty = tiny broken UI
- Drop-In `BankSelectorTokenizationViewModel.fetchBanks()` returns empty array without validation
- Headless `DefaultBanksComponent` has explicit `.banksNotLoaded()` error for empty banks
- `PrimerValidationError.banksNotLoaded(diagnosticsId:)` exists with message "Banks need to be loaded before bank id can be collected."
- For CC: show empty state view when `status == .ready && banks.isEmpty` — same visual as search empty state but with different message
