@testable import PrimerSDK
import XCTest

final class TokenizationServiceTests: XCTestCase {
    var sut: TokenizationService!
    private let mockApiClient = MockPrimerAPIClient()

    override func setUp() {
        super.setUp()
        sut = TokenizationService(apiClient: mockApiClient)

        AppState.current.clientToken = MockAppState.mockClientToken
        PrimerAPIConfigurationModule.apiClient = mockApiClient
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_tokenize_WhenClientTokenIsNil_ThenThrowsError() async {
        // Given
        AppState.current.clientToken = nil

        // When
        do {
            _ = try await sut.tokenize(requestBody: Mocks.tokenizationRequestBody)
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            // Then - error was thrown as expected
        }
    }

    func test_tokenize_WhenPciURLisNil_ThenThrowsError() async throws {
        // Given
        let clientToken = try! DecodedJWTToken.createMock(pciUrl: nil).toString()
        AppState.current.clientToken = clientToken

        // When
        do {
            _ = try await sut.tokenize(requestBody: Mocks.tokenizationRequestBody)
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            // Then - error was thrown as expected
        }
    }

    func test_tokenize_WhenUrlIsInvalid_ThenThrowsError() async {
        // Given
        let clientToken = try! DecodedJWTToken.createMock(pciUrl: "https://\u{0000}").toString()
        AppState.current.clientToken = clientToken

        // When
        do {
            _ = try await sut.tokenize(requestBody: Mocks.tokenizationRequestBody)
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            // Then - error was thrown as expected
        }
    }

    func test_tokenize_WhenApiClientReturnsError_ThenThrowsError() async {
        // Given
        let expectedError = PrimerError.invalidClientToken(userInfo: [:], diagnosticsId: "test-id")
        mockApiClient.tokenizePaymentMethodResult = (nil, expectedError)

        // When
        do {
            _ = try await sut.tokenize(requestBody: Mocks.tokenizationRequestBody)
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            // Then
            XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
        }
    }

    func test_tokenize_Success() async throws {
        // Given
        let expectedTokenData = Mocks.primerPaymentMethodTokenData
        mockApiClient.tokenizePaymentMethodResult = (expectedTokenData, nil)

        do {
            // When
            let result = try await sut.tokenize(requestBody: Mocks.tokenizationRequestBody)

            // Then
            XCTAssertEqual(result.id, expectedTokenData.id)
            XCTAssertEqual(result.token, expectedTokenData.token)
        } catch {
            XCTFail("Expected to succeed but failed with error: \(error)")
        }
    }

    func test_exchangePaymentMethodToken_WhenClientTokenIsNil_ThenThrowsError() async {
        // Given
        AppState.current.clientToken = nil

        // When
        do {
            _ = try await sut.exchangePaymentMethodToken(
                "MOCK_PAYMENT_METHOD",
                vaultedPaymentMethodAdditionalData: nil
            )
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            // Then - error was thrown as expected
        }
    }

    func test_exchangePaymentMethodToken_WhenApiClientReturnsError_ThenThrowsError() async {
        // Given
        let expectedError = PrimerError.invalidClientToken(userInfo: [:], diagnosticsId: "test-id")
        mockApiClient.exchangePaymentMethodTokenResult = (nil, expectedError)

        // When
        do {
            _ = try await sut.exchangePaymentMethodToken(
                "MOCK_PAYMENT_METHOD",
                vaultedPaymentMethodAdditionalData: nil
            )
            XCTFail("Expected to throw an error but succeeded")
        } catch {
            // Then
            XCTAssertEqual(error.localizedDescription, expectedError.localizedDescription)
        }
    }

    func test_exchangePaymentMethodToken_Success() async throws {
        // Given
        let expectedTokenData = Mocks.primerPaymentMethodTokenData
        mockApiClient.exchangePaymentMethodTokenResult = (expectedTokenData, nil)

        // When
        do {
            let result = try await sut.exchangePaymentMethodToken(
                "MOCK_PAYMENT_METHOD",
                vaultedPaymentMethodAdditionalData: nil
            )

            // Then
            XCTAssertEqual(result.id, expectedTokenData.id)
            XCTAssertEqual(result.token, expectedTokenData.token)
        } catch {
            XCTFail("Expected to succeed but failed with error: \(error)")
        }
    }
}
