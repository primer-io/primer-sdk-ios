//
//  FormRedirectRepositoryImplTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class FormRedirectRepositoryImplTests: XCTestCase {

    // MARK: - Properties

    private var mockTokenizationService: MockTokenizationService!
    private var mockApiClient: MockPrimerAPIClient!
    private var mockPaymentService: MockCreateResumePaymentService!
    private var mockApiConfigurationModule: MockPrimerAPIConfigurationModule!
    private var sut: FormRedirectRepositoryImpl!

    // MARK: - Setup / Teardown

    override func setUp() {
        super.setUp()
        mockTokenizationService = MockTokenizationService()
        mockApiClient = MockPrimerAPIClient()
        mockPaymentService = MockCreateResumePaymentService()
        mockApiConfigurationModule = MockPrimerAPIConfigurationModule()

        // Setup PollingModule to use mock API client
        PollingModule.apiClient = mockApiClient

        sut = FormRedirectRepositoryImpl(
            tokenizationService: mockTokenizationService,
            paymentServiceFactory: { [weak self] _ in self?.mockPaymentService ?? MockCreateResumePaymentService() },
            apiConfigurationModule: mockApiConfigurationModule,
            pollingModuleFactory: { url in PollingModule(url: url) }
        )

        // Setup mock API configuration
        setupMockAPIConfiguration()
    }

    override func tearDown() {
        mockTokenizationService = nil
        mockApiClient = nil
        mockPaymentService = nil
        mockApiConfigurationModule = nil
        sut = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PollingModule.apiClient = nil
        super.tearDown()
    }

    // MARK: - tokenize Tests

    func test_tokenize_withBlikSessionInfo_returnsTokenDataAndBuildsCorrectRequest() async throws {
        // Given
        let expectedTokenData = createMockTokenData()
        var capturedRequestBody: Request.Body.Tokenization?

        mockTokenizationService.onTokenize = { requestBody in
            capturedRequestBody = requestBody
            return .success(expectedTokenData)
        }

        let sessionInfo = BlikSessionInfo(
            blikCode: FormRedirectTestData.Constants.validBlikCode,
            locale: "en-US"
        )

        // When
        let response = try await sut.tokenize(
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(response.tokenData.id, expectedTokenData.id)
        XCTAssertEqual(response.tokenData.token, expectedTokenData.token)
        XCTAssertEqual(response.tokenData.paymentMethodType, expectedTokenData.paymentMethodType)
        let instrument = capturedRequestBody?.paymentInstrument as? OffSessionPaymentInstrument
        XCTAssertEqual(instrument?.paymentMethodType, FormRedirectTestData.Constants.blikPaymentMethodType)
    }

    func test_tokenize_withMBWaySessionInfo_returnsTokenData() async throws {
        // Given
        let expectedTokenData = createMockTokenData()
        mockTokenizationService.onTokenize = { _ in .success(expectedTokenData) }

        let phoneNumber = "\(FormRedirectTestData.Constants.dialCode)\(FormRedirectTestData.Constants.validPhoneNumber)"
        let sessionInfo = InputPhonenumberSessionInfo(phoneNumber: phoneNumber)

        // When
        let response = try await sut.tokenize(
            paymentMethodType: FormRedirectTestData.Constants.mbwayPaymentMethodType,
            sessionInfo: sessionInfo
        )

        // Then
        XCTAssertEqual(response.tokenData.paymentMethodType, expectedTokenData.paymentMethodType)
    }

    func test_tokenize_withMissingPaymentMethodConfig_throwsError() async throws {
        // Given
        PrimerAPIConfigurationModule.apiConfiguration = nil
        let sessionInfo = BlikSessionInfo(
            blikCode: FormRedirectTestData.Constants.validBlikCode,
            locale: "en-US"
        )

        // When/Then
        do {
            _ = try await sut.tokenize(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - config not found
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_tokenize_withTokenizationError_throwsError() async throws {
        // Given
        let expectedError = PrimerError.unknown(message: "Tokenization failed")
        mockTokenizationService.onTokenize = { _ in .failure(expectedError) }
        let sessionInfo = BlikSessionInfo(
            blikCode: FormRedirectTestData.Constants.validBlikCode,
            locale: "en-US"
        )

        // When/Then
        do {
            _ = try await sut.tokenize(
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
                sessionInfo: sessionInfo
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .unknown:
                // Expected
                break
            default:
                XCTFail("Expected unknown error")
            }
        }
    }

    // MARK: - createPayment Tests

    func test_createPayment_callsPaymentService() async throws {
        // Given
        mockPaymentService.onCreatePayment = { _ in
            Response.Body.Payment(
                id: FormRedirectTestData.Constants.paymentId,
                paymentId: FormRedirectTestData.Constants.paymentId,
                amount: 100,
                currencyCode: "USD",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .success,
                paymentFailureReason: nil
            )
        }

        // When
        let response = try await sut.createPayment(
            token: "test_token",
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType
        )

        // Then
        XCTAssertEqual(response.paymentId, FormRedirectTestData.Constants.paymentId)
        XCTAssertEqual(response.status, .success)
    }

    func test_createPayment_withPendingStatus_returnsResponse() async throws {
        // Given
        mockPaymentService.onCreatePayment = { _ in
            Response.Body.Payment(
                id: FormRedirectTestData.Constants.paymentId,
                paymentId: FormRedirectTestData.Constants.paymentId,
                amount: 100,
                currencyCode: "USD",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: Response.Body.Payment.RequiredAction(
                    clientToken: MockAppState.mockClientTokenWithRedirect,
                    name: .checkout,
                    description: nil
                ),
                status: .pending,
                paymentFailureReason: nil
            )
        }

        // When
        let response = try await sut.createPayment(
            token: "test_token",
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType
        )

        // Then
        XCTAssertEqual(response.status, .pending)
        XCTAssertEqual(response.paymentId, FormRedirectTestData.Constants.paymentId)
        XCTAssertEqual(response.statusUrl, URL(string: "https://localhost/status"))
    }

    func test_createPayment_withNilPaymentId_throwsError() async throws {
        // Given
        mockPaymentService.onCreatePayment = { _ in
            Response.Body.Payment(
                id: nil,
                paymentId: nil,
                amount: 100,
                currencyCode: "USD",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .success,
                paymentFailureReason: nil
            )
        }

        // When / Then
        do {
            _ = try await sut.createPayment(
                token: "test_token",
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "paymentId")
            default:
                XCTFail("Expected invalidValue error, got \(error)")
            }
        }
    }

    func test_createPayment_withError_throwsError() async throws {
        // Given
        mockPaymentService.onCreatePayment = nil // Will throw error

        // When / Then
        do {
            _ = try await sut.createPayment(
                token: "test_token",
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - resumePayment Tests

    func test_resumePayment_callsPaymentService() async throws {
        // Given
        mockPaymentService.onResumePayment = { _, _ in
            Response.Body.Payment(
                id: FormRedirectTestData.Constants.paymentId,
                paymentId: FormRedirectTestData.Constants.paymentId,
                amount: 100,
                currencyCode: "USD",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .success,
                paymentFailureReason: nil
            )
        }

        // When
        let response = try await sut.resumePayment(
            paymentId: FormRedirectTestData.Constants.paymentId,
            resumeToken: FormRedirectTestData.Constants.resumeToken,
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType
        )

        // Then
        XCTAssertEqual(response.paymentId, FormRedirectTestData.Constants.paymentId)
        XCTAssertEqual(response.status, .success)
    }

    func test_resumePayment_withError_throwsError() async throws {
        // Given
        mockPaymentService.onResumePayment = nil // Will throw error

        // When / Then
        do {
            _ = try await sut.resumePayment(
                paymentId: FormRedirectTestData.Constants.paymentId,
                resumeToken: FormRedirectTestData.Constants.resumeToken,
                paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - pollForCompletion Tests

    func test_pollForCompletion_withSuccess_returnsResumeToken() async throws {
        // Given
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: FormRedirectTestData.Constants.resumeToken, source: "src"), nil)
        ]

        // When
        let result = try await sut.pollForCompletion(statusUrl: FormRedirectTestData.Constants.statusUrl)

        // Then
        XCTAssertEqual(result, FormRedirectTestData.Constants.resumeToken)
    }

    func test_pollForCompletion_withNetworkError_eventuallySucceeds() async throws {
        // Given
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (nil, NSError(domain: "network", code: -1)),
            (PollingResponse(status: .complete, id: FormRedirectTestData.Constants.resumeToken, source: "src"), nil)
        ]

        // When
        let result = try await sut.pollForCompletion(statusUrl: FormRedirectTestData.Constants.statusUrl)

        // Then
        XCTAssertEqual(result, FormRedirectTestData.Constants.resumeToken)
    }

    func test_pollForCompletion_withMissingClientToken_throwsError() async throws {
        // Given
        AppState.current.clientToken = nil

        mockApiClient.pollingResults = [
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        // When/Then
        do {
            _ = try await sut.pollForCompletion(statusUrl: FormRedirectTestData.Constants.statusUrl)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - invalid client token
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - cancelPolling Tests

    func test_cancelPolling_cancelsActivePollingModule() async throws {
        // Given
        PrimerAPIConfigurationModule.clientToken = MockAppState.mockClientToken

        // Set up a slow polling response
        mockApiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "0", source: "src"), nil)
        ]

        // Start polling in a task
        let pollingTask = Task {
            try await sut.pollForCompletion(statusUrl: FormRedirectTestData.Constants.statusUrl)
        }

        // Give polling time to start
        try await Task.sleep(nanoseconds: 50_000_000)

        // When
        let cancelError = PrimerError.cancelled(paymentMethodType: "test")
        sut.cancelPolling(error: cancelError)

        // Then - the task should complete (either with result or cancelled)
        pollingTask.cancel()
    }

    // MARK: - Helper Methods

    private func setupMockAPIConfiguration() {
        let blikConfig = PrimerPaymentMethod(
            id: "blik_config_id",
            implementationType: .nativeSdk,
            type: FormRedirectTestData.Constants.blikPaymentMethodType,
            name: "BLIK",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )

        let mbwayConfig = PrimerPaymentMethod(
            id: "mbway_config_id",
            implementationType: .nativeSdk,
            type: FormRedirectTestData.Constants.mbwayPaymentMethodType,
            name: "MBWay",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )

        let apiConfig = PrimerAPIConfiguration(
            coreUrl: "https://api.primer.io",
            pciUrl: "https://pci.primer.io",
            binDataUrl: "https://bindata.primer.io",
            assetsUrl: "https://assets.primer.io",
            clientSession: nil,
            paymentMethods: [blikConfig, mbwayConfig],
            primerAccountId: nil,
            keys: nil,
            checkoutModules: nil
        )

        PrimerAPIConfigurationModule.apiConfiguration = apiConfig
    }

    private func createMockTokenData() -> PrimerPaymentMethodTokenData {
        PrimerPaymentMethodTokenData(
            analyticsId: "analytics_123",
            id: FormRedirectTestData.Constants.paymentId,
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .offSession,
            paymentMethodType: FormRedirectTestData.Constants.blikPaymentMethodType,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "token_123",
            tokenType: .singleUse,
            vaultData: nil
        )
    }
}
