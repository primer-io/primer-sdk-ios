//
//  PrimerAPIClientTests.swift
//
//
//  Created by Onur Var on 3.06.2025.
//

// swiftlint:disable file_length
// swiftlint:disable line_length
// swiftlint:disable type_body_length

@testable import PrimerSDK
import XCTest

final class PrimerAPIClientTests: XCTestCase {
    var sut: PrimerAPIClient!
    var networkService: MockNetworkService!
    let mockedError: PrimerError = .unknown(userInfo: ["test": "test"], diagnosticsId: "")

    override func setUp() {
        networkService = MockNetworkService()
        sut = PrimerAPIClient(networkService: networkService)
    }

    override class func tearDown() {}

    func test_genericAPICall_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedResult = SuccessResponse()

        // When
        sut.genericAPICall(
            clientToken: Mocks.decodedJWTToken,
            url: URL(string: "https://random.url")!
        ) { result in
            switch result {
            case .success(let flag):
                XCTAssertTrue(flag)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_genericAPICall_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        networkService.mockedResult = SuccessResponse()

        do {
            // When
            let flag = try await sut.genericAPICall(
                clientToken: Mocks.decodedJWTToken,
                url: URL(string: "https://random.url")!
            )
            // Then
            XCTAssertTrue(flag)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_genericAPICall_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let url = URL(string: "https://random.url")!
        networkService.mockedError = mockedError

        // When
        sut.genericAPICall(
            clientToken: Mocks.decodedJWTToken,
            url: url
        ) { result in
            switch result {
            case .success(let flag):
                XCTFail("Expected failure, but got success with flag: \(flag)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_genericAPICall_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        let url = URL(string: "https://random.url")!
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.genericAPICall(
                clientToken: Mocks.decodedJWTToken,
                url: url
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_fetchVaultedPaymentMethods_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockVaultedPaymentMethods
        networkService.mockedResult = mockedResult

        // When
        sut.fetchVaultedPaymentMethods(clientToken: Mocks.decodedJWTToken) { result in
            switch result {
            case .success(let paymentMethods):
                XCTAssertEqual(paymentMethods.data.count, 0)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchVaultedPaymentMethods_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockVaultedPaymentMethods
        networkService.mockedResult = mockedResult

        do {
            // When
            let paymentMethods = try await sut.fetchVaultedPaymentMethods(clientToken: Mocks.decodedJWTToken)
            // Then
            XCTAssertEqual(paymentMethods.data.count, 0)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_fetchVaultedPaymentMethods_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.fetchVaultedPaymentMethods(clientToken: Mocks.decodedJWTToken) { result in
            switch result {
            case .success(let paymentMethods):
                XCTFail("Expected failure, but got success with payment methods: \(paymentMethods)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchVaultedPaymentMethods_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.fetchVaultedPaymentMethods(clientToken: Mocks.decodedJWTToken)
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_exchangePaymentMethodToken_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockTokenizePaymentMethod
        networkService.mockedResult = mockedResult

        // When
        sut.exchangePaymentMethodToken(
            clientToken: Mocks.decodedJWTToken,
            vaultedPaymentMethodId: "MOCK_PAYMENT_METHOD",
            vaultedPaymentMethodAdditionalData: nil
        ) { result in
            switch result {
            case .success(let paymentMethod):
                XCTAssertEqual(paymentMethod.id, mockedResult.id)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_exchangePaymentMethodToken_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockTokenizePaymentMethod
        networkService.mockedResult = mockedResult

        do {
            // When
            let paymentMethod = try await sut.exchangePaymentMethodToken(
                clientToken: Mocks.decodedJWTToken,
                vaultedPaymentMethodId: "MOCK_PAYMENT_METHOD",
                vaultedPaymentMethodAdditionalData: nil
            )
            // Then
            XCTAssertEqual(paymentMethod.id, mockedResult.id)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_exchangePaymentMethodToken_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.exchangePaymentMethodToken(
            clientToken: Mocks.decodedJWTToken,
            vaultedPaymentMethodId: "MOCK_PAYMENT_METHOD",
            vaultedPaymentMethodAdditionalData: nil
        ) { result in
            switch result {
            case .success(let paymentMethod):
                XCTFail("Expected failure, but got success with payment method: \(paymentMethod)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_exchangePaymentMethodToken_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.exchangePaymentMethodToken(
                clientToken: Mocks.decodedJWTToken,
                vaultedPaymentMethodId: "MOCK_PAYMENT_METHOD",
                vaultedPaymentMethodAdditionalData: nil
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_deleteVaultedPaymentMethod_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedResult = DummySuccess()

        // When
        sut.deleteVaultedPaymentMethod(
            clientToken: Mocks.decodedJWTToken,
            id: "ID"
        ) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_deleteVaultedPaymentMethod_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        networkService.mockedResult = DummySuccess()

        do {
            // When
            try await sut.deleteVaultedPaymentMethod(
                clientToken: Mocks.decodedJWTToken,
                id: "ID"
            )
            // Then
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_deleteVaultedPaymentMethod_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.deleteVaultedPaymentMethod(
            clientToken: Mocks.decodedJWTToken,
            id: "ID"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_deleteVaultedPaymentMethod_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            try await sut.deleteVaultedPaymentMethod(
                clientToken: Mocks.decodedJWTToken,
                id: "ID"
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_fetchConfiguration_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockPrimerAPIConfiguration
        networkService.mockedResult = mockedResult
        networkService.mockedHeaders = [
            "TEST": "HEADER"
        ]

        // When
        sut.fetchConfiguration(
            clientToken: Mocks.decodedJWTToken,
            requestParameters: nil
        ) { result, headers in
            XCTAssertEqual(headers?["TEST"], "HEADER")
            switch result {
            case .success(let configuration):
                XCTAssertEqual(configuration.coreUrl, mockedResult.coreUrl)
                XCTAssertEqual(configuration.pciUrl, mockedResult.pciUrl)
                XCTAssertEqual(configuration.binDataUrl, mockedResult.binDataUrl)
                XCTAssertEqual(configuration.assetsUrl, mockedResult.assetsUrl)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchConfiguration_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockPrimerAPIConfiguration
        networkService.mockedResult = mockedResult
        networkService.mockedHeaders = [
            "TEST": "HEADER"
        ]

        do {
            // When
            let (configuration, headers) = try await sut.fetchConfiguration(
                clientToken: Mocks.decodedJWTToken,
                requestParameters: nil
            )
            // Then
            XCTAssertEqual(headers?["TEST"], "HEADER")
            XCTAssertEqual(configuration.coreUrl, mockedResult.coreUrl)
            XCTAssertEqual(configuration.pciUrl, mockedResult.pciUrl)
            XCTAssertEqual(configuration.binDataUrl, mockedResult.binDataUrl)
            XCTAssertEqual(configuration.assetsUrl, mockedResult.assetsUrl)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_fetchConfiguration_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.fetchConfiguration(
            clientToken: Mocks.decodedJWTToken,
            requestParameters: nil
        ) { result, headers in
            XCTAssertNil(headers, "Expected headers to be nil on failure")
            switch result {
            case .success(let configuration):
                XCTFail("Expected failure, but got success with configuration: \(configuration)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchConfiguration_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.fetchConfiguration(
                clientToken: Mocks.decodedJWTToken,
                requestParameters: nil
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_createPayPalOrderSession_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockPayPalCreateOrder
        networkService.mockedResult = mockedResult

        // When
        sut.createPayPalOrderSession(
            clientToken: Mocks.decodedJWTToken,
            payPalCreateOrderRequest: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                amount: 100,
                currencyCode: "USD",
                returnUrl: "scheme://return",
                cancelUrl: "scheme://cancel"
            )
        ) { result in
            switch result {
            case .success(let orderSession):
                XCTAssertEqual(orderSession.orderId, mockedResult.orderId)
                XCTAssertEqual(orderSession.approvalUrl, mockedResult.approvalUrl)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createPayPalOrderSession_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockPayPalCreateOrder
        networkService.mockedResult = mockedResult

        do {
            // When
            let orderSession = try await sut.createPayPalOrderSession(
                clientToken: Mocks.decodedJWTToken,
                payPalCreateOrderRequest: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    amount: 100,
                    currencyCode: "USD",
                    returnUrl: "scheme://return",
                    cancelUrl: "scheme://cancel"
                )
            )
            // Then
            XCTAssertEqual(orderSession.orderId, mockedResult.orderId)
            XCTAssertEqual(orderSession.approvalUrl, mockedResult.approvalUrl)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_createPayPalOrderSession_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.createPayPalOrderSession(
            clientToken: Mocks.decodedJWTToken,
            payPalCreateOrderRequest: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                amount: 100,
                currencyCode: "USD",
                returnUrl: "scheme://return",
                cancelUrl: "scheme://cancel"
            )
        ) { result in
            switch result {
            case .success(let orderSession):
                XCTFail("Expected failure, but got success with order session: \(orderSession)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createPayPalOrderSession_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.createPayPalOrderSession(
                clientToken: Mocks.decodedJWTToken,
                payPalCreateOrderRequest: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    amount: 100,
                    currencyCode: "USD",
                    returnUrl: "scheme://return",
                    cancelUrl: "scheme://cancel"
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_createPayPalBillingAgreementSession_shouldSuccess() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockCreatePayPalBillingAgreementSession
        networkService.mockedResult = mockedResult

        // When
        sut.createPayPalBillingAgreementSession(
            clientToken: Mocks.decodedJWTToken,
            payPalCreateBillingAgreementRequest: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                returnUrl: "scheme://return",
                cancelUrl: "scheme://cancel"
            )
        ) { result in
            switch result {
            case .success(let agreementSession):
                XCTAssertEqual(agreementSession.tokenId, mockedResult.tokenId)
                XCTAssertEqual(agreementSession.approvalUrl, mockedResult.approvalUrl)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createPayPalBillingAgreementSession_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockCreatePayPalBillingAgreementSession
        networkService.mockedResult = mockedResult

        do {
            // When
            let agreementSession = try await sut.createPayPalBillingAgreementSession(
                clientToken: Mocks.decodedJWTToken,
                payPalCreateBillingAgreementRequest: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    returnUrl: "scheme://return",
                    cancelUrl: "scheme://cancel"
                )
            )
            // Then
            XCTAssertEqual(agreementSession.tokenId, mockedResult.tokenId)
            XCTAssertEqual(agreementSession.approvalUrl, mockedResult.approvalUrl)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_createPayPalBillingAgreementSession_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.createPayPalBillingAgreementSession(
            clientToken: Mocks.decodedJWTToken,
            payPalCreateBillingAgreementRequest: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                returnUrl: "scheme://return",
                cancelUrl: "scheme://cancel"
            )
        ) { result in
            switch result {
            case .success(let agreementSession):
                XCTFail("Expected failure, but got success with agreement session: \(agreementSession)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createPayPalBillingAgreementSession_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.createPayPalBillingAgreementSession(
                clientToken: Mocks.decodedJWTToken,
                payPalCreateBillingAgreementRequest: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    returnUrl: "scheme://return",
                    cancelUrl: "scheme://cancel"
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_confirmPayPalBillingAgreementSession_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockConfirmPayPalBillingAgreement
        networkService.mockedResult = mockedResult

        // When
        sut.confirmPayPalBillingAgreement(
            clientToken: Mocks.decodedJWTToken,
            payPalConfirmBillingAgreementRequest: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                tokenId: "TOKEN_ID"
            )
        ) { result in
            switch result {
            case .success(let confirmation):
                XCTAssertEqual(confirmation.billingAgreementId, mockedResult.billingAgreementId)
                XCTAssertEqual(confirmation.externalPayerInfo.externalPayerId, mockedResult.externalPayerInfo.externalPayerId)
                XCTAssertEqual(confirmation.externalPayerInfo.email, mockedResult.externalPayerInfo.email)
                XCTAssertEqual(confirmation.externalPayerInfo.firstName, mockedResult.externalPayerInfo.firstName)
                XCTAssertEqual(confirmation.externalPayerInfo.lastName, mockedResult.externalPayerInfo.lastName)
                XCTAssertEqual(confirmation.shippingAddress?.firstName, mockedResult.shippingAddress?.firstName)
                XCTAssertEqual(confirmation.shippingAddress?.lastName, mockedResult.shippingAddress?.lastName)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_confirmPayPalBillingAgreementSession_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockConfirmPayPalBillingAgreement
        networkService.mockedResult = mockedResult

        do {
            // When
            let confirmation = try await sut.confirmPayPalBillingAgreement(
                clientToken: Mocks.decodedJWTToken,
                payPalConfirmBillingAgreementRequest: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    tokenId: "TOKEN_ID"
                )
            )
            // Then
            XCTAssertEqual(confirmation.billingAgreementId, mockedResult.billingAgreementId)
            XCTAssertEqual(confirmation.externalPayerInfo.externalPayerId, mockedResult.externalPayerInfo.externalPayerId)
            XCTAssertEqual(confirmation.externalPayerInfo.email, mockedResult.externalPayerInfo.email)
            XCTAssertEqual(confirmation.externalPayerInfo.firstName, mockedResult.externalPayerInfo.firstName)
            XCTAssertEqual(confirmation.externalPayerInfo.lastName, mockedResult.externalPayerInfo.lastName)
            XCTAssertEqual(confirmation.shippingAddress?.firstName, mockedResult.shippingAddress?.firstName)
            XCTAssertEqual(confirmation.shippingAddress?.lastName, mockedResult.shippingAddress?.lastName)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_confirmPayPalBillingAgreementSession_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.confirmPayPalBillingAgreement(
            clientToken: Mocks.decodedJWTToken,
            payPalConfirmBillingAgreementRequest: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                tokenId: "TOKEN_ID"
            )
        ) { result in
            switch result {
            case .success(let confirmation):
                XCTFail("Expected failure, but got success with confirmation: \(confirmation)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_confirmPayPalBillingAgreementSession_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.confirmPayPalBillingAgreement(
                clientToken: Mocks.decodedJWTToken,
                payPalConfirmBillingAgreementRequest: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    tokenId: "TOKEN_ID"
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_createKlarnaPaymentSession_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockCreateKlarnaPaymentSession
        networkService.mockedResult = mockedResult

        // When
        sut.createKlarnaPaymentSession(
            clientToken: Mocks.decodedJWTToken,
            klarnaCreatePaymentSessionAPIRequest: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                sessionType: .oneOffPayment,
                description: nil,
                redirectUrl: nil,
                totalAmount: nil,
                orderItems: nil,
                billingAddress: nil,
                shippingAddress: nil
            )
        ) { result in
            switch result {
            case .success(let paymentSession):
                XCTAssertEqual(paymentSession.clientToken, mockedResult.clientToken)
                XCTAssertEqual(paymentSession.sessionId, mockedResult.sessionId)
                XCTAssertEqual(paymentSession.categories.count, mockedResult.categories.count)
                XCTAssertEqual(paymentSession.categories.first?.identifier, mockedResult.categories.first?.identifier)
                XCTAssertEqual(paymentSession.categories.first?.name, mockedResult.categories.first?.name)
                XCTAssertEqual(paymentSession.categories.first?.descriptiveAssetUrl, mockedResult.categories.first?.descriptiveAssetUrl)
                XCTAssertEqual(paymentSession.categories.first?.standardAssetUrl, mockedResult.categories.first?.standardAssetUrl)
                XCTAssertEqual(paymentSession.hppSessionId, mockedResult.hppSessionId)
                XCTAssertEqual(paymentSession.hppRedirectUrl, mockedResult.hppRedirectUrl)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createKlarnaPaymentSession_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockCreateKlarnaPaymentSession
        networkService.mockedResult = mockedResult

        do {
            let paymentSession = try await sut.createKlarnaPaymentSession(
                clientToken: Mocks.decodedJWTToken,
                klarnaCreatePaymentSessionAPIRequest: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    sessionType: .oneOffPayment,
                    description: nil,
                    redirectUrl: nil,
                    totalAmount: nil,
                    orderItems: nil,
                    billingAddress: nil,
                    shippingAddress: nil
                )
            )

            // Then
            XCTAssertEqual(paymentSession.clientToken, mockedResult.clientToken)
            XCTAssertEqual(paymentSession.sessionId, mockedResult.sessionId)
            XCTAssertEqual(paymentSession.categories.count, mockedResult.categories.count)
            XCTAssertEqual(paymentSession.categories.first?.identifier, mockedResult.categories.first?.identifier)
            XCTAssertEqual(paymentSession.categories.first?.name, mockedResult.categories.first?.name)
            XCTAssertEqual(paymentSession.categories.first?.descriptiveAssetUrl, mockedResult.categories.first?.descriptiveAssetUrl)
            XCTAssertEqual(paymentSession.categories.first?.standardAssetUrl, mockedResult.categories.first?.standardAssetUrl)
            XCTAssertEqual(paymentSession.hppSessionId, mockedResult.hppSessionId)
            XCTAssertEqual(paymentSession.hppRedirectUrl, mockedResult.hppRedirectUrl)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_createKlarnaPaymentSession_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.createKlarnaPaymentSession(
            clientToken: Mocks.decodedJWTToken,
            klarnaCreatePaymentSessionAPIRequest: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                sessionType: .oneOffPayment,
                description: nil,
                redirectUrl: nil,
                totalAmount: nil,
                orderItems: nil,
                billingAddress: nil,
                shippingAddress: nil
            )
        ) { result in
            switch result {
            case .success(let paymentSession):
                XCTFail("Expected failure, but got success with payment session: \(paymentSession)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createKlarnaPaymentSession_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.createKlarnaPaymentSession(
                clientToken: Mocks.decodedJWTToken,
                klarnaCreatePaymentSessionAPIRequest: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    sessionType: .oneOffPayment,
                    description: nil,
                    redirectUrl: nil,
                    totalAmount: nil,
                    orderItems: nil,
                    billingAddress: nil,
                    shippingAddress: nil
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_createKlarnaCustomerToken_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockCreateKlarnaCustomerToken
        networkService.mockedResult = mockedResult

        // When
        sut.createKlarnaCustomerToken(
            clientToken: Mocks.decodedJWTToken,
            klarnaCreateCustomerTokenAPIRequest: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                sessionId: "MOCK_SESSION_ID",
                authorizationToken: nil,
                description: nil,
                localeData: nil
            )
        ) { result in
            switch result {
            case .success(let customerToken):
                XCTAssertEqual(customerToken.customerTokenId, mockedResult.customerTokenId)
                XCTAssertEqual(customerToken.sessionData.recurringDescription, mockedResult.sessionData.recurringDescription)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createKlarnaCustomerToken_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockCreateKlarnaCustomerToken
        networkService.mockedResult = mockedResult

        do {
            // When
            let customerToken = try await sut.createKlarnaCustomerToken(
                clientToken: Mocks.decodedJWTToken,
                klarnaCreateCustomerTokenAPIRequest: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    sessionId: "MOCK_SESSION_ID",
                    authorizationToken: nil,
                    description: nil,
                    localeData: nil
                )
            )

            // Then
            XCTAssertEqual(customerToken.customerTokenId, mockedResult.customerTokenId)
            XCTAssertEqual(customerToken.sessionData.recurringDescription, mockedResult.sessionData.recurringDescription)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_createKlarnaCustomerToken_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.createKlarnaCustomerToken(
            clientToken: Mocks.decodedJWTToken,
            klarnaCreateCustomerTokenAPIRequest: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                sessionId: "MOCK_SESSION_ID",
                authorizationToken: nil,
                description: nil,
                localeData: nil
            )
        ) { result in
            switch result {
            case .success(let customerToken):
                XCTFail("Expected failure, but got success with customer token: \(customerToken)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createKlarnaCustomerToken_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.createKlarnaCustomerToken(
                clientToken: Mocks.decodedJWTToken,
                klarnaCreateCustomerTokenAPIRequest: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    sessionId: "MOCK_SESSION_ID",
                    authorizationToken: nil,
                    description: nil,
                    localeData: nil
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_finalizeKlarnaPaymentSession_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockFinalizeKlarnaPaymentSession
        networkService.mockedResult = mockedResult

        // When
        sut.finalizeKlarnaPaymentSession(
            clientToken: Mocks.decodedJWTToken,
            klarnaFinalizePaymentSessionRequest: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                sessionId: "MOCK_SESSION_ID"
            )
        ) { result in
            switch result {
            case .success(let paymentSession):
                XCTAssertEqual(paymentSession.customerTokenId, mockedResult.customerTokenId)
                XCTAssertEqual(paymentSession.sessionData.recurringDescription, mockedResult.sessionData.recurringDescription)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_finalizeKlarnaPaymentSession_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockFinalizeKlarnaPaymentSession
        networkService.mockedResult = mockedResult

        do {
            // When
            let paymentSession = try await sut.finalizeKlarnaPaymentSession(
                clientToken: Mocks.decodedJWTToken,
                klarnaFinalizePaymentSessionRequest: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    sessionId: "MOCK_SESSION_ID"
                )
            )

            // Then
            XCTAssertEqual(paymentSession.customerTokenId, mockedResult.customerTokenId)
            XCTAssertEqual(paymentSession.sessionData.recurringDescription, mockedResult.sessionData.recurringDescription)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_finalizeKlarnaPaymentSession_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.finalizeKlarnaPaymentSession(
            clientToken: Mocks.decodedJWTToken,
            klarnaFinalizePaymentSessionRequest: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                sessionId: "MOCK_SESSION_ID"
            )
        ) { result in
            switch result {
            case .success(let paymentSession):
                XCTFail("Expected failure, but got success with payment session: \(paymentSession)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_finalizeKlarnaPaymentSession_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.finalizeKlarnaPaymentSession(
                clientToken: Mocks.decodedJWTToken,
                klarnaFinalizePaymentSessionRequest: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    sessionId: "MOCK_SESSION_ID"
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_listAdyenBanks_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockAdyenBanks
        networkService.mockedResult = mockedResult

        // When
        sut.listAdyenBanks(
            clientToken: Mocks.decodedJWTToken,
            request: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                parameters: .init(paymentMethod: "adyen")
            )
        ) { result in
            switch result {
            case .success(let banks):
                XCTAssertEqual(banks.result.count, mockedResult.result.count)
                XCTAssertEqual(banks.result.first?.name, mockedResult.result.first?.name)
                XCTAssertEqual(banks.result.first?.id, mockedResult.result.first?.id)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_listAdyenBanks_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockAdyenBanks
        networkService.mockedResult = mockedResult

        do {
            // When
            let banks = try await sut.listAdyenBanks(
                clientToken: Mocks.decodedJWTToken,
                request: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    parameters: .init(
                        paymentMethod: "adyen",
                        )
                )
            )

            // Then
            XCTAssertEqual(banks.result.count, mockedResult.result.count)
            XCTAssertEqual(banks.result.first?.name, mockedResult.result.first?.name)
            XCTAssertEqual(banks.result.first?.id, mockedResult.result.first?.id)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_listAdyenBanks_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.listAdyenBanks(
            clientToken: Mocks.decodedJWTToken,
            request: .init(
                paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                parameters: .init(paymentMethod: "adyen")
            )
        ) { result in
            switch result {
            case .success(let banks):
                XCTFail("Expected failure, but got success with banks: \(banks)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_listAdyenBanks_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.listAdyenBanks(
                clientToken: Mocks.decodedJWTToken,
                request: .init(
                    paymentMethodConfigId: "MOCK_PAYMENT_METHOD_CONFIG_ID",
                    parameters: .init(
                        paymentMethod: "adyen",
                        )
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_listRetailOutlets_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockListRetailOutlets
        networkService.mockedResult = mockedResult

        // When
        sut.listRetailOutlets(
            clientToken: Mocks.decodedJWTToken,
            paymentMethodId: ""
        ) { result in
            switch result {
            case .success(let outlets):
                XCTAssertEqual(outlets.result.count, mockedResult.result.count)
                XCTAssertEqual(outlets.result.first?.name, mockedResult.result.first?.name)
                XCTAssertEqual(outlets.result.first?.id, mockedResult.result.first?.id)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_listRetailOutlets_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockListRetailOutlets
        networkService.mockedResult = mockedResult

        do {
            // When
            let outlets = try await sut.listRetailOutlets(
                clientToken: Mocks.decodedJWTToken,
                paymentMethodId: ""
            )

            // Then
            XCTAssertEqual(outlets.result.count, mockedResult.result.count)
            XCTAssertEqual(outlets.result.first?.name, mockedResult.result.first?.name)
            XCTAssertEqual(outlets.result.first?.id, mockedResult.result.first?.id)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_listRetailOutlets_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.listRetailOutlets(
            clientToken: Mocks.decodedJWTToken,
            paymentMethodId: ""
        ) { result in
            switch result {
            case .success(let outlets):
                XCTFail("Expected failure, but got success with outlets: \(outlets)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_listRetailOutlets_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.listRetailOutlets(
                clientToken: Mocks.decodedJWTToken,
                paymentMethodId: ""
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_poll_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = PollingResponse(
            status: .complete,
            id: "mocked-id",
            source: "https://random.url"
        )
        networkService.mockedResult = mockedResult

        // When
        sut.poll(
            clientToken: Mocks.decodedJWTToken,
            url: "https://random.url"
        ) { result in
            switch result {
            case .success(let status):
                XCTAssertEqual(status.id, mockedResult.id)
                XCTAssertEqual(status.status, mockedResult.status)
                XCTAssertEqual(status.source, mockedResult.source)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_poll_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = PollingResponse(
            status: .complete,
            id: "mocked-id",
            source: "https://random.url"
        )
        networkService.mockedResult = mockedResult

        do {
            // When
            let status = try await sut.poll(
                clientToken: Mocks.decodedJWTToken,
                url: "https://random.url"
            )

            // Then
            XCTAssertEqual(status.id, mockedResult.id)
            XCTAssertEqual(status.status, mockedResult.status)
            XCTAssertEqual(status.source, mockedResult.source)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_poll_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.poll(
            clientToken: Mocks.decodedJWTToken,
            url: "https://random.url"
        ) { result in
            switch result {
            case .success(let status):
                XCTFail("Expected failure, but got success with status: \(status)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_poll_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.poll(
                clientToken: Mocks.decodedJWTToken,
                url: "https://random.url"
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_requestPrimerConfigurationWithActions_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockPrimerAPIConfiguration
        networkService.mockedResult = mockedResult
        networkService.mockedHeaders = [
            "TEST": "HEADER"
        ]

        // When
        sut.requestPrimerConfigurationWithActions(
            clientToken: Mocks.decodedJWTToken,
            request: .init(actions: .init(actions: [
                .init(type: .selectPaymentMethod)
            ]))
        ) { result, headers in
            XCTAssertEqual(headers?["TEST"], "HEADER")
            switch result {
            case .success(let configuration):
                XCTAssertEqual(configuration.coreUrl, mockedResult.coreUrl)
                XCTAssertEqual(configuration.pciUrl, mockedResult.pciUrl)
                XCTAssertEqual(configuration.binDataUrl, mockedResult.binDataUrl)
                XCTAssertEqual(configuration.assetsUrl, mockedResult.assetsUrl)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_requestPrimerConfigurationWithActions_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockPrimerAPIConfiguration
        networkService.mockedResult = mockedResult
        networkService.mockedHeaders = [
            "TEST": "HEADER"
        ]

        do {
            // When
            let (configuration, headers) = try await sut.requestPrimerConfigurationWithActions(
                clientToken: Mocks.decodedJWTToken,
                request: .init(actions: .init(actions: [
                    .init(type: .selectPaymentMethod)
                ]))
            )

            // Then
            XCTAssertEqual(headers?["TEST"], "HEADER")
            XCTAssertEqual(configuration.coreUrl, mockedResult.coreUrl)
            XCTAssertEqual(configuration.pciUrl, mockedResult.pciUrl)
            XCTAssertEqual(configuration.binDataUrl, mockedResult.binDataUrl)
            XCTAssertEqual(configuration.assetsUrl, mockedResult.assetsUrl)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_requestPrimerConfigurationWithActions_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.requestPrimerConfigurationWithActions(
            clientToken: Mocks.decodedJWTToken,
            request: .init(actions: .init(actions: [
                .init(type: .selectPaymentMethod)
            ]))
        ) { result, headers in
            XCTAssertNil(headers, "Expected headers to be nil on failure")
            switch result {
            case .success(let configuration):
                XCTFail("Expected failure, but got success with configuration: \(configuration)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_requestPrimerConfigurationWithActions_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.requestPrimerConfigurationWithActions(
                clientToken: Mocks.decodedJWTToken,
                request: .init(actions: .init(actions: [
                    .init(type: .selectPaymentMethod)
                ]))
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_sendAnalyticsEvents_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockSendAnalyticsEvents
        networkService.mockedResult = mockedResult

        // When
        sut.sendAnalyticsEvents(
            clientToken: Mocks.decodedJWTToken,
            url: URL(string: "https://random.url")!,
            body: nil
        ) { result in
            switch result {
            case .success(let response):
                XCTAssertEqual(response.id, mockedResult.id)
                XCTAssertEqual(response.result, mockedResult.result)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_sendAnalyticsEvents_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockSendAnalyticsEvents
        networkService.mockedResult = mockedResult

        do {
            // When
            let response = try await sut.sendAnalyticsEvents(
                clientToken: Mocks.decodedJWTToken,
                url: URL(string: "https://random.url")!,
                body: nil
            )

            // Then
            XCTAssertEqual(response.id, mockedResult.id)
            XCTAssertEqual(response.result, mockedResult.result)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_sendAnalyticsEvents_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.sendAnalyticsEvents(
            clientToken: Mocks.decodedJWTToken,
            url: URL(string: "https://random.url")!,
            body: nil
        ) { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, but got success with response: \(response)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_sendAnalyticsEvents_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.sendAnalyticsEvents(
                clientToken: Mocks.decodedJWTToken,
                url: URL(string: "https://random.url")!,
                body: nil
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_fetchPayPalExternalPayerInfo_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockFetchPayPalExternalPayerInfo
        networkService.mockedResult = mockedResult

        // When
        sut.fetchPayPalExternalPayerInfo(
            clientToken: Mocks.decodedJWTToken,
            payPalExternalPayerInfoRequestBody: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                orderId: "ORDER_ID"
            )
        ) { result in
            switch result {
            case .success(let externalPayerInfo):
                XCTAssertEqual(externalPayerInfo.orderId, mockedResult.orderId)
                XCTAssertEqual(externalPayerInfo.externalPayerInfo.externalPayerId, mockedResult.externalPayerInfo.externalPayerId)
                XCTAssertEqual(externalPayerInfo.externalPayerInfo.firstName, mockedResult.externalPayerInfo.firstName)
                XCTAssertEqual(externalPayerInfo.externalPayerInfo.lastName, mockedResult.externalPayerInfo.lastName)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchPayPalExternalPayerInfo_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockFetchPayPalExternalPayerInfo
        networkService.mockedResult = mockedResult

        do {
            // When
            let externalPayerInfo = try await sut.fetchPayPalExternalPayerInfo(
                clientToken: Mocks.decodedJWTToken,
                payPalExternalPayerInfoRequestBody: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    orderId: "ORDER_ID"
                )
            )

            // Then
            XCTAssertEqual(externalPayerInfo.orderId, mockedResult.orderId)
            XCTAssertEqual(externalPayerInfo.externalPayerInfo.externalPayerId, mockedResult.externalPayerInfo.externalPayerId)
            XCTAssertEqual(externalPayerInfo.externalPayerInfo.firstName, mockedResult.externalPayerInfo.firstName)
            XCTAssertEqual(externalPayerInfo.externalPayerInfo.lastName, mockedResult.externalPayerInfo.lastName)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_fetchPayPalExternalPayerInfo_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.fetchPayPalExternalPayerInfo(
            clientToken: Mocks.decodedJWTToken,
            payPalExternalPayerInfoRequestBody: .init(
                paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                orderId: "ORDER_ID"
            )
        ) { result in
            switch result {
            case .success(let externalPayerInfo):
                XCTFail("Expected failure, but got success with external payer info: \(externalPayerInfo)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchPayPalExternalPayerInfo_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.fetchPayPalExternalPayerInfo(
                clientToken: Mocks.decodedJWTToken,
                payPalExternalPayerInfoRequestBody: .init(
                    paymentMethodConfigId: "PAYPAL_CONFIG_ID",
                    orderId: "ORDER_ID"
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_validateClientToken_shouldSuccess_whenValidToken() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockValidateClientToken
        networkService.mockedResult = mockedResult

        // When
        sut.validateClientToken(request: .init(clientToken: "MOCK_CLIENT_TOKEN")) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_validateClientToken_shouldSuccess_whenValidToken_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockValidateClientToken
        networkService.mockedResult = mockedResult

        do {
            // When
            let response = try await sut.validateClientToken(request: .init(clientToken: "MOCK_CLIENT_TOKEN"))
            // Then
            XCTAssertNotNil(response)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_validateClientToken_shouldFail_whenInvalidToken() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.validateClientToken(request: .init(clientToken: "MOCK_CLIENT_TOKEN")) { result in
            switch result {
            case .success(let response):
                XCTFail("Expected failure, but got success with response: \(response)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_validateClientToken_shouldFail_whenInvalidToken_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.validateClientToken(request: .init(clientToken: "MOCK_CLIENT_TOKEN"))
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_createPayment_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockPayment
        networkService.mockedResult = mockedResult

        // When
        sut.createPayment(
            clientToken: Mocks.decodedJWTToken,
            paymentRequestBody: .init(token: "TOKEN_ID")
        ) { result in
            switch result {
            case .success(let payment):
                XCTAssertEqual(payment.id, mockedResult.id)
                XCTAssertEqual(payment.paymentId, mockedResult.paymentId)
                XCTAssertEqual(payment.status, mockedResult.status)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createPayment_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockPayment
        networkService.mockedResult = mockedResult

        do {
            // When
            let payment = try await sut.createPayment(
                clientToken: Mocks.decodedJWTToken,
                paymentRequestBody: .init(token: "TOKEN_ID")
            )

            // Then
            XCTAssertEqual(payment.id, mockedResult.id)
            XCTAssertEqual(payment.paymentId, mockedResult.paymentId)
            XCTAssertEqual(payment.status, mockedResult.status)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_createPayment_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.createPayment(
            clientToken: Mocks.decodedJWTToken,
            paymentRequestBody: .init(token: "TOKEN_ID")
        ) { result in
            switch result {
            case .success(let payment):
                XCTFail("Expected failure, but got success with payment: \(payment)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_createPayment_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.createPayment(
                clientToken: Mocks.decodedJWTToken,
                paymentRequestBody: .init(token: "TOKEN_ID")
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_resumePayment_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockResumePayment
        networkService.mockedResult = mockedResult

        // When
        sut.resumePayment(
            clientToken: Mocks.decodedJWTToken,
            paymentId: "PAYMENT_ID",
            paymentResumeRequest: .init(token: "TOKEN_ID")
        ) { result in
            switch result {
            case .success(let payment):
                XCTAssertEqual(payment.id, mockedResult.id)
                XCTAssertEqual(payment.paymentId, mockedResult.paymentId)
                XCTAssertEqual(payment.status, mockedResult.status)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_resumePayment_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockResumePayment
        networkService.mockedResult = mockedResult

        do {
            // When
            let payment = try await sut.resumePayment(
                clientToken: Mocks.decodedJWTToken,
                paymentId: "PAYMENT_ID",
                paymentResumeRequest: .init(token: "TOKEN_ID")
            )

            // Then
            XCTAssertEqual(payment.id, mockedResult.id)
            XCTAssertEqual(payment.paymentId, mockedResult.paymentId)
            XCTAssertEqual(payment.status, mockedResult.status)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_resumePayment_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.resumePayment(
            clientToken: Mocks.decodedJWTToken,
            paymentId: "PAYMENT_ID",
            paymentResumeRequest: .init(token: "TOKEN_ID")
        ) { result in
            switch result {
            case .success(let payment):
                XCTFail("Expected failure, but got success with payment: \(payment)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_resumePayment_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.resumePayment(
                clientToken: Mocks.decodedJWTToken,
                paymentId: "PAYMENT_ID",
                paymentResumeRequest: .init(token: "TOKEN_ID")
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_completePayment_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockSdkCompleteUrl
        networkService.mockedResult = mockedResult

        // When
        sut.completePayment(
            clientToken: Mocks.decodedJWTToken,
            url: URL(string: "https://random.url")!,
            paymentRequest: .init(mandateSignatureTimestamp: "2023-10-01T12:00:00Z")
        ) { result in
            switch result {
            case .success(let payment):
                XCTAssertNotNil(payment)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_completePayment_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockSdkCompleteUrl
        networkService.mockedResult = mockedResult

        do {
            // When
            let payment = try await sut.completePayment(
                clientToken: Mocks.decodedJWTToken,
                url: URL(string: "https://random.url")!,
                paymentRequest: .init(mandateSignatureTimestamp: "2023-10-01T12:00:00Z")
            )

            // Then
            XCTAssertNotNil(payment)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_completePayment_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.completePayment(
            clientToken: Mocks.decodedJWTToken,
            url: URL(string: "https://random.url")!,
            paymentRequest: .init(mandateSignatureTimestamp: "2023-10-01T12:00:00Z")
        ) { result in
            switch result {
            case .success(let payment):
                XCTFail("Expected failure, but got success with payment: \(payment)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_completePayment_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.completePayment(
                clientToken: Mocks.decodedJWTToken,
                url: URL(string: "https://random.url")!,
                paymentRequest: .init(mandateSignatureTimestamp: "2023-10-01T12:00:00Z")
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_testFinalizePolling_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockPayment
        networkService.mockedResult = mockedResult

        // When
        sut.testFinalizePolling(
            clientToken: Mocks.decodedJWTToken,
            testId: "TEST_ID"
        ) { result in
            switch result {
            case .success:
                XCTAssertTrue(true)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_testFinalizePolling_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockPayment
        networkService.mockedResult = mockedResult

        do {
            // When
            try await sut.testFinalizePolling(
                clientToken: Mocks.decodedJWTToken,
                testId: "TEST_ID"
            )
            // Then
            XCTAssertTrue(true)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_testFinalizePolling_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.testFinalizePolling(
            clientToken: Mocks.decodedJWTToken,
            testId: "TEST_ID"
        ) { result in
            switch result {
            case .success:
                XCTFail("Expected failure, but got success")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_testFinalizePolling_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.testFinalizePolling(
                clientToken: Mocks.decodedJWTToken,
                testId: "TEST_ID"
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_listCardNetworks_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockBinNetworks
        networkService.mockedResult = mockedResult

        // When
        _ = sut.listCardNetworks(
            clientToken: Mocks.decodedJWTToken,
            bin: ""
        ) { result in
            switch result {
            case .success(let cardNetworks):
                XCTAssertEqual(cardNetworks.networks.count, mockedResult.networks.count)
                XCTAssertEqual(cardNetworks.networks.first?.value, mockedResult.networks.first?.value)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_listCardNetworks_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockBinNetworks
        networkService.mockedResult = mockedResult

        do {
            // When
            let cardNetworks = try await sut.listCardNetworks(
                clientToken: Mocks.decodedJWTToken,
                bin: ""
            )

            // Then
            XCTAssertEqual(cardNetworks.networks.count, mockedResult.networks.count)
            XCTAssertEqual(cardNetworks.networks.first?.value, mockedResult.networks.first?.value)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_listCardNetworks_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        _ = sut.listCardNetworks(
            clientToken: Mocks.decodedJWTToken,
            bin: ""
        ) { result in
            switch result {
            case .success(let cardNetworks):
                XCTFail("Expected failure, but got success with card networks: \(cardNetworks)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_listCardNetworks_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.listCardNetworks(
                clientToken: Mocks.decodedJWTToken,
                bin: ""
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_fetchNolSdkSecret_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockFetchNolSdkSecret
        networkService.mockedResult = mockedResult

        // When
        sut.fetchNolSdkSecret(
            clientToken: Mocks.decodedJWTToken,
            paymentRequestBody: .init(
                nolSdkId: "MOCK_NOL_SDK_ID",
                nolAppId: "MOCK_NOL_APP_ID",
                phoneVendor: "MOCK_PHONE_VENDOR",
                phoneModel: "MOCK_PHONE_MODEL"
            )
        ) { result in
            switch result {
            case .success(let nolSdkSecret):
                XCTAssertEqual(nolSdkSecret.sdkSecret, mockedResult.sdkSecret)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchNolSdkSecret_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockFetchNolSdkSecret
        networkService.mockedResult = mockedResult

        do {
            // When
            let nolSdkSecret = try await sut.fetchNolSdkSecret(
                clientToken: Mocks.decodedJWTToken,
                paymentRequestBody: .init(
                    nolSdkId: "MOCK_NOL_SDK_ID",
                    nolAppId: "MOCK_NOL_APP_ID",
                    phoneVendor: "MOCK_PHONE_VENDOR",
                    phoneModel: "MOCK_PHONE_MODEL"
                )
            )

            // Then
            XCTAssertEqual(nolSdkSecret.sdkSecret, mockedResult.sdkSecret)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_fetchNolSdkSecret_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.fetchNolSdkSecret(
            clientToken: Mocks.decodedJWTToken,
            paymentRequestBody: .init(
                nolSdkId: "MOCK_NOL_SDK_ID",
                nolAppId: "MOCK_NOL_APP_ID",
                phoneVendor: "MOCK_PHONE_VENDOR",
                phoneModel: "MOCK_PHONE_MODEL"
            )
        ) { result in
            switch result {
            case .success(let nolSdkSecret):
                XCTFail("Expected failure, but got success with nol SDK secret: \(nolSdkSecret)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_fetchNolSdkSecret_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.fetchNolSdkSecret(
                clientToken: Mocks.decodedJWTToken,
                paymentRequestBody: .init(
                    nolSdkId: "MOCK_NOL_SDK_ID",
                    nolAppId: "MOCK_NOL_APP_ID",
                    phoneVendor: "MOCK_PHONE_VENDOR",
                    phoneModel: "MOCK_PHONE_MODEL"
                )
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }

    func test_getPhoneMetadata_shouldSuccess_whenValidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        let mockedResult = MockPrimerAPIClient.Samples.mockPhoneMetadataResponse
        networkService.mockedResult = mockedResult

        // When
        sut.getPhoneMetadata(
            clientToken: Mocks.decodedJWTToken,
            paymentRequestBody: .init(phoneNumber: "+123")
        ) { result in
            switch result {
            case .success(let phoneMetadata):
                XCTAssertEqual(phoneMetadata.isValid, mockedResult.isValid)
                XCTAssertEqual(phoneMetadata.countryCode, mockedResult.countryCode)
                XCTAssertEqual(phoneMetadata.nationalNumber, mockedResult.nationalNumber)
            case .failure(let error):
                XCTFail("Expected success, but got failure with error: \(error)")
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_getPhoneMetadata_shouldSuccess_whenValidResponse_async() async throws {
        // Given
        let mockedResult = MockPrimerAPIClient.Samples.mockPhoneMetadataResponse
        networkService.mockedResult = mockedResult

        do {
            // When
            let phoneMetadata = try await sut.getPhoneMetadata(
                clientToken: Mocks.decodedJWTToken,
                paymentRequestBody: .init(phoneNumber: "+123")
            )

            // Then
            XCTAssertEqual(phoneMetadata.isValid, mockedResult.isValid)
            XCTAssertEqual(phoneMetadata.countryCode, mockedResult.countryCode)
            XCTAssertEqual(phoneMetadata.nationalNumber, mockedResult.nationalNumber)
        } catch {
            XCTFail("Expected success, but got failure with error: \(error)")
        }
    }

    func test_getPhoneMetadata_shouldFail_whenInvalidResponse() {
        // Given
        let expectation = XCTestExpectation(description: "Callback called")
        networkService.mockedError = mockedError

        // When
        sut.getPhoneMetadata(
            clientToken: Mocks.decodedJWTToken,
            paymentRequestBody: .init(phoneNumber: "+123")
        ) { result in
            switch result {
            case .success(let phoneMetadata):
                XCTFail("Expected failure, but got success with phone metadata: \(phoneMetadata)")
            case .failure(let error):
                if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                    XCTAssertEqual(userInfo?["test"] as? String, "test")
                } else {
                    XCTFail("Expected PrimerError.unknown, but got: \(error)")
                }
            }
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 10.0)
    }

    func test_getPhoneMetadata_shouldFail_whenInvalidResponse_async() async throws {
        // Given
        networkService.mockedError = mockedError

        do {
            // When
            _ = try await sut.getPhoneMetadata(
                clientToken: Mocks.decodedJWTToken,
                paymentRequestBody: .init(phoneNumber: "+123")
            )
            XCTFail("Expected failure, but got success")
        } catch {
            if let primerError = error as? PrimerError, case .unknown(let userInfo, _) = primerError {
                XCTAssertEqual(userInfo?["test"] as? String, "test")
            } else {
                XCTFail("Expected PrimerError.unknown, but got: \(error)")
            }
        }
    }
}

// swiftlint:enable type_body_length
// swiftlint:enable line_length
// swiftlint:enable file_length
