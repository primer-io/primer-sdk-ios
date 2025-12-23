# Quickstart Guide: CheckoutComponents Unit Test Suite

**Date**: 2025-12-23
**Branch**: `002-checkout-components-unit-tests`

## Overview

This guide provides step-by-step instructions for implementing the CheckoutComponents unit test suite. Follow these patterns and examples to create consistent, maintainable tests.

---

## Quick Setup

### 1. Create Base Test Infrastructure

First, create the test support files in `Tests/Primer/CheckoutComponents/TestSupport/`:

```swift
// Tests/Primer/CheckoutComponents/TestSupport/CheckoutComponentsTestCase.swift
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

### 2. Create Mock Files

Add mocks to `Tests/Primer/CheckoutComponents/Mocks/`:

```swift
// Tests/Primer/CheckoutComponents/Mocks/MockHeadlessRepository.swift
@available(iOS 15.0, *)
final class MockHeadlessRepository: HeadlessRepository {
    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var errorToThrow: Error?

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        if let error = errorToThrow { throw error }
        return paymentMethodsToReturn
    }
    // ... implement other protocol methods
}
```

---

## Test Patterns

### Pattern 1: Testing Scope State Transitions

```swift
@available(iOS 15.0, *)
final class DefaultCheckoutScopeTests: CheckoutComponentsTestCase {

    func test_initialization_transitionsToReadyState() async throws {
        // Given
        let scope = try await createCheckoutScope()

        // When
        var states: [PrimerCheckoutState] = []
        for await state in scope.state.prefix(2) {
            states.append(state)
        }

        // Then
        XCTAssertEqual(states.count, 2)
        XCTAssertEqual(states[0], .initializing)
        XCTAssertEqual(states[1], .ready)
    }

    private func createCheckoutScope() async throws -> DefaultCheckoutScope {
        // Setup scope with mocked dependencies
        let mockRepo = MockHeadlessRepository()
        mockRepo.paymentMethodsToReturn = [TestData.PaymentMethods.card()]
        return DefaultCheckoutScope(repository: mockRepo)
    }
}
```

### Pattern 2: Testing Validation Rules

```swift
@available(iOS 15.0, *)
final class CardValidationRulesTests: XCTestCase {

    var sut: DefaultValidationService!

    override func setUp() {
        super.setUp()
        sut = DefaultValidationService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Card Number Tests

    func test_validateCardNumber_withValidVisa_returnsValid() {
        // Given
        let cardNumber = TestData.CardNumbers.validVisa

        // When
        let result = sut.validateCardNumber(cardNumber)

        // Then
        XCTAssertTrue(result.isValid)
        XCTAssertNil(result.errorMessage)
    }

    func test_validateCardNumber_withInvalidLuhn_returnsInvalid() {
        // Given
        let cardNumber = TestData.CardNumbers.invalidLuhn

        // When
        let result = sut.validateCardNumber(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
        XCTAssertNotNil(result.errorCode)
    }

    func test_validateCardNumber_withEmpty_returnsInvalid() {
        // Given
        let cardNumber = TestData.CardNumbers.empty

        // When
        let result = sut.validateCardNumber(cardNumber)

        // Then
        XCTAssertFalse(result.isValid)
    }

    // MARK: - CVV Tests

    func test_validateCVV_withValid3DigitForVisa_returnsValid() {
        // Given
        let cvv = TestData.CVV.valid3Digit

        // When
        let result = sut.validateCVV(cvv, cardNetwork: .visa)

        // Then
        XCTAssertTrue(result.isValid)
    }

    func test_validateCVV_with3DigitForAmex_returnsInvalid() {
        // Given
        let cvv = TestData.CVV.valid3Digit // Amex requires 4 digits

        // When
        let result = sut.validateCVV(cvv, cardNetwork: .amex)

        // Then
        XCTAssertFalse(result.isValid)
    }
}
```

### Pattern 3: Testing DI Container Resolution

```swift
@available(iOS 15.0, *)
final class ContainerResolutionTests: CheckoutComponentsTestCase {

    func test_resolve_registeredService_returnsInstance() async throws {
        // Given
        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When
        let service = try await container.resolve(ValidationService.self)

        // Then
        XCTAssertNotNil(service)
        XCTAssertTrue(service is DefaultValidationService)
    }

    func test_resolve_singleton_returnsSameInstance() async throws {
        // Given
        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When
        let service1 = try await container.resolve(SomeSingletonService.self)
        let service2 = try await container.resolve(SomeSingletonService.self)

        // Then
        XCTAssertTrue(service1 === service2)
    }

    func test_resolve_transient_returnsDifferentInstances() async throws {
        // Given
        guard let container = await DIContainer.current else {
            XCTFail("Container should be configured")
            return
        }

        // When
        let service1 = try await container.resolve(SomeTransientService.self)
        let service2 = try await container.resolve(SomeTransientService.self)

        // Then
        XCTAssertFalse(service1 === service2)
    }
}
```

### Pattern 4: Testing Navigation Coordinator

```swift
@available(iOS 15.0, *)
final class CheckoutCoordinatorTests: XCTestCase {

    var sut: CheckoutCoordinator!

    @MainActor
    override func setUp() {
        super.setUp()
        sut = CheckoutCoordinator()
    }

    @MainActor
    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    @MainActor
    func test_navigate_toPaymentSelection_appendsToStack() {
        // Given
        XCTAssertEqual(sut.navigationStack.count, 0)

        // When
        sut.navigate(to: .paymentSelection)

        // Then
        XCTAssertEqual(sut.navigationStack.count, 1)
        XCTAssertEqual(sut.currentRoute, .paymentSelection)
    }

    @MainActor
    func test_goBack_removesLastRoute() {
        // Given
        sut.navigate(to: .paymentSelection)
        sut.navigate(to: .paymentMethod(.paymentCard))
        XCTAssertEqual(sut.navigationStack.count, 2)

        // When
        sut.goBack()

        // Then
        XCTAssertEqual(sut.navigationStack.count, 1)
        XCTAssertEqual(sut.currentRoute, .paymentSelection)
    }

    @MainActor
    func test_navigate_toSameRoute_doesNotDuplicate() {
        // Given
        sut.navigate(to: .paymentSelection)
        XCTAssertEqual(sut.navigationStack.count, 1)

        // When
        sut.navigate(to: .paymentSelection)

        // Then
        XCTAssertEqual(sut.navigationStack.count, 1, "Should not duplicate route")
    }

    @MainActor
    func test_dismiss_clearsNavigationStack() {
        // Given
        sut.navigate(to: .paymentSelection)
        sut.navigate(to: .paymentMethod(.paymentCard))

        // When
        sut.dismiss()

        // Then
        XCTAssertTrue(sut.navigationStack.isEmpty)
    }
}
```

### Pattern 5: Testing Payment Interactors

```swift
@available(iOS 15.0, *)
final class ProcessCardPaymentInteractorTests: CheckoutComponentsTestCase {

    var sut: ProcessCardPaymentInteractor!
    var mockRepository: MockHeadlessRepository!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockHeadlessRepository()
        sut = ProcessCardPaymentInteractor(repository: mockRepository)
    }

    func test_execute_withValidCard_returnsSuccessResult() async throws {
        // Given
        let expectedResult = TestData.PaymentResults.success
        mockRepository.paymentResultToReturn = expectedResult

        // When
        let result = try await sut.execute(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: TestData.CVV.valid3Digit,
            expiryMonth: TestData.ExpiryDates.validFuture.month,
            expiryYear: TestData.ExpiryDates.validFuture.year,
            cardholderName: TestData.CardholderNames.valid,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(result.paymentId, expectedResult.paymentId)
        XCTAssertEqual(mockRepository.processCardPaymentCallCount, 1)
    }

    func test_execute_whenRepositoryThrows_propagatesError() async {
        // Given
        mockRepository.errorToThrow = TestData.Errors.networkError

        // When/Then
        do {
            _ = try await sut.execute(
                cardNumber: TestData.CardNumbers.validVisa,
                cvv: TestData.CVV.valid3Digit,
                expiryMonth: TestData.ExpiryDates.validFuture.month,
                expiryYear: TestData.ExpiryDates.validFuture.year,
                cardholderName: TestData.CardholderNames.valid,
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }
}
```

---

## Testing Async Streams

### Helper Extension

```swift
// Tests/Primer/CheckoutComponents/TestSupport/XCTestCase+Async.swift
extension XCTestCase {

    /// Collects values from an AsyncStream up to a limit or timeout
    func collect<T>(
        _ stream: AsyncStream<T>,
        count: Int,
        timeout: TimeInterval = 2.0
    ) async throws -> [T] {
        var values: [T] = []

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                for await value in stream {
                    values.append(value)
                    if values.count >= count {
                        return
                    }
                }
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }

            _ = try await group.next()
            group.cancelAll()
        }

        return values
    }
}
```

### Usage

```swift
func test_stateStream_emitsExpectedStates() async throws {
    // Given
    let scope = try await createScope()

    // When
    let states = try await collect(scope.state, count: 3)

    // Then
    XCTAssertEqual(states[0], .initializing)
    XCTAssertEqual(states[1], .ready)
    // etc.
}
```

---

## Coverage Measurement

### Enable Coverage in Xcode

1. Edit Scheme → Test → Options
2. Check "Gather coverage for: PrimerSDK"
3. Add exclusion patterns:
   - `**/Mock*.swift`
   - `**/*+PreviewHelpers.swift`
   - `**/Internal/Utilities/Mock*.swift`

### Run Tests with Coverage

```bash
# Command line
xcodebuild test \
  -scheme "PrimerSDK" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=18.4" \
  -enableCodeCoverage YES

# View coverage report
xcrun xccov view --report Build/Logs/Test/*.xcresult
```

---

## Naming Conventions

### Test Class Names
```
{ComponentUnderTest}Tests.swift

Examples:
- ValidationServiceTests.swift
- DefaultCheckoutScopeTests.swift
- CheckoutCoordinatorTests.swift
```

### Test Method Names
```
test_{scenario}_{expectedResult}

Examples:
- test_validateCardNumber_withValidVisa_returnsValid()
- test_navigate_toPaymentSelection_appendsToStack()
- test_resolve_singleton_returnsSameInstance()
```

### Test Data
```
TestData.{Category}.{item}

Examples:
- TestData.CardNumbers.validVisa
- TestData.ExpiryDates.validFuture
- TestData.PaymentResults.success
```

---

## Common Pitfalls to Avoid

| Pitfall | Solution |
|---------|----------|
| Forgetting `@MainActor` for coordinator tests | Add annotation to class or individual methods |
| Not resetting mocks between tests | Use setUp/tearDown to reset state |
| Hardcoding expiry dates | Use `TestData.ExpiryDates.validFuture` computed property |
| Testing private implementation details | Test behavior through public APIs |
| Flaky async tests | Use proper async/await patterns, avoid real delays |
| Not awaiting container resolution | Always `await` when resolving from DI container |

---

## Checklist: Before Creating a Test

- [ ] Does the test have a clear Given/When/Then structure?
- [ ] Are all mocks properly configured in setUp?
- [ ] Are all mocks reset in tearDown?
- [ ] Is the test deterministic (no random data, no real network)?
- [ ] Does the test name clearly describe the scenario and expected result?
- [ ] Are edge cases covered (empty input, nil values, errors)?
- [ ] Is `@available(iOS 15.0, *)` annotation present?
- [ ] For async tests: Is `async throws` signature used?
- [ ] For MainActor tests: Is `@MainActor` annotation present?

---

## Next Steps

1. **Create TestSupport files** (base class, test data, helpers)
2. **Create Mock files** (one per major dependency)
3. **Implement Validation tests** (highest value, standalone)
4. **Implement DI tests** (extend existing patterns)
5. **Implement Navigation tests** (simple, isolated)
6. **Implement Scope tests** (integration of above)
7. **Implement Interactor tests** (full flow testing)
8. **Verify 90% coverage** via Xcode coverage report
