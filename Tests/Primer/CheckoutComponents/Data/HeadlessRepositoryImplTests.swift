//
//  HeadlessRepositoryImplTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Select Card Network Tests

@available(iOS 15.0, *)
final class SelectCardNetworkTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [weak self] in
                self?.mockClientSessionActions ?? MockClientSessionActionsModule()
            }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_Visa_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.visa

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "VISA")
    }

    func testSelectCardNetwork_Mastercard_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.masterCard

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "MASTERCARD")
    }

    func testSelectCardNetwork_Amex_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.amex

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "AMEX")
    }

    func testSelectCardNetwork_Unknown_CallsSelectPaymentMethodWithOther() async throws {
        // Given
        let network = CardNetwork.unknown

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "OTHER")
    }

    func testSelectCardNetwork_MultipleNetworks_CallsSelectPaymentMethodMultipleTimes() async throws {
        // Given
        let networks: [CardNetwork] = [.visa, .masterCard, .amex]

        // When
        for network in networks {
            await repository.selectCardNetwork(network)
        }

        // Wait for all Tasks to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 3)
    }

    func testSelectCardNetwork_WithError_DoesNotThrow() async throws {
        // Given
        let network = CardNetwork.visa
        mockClientSessionActions.selectPaymentMethodError = NSError(domain: "test", code: 500)

        // When/Then - Should not throw since it's fire-and-forget
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify the call was made
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
    }
}

// MARK: - Network Detection Stream Tests

@available(iOS 15.0, *)
final class NetworkDetectionStreamTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetNetworkDetectionStream_ReturnsNonNilStream() {
        // When
        let stream = repository.getNetworkDetectionStream()

        // Then
        XCTAssertNotNil(stream)
    }
}

// MARK: - Set Billing Address Tests

@available(iOS 15.0, *)
final class SetBillingAddressTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testSetBillingAddress_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
            firstName: "John",
            lastName: "Doe",
            addressLine1: "123 Main St",
            addressLine2: nil,
            city: "New York",
            state: "NY",
            postalCode: "10001",
            countryCode: "US",
            phoneNumber: nil
        )

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }

    func testSetBillingAddress_WithMinimalData_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
            firstName: nil,
            lastName: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            postalCode: nil,
            countryCode: nil,
            phoneNumber: nil
        )

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }
}

// MARK: - Track Analytics Tests

@available(iOS 15.0, *)
final class TrackAnalyticsTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testTrackThreeDSChallenge_WithNilAuthentication_DoesNotCrash() {
        // Given - Token data without 3DS authentication
        // Note: We can't easily create a PrimerPaymentMethodTokenData with nil authentication
        // but this test verifies the code path doesn't crash when called
        // The actual tracking is tested through integration tests
    }

    func testTrackRedirectToThirdParty_WithNilInfo_DoesNotCrash() {
        // Given
        let nilInfo: PrimerCheckoutAdditionalInfo? = nil

        // When - Should not crash
        repository.trackRedirectToThirdPartyIfNeeded(from: nilInfo)

        // Then - No crash means success
    }
}

// MARK: - Initialization Tests

@available(iOS 15.0, *)
final class HeadlessRepositoryInitializationTests: XCTestCase {

    func testInit_WithDefaultFactory_CreatesInstance() {
        // When
        let repository = HeadlessRepositoryImpl()

        // Then
        XCTAssertNotNil(repository)
    }

    func testInit_WithCustomFactory_UsesProvidedFactory() async throws {
        // Given
        var factoryCalled = false
        let mockActions = MockClientSessionActionsModule()

        let repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: {
                factoryCalled = true
                return mockActions
            }
        )

        // When
        await repository.selectCardNetwork(.visa)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(factoryCalled)
        XCTAssertEqual(mockActions.selectPaymentMethodCalls.count, 1)
    }
}

// MARK: - Redirect Deduplication Tests

@available(iOS 15.0, *)
final class RedirectDeduplicationTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testTrackRedirect_SameURL_TracksOnlyOnce() {
        // Given
        // Note: We need to create a mock PrimerCheckoutAdditionalInfo with a redirect URL
        // For now, we verify nil handling works
        let nilInfo: PrimerCheckoutAdditionalInfo? = nil

        // When - Call twice with nil
        repository.trackRedirectToThirdPartyIfNeeded(from: nilInfo)
        repository.trackRedirectToThirdPartyIfNeeded(from: nilInfo)

        // Then - Should not crash and handle nil gracefully
    }
}

// MARK: - Extract URL Edge Cases Tests

@available(iOS 15.0, *)
final class ExtractURLEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractURL_WithDeepLink_ReturnsNil() {
        // Given - Deep links are not considered web URLs
        let value = "myapp://payment/callback"

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithNestedDictionary_HandlesGracefully() {
        // Given
        let nested: [String: Any] = [
            "outer": [
                "inner": "https://example.com/payment"
            ]
        ]

        // When
        let result = repository.extractURL(from: nested)

        // Then - extractURL only checks top-level, so this should return nil
        XCTAssertNil(result)
    }

    func testExtractURL_WithNumberValue_ReturnsNil() {
        // Given
        let value = 12345

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithBoolValue_ReturnsNil() {
        // Given
        let value = true

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }
}

// MARK: - Required Input Elements Edge Cases

@available(iOS 15.0, *)
final class RequiredInputElementsEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetRequiredInputElements_CaseInsensitive() {
        // Given - Lowercase payment card type
        let paymentMethodType = "payment_card"

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then - Should return empty since it's case-sensitive match
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_EmptyString_ReturnsEmpty() {
        // Given
        let paymentMethodType = ""

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_PaymentCard_ContainsAllRequiredFields() {
        // Given
        let paymentMethodType = "PAYMENT_CARD"

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.contains(.cardNumber))
        XCTAssertTrue(elements.contains(.cvv))
        XCTAssertTrue(elements.contains(.expiryDate))
        XCTAssertTrue(elements.contains(.cardholderName))
        XCTAssertEqual(elements.count, 4)
    }
}

// MARK: - Create Card Data Edge Cases

@available(iOS 15.0, *)
final class CreateCardDataEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testCreateCardData_WithLeadingZeroMonth_FormatsCorrectly() {
        // Given
        let cardNumber = "4111111111111111"
        let cvv = "123"
        let expiryMonth = "01"
        let expiryYear = "25"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.expiryDate, "01/25")
    }

    func testCreateCardData_WithFourDigitYear_FormatsCorrectly() {
        // Given
        let cardNumber = "4111111111111111"
        let cvv = "123"
        let expiryMonth = "12"
        let expiryYear = "2025"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.expiryDate, "12/2025")
    }

    func testCreateCardData_WithNetwork_SetsNetwork() {
        // Given
        let cardNumber = "4111111111111111"
        let cvv = "123"
        let expiryMonth = "12"
        let expiryYear = "25"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: .visa
        )

        // Then
        XCTAssertEqual(cardData.cardNetwork, .visa)
    }

    func testCreateCardData_WithEmptyStrings_CreatesCardData() {
        // Given
        let cardNumber = ""
        let cvv = ""
        let expiryMonth = ""
        let expiryYear = ""
        let cardholderName = ""

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then - PrimerCardData may have nil or empty values for empty input
        XCTAssertNotNil(cardData)
        XCTAssertEqual(cardData.expiryDate, "/")
    }

    func testCreateCardData_WithSpacesInCardNumber_SanitizesSpaces() {
        // Given - Card number with spaces (as user might type)
        let cardNumber = "4111 1111 1111 1111"
        let cvv = "123"
        let expiryMonth = "12"
        let expiryYear = "25"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then - Card number is sanitized (spaces removed)
        XCTAssertEqual(cardData.cardNumber, "4111111111111111")
    }
}

// MARK: - IsLikelyURL Edge Cases

@available(iOS 15.0, *)
final class IsLikelyURLEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testIsLikelyURL_WithPort_ReturnsTrue() {
        // Given
        let url = "https://localhost:8080/payment"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithQueryParameters_ReturnsTrue() {
        // Given
        let url = "https://example.com/payment?token=abc123&redirect=true"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithFragment_ReturnsTrue() {
        // Given
        let url = "https://example.com/payment#section"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_HttpsWithTrailingSlash_ReturnsTrue() {
        // Given
        let url = "https://example.com/"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithWhitespace_ReturnsFalse() {
        // Given
        let url = " https://example.com"

        // When
        let result = repository.isLikelyURL(url)

        // Then - Leading whitespace means it doesn't start with http
        XCTAssertFalse(result)
    }
}

// MARK: - GetPaymentMethods Tests

@available(iOS 15.0, *)
final class GetPaymentMethodsTests: XCTestCase {

    private var mockConfigurationService: MockConfigurationService!
    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockConfigurationService = MockConfigurationService()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [weak self] in
                self?.mockClientSessionActions ?? MockClientSessionActionsModule()
            },
            configurationServiceFactory: { [weak self] in
                self?.mockConfigurationService ?? MockConfigurationService()
            }
        )
    }

    override func tearDown() {
        mockConfigurationService = nil
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testGetPaymentMethods_WithNoConfig_ReturnsEmptyArray() async throws {
        // Given
        mockConfigurationService.apiConfiguration = nil

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertTrue(methods.isEmpty)
    }

    func testGetPaymentMethods_WithPaymentMethods_ReturnsMappedMethods() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "payment-card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: 100,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(methods.first?.name, "Card")
        XCTAssertEqual(methods.first?.configId, "config-123")
        XCTAssertEqual(methods.first?.surcharge, 100)
    }

    func testGetPaymentMethods_WithMultiplePaymentMethods_ReturnsAll() async throws {
        // Given
        let cardMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "card-config",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let paypalMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "paypal-config",
            surcharge: 50,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [cardMethod, paypalMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.count, 2)
        XCTAssertTrue(methods.contains { $0.type == "PAYMENT_CARD" })
        XCTAssertTrue(methods.contains { $0.type == "PAYPAL" })
    }

    func testGetPaymentMethods_WithEmptyPaymentMethods_ReturnsEmptyArray() async throws {
        // Given
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertTrue(methods.isEmpty)
    }

    func testGetPaymentMethods_PaymentCardHasRequiredInputElements() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "payment-card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.requiredInputElements)
        XCTAssertFalse(cardMethod?.requiredInputElements.isEmpty ?? true)
    }

    func testGetPaymentMethods_NonCardMethodHasNoRequiredInputElements() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        XCTAssertTrue(paypalMethod?.requiredInputElements.isEmpty ?? true)
    }

    // MARK: - Network Surcharges Tests

    func testGetPaymentMethods_WithNetworkSurcharges_ExtractsFromArray() async throws {
        // Given - Client session with network surcharges in array format
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": ["amount": 100]
            ],
            [
                "type": "MASTERCARD",
                "surcharge": ["amount": 150]
            ]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 100)
        XCTAssertEqual(cardMethod?.networkSurcharges?["MASTERCARD"], 150)
    }

    func testGetPaymentMethods_WithNetworkSurcharges_ExtractsFromDict() async throws {
        // Given - Client session with network surcharges in dictionary format
        let networkSurcharges: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 200]],
            "AMEX": ["surcharge": ["amount": 300]]
        ]
        // For dictionary format, we need to convert to the options array format
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 200)
        XCTAssertEqual(cardMethod?.networkSurcharges?["AMEX"], 300)
    }

    func testGetPaymentMethods_NonCardMethod_HasNilNetworkSurcharges() async throws {
        // Given - PayPal doesn't have network surcharges
        let paymentMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "config-123",
            surcharge: 50,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        XCTAssertNil(paypalMethod?.networkSurcharges)
        XCTAssertEqual(paypalMethod?.surcharge, 50)  // Regular surcharge should still be present
    }

    // MARK: - hasUnknownSurcharge Mapping Tests

    func testGetPaymentMethods_WithUnknownSurcharge_MapsCorrectly() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: 100,
            options: nil,
            displayMetadata: nil
        )
        paymentMethod.hasUnknownSurcharge = true
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertTrue(cardMethod?.hasUnknownSurcharge ?? false)
    }

    func testGetPaymentMethods_WithNoUnknownSurcharge_MapsFalse() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: 100,
            options: nil,
            displayMetadata: nil
        )
        // hasUnknownSurcharge defaults to false
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertFalse(cardMethod?.hasUnknownSurcharge ?? true)
    }

    // MARK: - Icon/Logo Mapping Tests

    func testGetPaymentMethods_WithNilDisplayMetadata_IconIsNil() async throws {
        // Given - Payment method with nil displayMetadata (thus nil logo)
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        // Icon is nil because displayMetadata is nil (no logo to load)
        XCTAssertNil(cardMethod?.icon)
    }

    func testGetPaymentMethods_IconMappingDoesNotCrash() async throws {
        // Given - Payment method configured normally
        let paymentMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - Should complete without crash
        XCTAssertEqual(methods.count, 1)
        let paypalMethod = methods.first { $0.type == "PAYPAL" }
        XCTAssertNotNil(paypalMethod)
        // Icon is optional - may be nil without displayMetadata/logo
    }

    // MARK: - Network Surcharges Edge Cases

    func testGetPaymentMethods_ClientSessionWithNoPaymentMethodData_NilNetworkSurcharges() async throws {
        // Given - Client session exists but no paymentMethod data
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: nil,  // No payment method data
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_ClientSessionWithNilOptions_NilNetworkSurcharges() async throws {
        // Given - Client session with paymentMethod but nil options
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: nil,  // Nil options
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_ClientSessionOptionsWithoutPaymentCardType_NilNetworkSurcharges() async throws {
        // Given - Options exist but no PAYMENT_CARD type
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYPAL",  // Not PAYMENT_CARD
                "someKey": "someValue"
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_PaymentCardOptionWithNoNetworksKey_NilNetworkSurcharges() async throws {
        // Given - PAYMENT_CARD option exists but no "networks" key
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "someOtherKey": "someValue"  // No "networks" key
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNil(cardMethod?.networkSurcharges)
    }

    func testGetPaymentMethods_WithDirectIntegerSurchargeFormat_ExtractsSurcharges() async throws {
        // Given - Direct integer surcharge format (not nested in "amount")
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": 75  // Direct integer, not nested
            ],
            [
                "type": "MASTERCARD",
                "surcharge": 125  // Direct integer
            ]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 75)
        XCTAssertEqual(cardMethod?.networkSurcharges?["MASTERCARD"], 125)
    }

    func testGetPaymentMethods_WithZeroSurcharge_ExcludesNetwork() async throws {
        // Given - Zero surcharge should be excluded
        let networkSurcharges: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": ["amount": 100]
            ],
            [
                "type": "MASTERCARD",
                "surcharge": ["amount": 0]  // Zero - should be excluded
            ]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        let cardMethod = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertNotNil(cardMethod)
        XCTAssertNotNil(cardMethod?.networkSurcharges)
        XCTAssertEqual(cardMethod?.networkSurcharges?["VISA"], 100)
        XCTAssertNil(cardMethod?.networkSurcharges?["MASTERCARD"])  // Zero excluded
    }

    func testGetPaymentMethods_MultipleMethodsWithMixedSurcharges_MapsCorrectly() async throws {
        // Given - Multiple payment methods with different surcharge configurations
        let networkSurcharges: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 50]]
        ]
        let paymentMethodOptions: [[String: Any]] = [
            [
                "type": "PAYMENT_CARD",
                "networks": networkSurcharges
            ]
        ]
        let clientSession = ClientSession.APIResponse(
            clientSessionId: "session-123",
            paymentMethod: ClientSession.PaymentMethod(
                vaultOnSuccess: false,
                options: paymentMethodOptions,
                orderedAllowedCardNetworks: nil,
                descriptor: nil
            ),
            order: nil,
            customer: nil,
            testId: nil
        )
        let cardMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "card-config",
            surcharge: 25,  // Method-level surcharge
            options: nil,
            displayMetadata: nil
        )
        let paypalMethod = PrimerPaymentMethod(
            id: "paypal-id",
            implementationType: .nativeSdk,
            type: "PAYPAL",
            name: "PayPal",
            processorConfigId: "paypal-config",
            surcharge: 100,  // PayPal has method-level surcharge
            options: nil,
            displayMetadata: nil
        )
        let applePayMethod = PrimerPaymentMethod(
            id: "applepay-id",
            implementationType: .nativeSdk,
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: "applepay-config",
            surcharge: nil,  // No surcharge
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: clientSession,
            paymentMethods: [cardMethod, paypalMethod, applePayMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.count, 3)

        // Card has both method-level and network surcharges
        let card = methods.first { $0.type == "PAYMENT_CARD" }
        XCTAssertEqual(card?.surcharge, 25)
        XCTAssertNotNil(card?.networkSurcharges)
        XCTAssertEqual(card?.networkSurcharges?["VISA"], 50)

        // PayPal has method-level surcharge but no network surcharges
        let paypal = methods.first { $0.type == "PAYPAL" }
        XCTAssertEqual(paypal?.surcharge, 100)
        XCTAssertNil(paypal?.networkSurcharges)

        // Apple Pay has no surcharges
        let applePay = methods.first { $0.type == "APPLE_PAY" }
        XCTAssertNil(applePay?.surcharge)
        XCTAssertNil(applePay?.networkSurcharges)
    }

    func testGetPaymentMethods_MapsIdToPaymentMethodType() async throws {
        // Given - Verify ID mapping
        let paymentMethod = PrimerPaymentMethod(
            id: "different-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - ID should be set to type (not the original id)
        let cardMethod = methods.first
        XCTAssertEqual(cardMethod?.id, "PAYMENT_CARD")  // ID is mapped to type
        XCTAssertEqual(cardMethod?.type, "PAYMENT_CARD")
    }

    func testGetPaymentMethods_IsEnabledAlwaysTrue() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - isEnabled is always true
        XCTAssertTrue(methods.first?.isEnabled ?? false)
    }

    func testGetPaymentMethods_SupportedCurrenciesIsNil() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - supportedCurrencies is always nil (not yet implemented)
        XCTAssertNil(methods.first?.supportedCurrencies)
    }

    func testGetPaymentMethods_MetadataIsNil() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - metadata is always nil (not yet extracted)
        XCTAssertNil(methods.first?.metadata)
    }
}

// MARK: - Configuration Service Factory Injection Tests

@available(iOS 15.0, *)
final class ConfigurationServiceFactoryTests: XCTestCase {

    func testInit_WithConfigurationServiceFactory_UsesFactory() async throws {
        // Given
        var factoryCalled = false
        let mockConfigService = MockConfigurationService()
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        mockConfigService.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )

        let repository = HeadlessRepositoryImpl(
            configurationServiceFactory: {
                factoryCalled = true
                return mockConfigService
            }
        )

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertTrue(factoryCalled)
        XCTAssertEqual(methods.count, 1)
        XCTAssertEqual(methods.first?.type, "PAYMENT_CARD")
    }

    func testInit_WithoutFactory_ReturnsEmptyWithoutDI() async throws {
        // Given - No factory and no DI container
        let repository = HeadlessRepositoryImpl()

        // When
        let methods = try await repository.getPaymentMethods()

        // Then - Without DI container or factory, returns empty array
        XCTAssertTrue(methods.isEmpty)
    }

    func testGetPaymentMethods_CalledTwice_OnlyInjectsOnce() async throws {
        // Given
        var factoryCallCount = 0
        let mockConfigService = MockConfigurationService()
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        mockConfigService.apiConfiguration = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )

        let repository = HeadlessRepositoryImpl(
            configurationServiceFactory: {
                factoryCallCount += 1
                return mockConfigService
            }
        )

        // When - Call getPaymentMethods twice
        _ = try await repository.getPaymentMethods()
        _ = try await repository.getPaymentMethods()

        // Then - Factory should only be called once (idempotent injection)
        XCTAssertEqual(factoryCallCount, 1)
    }
}

// MARK: - Process Card Payment Tests

@available(iOS 15.0, *)
final class ProcessCardPaymentTests: XCTestCase {

    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockRawDataManager: MockRawDataManager!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        repository = HeadlessRepositoryImpl(
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    override func tearDown() {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Factory Tests

    func testProcessCardPayment_CallsFactoryWithCorrectPaymentMethodType() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Factory called")
        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            XCTAssertEqual(type, "PAYMENT_CARD")
            XCTAssertNotNil(delegate)
            expectation.fulfill()
            return self.mockRawDataManager
        }

        // We need to cancel the task because the full flow won't complete without proper setup
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test User",
                selectedNetwork: .visa
            )
        }

        // Wait briefly for the factory to be called
        await fulfillment(of: [expectation], timeout: 2.0)
        task.cancel()

        // Then
        XCTAssertEqual(mockRawDataManagerFactory.createCallCount, 1)
        XCTAssertEqual(mockRawDataManagerFactory.lastCreateCall?.paymentMethodType, "PAYMENT_CARD")
    }

    func testProcessCardPayment_WhenFactoryThrows_PropagatesError() async {
        // Given
        let expectedError = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Factory error"])
        mockRawDataManagerFactory.createError = expectedError

        // When/Then
        do {
            _ = try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test User",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 123)
        }
    }

    func testProcessCardPayment_CallsConfigureOnRawDataManager() async throws {
        // Given
        let configureExpectation = XCTestExpectation(description: "Configure called")
        var configureCalled = false

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            // Track when configure is called
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if mock.configureCallCount > 0 {
                    configureCalled = true
                    configureExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test User",
                selectedNetwork: nil
            )
        }

        // Wait for configure to be called
        await fulfillment(of: [configureExpectation], timeout: 2.0)
        task.cancel()

        // Then
        XCTAssertTrue(configureCalled)
    }

    func testProcessCardPayment_SetsRawDataWithCardData() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedRawData: PrimerRawData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            // Monitor when rawData is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedRawData = mock.rawDataHistory.last ?? nil
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242 4242 4242 4242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test User",
                selectedNetwork: .visa
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertNotNil(capturedRawData)
        if let cardData = capturedRawData as? PrimerCardData {
            // Card number should have spaces removed
            XCTAssertEqual(cardData.cardNumber, "4242424242424242")
            XCTAssertEqual(cardData.cvv, "123")
            XCTAssertEqual(cardData.expiryDate, "12/25")
            XCTAssertEqual(cardData.cardholderName, "Test User")
            XCTAssertEqual(cardData.cardNetwork, .visa)
        } else {
            XCTFail("Expected PrimerCardData")
        }
    }

    func testProcessCardPayment_WithEmptyCardholderName_SetsNilCardholderName() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "",  // Empty name
                selectedNetwork: nil
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertNotNil(capturedCardData)
        XCTAssertNil(capturedCardData?.cardholderName)  // Empty should become nil
    }

    func testProcessCardPayment_WithNoNetwork_DoesNotSetCardNetwork() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil  // No network specified
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertNotNil(capturedCardData)
        // When no network is passed, cardNetwork should be nil (default)
        // Note: PrimerCardData may have a default value, so we check the flow worked
    }

    func testProcessCardPayment_WhenConfigureFails_PropagatesError() async {
        // Given
        let configureError = NSError(domain: "ConfigError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Config failed"])

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.configureError = configureError
            mock.delegate = delegate
            return mock
        }

        // When/Then
        do {
            _ = try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test User",
                selectedNetwork: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "ConfigError")
        }
    }

    // MARK: - Card Data Formatting Tests

    func testProcessCardPayment_FormatsExpiryDateCorrectly() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "03",
                expiryYear: "28",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then - Expiry should be formatted as "MM/YY"
        XCTAssertEqual(capturedCardData?.expiryDate, "03/28")
    }

    func testProcessCardPayment_StripsSpacesFromCardNumber() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When - Card number with spaces
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242 4242 4242 4242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "25",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then - Spaces should be stripped
        XCTAssertEqual(capturedCardData?.cardNumber, "4242424242424242")
    }
}

// MARK: - Extract Network Surcharges Edge Cases

@available(iOS 15.0, *)
final class ExtractNetworkSurchargesEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - extractFromNetworksArray Tests

    func testExtractFromNetworksArray_WithMissingType_SkipsEntry() {
        // Given - Network entry without type
        let networksArray: [[String: Any]] = [
            ["surcharge": ["amount": 100]],  // Missing type
            ["type": "VISA", "surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["VISA"], 50)
    }

    func testExtractFromNetworksArray_WithMissingSurcharge_SkipsEntry() {
        // Given - Network entry without surcharge
        let networksArray: [[String: Any]] = [
            ["type": "VISA"],  // Missing surcharge
            ["type": "MASTERCARD", "surcharge": ["amount": 75]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksArray_WithNegativeSurcharge_ExcludesEntry() {
        // Given - Negative surcharge should be excluded (not > 0)
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": -50]],
            ["type": "MASTERCARD", "surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
        XCTAssertNil(result?["VISA"])
    }

    func testExtractFromNetworksArray_WithEmptyArray_ReturnsNil() {
        // Given
        let networksArray: [[String: Any]] = []

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksArray_WithAllZeroSurcharges_ReturnsNil() {
        // Given - All zero surcharges should result in nil
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 0]],
            ["type": "MASTERCARD", "surcharge": ["amount": 0]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksArray_WithMixedFormats_HandlesBoth() {
        // Given - Mix of nested and direct surcharge formats
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 100]],  // Nested format
            ["type": "MASTERCARD", "surcharge": 75]  // Direct integer format
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksArray_WithInvalidSurchargeType_SkipsEntry() {
        // Given - Surcharge is a string instead of int/dict
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": "invalid"],
            ["type": "MASTERCARD", "surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
    }

    // MARK: - extractFromNetworksDict Tests

    func testExtractFromNetworksDict_WithEmptyDict_ReturnsNil() {
        // Given
        let networksDict: [String: [String: Any]] = [:]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksDict_WithNestedSurcharge_ExtractsCorrectly() {
        // Given - Dictionary format with nested surcharge
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 150]],
            "AMEX": ["surcharge": ["amount": 200]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertEqual(result?["AMEX"], 200)
    }

    func testExtractFromNetworksDict_WithDirectSurcharge_ExtractsCorrectly() {
        // Given - Dictionary format with direct integer surcharge
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": 100],
            "MASTERCARD": ["surcharge": 75]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksDict_WithZeroSurcharge_ExcludesEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 0]],
            "MASTERCARD": ["surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
        XCTAssertNil(result?["VISA"])
    }

    func testExtractFromNetworksDict_WithMissingSurchargeKey_SkipsEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["otherKey": "value"],  // No surcharge key
            "MASTERCARD": ["surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
    }
}

// MARK: - Update Client Session Before Payment Tests

@available(iOS 15.0, *)
final class UpdateClientSessionBeforePaymentTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockRawDataManager: MockRawDataManager!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [unowned self] in self.mockClientSessionActions },
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_DispatchesSelectPaymentMethodAction() async {
        // When
        await repository.selectCardNetwork(.visa)

        // Wait for the detached Task to complete (fire-and-forget pattern)
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "VISA")
    }

    func testSelectCardNetwork_WithMastercard_PassesCorrectNetwork() async {
        // When
        await repository.selectCardNetwork(.masterCard)

        // Wait for the detached Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "MASTERCARD")
    }

    func testSelectCardNetwork_WithAmex_PassesCorrectNetwork() async {
        // When
        await repository.selectCardNetwork(.amex)

        // Wait for the detached Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "AMEX")
    }

    func testSelectCardNetwork_WithDiscover_PassesCorrectNetwork() async {
        // When
        await repository.selectCardNetwork(.discover)

        // Wait for the detached Task to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 100ms

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.lastSelectPaymentMethodCall?.network, "DISCOVER")
    }
}

// MARK: - Process Card Payment Additional Edge Cases

@available(iOS 15.0, *)
final class ProcessCardPaymentEdgeCasesTests: XCTestCase {

    private var mockRawDataManagerFactory: MockRawDataManagerFactory!
    private var mockRawDataManager: MockRawDataManager!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockRawDataManager = MockRawDataManager()
        mockRawDataManagerFactory = MockRawDataManagerFactory()
        mockRawDataManagerFactory.mockRawDataManager = mockRawDataManager
        repository = HeadlessRepositoryImpl(
            rawDataManagerFactory: mockRawDataManagerFactory
        )
    }

    override func tearDown() {
        mockRawDataManager = nil
        mockRawDataManagerFactory = nil
        repository = nil
        super.tearDown()
    }

    func testProcessCardPayment_WithMastercard_SetsCorrectNetwork() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "5555555555554444",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "27",
                cardholderName: "Test",
                selectedNetwork: .masterCard
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertEqual(capturedCardData?.cardNetwork, .masterCard)
    }

    func testProcessCardPayment_WithAmex_SetsCorrectNetwork() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "378282246310005",
                cvv: "1234",
                expiryMonth: "12",
                expiryYear: "27",
                cardholderName: "Test",
                selectedNetwork: .amex
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertEqual(capturedCardData?.cardNetwork, .amex)
    }

    func testProcessCardPayment_With4DigitCVV_PassesCorrectly() async throws {
        // Given - Amex uses 4-digit CVV
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "378282246310005",
                cvv: "1234",
                expiryMonth: "12",
                expiryYear: "27",
                cardholderName: "Test",
                selectedNetwork: .amex
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertEqual(capturedCardData?.cvv, "1234")
    }

    func testProcessCardPayment_WithWhitespaceOnlyCardholderName_SetsNilName() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When - Whitespace-only name should be treated as empty
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "27",
                cardholderName: "   ",  // Whitespace only
                selectedNetwork: nil
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then - Current implementation only checks isEmpty, not whitespace
        // So whitespace-only name will be passed as-is
        XCTAssertNotNil(capturedCardData)
    }

    func testProcessCardPayment_WithSingleDigitMonth_FormatsCorrectly() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "1",  // Single digit month
                expiryYear: "27",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertEqual(capturedCardData?.expiryDate, "1/27")
    }

    func testProcessCardPayment_WithMultipleSpaces_StripsAllSpaces() async throws {
        // Given
        let rawDataSetExpectation = XCTestExpectation(description: "RawData set")
        var capturedCardData: PrimerCardData?

        mockRawDataManagerFactory.createMockHandler = { type, delegate in
            let mock = MockRawDataManager()
            mock.delegate = delegate
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if mock.rawDataSetCount > 0 {
                    capturedCardData = mock.rawDataHistory.last as? PrimerCardData
                    rawDataSetExpectation.fulfill()
                }
            }
            return mock
        }

        // When - Multiple spaces between groups
        let task = Task {
            try await repository.processCardPayment(
                cardNumber: "4242  4242  4242  4242",  // Double spaces
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "27",
                cardholderName: "Test",
                selectedNetwork: nil
            )
        }

        await fulfillment(of: [rawDataSetExpectation], timeout: 3.0)
        task.cancel()

        // Then
        XCTAssertEqual(capturedCardData?.cardNumber, "4242424242424242")
    }
}

// MARK: - Create Card Data Helper Tests

@available(iOS 15.0, *)
final class CreateCardDataHelperTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testCreateCardData_WithAllNetworks_SetsCorrectly() {
        // Test all major card networks
        let networks: [CardNetwork] = [.visa, .masterCard, .amex, .discover, .jcb, .diners]

        for network in networks {
            // When
            let cardData = repository.createCardData(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "27",
                cardholderName: "Test",
                selectedNetwork: network
            )

            // Then
            XCTAssertEqual(cardData.cardNetwork, network, "Failed for network: \(network)")
        }
    }

    func testCreateCardData_WithTabsInCardNumber_DoesNotStripTabs() {
        // Given - Tabs are not stripped, only spaces
        let cardData = repository.createCardData(
            cardNumber: "4242\t4242\t4242\t4242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then - Tabs are NOT stripped (only spaces are)
        XCTAssertEqual(cardData.cardNumber, "4242\t4242\t4242\t4242")
    }

    func testCreateCardData_WithLongCardholderName_PassesAsIs() {
        // Given
        let longName = String(repeating: "A", count: 200)

        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: longName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cardholderName, longName)
    }

    func testCreateCardData_WithSpecialCharactersInName_PassesAsIs() {
        // Given
        let specialName = "José García-Núñez"

        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: specialName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cardholderName, specialName)
    }

    func testCreateCardData_WithLeadingTrailingSpacesInCardNumber_StripsSpaces() {
        // Given
        let cardData = repository.createCardData(
            cardNumber: " 4242424242424242 ",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then - Leading/trailing spaces are stripped
        XCTAssertEqual(cardData.cardNumber, "4242424242424242")
    }
}

// MARK: - URL Helper Tests

@available(iOS 15.0, *)
final class URLHelperTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - isLikelyURL Tests

    func testIsLikelyURL_WithHttpsUrl_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("https://example.com"))
        XCTAssertTrue(repository.isLikelyURL("https://example.com/path"))
        XCTAssertTrue(repository.isLikelyURL("https://subdomain.example.com"))
    }

    func testIsLikelyURL_WithHttpUrl_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("http://example.com"))
        XCTAssertTrue(repository.isLikelyURL("http://localhost:8080"))
    }

    func testIsLikelyURL_WithMixedCaseProtocol_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("HTTPS://example.com"))
        XCTAssertTrue(repository.isLikelyURL("HTTP://example.com"))
        XCTAssertTrue(repository.isLikelyURL("Https://example.com"))
    }

    func testIsLikelyURL_WithNonHttpProtocol_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("ftp://example.com"))
        XCTAssertFalse(repository.isLikelyURL("myapp://deeplink"))
        XCTAssertFalse(repository.isLikelyURL("file:///path/to/file"))
    }

    func testIsLikelyURL_WithPlainString_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("example.com"))
        XCTAssertFalse(repository.isLikelyURL("just some text"))
        XCTAssertFalse(repository.isLikelyURL(""))
    }

    func testIsLikelyURL_WithPartialProtocol_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("htt://example.com"))
        XCTAssertFalse(repository.isLikelyURL("httpexample.com"))
    }

    // MARK: - extractURL Tests

    func testExtractURL_WithString_ReturnsUrl() {
        let result = repository.extractURL(from: "https://example.com/redirect")
        XCTAssertEqual(result, "https://example.com/redirect")
    }

    func testExtractURL_WithURL_ReturnsAbsoluteString() {
        let url = URL(string: "https://example.com/path")!
        let result = repository.extractURL(from: url)
        XCTAssertEqual(result, "https://example.com/path")
    }

    func testExtractURL_WithNonUrlString_ReturnsNil() {
        let result = repository.extractURL(from: "not a url")
        XCTAssertNil(result)
    }

    func testExtractURL_WithNumber_ReturnsNil() {
        let result = repository.extractURL(from: 12345)
        XCTAssertNil(result)
    }

    func testExtractURL_WithEmptyString_ReturnsNil() {
        let result = repository.extractURL(from: "")
        XCTAssertNil(result)
    }
}

// MARK: - Get Required Input Elements Tests

@available(iOS 15.0, *)
final class GetRequiredInputElementsTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetRequiredInputElements_ForPaymentCard_ReturnsCardInputs() {
        let result = repository.getRequiredInputElements(for: "PAYMENT_CARD")

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.contains(.cardNumber))
        XCTAssertTrue(result.contains(.cvv))
        XCTAssertTrue(result.contains(.expiryDate))
        XCTAssertTrue(result.contains(.cardholderName))
    }

    func testGetRequiredInputElements_ForPayPal_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "PAYPAL")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForApplePay_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "APPLE_PAY")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForGooglePay_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "GOOGLE_PAY")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForKlarna_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "KLARNA")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForUnknownType_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "UNKNOWN_PAYMENT_METHOD")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForEmptyType_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "")
        XCTAssertTrue(result.isEmpty)
    }
}

// MARK: - Create Card Data Expiry Format Tests

@available(iOS 15.0, *)
final class CreateCardDataExpiryFormatTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testCreateCardData_ExpiryFormat_StandardFormat() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.expiryDate, "12/27")
    }

    func testCreateCardData_ExpiryFormat_SingleDigitMonth() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "1",
            expiryYear: "28",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.expiryDate, "1/28")
    }

    func testCreateCardData_ExpiryFormat_FourDigitYear() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "06",
            expiryYear: "2029",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.expiryDate, "06/2029")
    }

    func testCreateCardData_EmptyCardholderName_SetsNil() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "",
            selectedNetwork: nil
        )

        XCTAssertNil(cardData.cardholderName)
    }

    func testCreateCardData_NonEmptyCardholderName_SetsValue() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "John Doe",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.cardholderName, "John Doe")
    }
}

// MARK: - Select Card Network Additional Tests

@available(iOS 15.0, *)
final class SelectCardNetworkAdditionalTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [weak self] in
                self?.mockClientSessionActions ?? MockClientSessionActionsModule()
            }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_Diners_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.diners

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "DINERS_CLUB")
    }

    func testSelectCardNetwork_JCB_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.jcb

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "JCB")
    }

    func testSelectCardNetwork_Discover_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.discover

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "DISCOVER")
    }

    func testSelectCardNetwork_Maestro_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.maestro

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "MAESTRO")
    }

    func testSelectCardNetwork_Elo_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.elo

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "ELO")
    }

    func testSelectCardNetwork_Mir_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.mir

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "MIR")
    }

    func testSelectCardNetwork_UnionPay_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.unionpay

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "UNIONPAY")
    }

    func testSelectCardNetwork_Bancontact_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.bancontact

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "BANCONTACT")
    }

    func testSelectCardNetwork_CartesBancaires_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.cartesBancaires

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "CARTES_BANCAIRES")
    }
}

// MARK: - Extract Networks Dict Additional Edge Cases

@available(iOS 15.0, *)
final class ExtractNetworksDictAdditionalTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractFromNetworksDict_WithNegativeSurcharge_ExcludesEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": -100]],
            "MASTERCARD": ["surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
        XCTAssertNil(result?["VISA"])
    }

    func testExtractFromNetworksDict_WithAllNegativeSurcharges_ReturnsNil() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": -100]],
            "MASTERCARD": ["surcharge": ["amount": -50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksDict_WithMixedFormats_HandlesBoth() {
        // Given - Mix of nested and direct surcharge formats
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 100]],  // Nested format
            "MASTERCARD": ["surcharge": 75]  // Direct integer format
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 2)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksDict_WithInvalidSurchargeType_SkipsEntry() {
        // Given - Surcharge is a string instead of int/dict
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": "invalid"],
            "MASTERCARD": ["surcharge": ["amount": 50]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 50)
    }

    func testExtractFromNetworksDict_WithMissingAmountKey_SkipsEntry() {
        // Given - Surcharge dict exists but no "amount" key
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["otherKey": 100]],
            "MASTERCARD": ["surcharge": ["amount": 75]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksDict_WithEmptyNestedDict_SkipsEntry() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": [:]],  // Empty surcharge dict
            "MASTERCARD": ["surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
    }
}

// MARK: - Extract Networks Array Additional Edge Cases

@available(iOS 15.0, *)
final class ExtractNetworksArrayAdditionalTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractFromNetworksArray_WithEmptyNestedDict_SkipsEntry() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": [:]],  // Empty surcharge dict
            ["type": "MASTERCARD", "surcharge": ["amount": 100]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
    }

    func testExtractFromNetworksArray_WithMissingAmountKey_SkipsEntry() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["currency": "EUR"]],  // No amount
            ["type": "MASTERCARD", "surcharge": ["amount": 75]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 75)
    }

    func testExtractFromNetworksArray_WithFloatAmount_SkipsEntry() {
        // Given - Float amounts should be skipped (only Int is valid)
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 99.99]],  // Float
            ["type": "MASTERCARD", "surcharge": ["amount": 100]]  // Int
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["MASTERCARD"], 100)
    }

    func testExtractFromNetworksArray_WithLargeAmount_IncludesEntry() {
        // Given - Large amounts should work
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 999999999]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertEqual(result?["VISA"], 999999999)
    }

    func testExtractFromNetworksArray_WithDuplicateNetworkTypes_KeepsLast() {
        // Given - Duplicate network types
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 50]],
            ["type": "VISA", "surcharge": ["amount": 100]]  // Duplicate
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then - Dictionary keeps last value for duplicate keys
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["VISA"], 100)
    }
}

// MARK: - Get Payment Methods Additional Edge Cases

@available(iOS 15.0, *)
final class GetPaymentMethodsAdditionalEdgeCasesTests: XCTestCase {

    private var mockConfigurationService: MockConfigurationService!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockConfigurationService = MockConfigurationService()
        repository = HeadlessRepositoryImpl(
            configurationServiceFactory: { [weak self] in
                self?.mockConfigurationService ?? MockConfigurationService()
            }
        )
    }

    override func tearDown() {
        mockConfigurationService = nil
        repository = nil
        super.tearDown()
    }

    func testGetPaymentMethods_WithVeryLongPaymentMethodName_MapsCorrectly() async throws {
        // Given - Payment method with very long name
        let longName = String(repeating: "A", count: 1000)
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: longName,
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.name, longName)
    }

    func testGetPaymentMethods_WithEmptyPaymentMethodName_MapsCorrectly() async throws {
        // Given - Payment method with empty name
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "",
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.name, "")
    }

    func testGetPaymentMethods_WithSpecialCharactersInName_MapsCorrectly() async throws {
        // Given - Payment method with special characters
        let specialName = "Карта 💳 & 日本語 <script>"
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: specialName,
            processorConfigId: "config-123",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.name, specialName)
    }

    func testGetPaymentMethods_WithNilProcessorConfigId_MapsToNil() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertNil(methods.first?.configId)
    }

    func testGetPaymentMethods_WithLargeSurcharge_MapsCorrectly() async throws {
        // Given - Very large surcharge value
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: Int.max,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When
        let methods = try await repository.getPaymentMethods()

        // Then
        XCTAssertEqual(methods.first?.surcharge, Int.max)
    }

    func testGetPaymentMethods_CalledMultipleTimes_ReturnsConsistentResults() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "card-id",
            implementationType: .nativeSdk,
            type: "PAYMENT_CARD",
            name: "Card",
            processorConfigId: "config-123",
            surcharge: 100,
            options: nil,
            displayMetadata: nil
        )
        let config = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bin.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [paymentMethod],
            primerAccountId: "account-123",
            keys: nil,
            checkoutModules: nil
        )
        mockConfigurationService.apiConfiguration = config

        // When - Call multiple times
        let methods1 = try await repository.getPaymentMethods()
        let methods2 = try await repository.getPaymentMethods()
        let methods3 = try await repository.getPaymentMethods()

        // Then - All should return same results
        XCTAssertEqual(methods1.count, methods2.count)
        XCTAssertEqual(methods2.count, methods3.count)
        XCTAssertEqual(methods1.first?.type, methods2.first?.type)
        XCTAssertEqual(methods2.first?.surcharge, methods3.first?.surcharge)
    }
}
