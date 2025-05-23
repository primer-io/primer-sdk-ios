//
//  TokenizationServiceTests.swift
//  PrimerSDKTests
//
//  Created by Carl Eriksson on 07/01/2021.
//

@testable import PrimerSDK
import XCTest

class TokenizationServiceTests: XCTestCase {
    var tokenizationService: TokenizationService!
    var mockApiClient: MockPrimerAPIClient!

    override func setUp() {
        super.setUp()
        mockApiClient = MockPrimerAPIClient()
        tokenizationService = TokenizationService(apiClient: mockApiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
    }

    override func tearDown() {
        tokenizationService = nil
        super.tearDown()
    }

    func testTokenizeSuccess() async throws {
        let expectedTokenData = Mocks.primerPaymentMethodTokenData
        mockApiClient.tokenizePaymentMethodResult = (expectedTokenData, nil)

        do {
            let result = try await tokenizationService.tokenize(requestBody: Mocks.tokenizationRequestBody)

            // Assert
            XCTAssertEqual(result.id, expectedTokenData.id)
            XCTAssertEqual(result.token, expectedTokenData.token)
        } catch {
            XCTFail("Expected to succeed but failed with error: \(error)")
        }
    }

    func testTokenizeFailure() async {
        let expectedError = PrimerError.invalidClientToken(userInfo: [:], diagnosticsId: "test-id")
        mockApiClient.tokenizePaymentMethodResult = (nil, expectedError)

        do {
            _ = try await tokenizationService.tokenize(requestBody: Mocks.tokenizationRequestBody)
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
        }
    }

    func testExchangePaymentMethodTokenSuccess() async throws {
        let expectedTokenData = Mocks.primerPaymentMethodTokenData
        mockApiClient.exchangePaymentMethodTokenResult = (expectedTokenData, nil)

        do {
            let result = try await tokenizationService.exchangePaymentMethodToken(
                "MOCK_PAYMENT_METHOD",
                vaultedPaymentMethodAdditionalData: nil
            )

            // Assert
            XCTAssertEqual(result.id, expectedTokenData.id)
            XCTAssertEqual(result.token, expectedTokenData.token)
        } catch {
            XCTFail("Expected to succeed but failed with error: \(error)")
        }
    }

    func testExchangePaymentMethodTokenFailure() async {
        let expectedError = PrimerError.invalidClientToken(userInfo: [:], diagnosticsId: "test-id")
        mockApiClient.exchangePaymentMethodTokenResult = (nil, expectedError)

        do {
            _ = try await tokenizationService.exchangePaymentMethodToken(
                "MOCK_PAYMENT_METHOD",
                vaultedPaymentMethodAdditionalData: nil
            )
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
        }
    }
}
