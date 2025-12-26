# Tasks: CheckoutComponents Code Coverage Improvement

**Input**: Design documents from `/specs/003-coverage-improvement/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, quickstart.md

**Tests**: All tasks in this feature ARE test implementations - the entire feature is about adding unit tests to improve coverage.

**Organization**: Tasks are grouped by user story (priority-based phases) to enable independent implementation and validation of coverage improvements.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Tests**: `Tests/Primer/CheckoutComponents/`
- **Production Code**: `Sources/PrimerSDK/Classes/CheckoutComponents/Internal/`
- **Test Data**: `Tests/Primer/CheckoutComponents/TestSupport/TestData.swift`
- **Mocks**: `Tests/Primer/CheckoutComponents/Mocks/`

---

## Phase 1: Setup & Test Data Extension

**Purpose**: Extend existing test infrastructure with new test data fixtures for Data/Payment layer testing

- [ ] T001 [P] Extend TestData.swift with APIResponses fixtures (validPaymentMethods, emptyPaymentMethods, malformedJSON) in Tests/Primer/CheckoutComponents/TestSupport/TestData.swift
- [ ] T002 [P] Extend TestData.swift with PaymentResults fixtures (success, threeDSRequired, declined) in Tests/Primer/CheckoutComponents/TestSupport/TestData.swift
- [ ] T003 [P] Extend TestData.swift with ThreeDSFlows fixtures (challengeRequired, frictionless, failed) in Tests/Primer/CheckoutComponents/TestSupport/TestData.swift
- [ ] T004 [P] Extend TestData.swift with NetworkResponses fixtures (success200, timeout, noConnection) in Tests/Primer/CheckoutComponents/TestSupport/TestData.swift
- [ ] T005 [P] Extend TestData.swift with Errors fixtures (networkTimeout, invalidCardNumber, paymentDeclined) in Tests/Primer/CheckoutComponents/TestSupport/TestData.swift

**Checkpoint**: Test data fixtures ready for Data and Payment layer testing

---

## Phase 2: User Story 3 - Complete Near-Finished Areas (Priority: P2) 🎯 Quick Wins

**Goal**: Achieve 90% coverage in Navigation (88.52% → 90%), Validation (72.14% → 90%), Core (70.23% → 90%), and DI Container (56.90% → 90%)

**Independent Test**: Run coverage report after this phase - these areas should all reach 90% independently

**Coverage Target**: +653 lines → 22.58% overall coverage

### Navigation Tests (88.52% → 90%)

- [ ] T006 [US3] Add NavigationEdgeCasesTests.swift testing back navigation edge cases in Tests/Primer/CheckoutComponents/Navigation/NavigationEdgeCasesTests.swift
- [ ] T007 [US3] Add test for route deduplication in NavigationEdgeCasesTests.swift

### Validation Tests (72.14% → 90%)

- [ ] T008 [P] [US3] Create BillingAddressValidationTests.swift testing billing address edge cases in Tests/Primer/CheckoutComponents/Validation/BillingAddressValidationTests.swift
- [ ] T009 [P] [US3] Create ExpiryDateValidationEdgeCasesTests.swift testing expiry date validation edge cases in Tests/Primer/CheckoutComponents/Validation/ExpiryDateValidationEdgeCasesTests.swift

### Core Tests (70.23% → 90%)

- [ ] T010 [P] [US3] Create CheckoutSDKInitializerTests.swift testing initialization error paths in Tests/Primer/CheckoutComponents/Core/CheckoutSDKInitializerTests.swift
- [ ] T011 [P] [US3] Create SettingsObserverTests.swift testing settings change observation in Tests/Primer/CheckoutComponents/Core/SettingsObserverTests.swift

### DI Container Tests (56.90% → 90%)

- [ ] T012 [P] [US3] Create RetentionPolicyTests.swift testing singleton/transient/weak retention policies in Tests/Primer/CheckoutComponents/DI/RetentionPolicyTests.swift
- [ ] T013 [P] [US3] Create FactoryRegistrationTests.swift testing factory registration and override in Tests/Primer/CheckoutComponents/DI/FactoryRegistrationTests.swift
- [ ] T014 [P] [US3] Create AsyncResolutionTests.swift testing async dependency resolution in Tests/Primer/CheckoutComponents/DI/AsyncResolutionTests.swift

**Checkpoint**: Navigation, Validation, Core, DI Container all at 90% coverage - run coverage report to validate

---

## Phase 3: User Story 1 - Data Layer Coverage (Priority: P1)

**Goal**: Comprehensive tests for repository implementations covering API interactions, data mapping, error handling, and cache behavior

**Independent Test**: Run Data layer tests - should achieve 16.82% → 90% coverage for Data layer

**Coverage Target**: +958 lines → 27.89% overall coverage

### Repository Tests

- [ ] T015 [P] [US1] Create HeadlessRepositoryImplTests.swift with valid API response mapping tests in Tests/Primer/CheckoutComponents/Data/Repositories/HeadlessRepositoryImplTests.swift
- [ ] T016 [US1] Add network error propagation tests to HeadlessRepositoryImplTests.swift
- [ ] T017 [US1] Add cache behavior tests to HeadlessRepositoryImplTests.swift (cache hit, cache miss, cache expiry)
- [ ] T018 [P] [US1] Create PayPalRepositoryImplTests.swift with retry logic tests (exponential backoff) in Tests/Primer/CheckoutComponents/Data/Repositories/PayPalRepositoryImplTests.swift
- [ ] T019 [P] [US1] Create ConfigurationRepositoryTests.swift with merchant config parsing tests in Tests/Primer/CheckoutComponents/Data/Repositories/ConfigurationRepositoryTests.swift

### Mapper Tests

- [ ] T020 [P] [US1] Create PaymentMethodMapperTests.swift testing API response to internal model mapping in Tests/Primer/CheckoutComponents/Data/Mappers/PaymentMethodMapperTests.swift
- [ ] T021 [P] [US1] Create ErrorMapperTests.swift testing error code to user-facing message mapping in Tests/Primer/CheckoutComponents/Data/Mappers/ErrorMapperTests.swift
- [ ] T022 [US1] Add malformed JSON handling tests to PaymentMethodMapperTests.swift

**Checkpoint**: Data layer at 90% coverage - repository and mapper implementations fully tested

---

## Phase 4: User Story 2 - Payment Flow Coverage (Priority: P1)

**Goal**: Comprehensive tests for payment interactors covering orchestration, 3DS handling, tokenization, and surcharge calculation

**Independent Test**: Run Payment layer tests - should achieve 13.17% → 90% coverage for Payment layer

**Coverage Target**: +899 lines → 32.87% overall coverage

### Payment Interactor Tests

- [ ] T023 [P] [US2] Create PaymentFlowCoordinatorTests.swift with 3DS required flow tests in Tests/Primer/CheckoutComponents/Payment/Interactors/PaymentFlowCoordinatorTests.swift
- [ ] T024 [US2] Add payment cancellation tests to PaymentFlowCoordinatorTests.swift (resources cleanup, state reset)
- [ ] T025 [US2] Add payment cancellation race condition tests to PaymentFlowCoordinatorTests.swift (cancellation-takes-priority behavior)
- [ ] T026 [P] [US2] Create ThreeDSHandlerTests.swift with challenge flow tests (success, failure, timeout) in Tests/Primer/CheckoutComponents/Payment/Interactors/ThreeDSHandlerTests.swift
- [ ] T027 [US2] Add frictionless 3DS flow tests to ThreeDSHandlerTests.swift
- [ ] T028 [P] [US2] Create TokenizationServiceTests.swift with tokenization security tests (no logging, no storage) in Tests/Primer/CheckoutComponents/Payment/Interactors/TokenizationServiceTests.swift
- [ ] T029 [P] [US2] Create SurchargeCalculatorTests.swift with network-based surcharge tests in Tests/Primer/CheckoutComponents/Payment/Interactors/SurchargeCalculatorTests.swift

### Payment Error Handling Tests

- [ ] T030 [US2] Add error categorization tests to PaymentFlowCoordinatorTests.swift (network, validation, payment declined)
- [ ] T031 [P] [US2] Create PaymentResultTests.swift with payment result model tests in Tests/Primer/CheckoutComponents/Payment/Models/PaymentResultTests.swift

**Checkpoint**: Payment layer at 90% coverage - payment orchestration and security verified

---

## Phase 5: User Story 4 - Scope & Utilities Coverage (Priority: P3)

**Goal**: Tests for Scope customization (43.60% → 90%), Analytics tracking, and utility code

**Independent Test**: Run Scope and Utilities tests independently

**Coverage Target**: +3,364 lines → 51.53% overall coverage

### Scope Tests

- [ ] T032 [P] [US4] Create ScopeCustomizationTests.swift with custom UI component rendering tests in Tests/Primer/CheckoutComponents/Scope/ScopeCustomizationTests.swift
- [ ] T033 [US4] Add scope lifecycle tests to ScopeCustomizationTests.swift
- [ ] T034 [US4] Add customization closure error handling tests to ScopeCustomizationTests.swift

### Analytics Tests

- [ ] T035 [P] [US4] Create AnalyticsEventTests.swift with event metadata validation tests in Tests/Primer/CheckoutComponents/Analytics/AnalyticsEventTests.swift
- [ ] T036 [P] [US4] Create AnalyticsSessionTests.swift with session tracking tests in Tests/Primer/CheckoutComponents/Analytics/AnalyticsSessionTests.swift

### Design Tokens Tests

- [ ] T037 [P] [US4] Create DesignTokensTests.swift with theme switching tests (light/dark) in Tests/Primer/CheckoutComponents/Utilities/Tokens/DesignTokensTests.swift
- [ ] T038 [P] [US4] Create DesignTokensManagerTests.swift with token value resolution tests in Tests/Primer/CheckoutComponents/Utilities/Tokens/DesignTokensManagerTests.swift

### Formatter Tests

- [ ] T039 [P] [US4] Create CardNumberFormatterTests.swift with mask pattern tests in Tests/Primer/CheckoutComponents/Utilities/Formatters/CardNumberFormatterTests.swift
- [ ] T040 [P] [US4] Create ExpiryDateFormatterTests.swift with expiry formatting tests in Tests/Primer/CheckoutComponents/Utilities/Formatters/ExpiryDateFormatterTests.swift

### Extension Tests

- [ ] T041 [P] [US4] Create StringExtensionsTests.swift with string utility tests in Tests/Primer/CheckoutComponents/Utilities/Extensions/StringExtensionsTests.swift

**Checkpoint**: Scope and Utilities layers tested - customization APIs and observability features verified

---

## Phase 6: Decision Point & Coverage Validation

**Purpose**: Evaluate coverage progress and decide on Presentation layer refactoring

- [ ] T042 Run full coverage report via xcodebuild -enableCodeCoverage YES and xcrun xccov
- [ ] T043 Verify GitHub Actions Sonar reports show coverage progress
- [ ] T044 Evaluate coverage metrics: Have we reached 80%+ without Presentation?
- [ ] T045 Document decision: Accept 80% pragmatic target OR proceed to Phase 7 (Presentation refactoring)

**Checkpoint**: Decision made - either declare success at 80% or proceed to Presentation refactoring

---

## Phase 7: User Story 5 - Presentation Layer Refactoring (Priority: P4 - OPTIONAL)

**Goal**: Extract ViewModels from SwiftUI views to enable unit testing of formatting/validation logic

**Independent Test**: ViewModel tests should run without SwiftUI rendering

**Coverage Target**: +5,150 lines → 90.00% overall coverage

**⚠️ HIGH RISK**: Only proceed if 90% coverage is required and Phase 6 decision approves

### ViewModel Extraction

- [ ] T046 [P] [US5] Extract CardNumberInputFieldViewModel from CardNumberInputField in Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/CardNumberInputField.swift
- [ ] T047 [P] [US5] Extract CVVInputFieldViewModel from CVVInputField in Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/CVVInputField.swift
- [ ] T048 [P] [US5] Extract BillingAddressViewModel from BillingAddressView in Sources/PrimerSDK/Classes/CheckoutComponents/Internal/Presentation/BillingAddressView.swift

### ViewModel Tests

- [ ] T049 [P] [US5] Create CardNumberInputFieldViewModelTests.swift with formatting logic tests in Tests/Primer/CheckoutComponents/Presentation/CardNumberInputFieldViewModelTests.swift
- [ ] T050 [P] [US5] Create CVVInputFieldViewModelTests.swift with validation logic tests in Tests/Primer/CheckoutComponents/Presentation/CVVInputFieldViewModelTests.swift
- [ ] T051 [P] [US5] Create BillingAddressViewModelTests.swift with field visibility tests in Tests/Primer/CheckoutComponents/Presentation/BillingAddressViewModelTests.swift

### UI Regression Validation

- [ ] T052 Manually test all refactored SwiftUI views for visual regressions
- [ ] T053 [P] Setup snapshot tests for critical UI components (if snapshot testing framework added)

**Checkpoint**: Presentation layer at 70% coverage (90% overall) - visual regressions checked

---

## Phase 8: Polish & Quality Gates

**Purpose**: Final validation and quality assurance

- [ ] T054 [P] Run full test suite 10 consecutive times to verify zero flaky failures
- [ ] T055 Measure test suite execution time - verify < 2 minutes on iPhone 17 simulator
- [ ] T056 [P] Code review all test files for behavior testing (not implementation details)
- [ ] T057 [P] Update quickstart.md with examples from newly added tests
- [ ] T058 Generate final coverage report and document results in specs/003-coverage-improvement/
- [ ] T059 Validate coverage exclusions (Mocks, MockDesignTokens, Preview providers excluded)

**Checkpoint**: All quality gates passed - feature complete

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Quick Wins (Phase 2)**: Depends on Setup completion
- **Data Layer (Phase 3)**: Depends on Setup completion - can run in parallel with Phase 2
- **Payment Layer (Phase 4)**: Depends on Setup completion - can run in parallel with Phases 2 and 3
- **Scope & Utilities (Phase 5)**: Depends on Setup completion - can run in parallel with Phases 2, 3, and 4
- **Decision Point (Phase 6)**: Depends on Phases 2, 3, 4, 5 completion
- **Presentation Refactoring (Phase 7)**: OPTIONAL - only if Phase 6 decision approves
- **Polish (Phase 8)**: Depends on all implemented phases

### User Story Dependencies

- **User Story 3 (P2 - Quick Wins)**: Independent - can start after Setup
- **User Story 1 (P1 - Data Layer)**: Independent - can start after Setup
- **User Story 2 (P1 - Payment Layer)**: Independent - can start after Setup
- **User Story 4 (P3 - Scope & Utilities)**: Independent - can start after Setup
- **User Story 5 (P4 - Presentation)**: OPTIONAL - Independent but requires refactoring production code

**All user stories are independently testable and can be implemented in parallel after Phase 1 completes**

### Within Each User Story

- Test data fixtures (Phase 1) should be extended before implementing tests that use them
- All tests marked [P] within a phase can run in parallel (different files)
- Tests without [P] depend on previous tasks completing
- Each phase should conclude with a coverage validation checkpoint

### Parallel Opportunities

- **Phase 1**: All T001-T005 tasks can run in parallel (different test data categories)
- **Phase 2 (US3)**: T008-T014 can run in parallel (different test files)
- **Phase 3 (US1)**: T015, T018, T019, T020, T021 can run in parallel (different test files)
- **Phase 4 (US2)**: T023, T026, T028, T029, T031 can run in parallel (different test files)
- **Phase 5 (US4)**: T032, T035-T041 can run in parallel (different test files)
- **Phase 7 (US5)**: T046-T051 can run in parallel (different ViewModels/tests)
- **Phase 8**: T054, T056, T057, T059 can run in parallel (independent validation tasks)

**Phases 2, 3, 4, 5 can all run in parallel after Phase 1 completes (different user stories, different files)**

---

## Parallel Example: User Story 1 (Data Layer)

```bash
# Launch all parallelizable repository tests together:
Task T015: "Create HeadlessRepositoryImplTests.swift with valid API response mapping tests"
Task T018: "Create PayPalRepositoryImplTests.swift with retry logic tests"
Task T019: "Create ConfigurationRepositoryTests.swift with merchant config parsing tests"

# Launch all parallelizable mapper tests together:
Task T020: "Create PaymentMethodMapperTests.swift testing API response to internal model mapping"
Task T021: "Create ErrorMapperTests.swift testing error code to user-facing message mapping"

# Sequential within HeadlessRepositoryImplTests (same file):
Task T015 → Task T016 → Task T017
```

---

## Parallel Example: User Story 2 (Payment Layer)

```bash
# Launch all parallelizable interactor tests together:
Task T023: "Create PaymentFlowCoordinatorTests.swift with 3DS required flow tests"
Task T026: "Create ThreeDSHandlerTests.swift with challenge flow tests"
Task T028: "Create TokenizationServiceTests.swift with tokenization security tests"
Task T029: "Create SurchargeCalculatorTests.swift with network-based surcharge tests"
Task T031: "Create PaymentResultTests.swift with payment result model tests"

# Sequential within PaymentFlowCoordinatorTests (same file):
Task T023 → Task T024 → Task T025 → Task T030
```

---

## Implementation Strategy

### MVP First (Quick Wins + Data + Payment)

**Recommended MVP Scope**: Complete Phases 1-4 for immediate 80%+ coverage

1. Complete Phase 1: Setup (extend TestData.swift with all fixtures)
2. Complete Phase 2: User Story 3 - Quick Wins (Navigation, Validation, Core, DI at 90%)
3. Complete Phase 3: User Story 1 - Data Layer (repositories and mappers at 90%)
4. Complete Phase 4: User Story 2 - Payment Layer (payment flows and 3DS at 90%)
5. Complete Phase 6: Decision Point
6. **STOP and VALIDATE**: Run coverage report - should be at 80%+ coverage
7. If 80% achieved: Declare success (pragmatic target)
8. If 90% required: Proceed to Phases 5 and 7

### Incremental Delivery

1. Phase 1 (Setup) → Test data ready
2. Phase 2 (US3) → Quick wins delivered, 22.58% coverage
3. Phase 3 (US1) → Data layer tested, 27.89% coverage
4. Phase 4 (US2) → Payment layer tested, 32.87% coverage
5. Phase 5 (US4) → Scope/Utilities tested, 51.53% coverage
6. Phase 6 (Decision) → Evaluate 80% vs 90%
7. Phase 7 (US5) → OPTIONAL Presentation refactoring, 90% coverage
8. Phase 8 (Polish) → Quality gates validated

### Parallel Team Strategy

With multiple developers after Phase 1 completes:

1. **Developer A**: Phase 2 (User Story 3 - Quick Wins)
2. **Developer B**: Phase 3 (User Story 1 - Data Layer)
3. **Developer C**: Phase 4 (User Story 2 - Payment Layer)
4. **Developer D**: Phase 5 (User Story 4 - Scope & Utilities)

All four phases can proceed independently and be validated separately.

---

## Notes

- **[P] tasks** = different files, no dependencies - can run in parallel
- **[Story] label** = maps task to specific user story (US1, US2, US3, US4, US5)
- **Every task creates tests** - this is a test coverage improvement feature
- **No production code changes** except optional Phase 7 (Presentation ViewModel extraction)
- **Independent validation**: Each phase should pass coverage metrics independently
- **Pragmatic target**: 80% coverage is success without high-risk Presentation refactoring
- **Decision point at Phase 6**: Evaluate whether 90% is worth the Presentation refactoring risk
- **Code review focus**: Tests should verify behavior, not implementation details
- **Flaky test definition**: Non-deterministic (passes/fails inconsistently on identical code)
- **Commit strategy**: Commit after each test file creation or logical test group
