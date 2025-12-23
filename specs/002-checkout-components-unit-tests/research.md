# Research: CheckoutComponents Unit Test Suite

**Date**: 2025-12-23
**Branch**: `002-checkout-components-unit-tests`

## Executive Summary

Research confirms that a solid foundation of CheckoutComponents tests already exists (11 test files in `Tests/Primer/CheckoutComponents/`), along with reusable mock utilities. The test suite can be extended systematically to achieve 90%+ coverage by focusing on untested areas: scope implementations, payment interactors, navigation system, and comprehensive validation coverage.

---

## Research Findings

### 1. Existing Test Infrastructure

**Decision**: Extend existing test structure rather than create new infrastructure

**Rationale**:
- 11 test files already exist in `Tests/Primer/CheckoutComponents/`
- Established patterns for async testing with `async throws` setUp/tearDown
- `@available(iOS 15.0, *)` annotations consistently applied
- DI container test patterns well-established (see `AccessibilityDIContainerTests.swift`)

**Alternatives Considered**:
- Creating separate test target → Rejected (adds complexity, existing structure works)
- Using Quick/Nimble BDD framework → Rejected (not used in project, adds dependencies)

### 2. Mock Utilities Available

**Decision**: Leverage existing mocks in `Internal/Utilities/`, extend as needed

**Rationale**:
Existing mocks found:
- `MockDIContainer.swift` - Basic container for previews, can be extended for tests
- `MockCardFormScope.swift` - Complete mock of card form scope
- `MockDesignTokens.swift` - Design system mocking
- `MockValidationService.swift` - Validation service mock

**What Needs Creation**:
- `MockHeadlessRepository` - For payment flow testing
- `MockCheckoutNavigator` - For navigation testing
- `MockPaymentMethodRegistry` - For scope testing

**Alternatives Considered**:
- Creating all mocks from scratch → Rejected (duplicates existing work)
- Using mocking library (Mockingbird, Cuckoo) → Rejected (not used in project, adds complexity)

### 3. Async Testing Patterns

**Decision**: Use native Swift async/await with XCTest async support

**Rationale**:
Existing pattern from `AccessibilityDIContainerTests.swift`:
```swift
override func setUp() async throws {
    try await super.setUp()
    composableContainer = ComposableContainer(settings: settings)
    await composableContainer.configure()
}

func testAsyncOperation() async throws {
    let service = try await container.resolve(SomeService.self)
    XCTAssertNotNil(service)
}
```

**Key Patterns**:
- Use `async throws` for setUp/tearDown
- Use `await` for actor-isolated operations
- No need for XCTestExpectation for simple async tests
- Container tests require `await DIContainer.current`

**Alternatives Considered**:
- Using Combine publishers → Rejected (async/await is cleaner, already used)
- Using dispatch queues → Rejected (outdated pattern, doesn't work with actors)

### 4. Components Requiring Tests

**Decision**: Prioritize by coverage impact and criticality

| Component | Priority | Existing Tests | Files to Test |
|-----------|----------|----------------|---------------|
| Scope Implementations | P1 | ❌ None | 5 scopes |
| Validation System | P1 | ❌ None | 6 files |
| DI Container | P2 | ✅ Partial (DI tests exist) | Extend existing |
| Payment Interactors | P2 | ❌ None | 3 interactors |
| Navigation | P3 | ❌ None | 3 files |

**Scope Files (5)**:
- `DefaultCheckoutScope.swift`
- `DefaultCardFormScope.swift`
- `DefaultPaymentMethodSelectionScope.swift`
- `DefaultSelectCountryScope.swift`
- `DefaultPayPalScope.swift`

**Validation Files (6)**:
- `ValidationService.swift`
- `RulesFactory.swift`
- `ValidationRule.swift`
- `ValidationError.swift`
- `ValidationResult.swift`
- `ExpiryDateInput.swift`
- Plus: `Rules/CardValidationRules.swift`, `Rules/CommonValidationRules.swift`

**Payment Interactors (3)**:
- `ProcessCardPaymentInteractor`
- `CardNetworkDetectionInteractor`
- `ValidateInputInteractor`

**Navigation (3)**:
- `CheckoutCoordinator.swift`
- `CheckoutNavigator.swift`
- `CheckoutRoute.swift`

### 5. Test Data Patterns

**Decision**: Use deterministic test data constants

**Rationale**:
Payment SDK tests require consistent, valid test data:
- Valid test card numbers (Visa: 4111111111111111, etc.)
- Valid expiry dates (always in future)
- Valid CVV patterns (3-4 digits)
- Valid billing address formats

**Test Data Categories**:
```swift
enum TestCardData {
    static let validVisa = "4111111111111111"
    static let validMastercard = "5555555555554444"
    static let invalidLuhn = "4111111111111112"
    static let tooShort = "411111111111"
}

enum TestExpiryData {
    static func validFuture() -> String {
        // Returns MM/YY for current month + 12 months
    }
    static let expired = "01/20"
    static let invalidFormat = "13/25"
}
```

**Alternatives Considered**:
- Random test data generation → Rejected (leads to flaky tests)
- External test data files → Rejected (adds complexity, inline is clearer)

### 6. Coverage Measurement Strategy

**Decision**: Use Xcode's built-in code coverage tools

**Rationale**:
- Xcode coverage is already configured in CI/CD
- No additional tooling required
- Can generate coverage reports per module

**Coverage Exclusions** (per spec clarification):
- `Internal/Utilities/Mock*.swift`
- `*+PreviewHelpers.swift`
- Test files themselves

**How to Enable**:
- Test scheme → Options → Code Coverage → Gather coverage for "PrimerSDK"
- Exclude patterns in scheme settings

**Alternatives Considered**:
- Third-party coverage tools (Slather, Codecov) → May use for reporting, but Xcode is primary
- Custom coverage scripts → Rejected (Xcode native is sufficient)

---

## Recommendations

### Immediate Actions

1. **Create test file structure** matching planned directory layout
2. **Create shared test utilities** (test data constants, base test class)
3. **Extend existing mocks** for new test requirements

### Test Organization Pattern

```swift
// Base test class for CheckoutComponents tests
@available(iOS 15.0, *)
class CheckoutComponentsTestCase: XCTestCase {
    var container: ComposableContainer!

    override func setUp() async throws {
        try await super.setUp()
        let settings = PrimerSettings(/* test config */)
        container = ComposableContainer(settings: settings)
        await container.configure()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }
}
```

### Risk Mitigations

| Risk | Mitigation |
|------|------------|
| Flaky tests from async timing | Use deterministic waits, avoid real delays |
| Mock drift from production | Keep mocks minimal, test with real components when safe |
| Coverage gaps in edge cases | Explicit edge case test methods per component |
| DI container state pollution | Reset container in tearDown |

---

## Open Questions Resolved

| Question | Resolution |
|----------|------------|
| Test framework? | XCTest (native, already used) |
| Async patterns? | Native async/await with @MainActor where needed |
| Mock strategy? | Extend existing mocks, manual mocking |
| Coverage target? | 90% production code (excludes mocks/previews) |
| Test data approach? | Deterministic constants |
