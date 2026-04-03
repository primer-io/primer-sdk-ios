//
//  KlarnaRepositoryImplTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class KlarnaRepositoryImplTests: XCTestCase {

    private var mockApiClient: MockPrimerAPIClient!
    private var mockTokenizationService: MockTokenizationService!
    private var mockPaymentService: MockCreateResumePaymentService!
    private var sut: KlarnaRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockApiClient = MockPrimerAPIClient()
        mockApiClient.mockedNetworkDelay = 0
        mockTokenizationService = MockTokenizationService()
        mockPaymentService = MockCreateResumePaymentService()

        sut = KlarnaRepositoryImpl(
            apiClient: mockApiClient,
            tokenizationService: mockTokenizationService,
            createResumePaymentService: mockPaymentService
        )
    }

    override func tearDown() {
        sut = nil
        mockApiClient = nil
        mockTokenizationService = nil
        mockPaymentService = nil
        PrimerAPIConfigurationModule.apiConfiguration = nil
        PrimerAPIConfigurationModule.clientToken = nil
        PrimerInternal.shared.intent = nil
        super.tearDown()
    }

    // MARK: - createSession — Invalid Token

    func test_createSession_noClientToken_throwsInvalidTokenError() async {
        // Given
        PrimerAPIConfigurationModule.clientToken = nil

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .invalidClientToken:
                break
            default:
                XCTFail("Expected invalidClientToken, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createSession_expiredClientToken_throwsInvalidTokenError() async {
        // Given
        AppState.current.clientToken = "invalid.token.value"

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .invalidClientToken:
                break
            default:
                XCTFail("Expected invalidClientToken, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - createSession — Missing Payment Method Config

    func test_createSession_noKlarnaPaymentMethod_throwsMissingSDKError() async {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [])

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .missingSDK:
                break
            default:
                XCTFail("Expected missingSDK error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createSession_klarnaPaymentMethodWithNilId_throwsMissingSDKError() async {
        // Given
        let klarnaNoId = PrimerPaymentMethod(
            id: nil,
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.klarna.rawValue,
            name: "Klarna",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [klarnaNoId])

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .missingSDK:
                break
            default:
                XCTFail("Expected missingSDK error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - createSession — One-Off Payment Validation

    func test_createSession_oneOffPayment_noAmount_throwsInvalidSettingError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: nil,
            totalOrderAmount: nil,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: [
                ClientSession.Order.LineItem(
                    itemId: "item-1",
                    quantity: 1,
                    amount: 100,
                    discountAmount: nil,
                    name: "Item 1",
                    description: nil,
                    taxAmount: nil,
                    taxCode: nil,
                    productType: nil
                ),
            ]
        ))

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "amount")
            default:
                XCTFail("Expected invalidValue(amount), got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createSession_oneOffPayment_noCurrency_throwsInvalidSettingError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: nil,
            fees: nil,
            lineItems: [
                ClientSession.Order.LineItem(
                    itemId: "item-1",
                    quantity: 1,
                    amount: 100,
                    discountAmount: nil,
                    name: "Item 1",
                    description: nil,
                    taxAmount: nil,
                    taxCode: nil,
                    productType: nil
                ),
            ]
        ))

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "currency")
            default:
                XCTFail("Expected invalidValue(currency), got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createSession_oneOffPayment_noLineItems_throwsInvalidSettingError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: nil
        ))

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "lineItems")
            default:
                XCTFail("Expected invalidValue(lineItems), got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createSession_oneOffPayment_emptyLineItems_throwsInvalidSettingError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: []
        ))

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "lineItems")
            default:
                XCTFail("Expected invalidValue(lineItems), got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createSession_oneOffPayment_lineItemWithNilAmount_throwsInvalidValueError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: [
                ClientSession.Order.LineItem(
                    itemId: "item-1",
                    quantity: 1,
                    amount: nil,
                    discountAmount: nil,
                    name: "Item 1",
                    description: nil,
                    taxAmount: nil,
                    taxCode: nil,
                    productType: nil
                ),
            ]
        ))

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "settings.orderItems")
            default:
                XCTFail("Expected invalidValue(settings.orderItems), got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - createSession — API Error

    func test_createSession_apiClientConfigUpdateFails_throwsError() async {
        // Given
        PrimerInternal.shared.intent = .vault
        setupKlarnaConfig()

        let expectedError = NSError(domain: "test", code: 500, userInfo: nil)
        mockApiClient.fetchConfigurationWithActionsResult = (nil, expectedError)

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }

    // MARK: - tokenize — Invalid Token

    func test_tokenize_noClientToken_throwsInvalidTokenError() async {
        // Given
        PrimerAPIConfigurationModule.clientToken = nil

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .invalidClientToken:
                break
            default:
                XCTFail("Expected invalidClientToken, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - tokenize — Missing Payment Method Config

    func test_tokenize_noKlarnaPaymentMethod_throwsMissingSDKError() async {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [])

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .missingSDK:
                break
            default:
                XCTFail("Expected missingSDK error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_tokenize_klarnaPaymentMethodWithNilId_throwsMissingSDKError() async {
        // Given
        let klarnaNoId = PrimerPaymentMethod(
            id: nil,
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.klarna.rawValue,
            name: "Klarna",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [klarnaNoId])

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .missingSDK:
                break
            default:
                XCTFail("Expected missingSDK error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - tokenize — Missing Session ID

    func test_tokenize_noPaymentSessionId_throwsInvalidValueError() async {
        // Given
        setupKlarnaConfig()

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "paymentSessionId")
            default:
                XCTFail("Expected invalidValue(paymentSessionId), got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - configureForCategory — Test Flow

    func test_configureForCategory_testFlow_returnsNil() async throws {
        // Given
        setupKlarnaConfig(showTestId: true)

        // When
        let view = try await sut.configureForCategory(
            clientToken: "client_token",
            categoryId: "pay_now"
        )

        // Then
        XCTAssertNil(view)
    }

    // MARK: - configureForCategory — Without PrimerKlarnaSDK

    #if !canImport(PrimerKlarnaSDK)
        func test_configureForCategory_noKlarnaSDK_throwsMissingSDKError() async {
            // Given
            setupKlarnaConfig()

            // When/Then
            do {
                _ = try await sut.configureForCategory(
                    clientToken: "client_token",
                    categoryId: "pay_now"
                )
                XCTFail("Expected error to be thrown")
            } catch let error as PrimerError {
                switch error {
                case .missingSDK:
                    break
                default:
                    XCTFail("Expected missingSDK error, got: \(error)")
                }
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    #endif

    // MARK: - authorize — Test Flow

    func test_authorize_testFlow_returnsApprovedWithMockToken() async throws {
        // Given
        setupKlarnaConfig(showTestId: true)

        // When
        let result = try await sut.authorize()

        // Then
        switch result {
        case let .approved(authToken):
            XCTAssertFalse(authToken.isEmpty)
        default:
            XCTFail("Expected approved result, got: \(result)")
        }
    }

    // MARK: - authorize — Without PrimerKlarnaSDK

    #if !canImport(PrimerKlarnaSDK)
        func test_authorize_noKlarnaSDK_throwsMissingSDKError() async {
            // Given
            setupKlarnaConfig()

            // When/Then
            do {
                _ = try await sut.authorize()
                XCTFail("Expected error to be thrown")
            } catch let error as PrimerError {
                switch error {
                case .missingSDK:
                    break
                default:
                    XCTFail("Expected missingSDK error, got: \(error)")
                }
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    #endif

    // MARK: - finalize — Without PrimerKlarnaSDK

    #if !canImport(PrimerKlarnaSDK)
        func test_finalize_noKlarnaSDK_throwsMissingSDKError() async {
            // Given
            setupKlarnaConfig()

            // When/Then
            do {
                _ = try await sut.finalize()
                XCTFail("Expected error to be thrown")
            } catch let error as PrimerError {
                switch error {
                case .missingSDK:
                    break
                default:
                    XCTFail("Expected missingSDK error, got: \(error)")
                }
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    #endif

    // MARK: - KlarnaSessionResult Model

    func test_klarnaSessionResult_storesAllProperties() {
        // Given/When
        let categories = KlarnaTestData.allCategories
        let result = KlarnaSessionResult(
            clientToken: "ct",
            sessionId: "sid",
            categories: categories,
            hppSessionId: "hpp"
        )

        // Then
        XCTAssertEqual(result.clientToken, "ct")
        XCTAssertEqual(result.sessionId, "sid")
        XCTAssertEqual(result.categories.count, 3)
        XCTAssertEqual(result.hppSessionId, "hpp")
    }

    func test_klarnaSessionResult_nilHppSessionId() {
        // Given/When
        let result = KlarnaSessionResult(
            clientToken: "ct",
            sessionId: "sid",
            categories: [],
            hppSessionId: nil
        )

        // Then
        XCTAssertNil(result.hppSessionId)
        XCTAssertTrue(result.categories.isEmpty)
    }

    // MARK: - KlarnaAuthorizationResult Equatable

    func test_authorizationResult_approvedSameTokens_equal() {
        XCTAssertEqual(
            KlarnaAuthorizationResult.approved(authToken: "t1"),
            KlarnaAuthorizationResult.approved(authToken: "t1")
        )
    }

    func test_authorizationResult_approvedDifferentTokens_notEqual() {
        XCTAssertNotEqual(
            KlarnaAuthorizationResult.approved(authToken: "t1"),
            KlarnaAuthorizationResult.approved(authToken: "t2")
        )
    }

    func test_authorizationResult_finalizationRequiredSameTokens_equal() {
        XCTAssertEqual(
            KlarnaAuthorizationResult.finalizationRequired(authToken: "t1"),
            KlarnaAuthorizationResult.finalizationRequired(authToken: "t1")
        )
    }

    func test_authorizationResult_declined_equal() {
        XCTAssertEqual(
            KlarnaAuthorizationResult.declined,
            KlarnaAuthorizationResult.declined
        )
    }

    func test_authorizationResult_differentCases_notEqual() {
        let approved = KlarnaAuthorizationResult.approved(authToken: "t")
        let finalization = KlarnaAuthorizationResult.finalizationRequired(authToken: "t")
        let declined = KlarnaAuthorizationResult.declined

        XCTAssertNotEqual(approved, finalization)
        XCTAssertNotEqual(approved, declined)
        XCTAssertNotEqual(finalization, declined)
    }

    // MARK: - createSession — Successful Recurring Payment

    func test_createSession_recurringPayment_skipsOneOffValidation() async {
        // Given — vault intent skips one-off validation (no amount/currency needed)
        PrimerInternal.shared.intent = .vault
        setupKlarnaConfig()

        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "klarna_ct",
                sessionId: "klarna_sid",
                categories: [
                    Response.Body.Klarna.SessionCategory(
                        identifier: "pay_later",
                        name: "Pay Later",
                        descriptiveAssetUrl: "https://example.com/desc",
                        standardAssetUrl: "https://example.com/std"
                    ),
                ],
                hppSessionId: "hpp_123",
                hppRedirectUrl: nil
            ),
            nil
        )

        // When
        let result = try? await sut.createSession()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.clientToken, "klarna_ct")
        XCTAssertEqual(result?.sessionId, "klarna_sid")
        XCTAssertEqual(result?.categories.count, 1)
        XCTAssertEqual(result?.categories.first?.id, "pay_later")
        XCTAssertEqual(result?.hppSessionId, "hpp_123")
    }

    func test_createSession_recurringPayment_mapsMultipleCategories() async {
        // Given
        PrimerInternal.shared.intent = .vault
        setupKlarnaConfig()

        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "ct",
                sessionId: "sid",
                categories: [
                    Response.Body.Klarna.SessionCategory(
                        identifier: "pay_now",
                        name: "Pay Now",
                        descriptiveAssetUrl: "https://example.com/desc1",
                        standardAssetUrl: "https://example.com/std1"
                    ),
                    Response.Body.Klarna.SessionCategory(
                        identifier: "pay_later",
                        name: "Pay Later",
                        descriptiveAssetUrl: "https://example.com/desc2",
                        standardAssetUrl: "https://example.com/std2"
                    ),
                ],
                hppSessionId: nil,
                hppRedirectUrl: nil
            ),
            nil
        )

        // When
        let result = try? await sut.createSession()

        // Then
        XCTAssertEqual(result?.categories.count, 2)
        XCTAssertNil(result?.hppSessionId)
    }

    // MARK: - createSession — Klarna Session API Error

    func test_createSession_klarnaSessionApiFails_throwsError() async {
        // Given
        PrimerInternal.shared.intent = .vault
        setupKlarnaConfig()

        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)

        let expectedError = NSError(domain: "test", code: 503, userInfo: nil)
        mockApiClient.createKlarnaPaymentSessionResult = (nil, expectedError)

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is NSError)
        }
    }

    // MARK: - tokenize — No Decoded JWT

    func test_tokenize_expiredClientToken_throwsInvalidTokenError() async {
        // Given
        AppState.current.clientToken = "invalid.token.value"

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case .invalidClientToken:
                break
            default:
                XCTFail("Expected invalidClientToken, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - authorize — Test Flow Auth Token Not Empty

    func test_authorize_testFlow_returnsNonEmptyAuthToken() async throws {
        // Given
        setupKlarnaConfig(showTestId: true)

        // When
        let result = try await sut.authorize()

        // Then
        switch result {
        case let .approved(authToken):
            XCTAssertEqual(authToken.count, 36) // UUID string length
        default:
            XCTFail("Expected approved result, got: \(result)")
        }
    }

    // MARK: - configureForCategory — Test Flow With Different Categories

    func test_configureForCategory_testFlow_differentCategories_returnsNil() async throws {
        // Given
        setupKlarnaConfig(showTestId: true)

        // When/Then — all categories should return nil in test flow
        for categoryId in ["pay_now", "pay_later", "slice_it"] {
            let view = try await sut.configureForCategory(
                clientToken: "client_token",
                categoryId: categoryId
            )
            XCTAssertNil(view)
        }
    }

    // MARK: - createSession — One-Off Valid Configuration

    func test_createSession_oneOffPayment_validConfig_callsAPIClient() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: [
                ClientSession.Order.LineItem(
                    itemId: "item-1",
                    quantity: 1,
                    amount: 100,
                    discountAmount: nil,
                    name: "Item 1",
                    description: nil,
                    taxAmount: nil,
                    taxCode: nil,
                    productType: nil
                ),
            ]
        ))

        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "ct",
                sessionId: "sid",
                categories: [],
                hppSessionId: nil,
                hppRedirectUrl: nil
            ),
            nil
        )

        // When
        let result = try? await sut.createSession()

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.clientToken, "ct")
    }

    // MARK: - KlarnaSessionResult — Empty Categories

    func test_klarnaSessionResult_emptyCategories() {
        // Given/When
        let result = KlarnaSessionResult(
            clientToken: "ct",
            sessionId: "sid",
            categories: [],
            hppSessionId: "hpp"
        )

        // Then
        XCTAssertTrue(result.categories.isEmpty)
        XCTAssertEqual(result.hppSessionId, "hpp")
    }

    // MARK: - KlarnaAuthorizationResult — Finalization Different Tokens

    func test_authorizationResult_finalizationRequiredDifferentTokens_notEqual() {
        XCTAssertNotEqual(
            KlarnaAuthorizationResult.finalizationRequired(authToken: "t1"),
            KlarnaAuthorizationResult.finalizationRequired(authToken: "t2")
        )
    }

    // MARK: - createSession — Updates Client Session

    func test_createSession_recurringPayment_updatesClientSession() async {
        // Given
        PrimerInternal.shared.intent = .vault
        setupKlarnaConfig()

        let updatedSession = ClientSession.APIResponse(
            clientSessionId: "updated_session",
            paymentMethod: nil,
            order: nil,
            customer: nil,
            testId: nil
        )
        let updatedConfig = Response.Body.Configuration(
            coreUrl: "core_url",
            pciUrl: "pci_url",
            binDataUrl: "bindata_url",
            assetsUrl: "https://assets.staging.core.primer.io",
            clientSession: updatedSession,
            paymentMethods: PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods,
            primerAccountId: "account_id",
            keys: nil,
            checkoutModules: nil
        )
        mockApiClient.fetchConfigurationWithActionsResult = (updatedConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "ct",
                sessionId: "sid",
                categories: [],
                hppSessionId: nil,
                hppRedirectUrl: nil
            ),
            nil
        )

        // When
        _ = try? await sut.createSession()

        // Then — client session should be updated
        XCTAssertEqual(
            PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.clientSessionId,
            "updated_session"
        )
    }

    // MARK: - tokenize — Missing Payment Session ID After Create

    func test_tokenize_afterFreshInit_throwsMissingSessionId() async {
        // Given — no createSession called, so paymentSessionId is nil
        setupKlarnaConfig()

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "paymentSessionId")
            default:
                XCTFail("Expected invalidValue(paymentSessionId), got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - tokenize — One-Off Payment Happy Path

    func test_tokenize_oneOffPayment_successfulFlow_returnsPaymentResult() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: [
                ClientSession.Order.LineItem(
                    itemId: "item-1", quantity: 1, amount: 100,
                    discountAmount: nil, name: "Item 1", description: nil,
                    taxAmount: nil, taxCode: nil, productType: nil
                ),
            ]
        ))

        // Set up mocks to reach tokenize through createSession first
        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "klarna_ct",
                sessionId: "klarna_sid",
                categories: [
                    Response.Body.Klarna.SessionCategory(
                        identifier: "pay_now", name: "Pay Now",
                        descriptiveAssetUrl: "https://example.com/desc",
                        standardAssetUrl: "https://example.com/std"
                    ),
                ],
                hppSessionId: nil,
                hppRedirectUrl: nil
            ),
            nil
        )

        _ = try await sut.createSession()

        // Set up finalize session for one-off payment
        let customerToken = Response.Body.Klarna.CustomerToken(
            customerTokenId: nil,
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: nil,
                purchaseCountry: "US",
                purchaseCurrency: "USD",
                locale: "en-US",
                orderAmount: 1000,
                orderTaxAmount: nil,
                orderLines: [],
                billingAddress: nil,
                shippingAddress: nil,
                tokenDetails: nil
            )
        )
        mockApiClient.finalizeKlarnaPaymentSessionResult = (customerToken, nil)

        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics-1",
            id: "token-1",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .klarna,
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "tok_klarna_123",
            tokenType: .singleUse,
            vaultData: nil
        )
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        let paymentResponse = Response.Body.Payment(
            id: "pay_klarna",
            paymentId: "pay_klarna",
            amount: 1000,
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
        mockPaymentService.onCreatePayment = { _ in paymentResponse }

        // When
        let result = try await sut.tokenize(authToken: "auth_token_123")

        // Then
        XCTAssertEqual(result.paymentId, "pay_klarna")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.token, "tok_klarna_123")
        XCTAssertEqual(result.paymentMethodType, PrimerPaymentMethodType.klarna.rawValue)
    }

    // MARK: - tokenize — Recurring Payment Happy Path

    func test_tokenize_recurringPayment_successfulFlow_returnsPaymentResult() async throws {
        // Given
        PrimerInternal.shared.intent = .vault
        setupKlarnaConfig()

        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "ct", sessionId: "sid",
                categories: [
                    Response.Body.Klarna.SessionCategory(
                        identifier: "pay_later", name: "Pay Later",
                        descriptiveAssetUrl: "https://example.com/d",
                        standardAssetUrl: "https://example.com/s"
                    ),
                ],
                hppSessionId: nil, hppRedirectUrl: nil
            ),
            nil
        )

        _ = try await sut.createSession()

        let customerToken = Response.Body.Klarna.CustomerToken(
            customerTokenId: "klarna_customer_tok",
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: "Monthly payment",
                purchaseCountry: "US",
                purchaseCurrency: "USD",
                locale: "en-US",
                orderAmount: nil,
                orderTaxAmount: nil,
                orderLines: [],
                billingAddress: nil,
                shippingAddress: nil,
                tokenDetails: nil
            )
        )
        mockApiClient.createKlarnaCustomerTokenResult = (customerToken, nil)

        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics-2",
            id: "token-2",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .klarna,
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "tok_klarna_recurring",
            tokenType: .singleUse,
            vaultData: nil
        )
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        let paymentResponse = Response.Body.Payment(
            id: "pay_recurring",
            paymentId: "pay_recurring",
            amount: nil,
            currencyCode: nil,
            customer: nil,
            customerId: nil,
            dateStr: nil,
            order: nil,
            orderId: nil,
            requiredAction: nil,
            status: .success,
            paymentFailureReason: nil
        )
        mockPaymentService.onCreatePayment = { _ in paymentResponse }

        // When
        let result = try await sut.tokenize(authToken: "auth_recurring")

        // Then
        XCTAssertEqual(result.paymentId, "pay_recurring")
        XCTAssertEqual(result.status, .success)
    }

    // MARK: - tokenize — Nil Token After Tokenization

    func test_tokenize_nilTokenInTokenData_throwsError() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        setupKlarnaConfig(order: ClientSession.Order(
            id: "order-1",
            merchantAmount: 1000,
            totalOrderAmount: 1000,
            totalTaxAmount: nil,
            countryCode: .us,
            currencyCode: Currency(code: "USD", decimalDigits: 2),
            fees: nil,
            lineItems: [
                ClientSession.Order.LineItem(
                    itemId: "item-1", quantity: 1, amount: 100,
                    discountAmount: nil, name: "Item 1", description: nil,
                    taxAmount: nil, taxCode: nil, productType: nil
                ),
            ]
        ))

        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "ct", sessionId: "sid", categories: [],
                hppSessionId: nil, hppRedirectUrl: nil
            ),
            nil
        )

        _ = try await sut.createSession()

        let customerToken = Response.Body.Klarna.CustomerToken(
            customerTokenId: nil,
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: nil, purchaseCountry: nil, purchaseCurrency: nil,
                locale: nil, orderAmount: nil, orderTaxAmount: nil, orderLines: [],
                billingAddress: nil, shippingAddress: nil, tokenDetails: nil
            )
        )
        mockApiClient.finalizeKlarnaPaymentSessionResult = (customerToken, nil)

        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics-nil",
            id: "token-nil",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .klarna,
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: nil,
            tokenType: .singleUse,
            vaultData: nil
        )
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_tok")
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case .invalidClientToken = error {
                // Expected — nil token triggers invalidClientToken
            } else {
                XCTFail("Expected invalidClientToken, got: \(error)")
            }
        }
    }

    // MARK: - tokenize — Recurring Payment Missing Customer Token ID

    func test_tokenize_recurringPayment_missingCustomerTokenId_throwsError() async throws {
        // Given
        PrimerInternal.shared.intent = .vault
        setupKlarnaConfig()

        let mockConfig = PrimerAPIConfigurationModule.apiConfiguration!
        mockApiClient.fetchConfigurationWithActionsResult = (mockConfig, nil)
        mockApiClient.createKlarnaPaymentSessionResult = (
            Response.Body.Klarna.PaymentSession(
                clientToken: "ct", sessionId: "sid", categories: [],
                hppSessionId: nil, hppRedirectUrl: nil
            ),
            nil
        )

        _ = try await sut.createSession()

        let customerToken = Response.Body.Klarna.CustomerToken(
            customerTokenId: nil,
            sessionData: Response.Body.Klarna.SessionData(
                recurringDescription: nil, purchaseCountry: nil, purchaseCurrency: nil,
                locale: nil, orderAmount: nil, orderTaxAmount: nil, orderLines: [],
                billingAddress: nil, shippingAddress: nil, tokenDetails: nil
            )
        )
        mockApiClient.createKlarnaCustomerTokenResult = (customerToken, nil)

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: "auth_tok")
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case let .invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "tokenization.customerToken")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private func setupKlarnaConfig(
        order: ClientSession.Order? = nil,
        showTestId: Bool = false
    ) {
        let klarnaPaymentMethod = PrimerPaymentMethod(
            id: "klarna_config_id",
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.klarna.rawValue,
            name: "Klarna",
            processorConfigId: nil,
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(
            withPaymentMethods: [klarnaPaymentMethod],
            order: order,
            showTestId: showTestId
        )
    }
}
