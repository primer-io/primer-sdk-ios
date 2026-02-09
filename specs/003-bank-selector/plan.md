# Implementation Plan: Bank Selector Scope for CheckoutComponents

**Branch**: `003-bank-selector` | **Date**: 2026-02-09 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/003-bank-selector/spec.md`

## Summary

Add bank selector support to CheckoutComponents, enabling bank-based payment methods (iDEAL, Dotpay) with a searchable bank list, immediate redirect on selection, and full merchant customization. The implementation follows existing CheckoutComponents patterns: scope protocol + default implementation + interactor/repository + DI registration + payment method registry. All post-selection payment processing (redirect, polling, success, failure) is delegated to the existing checkout scope infrastructure.

## Technical Context

**Language/Version**: Swift 6.0+ with strict concurrency
**Primary Dependencies**: SwiftUI (iOS 15+), existing CheckoutComponents DI framework, existing `PrimerAPIClient` bank list API, existing tokenization/redirect/polling infrastructure
**Storage**: N/A (no local persistence; bank list fetched per session)
**Testing**: XCTest (unit tests for interactor, repository, scope, filtering logic)
**Target Platform**: iOS 15.0+ (CheckoutComponents requirement)
**Project Type**: Mobile SDK (iOS)
**Performance Goals**: Bank list search filtering < 100ms; 60fps UI scrolling
**Constraints**: Must follow existing CheckoutComponents patterns; no new external dependencies; reuse existing core SDK infrastructure
**Scale/Scope**: 2 payment methods (ADYEN_IDEAL, ADYEN_DOTPAY); ~10 new source files + 4 test files; 1 new screen

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. iOS Platform Standards | PASS | iOS 15.0+ (CC requirement), Swift 6.0+, SwiftLint rules respected |
| II. Cross-Platform API Parity | PASS | Scope naming and state patterns match Android bank selector API |
| III. Integration Flexibility | PASS | Bank selector is a CC scope only; no coupling to Drop-In or Headless |
| IV. Security & PCI Compliance | PASS | No payment data in logs/state; bank IDs are non-sensitive identifiers |
| V. Test Coverage & Quality Gates | PASS | Unit tests planned for all business logic (filtering, state transitions, mapping) |
| VI. Backward Compatibility | PASS | Additive feature (new scope, new models); no breaking changes to existing APIs |

### Post-Design Gate

| Principle | Status | Notes |
|-----------|--------|-------|
| I. iOS Platform Standards | PASS | SwiftUI screen follows HIG; accessibility identifiers defined in `AccessibilityIdentifiers.BankSelector`; VoiceOver labels/hints via `CheckoutComponentsStrings`; all interactive elements annotated with `.accessibility(config:)` |
| II. Cross-Platform API Parity | PASS | `PrimerBankSelectorScope` protocol mirrors Android API; `Bank` model matches; analytics events use platform-agnostic types |
| III. Integration Flexibility | PASS | Scope registered via `PaymentMethodRegistry`; no cross-integration coupling |
| IV. Security & PCI Compliance | PASS | Bank IDs/names are non-PII; no card data involved; accessibility identifiers are data-independent |
| V. Test Coverage & Quality Gates | PASS | Minimum high-value test suite included: interactor tests (mapping, execution), scope tests (state transitions, search, disabled banks, errors), state model tests (init, equality) — ~20 tests across 3 test files |
| VI. Backward Compatibility | PASS | New public types only (`PrimerBankSelectorScope`, `BankSelectorState`, `Bank`); MINOR version bump |

## Project Structure

### Documentation (this feature)

```text
specs/003-bank-selector/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 research findings
├── data-model.md        # Entity definitions and state machine
├── quickstart.md        # Integration guide and architecture overview
├── contracts/
│   ├── scope-api.md     # Public PrimerBankSelectorScope protocol
│   └── internal-api.md  # Interactor, repository, DI contracts
├── checklists/
│   └── requirements.md  # Spec quality checklist
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
Sources/PrimerSDK/Classes/CheckoutComponents/
├── Scope/
│   └── PrimerBankSelectorScope.swift              # Public scope protocol
├── PaymentMethods/
│   └── BankSelector/
│       ├── BankSelectorPaymentMethod.swift         # PaymentMethodProtocol + bulk registration
│       ├── BankSelectorState.swift                 # Public state model (BankSelectorState + Status)
│       └── Bank.swift                              # Public Bank model
└── Internal/
    ├── Domain/
    │   ├── Interactors/
    │   │   └── ProcessBankSelectorPaymentInteractor.swift  # Protocol + Impl
    │   └── Repositories/
    │       └── BankSelectorRepository.swift                # Protocol + Impl
    ├── Presentation/
    │   ├── Scope/
    │   │   └── DefaultBankSelectorScope.swift              # Scope implementation
    │   └── Screens/
    │       └── BankSelectorScreen.swift                    # Default SwiftUI screen
    └── DI/
        └── ComposableContainer.swift                       # Modified: add bank selector registrations

Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/Scope/
└── DefaultCheckoutScope.swift                              # Modified: add BankSelectorPaymentMethod.registerAll()

Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Constants/
└── CheckoutComponentsStrings.swift                         # Modified: add bank selector localized strings

Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Accessibility/Domain/
└── AccessibilityIdentifiers.swift                          # Modified: add BankSelector enum

Tests/Primer/CheckoutComponents/BankSelector/
├── ProcessBankSelectorPaymentInteractorTests.swift         # Interactor tests (mapping, delegation, errors)
├── DefaultBankSelectorScopeTests.swift                     # Scope tests (state transitions, search, guards)
├── BankSelectorStateTests.swift                            # State model tests (init, equality)
└── Mocks/
    └── MockProcessBankSelectorPaymentInteractor.swift      # Configurable mock with call tracking
```

**Structure Decision**: Follows the existing CheckoutComponents module structure. New files are organized under `PaymentMethods/BankSelector/` (public models) and `Internal/Domain/` + `Internal/Presentation/` (implementation). This matches how Card, PayPal, ApplePay, and Klarna are organized. Tests follow the same pattern as `Tests/Primer/CheckoutComponents/Klarna/` and `Tests/Primer/CheckoutComponents/ApplePay/`.

## Complexity Tracking

No constitution violations to justify. The implementation follows all established patterns without introducing new architectural concepts.

### Cross-Cutting Concerns

- **Accessibility**: Follows existing `AccessibilityIdentifiers` + `AccessibilityConfiguration` + `.accessibility(config:)` pattern (R7). All interactive elements annotated.
- **Translations**: All user-facing text via `CheckoutComponentsStrings.swift` with `NSLocalizedString` (R8). Supports 41 languages.
- **Analytics**: Reuses existing `AnalyticsEventType` cases — no new event types needed (R9). Fire-and-forget tracking in scope.
- **Empty bank list**: Explicit empty state when API returns zero banks — improves on Drop-In which has no handling (R11).
- **Test coverage**: Minimum high-value test suite: interactor, scope, state model (~20 tests across 3 files) following Klarna/ApplePay/PayPal patterns (R10).

## Design Decisions

### D1: Multi-Payment-Method Registration

**Problem**: `PaymentMethodProtocol` uses a static `paymentMethodType` property, but bank selector covers 2 APMs.

**Decision**: Create thin per-APM structs (`IDealPaymentMethod`, `DotpayPaymentMethod`) that delegate `createScope()` and `createView()` to shared `BankSelectorPaymentMethod` logic. Alternatively, if the registry supports closure-based registration, use `BankSelectorPaymentMethod.registerAll()` to register each type with the appropriate identifier.

**Rationale**: Keeps each APM discoverable in the registry with its own type key while sharing all implementation code.

### D2: Repository Wraps Core SDK

**Problem**: CheckoutComponents needs to fetch banks and process payments without depending on Drop-In/Headless ViewModel hierarchy.

**Decision**: `BankSelectorRepositoryImpl` wraps `PrimerAPIClient.listAdyenBanks()` for bank fetching and delegates to the existing tokenization + payment creation + redirect/polling infrastructure for payment processing.

**Rationale**: Follows the PayPalRepository pattern. Keeps the scope layer decoupled from core SDK internals while reusing battle-tested infrastructure.

### D3: Bank Model Decoupling

**Problem**: The API returns `AdyenBank` (internal type). The public scope API should not expose internal types.

**Decision**: Create a public `Bank` model and map from `AdyenBank` in the interactor layer.

**Rationale**: Matches how `IssuingBank` decouples the Headless API from `AdyenBank`. Provides a stable public contract independent of the internal API response shape.

### D4: Search Filtering in Scope (Not Interactor)

**Problem**: Bank filtering needs to be fast and responsive. Should it live in the scope or interactor?

**Decision**: Filtering logic lives in `DefaultBankSelectorScope` directly, operating on the in-memory `banks` array.

**Rationale**: Filtering is a pure UI concern (substring match on names). Routing through the interactor adds unnecessary indirection for a synchronous in-memory operation. The scope holds the bank list in state and can filter immediately on `search(query:)`.

## Artifacts

| Artifact | Path | Status |
|----------|------|--------|
| Feature Spec | [spec.md](./spec.md) | Complete |
| Research | [research.md](./research.md) | Complete |
| Data Model | [data-model.md](./data-model.md) | Complete |
| Scope API Contract | [contracts/scope-api.md](./contracts/scope-api.md) | Complete |
| Internal API Contract | [contracts/internal-api.md](./contracts/internal-api.md) | Complete |
| Quickstart Guide | [quickstart.md](./quickstart.md) | Complete |
| Requirements Checklist | [checklists/requirements.md](./checklists/requirements.md) | Complete |
| Tasks | tasks.md | Complete (31 tasks across 9 phases) |
