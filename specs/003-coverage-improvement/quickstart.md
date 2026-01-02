# Developer Guide: CheckoutComponents Coverage Improvement

**Feature**: 003-coverage-improvement
**Date**: 2025-12-24
**For**: Developers implementing unit tests to improve coverage

## Overview

This guide helps you add unit tests to improve CheckoutComponents coverage from 18.96% to 90%. All test infrastructure from Spec 002 is already in place—this work focuses on adding tests for untested production code.

---

## Quick Start

### 1. Run Coverage Analysis

```bash
# Run tests with coverage enabled
xcodebuild test \
  -project "Debug App/Primer.io Debug App SPM.xcodeproj" \
  -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -enableCodeCoverage YES \
  -resultBundlePath TestResults.xcresult

# View coverage report
xcrun xccov view --report TestResults.xcresult | \
  grep "Sources/PrimerSDK/Classes/CheckoutComponents"
```

### 2. Identify Uncovered Code

```bash
# Show line-by-line coverage for a specific file
xcrun xccov view --file HeadlessRepositoryImpl.swift TestResults.xcresult
```

### 3. Create Test File

Follow this pattern from Spec 002:

```swift
import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
@MainActor
final class HeadlessRepositoryImplTests: XCTestCase {

    // MARK: - Properties

    private var sut: HeadlessRepositoryImpl!
    private var mockNetworkService: MockNetworkService!

    // MARK: - Setup

    override func setUp() async throws {
        try await super.setUp()

        mockNetworkService = MockNetworkService()
        sut = HeadlessRepositoryImpl(networkService: mockNetworkService)
    }

    override func tearDown() async throws {
        sut = nil
        mockNetworkService = nil

        try await super.tearDown()
    }

    // MARK: - Tests

    func test_getPaymentMethods_withValidResponse_returnsPaymentMethods() async throws {
        // Given
        mockNetworkService.responseToReturn = TestData.APIResponses.validPaymentMethods

        // When
        let paymentMethods = try await sut.getPaymentMethods()

        // Then
        XCTAssertEqual(paymentMethods.count, 1)
        XCTAssertEqual(paymentMethods[0].type, "PAYMENT_CARD")
        XCTAssertEqual(mockNetworkService.requestCallCount, 1)
    }

    func test_getPaymentMethods_withNetworkError_throwsError() async throws {
        // Given
        mockNetworkService.errorToThrow = TestData.Errors.networkTimeout

        // When/Then
        do {
            _ = try await sut.getPaymentMethods()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}
```

---

## Test Structure Pattern

### Standard Test Structure

```swift
// 1. Arrange (Given)
let mockRepo = MockHeadlessRepository()
mockRepo.paymentMethodsToReturn = [TestData.PaymentMethods.validCard]

// 2. Act (When)
let result = try await sut.fetchPaymentMethods()

// 3. Assert (Then)
XCTAssertEqual(result.count, 1)
XCTAssertEqual(mockRepo.fetchCallCount, 1)
```

### Async/Await Pattern

```swift
func test_asyncOperation_succeeds() async throws {
    // Given
    let expectation = XCTestExpectation(description: "Async operation")

    // When
    let result = try await sut.performAsyncOperation()
    expectation.fulfill()

    // Then
    await fulfillment(of: [expectation], timeout: 1.0)
    XCTAssertNotNil(result)
}
```

### Error Testing Pattern

```swift
func test_operation_withError_throwsExpectedError() async throws {
    // Given
    mockService.errorToThrow = PrimerError.validationError("Invalid input")

    // When/Then
    do {
        _ = try await sut.performOperation()
        XCTFail("Expected error to be thrown")
    } catch let error as PrimerError {
        XCTAssertEqual(error.errorCode, "validation-error")
    }
}
```

---

## Creating Mock Objects

### Protocol-Based Mock Pattern

```swift
@available(iOS 15.0, *)
final class MockHeadlessRepository: HeadlessRepository {

    // MARK: - Configurable Returns

    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var errorToThrow: Error?

    // MARK: - Call Tracking

    var getPaymentMethodsCallCount = 0
    var lastRequestParameters: RequestParameters?

    // MARK: - Protocol Implementation

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        getPaymentMethodsCallCount += 1

        if let error = errorToThrow {
            throw error
        }

        return paymentMethodsToReturn
    }

    // MARK: - Reset

    func reset() {
        paymentMethodsToReturn = []
        errorToThrow = nil
        getPaymentMethodsCallCount = 0
        lastRequestParameters = nil
    }
}
```

### Using Existing Mocks

Extend existing mocks from Spec 002:

```swift
// Already available:
- MockHeadlessRepository
- MockValidationService
- MockConfigurationService
- MockAnalyticsInteractor
- MockNavigator (if not deleted)

// Use them:
let mockRepo = MockHeadlessRepository()
mockRepo.paymentMethodsToReturn = TestData.PaymentMethods.all
```

---

## Test Data Fixtures

### Using TestData.swift

```swift
extension TestData {
    enum APIResponses {
        static let validPaymentMethods = MockAPIResponse(
            json: """
            {
                "paymentMethods": [
                    {
                        "type": "PAYMENT_CARD",
                        "name": "Card",
                        "supportedCardNetworks": ["VISA", "MASTERCARD"]
                    }
                ]
            }
            """,
            statusCode: 200,
            headers: ["Content-Type": "application/json"]
        )

        static let emptyPaymentMethods = MockAPIResponse(
            json: """
            {
                "paymentMethods": []
            }
            """,
            statusCode: 200,
            headers: ["Content-Type": "application/json"]
        )
    }

    enum Errors {
        static let networkTimeout = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
        )

        static let invalidCardNumber = PrimerError.validationError(
            message: "Invalid card number",
            userInfo: ["field": "cardNumber"]
        )
    }
}
```

### Reusable Test Data

```swift
// Card numbers (already in TestData.swift)
TestData.CardNumbers.validVisa
TestData.CardNumbers.validMastercard
TestData.CardNumbers.invalidChecksum

// Expiry dates
TestData.ExpiryDates.valid
TestData.ExpiryDates.expired
TestData.ExpiryDates.future

// CVV
TestData.CVV.valid3Digit
TestData.CVV.valid4Digit
TestData.CVV.invalid
```

---

## Coverage by Layer

### Data Layer (Target: 16.82% → 90%)

**Files to Test**:
- `HeadlessRepositoryImpl.swift`
- `PayPalRepositoryImpl.swift`
- `ConfigurationRepository.swift`
- `PaymentMethodMapper.swift`
- `ErrorMapper.swift`

**Example Test**:
```swift
func test_paymentMethodMapper_mapsAPIResponseCorrectly() throws {
    // Given
    let apiResponse = TestData.APIResponses.validPaymentMethods
    let mapper = PaymentMethodMapper()

    // When
    let result = try mapper.map(apiResponse)

    // Then
    XCTAssertEqual(result.type, .card)
    XCTAssertEqual(result.supportedNetworks, [.visa, .mastercard])
}
```

### Payment Layer (Target: 13.17% → 90%)

**Files to Test**:
- `ProcessCardPaymentInteractor.swift`
- `ThreeDSHandler.swift`
- `TokenizationService.swift`
- `SurchargeCalculator.swift`

**Example Test**:
```swift
func test_processPayment_with3DSRequired_executes3DSFlow() async throws {
    // Given
    let mock3DS = Mock3DSHandler()
    mock3DS.flowToReturn = TestData.ThreeDSFlows.challengeRequired
    let sut = ProcessCardPaymentInteractor(threeDSHandler: mock3DS)

    // When
    let result = try await sut.processPayment(cardData: TestData.CardNumbers.validVisa)

    // Then
    XCTAssertTrue(result.threeDSRequired)
    XCTAssertEqual(mock3DS.executeChallengeCallCount, 1)
}
```

### Quick Wins (Complete Near-Finished Areas)

**Navigation (88.52% → 90%)**:
- Test edge cases: back navigation, route deduplication

**Validation (72.14% → 90%)**:
- Test edge cases: billing address validation, expiry date edge cases

**Core (70.23% → 90%)**:
- Test error paths: CheckoutSDKInitializer, SettingsObserver

**DI Container (56.90% → 90%)**:
- Test: factory registration, async resolution, retention policies

---

## Common Patterns

### Testing Async Operations

```swift
func test_asyncOperation_withDelay_completesSuccessfully() async throws {
    // Given
    let startTime = Date()

    // When
    try await sut.operationWithDelay(seconds: 0.1)

    // Then
    let elapsed = Date().timeIntervalSince(startTime)
    XCTAssertGreaterThan(elapsed, 0.1)
}
```

### Testing Error Propagation

```swift
func test_repository_propagatesNetworkError() async throws {
    // Given
    mockNetworkService.errorToThrow = TestData.Errors.networkTimeout

    // When
    do {
        _ = try await sut.fetchData()
        XCTFail("Expected error to be thrown")
    } catch let error as NSError {
        // Then
        XCTAssertEqual(error.domain, NSURLErrorDomain)
        XCTAssertEqual(error.code, NSURLErrorTimedOut)
    }
}
```

### Testing State Transitions

```swift
func test_paymentFlow_transitionsCorrectly() async throws {
    // Given
    var states: [PaymentState] = []
    sut.onStateChange = { states.append($0) }

    // When
    try await sut.processPayment()

    // Then
    XCTAssertEqual(states, [.idle, .processing, .completed])
}
```

---

## Best Practices

### DO

✅ **Test behavior, not implementation**
```swift
// Good - tests behavior
func test_validation_rejectsExpiredCard() {
    let result = validator.validate(expiry: "01/20")
    XCTAssertFalse(result.isValid)
}

// Bad - tests implementation detail
func test_validation_callsDateComparison() {
    validator.validate(expiry: "01/20")
    XCTAssertEqual(validator.dateComparisonCallCount, 1)
}
```

✅ **Use descriptive test names**
```swift
// Good
func test_getPaymentMethods_withEmptyResponse_returnsEmptyArray()

// Bad
func testGetPaymentMethods()
```

✅ **Test edge cases**
```swift
func test_cardNumberFormatter_withMaxLength_truncatesCorrectly()
func test_validation_withNilInput_throwsError()
func test_mapper_withMalformedJSON_throwsDecodingError()
```

✅ **Verify call counts**
```swift
XCTAssertEqual(mockRepo.fetchCallCount, 1)
XCTAssertEqual(mockAnalytics.trackEventCallCount, 2)
```

### DON'T

❌ **Don't test private methods directly**
```swift
// Bad - testing private method
func test_privateHelperMethod() {
    let result = sut.perform(#selector(privateMethod))
}

// Good - test through public API
func test_publicMethod_usesHelperCorrectly() {
    let result = sut.publicMethod()
    XCTAssertEqual(result, expectedValue)
}
```

❌ **Don't make tests dependent on each other**
```swift
// Bad - tests have shared state
var sharedData: [String] = []

func test_first() {
    sharedData.append("data")
}

func test_second() {
    XCTAssertEqual(sharedData.count, 1) // Depends on test_first
}

// Good - each test is independent
func test_first() {
    var data: [String] = []
    data.append("data")
    XCTAssertEqual(data.count, 1)
}
```

❌ **Don't skip error paths**
```swift
// Bad - only tests happy path
func test_operation_succeeds() {
    let result = try! sut.operation()
    XCTAssertNotNil(result)
}

// Good - also tests error path
func test_operation_withInvalidInput_throwsError() async throws {
    do {
        _ = try await sut.operation()
        XCTFail("Expected error")
    } catch {
        XCTAssertNotNil(error)
    }
}
```

---

## Running Tests

### Run All Tests

```bash
xcodebuild test \
  -project "Debug App/Primer.io Debug App SPM.xcodeproj" \
  -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'
```

### Run Specific Test File

```bash
xcodebuild test \
  -project "Debug App/Primer.io Debug App SPM.xcodeproj" \
  -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -only-testing:PrimerSDKTests/HeadlessRepositoryImplTests
```

### Run Single Test

```bash
xcodebuild test \
  -project "Debug App/Primer.io Debug App SPM.xcodeproj" \
  -scheme PrimerSDKTests \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2' \
  -only-testing:PrimerSDKTests/HeadlessRepositoryImplTests/test_getPaymentMethods_succeeds
```

---

## Debugging Failed Tests

### Enable Verbose Logging

```swift
override func setUp() async throws {
    try await super.setUp()

    // Enable debug logging
    PrimerSettings.enableDebugLogs = true
}
```

### Print Network Requests

```swift
func test_repository_sendsCorrectRequest() async throws {
    // Given
    mockNetworkService.onRequest = { request in
        print("Request URL: \(request.url)")
        print("Request Body: \(request.httpBody)")
    }

    // When
    _ = try await sut.fetchData()
}
```

### Use Breakpoints

```swift
func test_complexFlow_executesCorrectly() async throws {
    let result = try await sut.complexOperation()

    // Set breakpoint here to inspect result
    XCTAssertNotNil(result)
}
```

---

## Tracking Progress

### After Each Phase

```bash
# Run coverage
xcodebuild test -enableCodeCoverage YES ...

# View results
xcrun xccov view --report TestResults.xcresult | \
  grep "CheckoutComponents" | \
  awk '{print $4}' | \
  sort -rn
```

### Coverage Targets by Phase

- **Phase 1 (Quick Wins)**: 22.58%
- **Phase 2 (Data Layer)**: 27.89%
- **Phase 3 (Payment Layer)**: 32.87%
- **Phase 4 (Scope & Utilities)**: 51.53%
- **Phase 6 (Presentation)**: 90.00% (optional)

---

## Resources

- **Spec 002 Tests**: `/Users/onurvar/Projects/primer-sdk-ios/Tests/Primer/CheckoutComponents/`
- **Existing Mocks**: `/Users/onurvar/Projects/primer-sdk-ios/Tests/Primer/CheckoutComponents/Mocks/`
- **Test Data**: `/Users/onurvar/Projects/primer-sdk-ios/Tests/Primer/CheckoutComponents/TestSupport/TestData.swift`
- **Coverage Report**: `TestResults.xcresult` (regenerate after test runs)

---

## Next Steps

1. Choose a module from Phase 1-4 based on priority
2. Identify uncovered code paths using coverage report
3. Create test file following patterns in this guide
4. Run tests and verify coverage improvement
5. Repeat until phase target achieved
6. Move to next phase

**Questions?** Refer to [research.md](./research.md) for decisions or [plan.md](./plan.md) for implementation strategy.
