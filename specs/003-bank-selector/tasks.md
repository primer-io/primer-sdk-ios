# Tasks: Bank Selector Scope for CheckoutComponents

**Input**: Design documents from `/specs/003-bank-selector/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Minimum high-value test suite included (Phase 9) covering interactor, scope, and state model.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create file structure and public models shared across all user stories

- [x] T001 [P] Create `Bank` public model with `id`, `name`, `iconUrl`, `isDisabled` properties and mapping initializer from `AdyenBank` in `Sources/PrimerSDK/Classes/CheckoutComponents/PaymentMethods/BankSelector/Bank.swift`
- [x] T002 [P] Create `BankSelectorState` public state model with `Status` enum (`.loading`, `.ready`, `.selected(Bank)`), `banks`, `filteredBanks`, `selectedBank`, and `searchQuery` properties in `Sources/PrimerSDK/Classes/CheckoutComponents/PaymentMethods/BankSelector/BankSelectorState.swift`
- [x] T003 [P] Create `PrimerBankSelectorScope` public protocol extending `PrimerPaymentMethodScope` with `State == BankSelectorState`, adding `search(query:)`, `selectBank(_:)`, `onCancel()`, `presentationContext`, `dismissalMechanism`, and customization properties (`screen`, `bankItemComponent`, `searchBarComponent`, `emptyStateComponent`) in `Sources/PrimerSDK/Classes/CheckoutComponents/Scope/PrimerBankSelectorScope.swift`
- [x] T004 [P] Add `BankSelectorScreenComponent` and `BankItemComponent` type aliases to `Sources/PrimerSDK/Classes/CheckoutComponents/Scope/ComponentTypeAliases.swift` — note: `searchBarComponent` and `emptyStateComponent` use the existing `Component` typealias (`() -> any View`) already defined in this file
- [x] T005 [P] Add bank selector localized strings to `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Constants/CheckoutComponentsStrings.swift` — screen title (`primer_bank_selector_title`: "Choose your bank"), search placeholder (`primer_bank_selector_search_placeholder`: "Search banks"), empty state (`primer_bank_selector_empty_state`: "No banks found"), no banks available (`primer_bank_selector_no_banks_available`: "No banks available"), bank unavailable (`primer_bank_selector_bank_unavailable`: "Unavailable"), plus accessibility strings with `accessibility_bank_selector_` prefix (search label/hint, bank item hint, disabled bank label, loading announcement, empty state announcement). Add corresponding entries to English `CheckoutComponentsStrings.strings` resource file.
- [x] T006 [P] Add `BankSelector` enum to `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Accessibility/Domain/AccessibilityIdentifiers.swift` with identifiers: `container` (`checkout_components_bank_selector_container`), `searchBar` (`checkout_components_bank_selector_search_bar`), `bankItem(_:)` dynamic with bank ID (`checkout_components_bank_selector_{bankId}_item`), `loadingIndicator` (`checkout_components_bank_selector_loading`), `emptyState` (`checkout_components_bank_selector_empty_state`), `backButton` and `cancelButton` (reuse `AccessibilityIdentifiers.Common` if available)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Repository, interactor, and DI registration that MUST be complete before any user story can be implemented

**CRITICAL**: No user story work can begin until this phase is complete

- [x] T007 Create `BankSelectorRepository` protocol with `listBanks(paymentMethodType:)` and `tokenizeAndProcess(bankId:paymentMethodType:)` methods, plus `BankSelectorRepositoryImpl` wrapping `PrimerAPIClient.listAdyenBanks()` and existing tokenization/redirect/polling infrastructure — include payment method type mapping (`ADYEN_IDEAL` → `"ideal"`, `ADYEN_DOTPAY` → `"dotpay"`) in the repository implementation — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Domain/Repositories/BankSelectorRepository.swift`
- [x] T008 Create `ProcessBankSelectorPaymentInteractor` protocol with `fetchBanks(paymentMethodType:)` and `execute(bankId:paymentMethodType:)` methods, plus `ProcessBankSelectorPaymentInteractorImpl` that uses `BankSelectorRepository` and maps `AdyenBank` to `Bank` in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Domain/Interactors/ProcessBankSelectorPaymentInteractor.swift`
- [x] T009 Register `BankSelectorRepository` (`.asTransient()`) in `registerData()` and `ProcessBankSelectorPaymentInteractor` (`.asTransient()`) in `registerDomain()` in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/DI/ComposableContainer.swift`

**Checkpoint**: Foundation ready — domain layer complete, DI configured, user story implementation can begin

---

## Phase 3: User Story 1 — Select a Bank and Complete Payment (Priority: P1) MVP

**Goal**: End-to-end bank selection and payment flow: fetch banks → display list → select bank → tokenize → redirect → poll → success/failure

**Independent Test**: Configure a client session with ADYEN_IDEAL, launch CheckoutComponents, select a bank, verify redirect and payment completion

### Implementation for User Story 1

- [x] T010 [US1] Create `DefaultBankSelectorScope` implementing `PrimerBankSelectorScope` and `ObservableObject` with: `@Published internalState`, `AsyncStream<BankSelectorState>` via `$internalState.values`, `start()` that calls interactor `fetchBanks()` and transitions state from `.loading` to `.ready`, `selectBank(_:)` that sets `.selected`, calls `checkoutScope.startProcessing()`, then calls interactor `execute()` with `handlePaymentSuccess`/`handlePaymentError`, `cancel()`/`onBack()` navigation via `checkoutScope`, and `presentationContext`/`dismissalMechanism` delegation. Include `analyticsInteractor` dependency (resolved from DI) for event tracking. — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultBankSelectorScope.swift`
- [x] T011 [US1] Create `BankSelectorPaymentMethod` struct conforming to `PaymentMethodProtocol` with `createScope()` that resolves `ProcessBankSelectorPaymentInteractor` from DI and creates `DefaultBankSelectorScope`, `createView()` that returns `BankSelectorScreen`, and `registerAll()` static method that registers both `ADYEN_IDEAL` and `ADYEN_DOTPAY` in `PaymentMethodRegistry` in `Sources/PrimerSDK/Classes/CheckoutComponents/PaymentMethods/BankSelector/BankSelectorPaymentMethod.swift`
- [x] T012 [US1] Add `BankSelectorPaymentMethod.registerAll()` call to `registerPaymentMethods()` in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultCheckoutScope.swift`
- [x] T013 [US1] Create `BankSelectorScreen` SwiftUI view that receives `any PrimerBankSelectorScope`, observes state via `for await state in scope.state` in `.onAppear`, renders header (title from `CheckoutComponentsStrings.bankSelectorTitle`), scrollable list of bank rows (name + async icon + disabled indicator), loading state, and handles bank tap via `scope.selectBank(_:)` — use localized strings from T005 for all user-facing text — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift`

**Checkpoint**: At this point, iDEAL and Dotpay should appear in payment method selection, tapping shows bank list, selecting a bank triggers the full payment flow

---

## Phase 4: User Story 2 — Search and Filter Banks (Priority: P1)

**Goal**: Real-time search filtering of the bank list with case-insensitive and diacritics-insensitive matching

**Independent Test**: Display bank list, type partial names, verify real-time filtering and empty state

### Implementation for User Story 2

- [x] T014 [US2] Add `search(query:)` implementation to `DefaultBankSelectorScope` that updates `internalState.searchQuery` and `internalState.filteredBanks` using case-insensitive, diacritics-insensitive substring matching (`.lowercased().folding(options: .diacriticInsensitive, locale: nil)`) on bank names, restoring full list when query is empty — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultBankSelectorScope.swift`
- [x] T015 [US2] Add search bar to `BankSelectorScreen` at the top of the bank list, binding text input to `scope.search(query:)` on change, and add empty state view when `filteredBanks` is empty and `searchQuery` is not empty — use localized strings for search placeholder and empty state message — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift`

**Checkpoint**: Bank list is searchable with real-time filtering, empty state shows when no results match

---

## Phase 5: User Story 3 — Merchant UI Customization (Priority: P2)

**Goal**: Merchants can customize the bank selector appearance via scope-level component properties

**Independent Test**: Pass customization closures through scope API, verify custom rendering

### Implementation for User Story 3

- [x] T016 [US3] Add customization property support to `BankSelectorScreen`: check `scope.screen` for full screen replacement, check `scope.bankItemComponent` for custom bank row rendering, check `scope.searchBarComponent` for custom search bar, check `scope.emptyStateComponent` for custom empty state — fall back to default views when nil — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift`
- [x] T017 [US3] Update `BankSelectorPaymentMethod.createView()` to check for `scope.screen` custom screen component before returning default `BankSelectorScreen` in `Sources/PrimerSDK/Classes/CheckoutComponents/PaymentMethods/BankSelector/BankSelectorPaymentMethod.swift`

**Checkpoint**: Merchants can replace the full screen, individual bank items, search bar, and empty state with custom views

---

## Phase 6: User Story 4 — Navigate Back or Cancel (Priority: P2)

**Goal**: Proper back/cancel navigation based on presentation context (multi-method vs single-method checkout)

**Independent Test**: Present bank selector in both direct and fromPaymentSelection contexts, verify back/cancel behavior

### Implementation for User Story 4

- [x] T018 [US4] Add header section to `BankSelectorScreen` with back button (when `scope.presentationContext == .fromPaymentSelection`) calling `scope.onBack()`, and cancel/close button (when `scope.dismissalMechanism.contains(.closeButton)`) calling `scope.onCancel()` — following the same pattern as `CardFormScreen` and `PayPalView` headers — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift`

**Checkpoint**: Back button returns to payment method selection; cancel button dismisses checkout; no state leaked on navigation

---

## Phase 7: User Story 5 — Observe Bank Selector State (Priority: P2)

**Goal**: Merchants can observe the full bank selector state via AsyncStream for building custom UIs

**Independent Test**: Subscribe to state stream, verify transitions: loading → ready (with banks) → selected

### Implementation for User Story 5

- [x] T019 [US5] Verify `DefaultBankSelectorScope.state` AsyncStream correctly yields all state transitions by reviewing that `@Published internalState` mutations in `start()`, `search()`, and `selectBank()` are all captured by the `$internalState.values` stream — add `submit()` implementation that calls `selectBank()` if a bank is selected (for protocol conformance) — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultBankSelectorScope.swift`

**Checkpoint**: State stream is complete and observable — merchants can build fully custom UIs by subscribing to the stream

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Edge cases, disabled bank handling, accessibility, analytics, and final validation

- [x] T020 [P] Add disabled bank visual treatment to `BankSelectorScreen` — dimmed appearance and non-interactive for banks where `isDisabled == true` — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift`
- [x] T021 [P] Add disabled bank selection guard to `DefaultBankSelectorScope.selectBank(_:)` — reject selection if `bank.isDisabled` is true — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultBankSelectorScope.swift`
- [x] T022 [P] Add error handling in `DefaultBankSelectorScope.start()` — catch bank list fetch errors and delegate to `checkoutScope?.handlePaymentError()` for standard ErrorScreen display — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultBankSelectorScope.swift`
- [x] T023 Add loading state view to `BankSelectorScreen` — show loading indicator when `state.status == .loading` — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift`
- [x] T024 Add empty bank list handling — when `start()` receives zero banks from API (success but empty array), show a dedicated "no banks available" empty state (using localized string from T005) rather than a broken minimal UI. This is different from the search empty state (no matching banks) — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultBankSelectorScope.swift` (state transition) and `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift` (UI)
- [x] T025 Add analytics event tracking to `DefaultBankSelectorScope` — track `.paymentMethodSelection` with `.payment(PaymentEvent(paymentMethod: paymentMethodType))` metadata when bank selector screen appears (in `start()`), track `.paymentSubmitted` when a bank is selected (in `selectBank(_:)`), track `.paymentRedirectToThirdParty` when web redirect begins (in `selectBank(_:)` after tokenization, or delegate to repository/checkout scope if redirect tracking is handled there) — following the fire-and-forget pattern via `analyticsInteractor?.trackEvent()` — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/DefaultBankSelectorScope.swift`
- [x] T026 Apply accessibility identifiers and VoiceOver configuration to `BankSelectorScreen` — annotate all interactive elements with `.accessibility(config: AccessibilityConfiguration(...))` using identifiers from T006 and labels/hints from T005: search bar (label + hint), bank items (label with bank name + disabled status, hint for tap action), loading indicator (label announcing loading state), empty state (label announcing no results), back/cancel buttons (reuse common accessibility patterns from CardFormScreen/KlarnaView) — in `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Screens/BankSelectorScreen.swift`
- [ ] T027 Verify end-to-end flow with ADYEN_IDEAL and ADYEN_DOTPAY in Debug App — configure client session with both payment methods, test bank selection, search, navigation, payment completion, VoiceOver navigation, and analytics event capture

---

## Phase 9: Tests (Minimum High-Value Coverage)

**Purpose**: Ensure critical business logic has test coverage — interactor mapping, scope state transitions, and state model integrity

- [ ] T028 [P] Create `MockProcessBankSelectorPaymentInteractor` with configurable `Result` properties for `fetchBanks` and `execute`, call tracking (`fetchBanksCallCount`, `executeCallCount`, captured arguments), and optional closure overrides for complex behavior — following the `MockProcessKlarnaPaymentInteractor` pattern — in `Tests/Primer/CheckoutComponents/BankSelector/Mocks/MockProcessBankSelectorPaymentInteractor.swift`
- [ ] T029 [P] Create `BankSelectorStateTests` — test default initialization (status `.loading`, empty banks, empty searchQuery), custom initialization with all parameters, `Status` enum equality (`.loading == .loading`, `.selected(bankA) != .selected(bankB)`), and `BankSelectorState` Equatable conformance — in `Tests/Primer/CheckoutComponents/BankSelector/BankSelectorStateTests.swift`
- [ ] T030 Create `ProcessBankSelectorPaymentInteractorTests` — test `fetchBanks()` correctly maps `[AdyenBank]` → `[Bank]` (name, id, iconUrl, isDisabled fields), test `execute()` delegates bankId and paymentMethodType to repository, test error propagation from repository throws through interactor — using a `MockBankSelectorRepository` — in `Tests/Primer/CheckoutComponents/BankSelector/ProcessBankSelectorPaymentInteractorTests.swift`
- [ ] T031 Create `DefaultBankSelectorScopeTests` — test state transitions: `start()` transitions `.loading` → `.ready` with banks; `selectBank()` transitions to `.selected(bank)`; `search(query:)` filters banks case-insensitively and diacritics-insensitively; `search(query: "")` restores full list; `selectBank()` with disabled bank is rejected; `start()` with fetch error delegates to `handlePaymentError()`; `start()` with empty bank list sets `.ready` with empty banks — using `MockProcessBankSelectorPaymentInteractor` from T028 — in `Tests/Primer/CheckoutComponents/BankSelector/DefaultBankSelectorScopeTests.swift`

**Checkpoint**: Core business logic has test coverage — interactor mapping verified, scope state machine tested, disabled bank guard confirmed, error delegation validated

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — all 6 tasks can run in parallel
- **Foundational (Phase 2)**: Depends on Phase 1 (T001 Bank model needed by T007/T008)
- **User Stories (Phase 3+)**: All depend on Phase 2 completion
  - US1 (Phase 3): Core flow — no dependency on other stories
  - US2 (Phase 4): Builds on US1 screen and scope — depends on Phase 3
  - US3 (Phase 5): Adds customization to US1+US2 screen — depends on Phase 4
  - US4 (Phase 6): Adds navigation to screen — can run after Phase 3 (parallel with US2/US3)
  - US5 (Phase 7): Verification of state stream — can run after Phase 3
- **Polish (Phase 8)**: Depends on all user stories being complete. T025 (analytics) and T026 (accessibility) need T005 (strings) and T006 (identifiers) from Phase 1.
- **Tests (Phase 9)**: Depends on Phase 2 (interactor tests) and Phase 8 (scope tests need final scope implementation). T028/T029 can start after Phase 2. T030/T031 should wait for Phase 8.

### User Story Dependencies

- **US1 (P1)**: Start after Phase 2 — no dependencies on other stories
- **US2 (P1)**: Builds on US1's screen and scope — depends on US1
- **US3 (P2)**: Builds on US1+US2's screen — depends on US2
- **US4 (P2)**: Adds navigation to screen — depends on US1, can parallel with US2/US3
- **US5 (P2)**: Verifies state stream — depends on US1, can parallel with US2/US3/US4

### Within Each User Story

- Models before interactors/repositories
- Interactors/repositories before scope implementation
- Scope before screen
- Registration before screen (scope must be resolvable)

### Parallel Opportunities

- Phase 1: All 6 setup tasks (T001–T006) can run in parallel
- Phase 2: T007 and T008 can start in parallel once T001 is complete
- After Phase 3: US4 and US5 can run in parallel with US2/US3
- Phase 8: T020, T021, T022, T025 can all run in parallel
- Phase 9: T028 and T029 can run in parallel (different files, no dependencies)

---

## Parallel Example: Phase 1 (Setup)

```
# Launch all public model/protocol/infrastructure tasks together:
Task T001: "Create Bank model in .../BankSelector/Bank.swift"
Task T002: "Create BankSelectorState in .../BankSelector/BankSelectorState.swift"
Task T003: "Create PrimerBankSelectorScope protocol in .../Scope/PrimerBankSelectorScope.swift"
Task T004: "Add type aliases in .../Scope/ComponentTypeAliases.swift"
Task T005: "Add localized strings to .../Constants/CheckoutComponentsStrings.swift"
Task T006: "Add accessibility identifiers to .../Accessibility/Domain/AccessibilityIdentifiers.swift"
```

## Parallel Example: After Phase 3 (US1 complete)

```
# These can run in parallel after US1 is done:
Developer A: US2 (Phase 4) — Search and filtering
Developer B: US4 (Phase 6) — Navigation back/cancel
Developer C: US5 (Phase 7) — State stream verification
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (public models and protocols)
2. Complete Phase 2: Foundational (repository, interactor, DI)
3. Complete Phase 3: User Story 1 (scope, registration, screen)
4. **STOP and VALIDATE**: Test with ADYEN_IDEAL in Debug App
5. Bank selection and payment works end-to-end

### Incremental Delivery

1. Setup + Foundational → Models, domain layer, strings, accessibility identifiers ready
2. Add US1 → Core bank selection flow works → MVP
3. Add US2 → Search filtering works → Better UX
4. Add US3 → Customization works → Merchant flexibility
5. Add US4 → Navigation works → Complete user experience
6. Add US5 → State observation verified → Custom UI support
7. Polish → Edge cases, disabled banks, error handling, accessibility, analytics, empty bank list → Production ready
8. Tests → Minimum high-value test coverage → Confidence for shipping

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story is independently completable and testable after Phase 2
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- The bank selector reuses existing core SDK infrastructure — no new API endpoints or tokenization logic needed
- Translations (T005) and accessibility identifiers (T006) are set up in Phase 1 so they're available for all subsequent screen work
- Analytics events reuse existing `AnalyticsEventType` cases — no new event types needed
- Empty bank list handling (T024) improves on Drop-In's broken minimal UI with a proper empty state
- Test suite (Phase 9) follows Klarna/ApplePay/PayPal test patterns with ~20 high-value tests across 3 files
