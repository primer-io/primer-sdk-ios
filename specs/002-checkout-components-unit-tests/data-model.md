# Test Structure Model: CheckoutComponents Unit Test Suite

**Date**: 2025-12-23
**Branch**: `002-checkout-components-unit-tests`

## Overview

This document defines the complete test structure, mock implementations, and test data patterns for achieving 90%+ coverage of CheckoutComponents production code.

---

## Test Directory Structure

```text
Tests/
└── Primer/
    └── CheckoutComponents/
        ├── TestSupport/                      # Shared test infrastructure
        │   ├── CheckoutComponentsTestCase.swift    # Base test class
        │   ├── TestData.swift                      # Test constants & fixtures
        │   └── XCTestCase+Async.swift              # Async test helpers
        │
        ├── Mocks/                            # Test-specific mocks
        │   ├── MockHeadlessRepository.swift
        │   ├── MockCheckoutNavigator.swift
        │   ├── MockCheckoutCoordinator.swift
        │   ├── MockPaymentMethodRegistry.swift
        │   ├── MockRulesFactory.swift
        │   └── MockConfigurationService.swift
        │
        ├── Scope/                            # Scope implementation tests
        │   ├── DefaultCheckoutScopeTests.swift
        │   ├── DefaultCardFormScopeTests.swift
        │   ├── DefaultPaymentMethodSelectionScopeTests.swift
        │   ├── DefaultSelectCountryScopeTests.swift
        │   └── DefaultPayPalScopeTests.swift
        │
        ├── Validation/                       # Validation system tests
        │   ├── ValidationServiceTests.swift
        │   ├── RulesFactoryTests.swift
        │   ├── CardValidationRulesTests.swift
        │   ├── CommonValidationRulesTests.swift
        │   ├── ValidationResultCacheTests.swift
        │   └── FieldErrorTests.swift
        │
        ├── DI/                               # DI container tests
        │   ├── ContainerRegistrationTests.swift
        │   ├── ContainerResolutionTests.swift
        │   ├── RetentionPolicyTests.swift
        │   ├── FactoryPatternTests.swift
        │   └── ContainerDiagnosticsTests.swift
        │
        ├── Interactors/                      # Payment interactor tests
        │   ├── ProcessCardPaymentInteractorTests.swift
        │   ├── CardNetworkDetectionInteractorTests.swift
        │   ├── ValidateInputInteractorTests.swift
        │   ├── GetPaymentMethodsInteractorTests.swift
        │   └── ProcessPayPalPaymentInteractorTests.swift
        │
        └── Navigation/                       # Navigation system tests
            ├── CheckoutCoordinatorTests.swift
            ├── CheckoutNavigatorTests.swift
            └── CheckoutRouteTests.swift
```

---

## Mock Implementations

### 1. MockHeadlessRepository

**Purpose**: Mock the Headless SDK for payment flow testing

```swift
@available(iOS 15.0, *)
final class MockHeadlessRepository: HeadlessRepository {

    // MARK: - Configurable Behavior
    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var paymentResultToReturn: PaymentResult?
    var errorToThrow: Error?
    var networkDetectionNetworks: [CardNetwork] = []

    // MARK: - Call Tracking
    var getPaymentMethodsCallCount = 0
    var processCardPaymentCallCount = 0
    var setBillingAddressCallCount = 0
    var lastBillingAddress: BillingAddress?
    var lastCardNumber: String?
    var lastSelectedNetwork: CardNetwork?

    // MARK: - Protocol Implementation

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        getPaymentMethodsCallCount += 1
        if let error = errorToThrow { throw error }
        return paymentMethodsToReturn
    }

    func processCardPayment(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> PaymentResult {
        processCardPaymentCallCount += 1
        lastCardNumber = cardNumber
        lastSelectedNetwork = selectedNetwork
        if let error = errorToThrow { throw error }
        guard let result = paymentResultToReturn else {
            throw MockError.noResultConfigured
        }
        return result
    }

    func setBillingAddress(_ billingAddress: BillingAddress) async throws {
        setBillingAddressCallCount += 1
        lastBillingAddress = billingAddress
        if let error = errorToThrow { throw error }
    }

    func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]> {
        AsyncStream { continuation in
            continuation.yield(networkDetectionNetworks)
            continuation.finish()
        }
    }

    func updateCardNumberInRawDataManager(_ cardNumber: String) async {
        lastCardNumber = cardNumber
    }

    func selectCardNetwork(_ cardNetwork: CardNetwork) async {
        lastSelectedNetwork = cardNetwork
    }

    // MARK: - Test Helpers

    func reset() {
        paymentMethodsToReturn = []
        paymentResultToReturn = nil
        errorToThrow = nil
        networkDetectionNetworks = []
        getPaymentMethodsCallCount = 0
        processCardPaymentCallCount = 0
        setBillingAddressCallCount = 0
        lastBillingAddress = nil
        lastCardNumber = nil
        lastSelectedNetwork = nil
    }
}
```

### 2. MockCheckoutCoordinator

**Purpose**: Mock navigation coordinator for scope and flow testing

```swift
@available(iOS 15.0, *)
@MainActor
final class MockCheckoutCoordinator: ObservableObject {

    // MARK: - Published Properties (matching real coordinator)
    @Published var navigationStack: [CheckoutRoute] = []

    // MARK: - Call Tracking
    var navigateCallCount = 0
    var goBackCallCount = 0
    var dismissCallCount = 0
    var lastNavigatedRoute: CheckoutRoute?
    var lastError: PrimerError?

    // MARK: - Computed Properties
    var currentRoute: CheckoutRoute {
        navigationStack.last ?? .splash
    }

    // MARK: - Navigation Methods

    func navigate(to route: CheckoutRoute) {
        navigateCallCount += 1
        lastNavigatedRoute = route
        navigationStack.append(route)
    }

    func goBack() {
        goBackCallCount += 1
        if !navigationStack.isEmpty {
            navigationStack.removeLast()
        }
    }

    func dismiss() {
        dismissCallCount += 1
        navigationStack = []
    }

    func handlePaymentFailure(_ error: PrimerError) {
        lastError = error
        navigate(to: .failure(error))
    }

    // MARK: - Test Helpers

    func reset() {
        navigationStack = []
        navigateCallCount = 0
        goBackCallCount = 0
        dismissCallCount = 0
        lastNavigatedRoute = nil
        lastError = nil
    }
}
```

### 3. MockCheckoutNavigator

**Purpose**: Mock navigation event stream for observer testing

```swift
@available(iOS 15.0, *)
final class MockCheckoutNavigator {

    // MARK: - Properties
    private var continuation: AsyncStream<NavigationEvent>.Continuation?
    var navigationEvents: AsyncStream<NavigationEvent>

    // MARK: - Call Tracking
    var publishedEvents: [NavigationEvent] = []

    // MARK: - Initialization

    init() {
        var capturedContinuation: AsyncStream<NavigationEvent>.Continuation?
        navigationEvents = AsyncStream { continuation in
            capturedContinuation = continuation
        }
        self.continuation = capturedContinuation
    }

    // MARK: - Event Publishing

    func publish(_ event: NavigationEvent) {
        publishedEvents.append(event)
        continuation?.yield(event)
    }

    func finish() {
        continuation?.finish()
    }

    // MARK: - Test Helpers

    func reset() {
        publishedEvents = []
    }
}
```

### 4. MockRulesFactory

**Purpose**: Mock validation rule creation for testing validation service

```swift
@available(iOS 15.0, *)
final class MockRulesFactory: RulesFactory {

    // MARK: - Configurable Rules
    var cardNumberRule: (any ValidationRule)?
    var expiryDateRule: (any ValidationRule)?
    var cvvRule: (any ValidationRule)?
    var cardholderNameRule: (any ValidationRule)?

    // MARK: - Call Tracking
    var createCardNumberRuleCallCount = 0
    var createExpiryDateRuleCallCount = 0
    var createCVVRuleCallCount = 0

    // MARK: - Factory Methods

    func createCardNumberRule(allowedCardNetworks: [CardNetwork]?) -> any ValidationRule {
        createCardNumberRuleCallCount += 1
        return cardNumberRule ?? AlwaysValidRule()
    }

    func createExpiryDateRule() -> any ValidationRule {
        createExpiryDateRuleCallCount += 1
        return expiryDateRule ?? AlwaysValidRule()
    }

    func createCVVRule(cardNetwork: CardNetwork) -> any ValidationRule {
        createCVVRuleCallCount += 1
        return cvvRule ?? AlwaysValidRule()
    }

    func createCardholderNameRule() -> any ValidationRule {
        return cardholderNameRule ?? AlwaysValidRule()
    }

    // ... other factory methods with similar patterns
}

// Helper rule for testing
struct AlwaysValidRule: ValidationRule {
    typealias Input = String
    func validate(_ input: String) -> ValidationResult { .valid }
}

struct AlwaysInvalidRule: ValidationRule {
    typealias Input = String
    let errorCode: String
    let errorMessage: String
    func validate(_ input: String) -> ValidationResult {
        .invalid(code: errorCode, message: errorMessage)
    }
}
```

### 5. MockConfigurationService

**Purpose**: Mock SDK configuration for initialization testing

```swift
@available(iOS 15.0, *)
final class MockConfigurationService {

    // MARK: - Configurable State
    var isConfigured = false
    var clientToken: String?
    var configurationError: Error?

    // MARK: - Call Tracking
    var configureCallCount = 0
    var resetCallCount = 0

    // MARK: - Methods

    func configure(clientToken: String) async throws {
        configureCallCount += 1
        if let error = configurationError { throw error }
        self.clientToken = clientToken
        isConfigured = true
    }

    func reset() {
        resetCallCount += 1
        isConfigured = false
        clientToken = nil
    }
}
```

---

## Test Data Constants

### TestData.swift

```swift
@available(iOS 15.0, *)
enum TestData {

    // MARK: - Card Numbers
    enum CardNumbers {
        static let validVisa = "4111111111111111"
        static let validMastercard = "5555555555554444"
        static let validAmex = "378282246310005"
        static let invalidLuhn = "4111111111111112"
        static let tooShort = "411111111111"
        static let tooLong = "41111111111111111111"
        static let withSpaces = "4111 1111 1111 1111"
        static let withDashes = "4111-1111-1111-1111"
        static let empty = ""
        static let nonNumeric = "411111111111111a"
    }

    // MARK: - Expiry Dates
    enum ExpiryDates {
        static var validFuture: (month: String, year: String) {
            let calendar = Calendar.current
            let futureDate = calendar.date(byAdding: .year, value: 1, to: Date())!
            let month = calendar.component(.month, from: futureDate)
            let year = calendar.component(.year, from: futureDate) % 100
            return (String(format: "%02d", month), String(format: "%02d", year))
        }
        static let expired = (month: "01", year: "20")
        static let invalidMonth = (month: "13", year: "25")
        static let invalidFormat = (month: "1", year: "5")
        static let currentMonth: (month: String, year: String) = {
            let calendar = Calendar.current
            let month = calendar.component(.month, from: Date())
            let year = calendar.component(.year, from: Date()) % 100
            return (String(format: "%02d", month), String(format: "%02d", year))
        }()
    }

    // MARK: - CVV
    enum CVV {
        static let valid3Digit = "123"
        static let valid4Digit = "1234" // For Amex
        static let tooShort = "12"
        static let tooLong = "12345"
        static let nonNumeric = "12a"
        static let empty = ""
    }

    // MARK: - Cardholder Names
    enum CardholderNames {
        static let valid = "John Doe"
        static let validWithMiddle = "John Michael Doe"
        static let validSingleName = "Madonna"
        static let empty = ""
        static let tooLong = String(repeating: "A", count: 300)
        static let withNumbers = "John123 Doe"
        static let withSpecialChars = "Jöhn-O'Brien"
    }

    // MARK: - Billing Address
    enum BillingAddresses {
        static let validUS = BillingAddress(
            firstName: "John",
            lastName: "Doe",
            addressLine1: "123 Main St",
            addressLine2: "Apt 4B",
            city: "New York",
            state: "NY",
            countryCode: "US",
            postalCode: "10001"
        )

        static let validUK = BillingAddress(
            firstName: "Jane",
            lastName: "Smith",
            addressLine1: "10 Downing Street",
            addressLine2: nil,
            city: "London",
            state: nil,
            countryCode: "GB",
            postalCode: "SW1A 2AA"
        )

        static let minimal = BillingAddress(
            firstName: nil,
            lastName: nil,
            addressLine1: "123 Main St",
            addressLine2: nil,
            city: "City",
            state: nil,
            countryCode: "US",
            postalCode: "12345"
        )
    }

    // MARK: - Payment Methods
    enum PaymentMethods {
        static func card(type: PrimerPaymentMethodType = .paymentCard) -> InternalPaymentMethod {
            InternalPaymentMethod(
                type: type,
                name: "Card",
                displayName: "Credit/Debit Card",
                isEnabled: true
            )
        }

        static let paypal = InternalPaymentMethod(
            type: .payPal,
            name: "PayPal",
            displayName: "PayPal",
            isEnabled: true
        )

        static let applePay = InternalPaymentMethod(
            type: .applePay,
            name: "Apple Pay",
            displayName: "Apple Pay",
            isEnabled: true
        )
    }

    // MARK: - Payment Results
    enum PaymentResults {
        static let success = PaymentResult(
            paymentId: "pay_test_123",
            status: .success
        )

        static let pending = PaymentResult(
            paymentId: "pay_test_456",
            status: .pending
        )
    }

    // MARK: - Errors
    enum Errors {
        static let networkError = NSError(
            domain: "TestDomain",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Network error"]
        )

        static let validationError = PrimerError.validationFailed(
            message: "Validation failed",
            userInfo: nil,
            diagnosticsId: "test-diag-123"
        )
    }

    // MARK: - Client Tokens
    enum ClientTokens {
        static let valid = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.test"
        static let expired = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.expired"
        static let invalid = "not-a-valid-token"
    }
}
```

---

## Base Test Class

### CheckoutComponentsTestCase.swift

```swift
import XCTest
@testable import PrimerSDK

/// Base test class for all CheckoutComponents unit tests.
/// Provides common setup/teardown and shared utilities.
@available(iOS 15.0, *)
class CheckoutComponentsTestCase: XCTestCase {

    // MARK: - Properties

    var container: ComposableContainer!
    var mockHeadlessRepository: MockHeadlessRepository!
    var mockValidationService: MockValidationService!

    // MARK: - Default Settings

    var testSettings: PrimerSettings {
        PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
    }

    // MARK: - Lifecycle

    override func setUp() async throws {
        try await super.setUp()

        // Create fresh mocks
        mockHeadlessRepository = MockHeadlessRepository()
        mockValidationService = MockValidationService()

        // Configure container with test settings
        container = ComposableContainer(settings: testSettings)
        await container.configure()
    }

    override func tearDown() async throws {
        // Clean up
        mockHeadlessRepository?.reset()
        mockValidationService = nil
        container = nil

        try await super.tearDown()
    }

    // MARK: - Utilities

    /// Resolves a dependency from the current container
    func resolve<T>(_ type: T.Type) async throws -> T {
        guard let currentContainer = await DIContainer.current else {
            throw TestError.containerNotAvailable
        }
        return try await currentContainer.resolve(type)
    }

    /// Creates a configured ComposableContainer with custom settings
    func createContainer(settings: PrimerSettings) async -> ComposableContainer {
        let container = ComposableContainer(settings: settings)
        await container.configure()
        return container
    }

    /// Waits for async stream to emit a value
    func awaitFirst<T>(_ stream: AsyncStream<T>, timeout: TimeInterval = 1.0) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                for await value in stream {
                    return value
                }
                throw TestError.streamDidNotEmit
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw TestError.timeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Test Errors

enum TestError: Error, LocalizedError {
    case containerNotAvailable
    case streamDidNotEmit
    case timeout
    case mockNotConfigured

    var errorDescription: String? {
        switch self {
        case .containerNotAvailable: return "DI Container not available"
        case .streamDidNotEmit: return "AsyncStream did not emit a value"
        case .timeout: return "Operation timed out"
        case .mockNotConfigured: return "Mock not properly configured"
        }
    }
}

enum MockError: Error {
    case noResultConfigured
    case simulatedError(String)
}
```

---

## Test Categories & Coverage Targets

| Category | Files | Target Coverage | Priority |
|----------|-------|-----------------|----------|
| Scope Implementations | 5 test files | 90% | P1 |
| Validation System | 6 test files | 95% | P1 |
| DI Container | 5 test files | 90% | P2 |
| Payment Interactors | 5 test files | 90% | P2 |
| Navigation System | 3 test files | 85% | P3 |

**Total**: 24 test files + 6 support files = **30 files**

---

## Existing Assets to Leverage

### From `Internal/Utilities/` (already exist)

| File | Purpose | Extend/Use As-Is |
|------|---------|------------------|
| `MockCardFormScope.swift` | Card form scope mock | Use as-is |
| `MockDIContainer.swift` | Basic DI container mock | Extend for tests |
| `MockDesignTokens.swift` | Design token mock | Use as-is |
| `MockValidationService.swift` | Validation service mock | Extend for tests |

### From Existing Tests (already exist)

| File | Patterns to Follow |
|------|-------------------|
| `AccessibilityDIContainerTests.swift` | Async setUp/tearDown, DI resolution |
| `AccessibilityConfigurationTests.swift` | Configuration testing patterns |
| `HeadlessRepositorySettingsTests.swift` | Repository testing patterns |

---

## Dependencies Between Test Categories

```
┌─────────────────────────────────────────────────────────┐
│                    TestSupport/                         │
│  (CheckoutComponentsTestCase, TestData, Mocks)         │
└─────────────────────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         ▼                ▼                ▼
   ┌──────────┐    ┌───────────┐    ┌────────────┐
   │Validation│    │    DI     │    │ Navigation │
   │  Tests   │    │  Tests    │    │   Tests    │
   └──────────┘    └───────────┘    └────────────┘
         │                │                │
         └────────────────┼────────────────┘
                          ▼
                   ┌────────────┐
                   │   Scope    │
                   │   Tests    │
                   └────────────┘
                          │
                          ▼
                   ┌────────────┐
                   │ Interactor │
                   │   Tests    │
                   └────────────┘
```

**Recommended Implementation Order**:
1. TestSupport (base class, test data, mocks)
2. Validation Tests (standalone, foundational)
3. DI Container Tests (extend existing)
4. Navigation Tests (standalone)
5. Scope Tests (depends on DI, validation)
6. Interactor Tests (depends on all above)
