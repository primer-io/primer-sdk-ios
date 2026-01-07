//
//  KlarnaTokenizationComponentTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import PrimerFoundation
@testable import PrimerSDK
import XCTest

final class KlarnaTokenizationComponentTests: XCTestCase {
    var tokenizationComponent: KlarnaTokenizationComponent!
    var paymentMethod: PrimerPaymentMethod!

    override func setUp() {
        super.setUp()
        paymentMethod = Mocks.PaymentMethods.klarnaPaymentMethod
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)
    }

    override func tearDown() {
        restartPrimerConfiguration()
        paymentMethod = nil
        super.tearDown()
    }

    func test_validateWithSuccess() {
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)

        XCTAssertNoThrow(try tokenizationComponent.validate(), "Validation should not throw any error.")
    }

    func test_validateWithError_lineItems() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasItems: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)

        let expectedError = getInvalidValueError(key: "lineItems")

        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }

    func test_validateWithError_orderItemsAmount() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasLineItemAmout: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)

        let expectedError = getInvalidValueError(key: "settings.orderItems")

        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }

    func test_validateWithError_amount() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasAmount: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)

        let expectedError = getInvalidSettingError(name: "amount")

        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }

    func test_validateWithError_currency() {
        let clientSession = KlarnaTestsMocks.getClientSession(hasCurrency: false)
        let failingApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: failingApiConfiguration)

        let expectedError = getInvalidSettingError(name: "currency")

        XCTAssertThrowsError(try tokenizationComponent.validate()) { error in
            if let err = error as? PrimerError {
                XCTAssertEqual(err.plainDescription, expectedError.plainDescription, "Validation error is expected here.")
            }
        }
    }

    func test_createPaymentSessionSuccess() async throws {
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)

        do {
            let paymentSession = try await tokenizationComponent.createPaymentSession()
            XCTAssertNotNil(paymentSession, "Result should not be nil")
        } catch {
            XCTFail("Request failed with: \(error)")
        }
    }

    func test_authorizePaymentSessionSuccess() async throws {
        let clientSession = KlarnaTestsMocks.getClientSession()
        let successApiConfiguration = KlarnaTestsMocks.getMockPrimerApiConfiguration(clientSession: clientSession)
        setupPrimerConfiguration(paymentMethod: paymentMethod, apiConfiguration: successApiConfiguration)

        tokenizationComponent.setSessionId(paymentSessionId: "mock-session-id")

        do {
            let paymentSession = try await tokenizationComponent.authorizePaymentSession(authorizationToken: "")
            XCTAssertNotNil(paymentSession, "Result should not be nil")
        } catch {
            XCTFail("Request failed with: \(error)")
        }
    }
}

extension KlarnaTokenizationComponentTests {
    private func setupPrimerConfiguration(paymentMethod: PrimerPaymentMethod, apiConfiguration: PrimerAPIConfiguration) {
        restartPrimerConfiguration()

        let mockApiClient = MockPrimerAPIClient()
        mockApiClient.fetchConfigurationWithActionsResult = (apiConfiguration, nil)
        mockApiClient.mockSuccessfulResponses()

        AppState.current.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = KlarnaTestsMocks.clientToken
        PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration

        tokenizationComponent = KlarnaTokenizationComponent(paymentMethod: paymentMethod)
    }

    private func restartPrimerConfiguration() {
        AppState.current.clientToken = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.apiClient = nil
        tokenizationComponent = nil
    }

    private func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken()
        ErrorHandler.handle(error: error)
        return error
    }

    func getInvalidValueError(
        key: String,
        value: Any? = nil
    ) -> PrimerError {
        let error = PrimerError.invalidValue(key: key, value: value)
        ErrorHandler.handle(error: error)
        return error
    }

    func getInvalidSettingError(
        name: String
    ) -> PrimerError {
        let error = PrimerError.invalidValue(key: name)
        ErrorHandler.handle(error: error)
        return error
    }
}

#endif
