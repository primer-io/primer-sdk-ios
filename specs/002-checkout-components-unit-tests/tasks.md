# Implementation Tasks: CheckoutComponents Comprehensive Unit Test Suite

**Branch**: `002-checkout-components-unit-tests` | **Date**: 2025-12-23 | **Spec**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Task Overview

| Phase | Description | Tasks | Priority |
|-------|-------------|-------|----------|
| 0 | Setup & Infrastructure | 4 | P0 |
| 1 | Scope Implementation Tests (US1) | 4 | P1 |
| 2 | Validation System Tests (US2) | 4 | P1 |
| 3 | DI Container Tests (US3) | 3 | P2 |
| 4 | Payment Flow Tests (US4) | 3 | P2 |
| 5 | Navigation System Tests (US5) | 3 | P3 |
| 6 | Polish & Coverage Verification | 3 | P1 |

---

## Phase 0: Setup & Infrastructure

### Task 0.1: Create Test Directory Structure
**Priority**: P0 | **Estimate**: Small | **User Story**: Setup

Create the test directory structure as defined in plan.md.

**Files to Create**:
```
Tests/Primer/CheckoutComponents/
├── Scope/
├── Validation/
├── DI/
├── Payment/
├── Navigation/
├── Mocks/
└── TestSupport/
```

**Acceptance Criteria**:
- [ ] All directories exist under `Tests/Primer/CheckoutComponents/`
- [ ] Directory structure matches plan.md specification

---

### Task 0.2: Create CheckoutComponentsTestCase Base Class
**Priority**: P0 | **Estimate**: Small | **User Story**: Setup

Create the base test class with async setUp/tearDown and DI container configuration.

**File**: `Tests/Primer/CheckoutComponents/TestSupport/CheckoutComponentsTestCase.swift`

**Implementation**:
```swift
import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
class CheckoutComponentsTestCase: XCTestCase {

    var container: ComposableContainer!

    override func setUp() async throws {
        try await super.setUp()
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        container = ComposableContainer(settings: settings)
        await container.configure()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }
}
```

**Acceptance Criteria**:
- [ ] Base class compiles with iOS 15.0+ availability
- [ ] setUp properly initializes ComposableContainer
- [ ] tearDown cleans up resources

---

### Task 0.3: Create TestData Shared Test Fixtures
**Priority**: P0 | **Estimate**: Medium | **User Story**: Setup

Create centralized test data following data-model.md specification.

**File**: `Tests/Primer/CheckoutComponents/TestSupport/TestData.swift`

**Content Sections** (from data-model.md):
- `TestData.CardNumbers` - Valid/invalid card numbers
- `TestData.ExpiryDates` - Valid/expired dates (computed for future-proofing)
- `TestData.CVV` - Valid/invalid CVV codes
- `TestData.CardholderNames` - Valid/invalid names
- `TestData.BillingAddress` - Complete/partial addresses
- `TestData.PaymentMethods` - InternalPaymentMethod fixtures
- `TestData.Errors` - Common error cases

**Acceptance Criteria**:
- [ ] All test data categories implemented
- [ ] Expiry dates use computed properties for future-proof dates
- [ ] Card numbers include Visa, Mastercard, Amex, invalid Luhn
- [ ] Billing addresses support all common countries

---

### Task 0.4: Create Core Mock Implementations
**Priority**: P0 | **Estimate**: Medium | **User Story**: Setup

Create mock implementations for primary dependencies.

**Files**:
- `Tests/Primer/CheckoutComponents/Mocks/MockHeadlessRepository.swift`
- `Tests/Primer/CheckoutComponents/Mocks/MockCheckoutCoordinator.swift`
- `Tests/Primer/CheckoutComponents/Mocks/MockCheckoutNavigator.swift`
- `Tests/Primer/CheckoutComponents/Mocks/MockRulesFactory.swift`

**Implementation Pattern** (from data-model.md):
```swift
@available(iOS 15.0, *)
final class MockHeadlessRepository: HeadlessRepository {
    // Configurable returns
    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var errorToThrow: Error?

    // Call tracking
    var getPaymentMethodsCallCount = 0

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        getPaymentMethodsCallCount += 1
        if let error = errorToThrow { throw error }
        return paymentMethodsToReturn
    }
}
```

**Acceptance Criteria**:
- [ ] All mocks implement their respective protocols
- [ ] Mocks have configurable return values
- [ ] Mocks track call counts for verification
- [ ] Mocks can be configured to throw errors

---

## Phase 1: Scope Implementation Tests (US1)

### Task 1.1: DefaultCheckoutScope Tests
**Priority**: P1 | **Estimate**: Medium | **User Story**: US1

Test the main checkout scope lifecycle and state management.

**File**: `Tests/Primer/CheckoutComponents/Scope/DefaultCheckoutScopeTests.swift`

**Test Cases**:
1. `test_initialization_transitionsToReadyState()` - Verify state flow: initializing → ready
2. `test_initialization_withInvalidToken_transitionsToFailureState()` - Error handling
3. `test_getPaymentMethodScope_returnsCorrectScopeType()` - Scope resolution
4. `test_state_emitsCorrectSequence()` - AsyncStream state observation
5. `test_dismiss_transitionsToDismissedState()` - Dismissal handling

**Acceptance Criteria**:
- [ ] All state transitions covered
- [ ] Error states properly tested
- [ ] AsyncStream observation works correctly
- [ ] Scope resolution verified

---

### Task 1.2: DefaultCardFormScope Tests
**Priority**: P1 | **Estimate**: Large | **User Story**: US1

Test card form scope field validation and state management.

**File**: `Tests/Primer/CheckoutComponents/Scope/DefaultCardFormScopeTests.swift`

**Test Cases**:
1. `test_cardNumberField_validatesCorrectly()` - Card number validation
2. `test_cvvField_validatesForCardNetwork()` - CVV by network (3 vs 4 digits)
3. `test_expiryField_rejectsExpiredDates()` - Expiry validation
4. `test_cardholderNameField_validatesCorrectly()` - Name validation
5. `test_state_reflectsFieldValidation()` - Aggregate validation state
6. `test_submit_withValidData_triggersPayment()` - Submit action
7. `test_submit_withInvalidData_doesNotSubmit()` - Validation gate
8. `test_coBadgedCardDetection_exposesNetworkOptions()` - Co-badged support

**Acceptance Criteria**:
- [ ] All field types validated
- [ ] Co-badged card detection works
- [ ] Submit only proceeds with valid data
- [ ] State accurately reflects validation

---

### Task 1.3: DefaultPaymentMethodSelectionScope Tests
**Priority**: P1 | **Estimate**: Medium | **User Story**: US1

Test payment method selection and loading.

**File**: `Tests/Primer/CheckoutComponents/Scope/DefaultPaymentMethodSelectionScopeTests.swift`

**Test Cases**:
1. `test_loadPaymentMethods_populatesState()` - Method loading
2. `test_selectPaymentMethod_updatesSelection()` - Selection handling
3. `test_filterPaymentMethods_appliesCorrectly()` - Filtering
4. `test_state_exposesPaymentMethodsAsStream()` - AsyncStream
5. `test_emptyPaymentMethods_handledGracefully()` - Empty state

**Acceptance Criteria**:
- [ ] Payment methods load correctly
- [ ] Selection state updates properly
- [ ] Empty states handled
- [ ] Filtering works as expected

---

### Task 1.4: DefaultSelectCountryScope Tests
**Priority**: P1 | **Estimate**: Small | **User Story**: US1

Test country selection scope.

**File**: `Tests/Primer/CheckoutComponents/Scope/DefaultSelectCountryScopeTests.swift`

**Test Cases**:
1. `test_loadCountries_populatesState()` - Country list loading
2. `test_selectCountry_propagatesToParent()` - Selection propagation
3. `test_searchCountries_filtersCorrectly()` - Search/filter
4. `test_initialSelection_reflectedInState()` - Initial state

**Acceptance Criteria**:
- [ ] Countries load correctly
- [ ] Selection propagates to parent scope
- [ ] Search filtering works
- [ ] Initial selection respected

---

## Phase 2: Validation System Tests (US2)

### Task 2.1: ValidationService Tests
**Priority**: P1 | **Estimate**: Medium | **User Story**: US2

Test the core validation service orchestration.

**File**: `Tests/Primer/CheckoutComponents/Validation/ValidationServiceTests.swift`

**Test Cases**:
1. `test_validateField_withValidInput_returnsValid()` - Valid input
2. `test_validateField_withInvalidInput_returnsError()` - Invalid input
3. `test_validateField_withEmpty_whenRequired_returnsError()` - Required fields
4. `test_validateField_withEmpty_whenOptional_returnsValid()` - Optional fields
5. `test_validateMultipleFields_aggregatesResults()` - Batch validation
6. `test_validateField_usesCorrectRules()` - Rule selection

**Acceptance Criteria**:
- [ ] Service delegates to correct rules
- [ ] Required vs optional handled correctly
- [ ] Aggregation works for multiple fields
- [ ] Error codes properly returned

---

### Task 2.2: CardValidationRules Tests
**Priority**: P1 | **Estimate**: Large | **User Story**: US2

Test all card-specific validation rules.

**File**: `Tests/Primer/CheckoutComponents/Validation/CardValidationRulesTests.swift`

**Test Cases**:
Card Number:
1. `test_validateCardNumber_withValidVisa_returnsValid()`
2. `test_validateCardNumber_withValidMastercard_returnsValid()`
3. `test_validateCardNumber_withValidAmex_returnsValid()`
4. `test_validateCardNumber_withInvalidLuhn_returnsInvalid()`
5. `test_validateCardNumber_withTooShort_returnsInvalid()`
6. `test_validateCardNumber_withNonNumeric_returnsInvalid()`

CVV:
7. `test_validateCVV_with3DigitsForVisa_returnsValid()`
8. `test_validateCVV_with4DigitsForAmex_returnsValid()`
9. `test_validateCVV_with3DigitsForAmex_returnsInvalid()`
10. `test_validateCVV_withNonNumeric_returnsInvalid()`

Expiry:
11. `test_validateExpiry_withFutureDate_returnsValid()`
12. `test_validateExpiry_withPastDate_returnsInvalid()`
13. `test_validateExpiry_withInvalidMonth_returnsInvalid()`
14. `test_validateExpiry_withCurrentMonth_returnsValid()`

Cardholder Name:
15. `test_validateCardholderName_withValidName_returnsValid()`
16. `test_validateCardholderName_withNumbers_returnsInvalid()`
17. `test_validateCardholderName_withEmpty_returnsInvalid()`

**Acceptance Criteria**:
- [ ] All card networks tested
- [ ] Luhn algorithm validation works
- [ ] CVV length varies by network
- [ ] Expiry date edge cases covered
- [ ] Name validation follows rules

---

### Task 2.3: CommonValidationRules Tests
**Priority**: P1 | **Estimate**: Medium | **User Story**: US2

Test common validation rules (email, phone, postal code, etc.).

**File**: `Tests/Primer/CheckoutComponents/Validation/CommonValidationRulesTests.swift`

**Test Cases**:
1. `test_validateEmail_withValidFormats_returnsValid()`
2. `test_validateEmail_withInvalidFormats_returnsInvalid()`
3. `test_validatePhoneNumber_withValidFormats_returnsValid()`
4. `test_validatePostalCode_withValidFormats_returnsValid()`
5. `test_validateRequired_withEmpty_returnsInvalid()`
6. `test_validateRequired_withValue_returnsValid()`

**Acceptance Criteria**:
- [ ] Email validation covers common formats
- [ ] Phone validation is flexible
- [ ] Postal code validation is country-aware
- [ ] Required field validation works

---

### Task 2.4: RulesFactory Tests
**Priority**: P1 | **Estimate**: Small | **User Story**: US2

Test the validation rules factory.

**File**: `Tests/Primer/CheckoutComponents/Validation/RulesFactoryTests.swift`

**Test Cases**:
1. `test_createRules_forCardNumber_returnsCardNumberRules()`
2. `test_createRules_forCVV_returnsCVVRules()`
3. `test_createRules_forExpiry_returnsExpiryRules()`
4. `test_createRules_forBillingField_returnsCorrectRules()`
5. `test_createRules_combinesMultipleRules()`

**Acceptance Criteria**:
- [ ] Factory creates correct rule types
- [ ] Rules can be combined
- [ ] Field types map to correct rules

---

## Phase 3: DI Container Tests (US3)

### Task 3.1: Container Registration & Resolution Tests
**Priority**: P2 | **Estimate**: Medium | **User Story**: US3

Test basic DI container functionality.

**File**: `Tests/Primer/CheckoutComponents/DI/ContainerTests.swift`

**Test Cases**:
1. `test_resolve_registeredDependency_returnsInstance()`
2. `test_resolve_unregisteredDependency_throwsError()`
3. `test_resolve_afterConfiguration_succeeds()`
4. `test_resolve_beforeConfiguration_throwsError()`
5. `test_currentContainer_isAccessibleAfterConfiguration()`

**Acceptance Criteria**:
- [ ] Resolution works for registered types
- [ ] Unregistered types throw
- [ ] Configuration gate works
- [ ] Global container access works

---

### Task 3.2: Retention Policy Tests
**Priority**: P2 | **Estimate**: Medium | **User Story**: US3

Test singleton, transient, and weak retention policies.

**File**: `Tests/Primer/CheckoutComponents/DI/RetentionPolicyTests.swift`

**Test Cases**:
1. `test_singleton_returnsSameInstance()`
2. `test_transient_returnsDifferentInstances()`
3. `test_weak_releaseWhenNoStrongReferences()`
4. `test_weak_returnsSameInstanceWhileReferenced()`

**Acceptance Criteria**:
- [ ] Singleton returns same instance
- [ ] Transient returns new instances
- [ ] Weak releases correctly
- [ ] Memory behavior verified

---

### Task 3.3: Factory Registration Tests
**Priority**: P2 | **Estimate**: Small | **User Story**: US3

Test factory-based registrations.

**File**: `Tests/Primer/CheckoutComponents/DI/FactoryTests.swift`

**Test Cases**:
1. `test_factoryRegistration_createsWithParameters()`
2. `test_factoryRegistration_calledEachTime()`
3. `test_asyncFactory_resolvesCorrectly()`

**Acceptance Criteria**:
- [ ] Factories receive parameters
- [ ] Factories called on each resolution
- [ ] Async factories work

---

## Phase 4: Payment Flow Tests (US4)

### Task 4.1: ProcessCardPaymentInteractor Tests
**Priority**: P2 | **Estimate**: Large | **User Story**: US4

Test card payment processing interactor.

**File**: `Tests/Primer/CheckoutComponents/Payment/ProcessCardPaymentInteractorTests.swift`

**Test Cases**:
1. `test_execute_withValidCard_returnsSuccessResult()`
2. `test_execute_withInvalidCard_throwsValidationError()`
3. `test_execute_whenRepositoryFails_propagatesError()`
4. `test_execute_tracksAnalyticsEvent()`
5. `test_execute_with3DSRequired_handlesChallenge()`
6. `test_execute_whenCancelled_handlesCancellation()`

**Acceptance Criteria**:
- [ ] Successful payment flow works
- [ ] Validation errors caught
- [ ] Repository errors propagated
- [ ] 3DS flow handled
- [ ] Cancellation handled gracefully

---

### Task 4.2: CardNetworkDetectionInteractor Tests
**Priority**: P2 | **Estimate**: Medium | **User Story**: US4

Test card network detection logic.

**File**: `Tests/Primer/CheckoutComponents/Payment/CardNetworkDetectionInteractorTests.swift`

**Test Cases**:
1. `test_detect_visaPrefix_returnsVisa()`
2. `test_detect_mastercardPrefix_returnsMastercard()`
3. `test_detect_amexPrefix_returnsAmex()`
4. `test_detect_unknownPrefix_returnsUnknown()`
5. `test_detect_coBadgedCard_returnsMultipleNetworks()`
6. `test_detect_partialNumber_returnsPartialMatch()`

**Acceptance Criteria**:
- [ ] All major networks detected
- [ ] Co-badged cards return multiple options
- [ ] Partial numbers handled
- [ ] Unknown prefixes handled

---

### Task 4.3: ValidateInputInteractor Tests
**Priority**: P2 | **Estimate**: Small | **User Story**: US4

Test input validation interactor.

**File**: `Tests/Primer/CheckoutComponents/Payment/ValidateInputInteractorTests.swift`

**Test Cases**:
1. `test_validateAll_withValidInputs_returnsValid()`
2. `test_validateAll_withInvalidInputs_returnsErrors()`
3. `test_validateAll_aggregatesAllErrors()`
4. `test_validateField_delegatesToService()`

**Acceptance Criteria**:
- [ ] Full validation works
- [ ] Errors aggregated correctly
- [ ] Delegation verified

---

## Phase 5: Navigation System Tests (US5)

### Task 5.1: CheckoutCoordinator Tests
**Priority**: P3 | **Estimate**: Medium | **User Story**: US5

Test navigation stack management.

**File**: `Tests/Primer/CheckoutComponents/Navigation/CheckoutCoordinatorTests.swift`

**Test Cases**:
1. `test_navigate_toRoute_appendsToStack()`
2. `test_goBack_removesLastRoute()`
3. `test_goBack_onEmptyStack_doesNotCrash()`
4. `test_navigate_toSameRoute_doesNotDuplicate()`
5. `test_dismiss_clearsNavigationStack()`
6. `test_currentRoute_reflectsTopOfStack()`

**Acceptance Criteria**:
- [ ] Navigation stack updates correctly
- [ ] Back navigation works
- [ ] Empty stack handled
- [ ] Dismiss clears state
- [ ] @MainActor isolation respected

---

### Task 5.2: CheckoutNavigator Tests
**Priority**: P3 | **Estimate**: Small | **User Story**: US5

Test navigation event publishing.

**File**: `Tests/Primer/CheckoutComponents/Navigation/CheckoutNavigatorTests.swift`

**Test Cases**:
1. `test_publishEvent_observersReceiveEvent()`
2. `test_navigationEvents_emitsAsAsyncStream()`
3. `test_multipleObservers_allReceiveEvents()`

**Acceptance Criteria**:
- [ ] Events published correctly
- [ ] AsyncStream works
- [ ] Multiple observers supported

---

### Task 5.3: CheckoutRoute Tests
**Priority**: P3 | **Estimate**: Small | **User Story**: US5

Test route definitions and behavior.

**File**: `Tests/Primer/CheckoutComponents/Navigation/CheckoutRouteTests.swift`

**Test Cases**:
1. `test_route_equality_worksCorrectly()`
2. `test_route_paymentMethod_containsCorrectType()`
3. `test_route_presentationContext_isCorrect()`

**Acceptance Criteria**:
- [ ] Route equality works
- [ ] Associated values correct
- [ ] Presentation context accurate

---

## Phase 6: Polish & Coverage Verification

### Task 6.1: Async Stream Test Helpers
**Priority**: P1 | **Estimate**: Small | **User Story**: Polish

Create helper extensions for async stream testing.

**File**: `Tests/Primer/CheckoutComponents/TestSupport/XCTestCase+Async.swift`

**Implementation** (from quickstart.md):
```swift
extension XCTestCase {
    func collect<T>(
        _ stream: AsyncStream<T>,
        count: Int,
        timeout: TimeInterval = 2.0
    ) async throws -> [T] {
        // Implementation as per quickstart.md
    }
}
```

**Acceptance Criteria**:
- [ ] Helper collects stream values
- [ ] Timeout prevents hanging
- [ ] Used by stream tests

---

### Task 6.2: Run All Tests & Fix Failures
**Priority**: P1 | **Estimate**: Variable | **User Story**: Polish

Run complete test suite and fix any failures.

**Command**:
```bash
xcodebuild test \
  -scheme "PrimerSDK" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4" \
  -enableCodeCoverage YES
```

**Acceptance Criteria**:
- [ ] All tests pass
- [ ] No flaky tests
- [ ] Test execution < 60 seconds

---

### Task 6.3: Verify 90% Coverage Target
**Priority**: P1 | **Estimate**: Small | **User Story**: SC-001

Verify code coverage meets 90% target for CheckoutComponents.

**Command**:
```bash
xcrun xccov view --report Build/Logs/Test/*.xcresult --files-for-target PrimerSDK | grep CheckoutComponents
```

**Acceptance Criteria**:
- [ ] Coverage report generated
- [ ] CheckoutComponents production code >= 90%
- [ ] Mocks, previews, test utilities excluded

---

## Test Execution

**Workspace**: `PrimerSDK.xcworkspace`
**Scheme**: `PrimerSDKTests`

```bash
# Run specific test file only (use during implementation for speed)
xcodebuild test \
  -workspace "PrimerSDK.xcworkspace" \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4" \
  -only-testing:"PrimerSDKTests/DefaultCheckoutScopeTests"

# Run full suite (Phase 6 only)
xcodebuild test \
  -workspace "PrimerSDK.xcworkspace" \
  -scheme "PrimerSDKTests" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4" \
  -enableCodeCoverage YES
```

---

## Definition of Done

Each task is complete when:
- [ ] All acceptance criteria met
- [ ] Code compiles without warnings
- [ ] Tests pass consistently
- [ ] @available(iOS 15.0, *) annotation present
- [ ] Follows naming conventions from quickstart.md
- [ ] No hardcoded expiry dates (use computed properties)

## Dependencies Graph

```
Phase 0 (Setup)
    ├── Task 0.1: Directory Structure
    ├── Task 0.2: Base Test Class ─────┐
    ├── Task 0.3: TestData ────────────┤
    └── Task 0.4: Mocks ───────────────┤
                                       │
Phase 1-5 (Feature Tests) ◄────────────┘
    ├── Phase 1: Scopes (US1) ─── P1
    ├── Phase 2: Validation (US2) ─── P1
    ├── Phase 3: DI Container (US3) ─── P2
    ├── Phase 4: Payment (US4) ─── P2
    └── Phase 5: Navigation (US5) ─── P3
                                       │
Phase 6 (Polish) ◄─────────────────────┘
    ├── Task 6.1: Async Helpers
    ├── Task 6.2: Run & Fix
    └── Task 6.3: Coverage Verification
```

**Note**: Phases 1-5 can be executed in parallel after Phase 0 completion. Phase 6 must wait for all feature tests.
