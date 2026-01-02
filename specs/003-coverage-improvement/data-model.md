# Data Model: Test Data Entities

**Feature**: 003-coverage-improvement
**Date**: 2025-12-24

## Overview

This document defines the test data entities used in CheckoutComponents coverage improvement. Unlike typical data models for production features, this describes **test doubles, fixtures, and mock data structures** used to test CheckoutComponents production code.

---

## Test Data Entities

### 1. Mock API Response

**Purpose**: Represents mocked JSON responses from Primer backend APIs

**Structure**:
```swift
struct MockAPIResponse {
    let json: String
    let statusCode: Int
    let headers: [String: String]
}
```

**Variants**:
- **Valid Payment Methods Response**: List of payment methods with full configuration
- **Empty Payment Methods Response**: Empty array (edge case)
- **Malformed JSON**: Invalid JSON to test error handling
- **Merchant Config Response**: Merchant settings and theme configuration
- **Error Response**: API error with error code and message

**Usage**: Configure MockHeadlessRepository to return specific responses

**Example**:
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

        static let malformedJSON = MockAPIResponse(
            json: "{invalid json}",
            statusCode: 200,
            headers: ["Content-Type": "application/json"]
        )
    }
}
```

---

### 2. Test Coverage Report

**Purpose**: Represents coverage metrics for tracking progress

**Structure**:
```swift
struct TestCoverageReport {
    let module: String
    let coveredLines: Int
    let totalLines: Int
    let percentage: Double
    let uncoveredRanges: [LineRange]
}

struct LineRange {
    let start: Int
    let end: Int
}
```

**Modules Tracked**:
- Data (Repositories, Mappers)
- Payment (Interactors, 3DS handlers)
- Validation (Rules, Service)
- Navigation (Coordinator, Navigator)
- Core (Services, Initializers)
- DI (Container, Retention policies)
- Scope (Implementations)
- Presentation (UI components - optional)

**Usage**: Parse output from `xcrun xccov view --report TestResults.xcresult`

**Example**:
```swift
let dataLayerCoverage = TestCoverageReport(
    module: "Data",
    coveredLines: 220,
    totalLines: 1308,
    percentage: 16.82,
    uncoveredRanges: [
        LineRange(start: 45, end: 78),
        LineRange(start: 123, end: 156)
    ]
)
```

---

### 3. Mock 3DS Flow

**Purpose**: Test double for 3D Secure challenge scenarios

**Structure**:
```swift
struct Mock3DSFlow {
    let transactionId: String
    let acsTransactionId: String
    let acsReferenceNumber: String
    let acsSignedContent: String?
    let challengeRequired: Bool
    let outcome: ThreeDSOutcome
}

enum ThreeDSOutcome {
    case success
    case failure(String)
    case cancelled
    case timeout
}
```

**Variants**:
- **Challenge Required**: User must complete 3DS challenge
- **Frictionless**: 3DS completed without user interaction
- **Failed**: 3DS authentication failed
- **Cancelled**: User cancelled 3DS challenge
- **Timeout**: 3DS challenge timed out

**Usage**: Configure Mock3DSHandler to return specific outcomes

**Example**:
```swift
extension TestData {
    enum ThreeDSFlows {
        static let challengeRequired = Mock3DSFlow(
            transactionId: "test-tx-123",
            acsTransactionId: "test-acs-456",
            acsReferenceNumber: "test-ref-789",
            acsSignedContent: "signed-content",
            challengeRequired: true,
            outcome: .success
        )

        static let frictionless = Mock3DSFlow(
            transactionId: "test-tx-123",
            acsTransactionId: "test-acs-456",
            acsReferenceNumber: "test-ref-789",
            acsSignedContent: nil,
            challengeRequired: false,
            outcome: .success
        )

        static let failed = Mock3DSFlow(
            transactionId: "test-tx-123",
            acsTransactionId: "test-acs-456",
            acsReferenceNumber: "test-ref-789",
            acsSignedContent: "signed-content",
            challengeRequired: true,
            outcome: .failure("Authentication failed")
        )
    }
}
```

---

### 4. Payment Result Fixture

**Purpose**: Represents payment processing outcomes

**Structure**:
```swift
struct PaymentResultFixture {
    let status: PaymentStatus
    let transactionId: String?
    let error: PrimerError?
    let threeDSRequired: Bool
    let surchargeAmount: Int?
}

enum PaymentStatus {
    case success
    case failure
    case pending
    case cancelled
}
```

**Variants**:
- **Success**: Payment completed successfully
- **Failure**: Payment failed (declined, network error, validation error)
- **3DS Required**: Payment requires 3DS challenge
- **Cancelled**: User cancelled payment
- **Pending**: Payment awaiting confirmation

**Usage**: Configure MockPaymentProcessor return values

**Example**:
```swift
extension TestData {
    enum PaymentResults {
        static let success = PaymentResultFixture(
            status: .success,
            transactionId: "test-payment-123",
            error: nil,
            threeDSRequired: false,
            surchargeAmount: nil
        )

        static let threeDSRequired = PaymentResultFixture(
            status: .pending,
            transactionId: "test-payment-123",
            error: nil,
            threeDSRequired: true,
            surchargeAmount: nil
        )

        static let declined = PaymentResultFixture(
            status: .failure,
            transactionId: nil,
            error: PrimerError.paymentDeclined("Insufficient funds"),
            threeDSRequired: false,
            surchargeAmount: nil
        )
    }
}
```

---

### 5. Mock Network Response

**Purpose**: Configurable HTTP response for testing network layer

**Structure**:
```swift
struct MockNetworkResponse {
    let data: Data?
    let urlResponse: HTTPURLResponse?
    let error: Error?
    let delay: TimeInterval
}
```

**Variants**:
- **Success**: Valid data + 200 status code
- **Client Error**: 400/401/403/404 status codes
- **Server Error**: 500/502/503 status codes
- **Network Timeout**: Simulate connection timeout
- **No Connection**: Simulate offline state

**Usage**: Configure MockURLSession for testing repository network calls

**Example**:
```swift
extension TestData {
    enum NetworkResponses {
        static let success200 = MockNetworkResponse(
            data: APIResponses.validPaymentMethods.json.data(using: .utf8),
            urlResponse: HTTPURLResponse(
                url: URL(string: "https://api.primer.io/test")!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            ),
            error: nil,
            delay: 0
        )

        static let timeout = MockNetworkResponse(
            data: nil,
            urlResponse: nil,
            error: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorTimedOut,
                userInfo: nil
            ),
            delay: 0
        )
    }
}
```

---

### 6. Error Fixtures

**Purpose**: Standard error cases for testing error handling

**Structure**:
```swift
enum ErrorFixtures {
    case network(NSError)
    case validation(PrimerError)
    case payment(PrimerError)
    case configuration(PrimerError)
    case threeds(Primer3DSError)
}
```

**Categories**:
- **Network Errors**: Timeout, no connection, DNS failure
- **Validation Errors**: Invalid card number, expired card, invalid CVV
- **Payment Errors**: Payment declined, insufficient funds, fraud check
- **Configuration Errors**: Invalid merchant config, missing API key
- **3DS Errors**: 3DS initialization failed, challenge timeout, cancelled

**Usage**: Test error propagation and error handling paths

**Example**:
```swift
extension TestData {
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

        static let paymentDeclined = PrimerError.paymentDeclined(
            "Payment declined by issuer"
        )
    }
}
```

---

## Test Data Relationships

```
TestData (Root)
├── APIResponses
│   ├── validPaymentMethods
│   ├── emptyPaymentMethods
│   └── malformedJSON
├── PaymentResults
│   ├── success
│   ├── threeDSRequired
│   └── declined
├── ThreeDSFlows
│   ├── challengeRequired
│   ├── frictionless
│   └── failed
├── NetworkResponses
│   ├── success200
│   ├── timeout
│   └── noConnection
└── Errors
    ├── networkTimeout
    ├── invalidCardNumber
    └── paymentDeclined
```

---

## Validation Rules

**Test Data Must**:
- Be deterministic (same input = same output)
- Cover happy path + edge cases + error cases
- Be reusable across multiple test files
- Follow naming convention: `Test Data.Category.variant`
- Include comments explaining when to use each variant

**Test Data Must NOT**:
- Contain real PII or payment card data
- Make network calls (all mocked)
- Have side effects
- Depend on external state

---

## Usage Examples

### Testing Repository with Mock API Response

```swift
func test_fetchPaymentMethods_withValidResponse_mapsCorrectly() async throws {
    // Given
    let mockRepo = MockHeadlessRepository()
    mockRepo.apiResponseToReturn = TestData.APIResponses.validPaymentMethods

    // When
    let paymentMethods = try await mockRepo.getPaymentMethods()

    // Then
    XCTAssertEqual(paymentMethods.count, 1)
    XCTAssertEqual(paymentMethods[0].type, "PAYMENT_CARD")
}
```

### Testing Payment Flow with 3DS

```swift
func test_processPayment_when3DSRequired_executesChallenge() async throws {
    // Given
    let mock3DS = Mock3DSHandler()
    mock3DS.flowToReturn = TestData.ThreeDSFlows.challengeRequired
    let interactor = ProcessCardPaymentInteractor(threeDSHandler: mock3DS)

    // When
    let result = try await interactor.processPayment(cardData: TestData.CardNumbers.validVisa)

    // Then
    XCTAssertTrue(result.threeDSRequired)
    XCTAssertEqual(mock3DS.executeChallengeCallCount, 1)
}
```

---

## Next Steps

1. Extend existing `TestData.swift` with new categories
2. Create mock objects that consume these fixtures
3. Use in test implementations across all phases
4. Update as new test scenarios discovered
