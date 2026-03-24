//
//  AchRepositoryImplTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class AchRepositoryImplTests: XCTestCase {

    private var sut: AchRepositoryImpl!

    override func tearDown() {
        sut = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - Helpers

    private func makeSUT(
        urlScheme: String = "testapp://payment",
        stripeOptions: PrimerStripeOptions? = PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .fullMandate(text: AchTestData.Constants.mandateText)
        )
    ) -> AchRepositoryImpl {
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                urlScheme: urlScheme,
                stripeOptions: stripeOptions
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        return AchRepositoryImpl(settings: settings)
    }

    private func setUpACHSession(
        customer: ClientSession.Customer? = nil,
        paymentMethods: [PrimerPaymentMethod]? = nil
    ) {
        let achPaymentMethod = PrimerPaymentMethod(
            id: "stripe-ach-test",
            implementationType: .nativeSdk,
            type: PrimerPaymentMethodType.stripeAch.rawValue,
            name: "Stripe ACH",
            processorConfigId: "ach-processor",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let methods = paymentMethods ?? [achPaymentMethod]
        SDKSessionHelper.setUp(withPaymentMethods: methods, customer: customer)
    }

    // MARK: - loadUserDetails — Valid Token

    func test_loadUserDetails_validToken_returnsCustomerDetails() async throws {
        // Given
        sut = makeSUT()
        setUpACHSession(customer: ClientSession.Customer(
            id: nil,
            firstName: AchTestData.Constants.firstName,
            lastName: AchTestData.Constants.lastName,
            emailAddress: AchTestData.Constants.emailAddress,
            mobileNumber: nil,
            billingAddress: nil,
            shippingAddress: nil
        ))

        // When
        let result = try await sut.loadUserDetails()

        // Then
        XCTAssertEqual(result.firstName, AchTestData.Constants.firstName)
        XCTAssertEqual(result.lastName, AchTestData.Constants.lastName)
        XCTAssertEqual(result.emailAddress, AchTestData.Constants.emailAddress)
    }

    func test_loadUserDetails_noCustomer_returnsEmptyStrings() async throws {
        // Given
        sut = makeSUT()
        setUpACHSession()

        // When
        let result = try await sut.loadUserDetails()

        // Then
        XCTAssertEqual(result.firstName, "")
        XCTAssertEqual(result.lastName, "")
        XCTAssertEqual(result.emailAddress, "")
    }

    // MARK: - loadUserDetails — Invalid Token

    func test_loadUserDetails_noClientToken_throwsError() async {
        // Given
        sut = makeSUT()
        PrimerAPIConfigurationModule.clientToken = nil

        // When/Then
        do {
            _ = try await sut.loadUserDetails()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - getMandateData — Full Mandate

    func test_getMandateData_fullMandate_returnsFullText() async throws {
        // Given
        sut = makeSUT(stripeOptions: PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .fullMandate(text: AchTestData.Constants.mandateText)
        ))

        // When
        let result = try await sut.getMandateData()

        // Then
        XCTAssertEqual(result.fullMandateText, AchTestData.Constants.mandateText)
        XCTAssertNil(result.templateMandateText)
    }

    // MARK: - getMandateData — Template Mandate

    func test_getMandateData_templateMandate_returnsMerchantName() async throws {
        // Given
        sut = makeSUT(stripeOptions: PrimerStripeOptions(
            publishableKey: "pk_test_123",
            mandateData: .templateMandate(merchantName: AchTestData.Constants.merchantName)
        ))

        // When
        let result = try await sut.getMandateData()

        // Then
        XCTAssertNil(result.fullMandateText)
        XCTAssertEqual(result.templateMandateText, AchTestData.Constants.merchantName)
    }

    // MARK: - getMandateData — Missing Mandate Data

    func test_getMandateData_nilMandateData_throwsMerchantError() async {
        // Given
        sut = makeSUT(stripeOptions: PrimerStripeOptions(publishableKey: "pk_test_123"))

        // When/Then
        do {
            _ = try await sut.getMandateData()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .merchantError = error {
                // Expected
            } else {
                XCTFail("Expected merchantError, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_getMandateData_noStripeOptions_throwsMerchantError() async {
        // Given
        sut = makeSUT(stripeOptions: nil)

        // When/Then
        do {
            _ = try await sut.getMandateData()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .merchantError = error {
                // Expected
            } else {
                XCTFail("Expected merchantError, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - validate — No Payment Method

    func test_validate_noPaymentMethodConfig_throwsError() async {
        // Given
        sut = makeSUT()
        setUpACHSession(paymentMethods: [])

        // When/Then
        do {
            try await sut.validate()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - createPayment — Nil Token

    func test_createPayment_nilToken_throwsError() async {
        // Given
        sut = makeSUT()
        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics_123",
            id: "id_123",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .stripeAch,
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: nil,
            tokenType: .singleUse,
            vaultData: nil
        )

        // When/Then
        do {
            _ = try await sut.createPayment(tokenData: tokenData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - createBankCollector — Missing Publishable Key

    func test_createBankCollector_noStripeOptions_throwsError() async {
        // Given
        sut = makeSUT(stripeOptions: nil)
        let delegate = MockAchBankCollectorDelegate()

        // When/Then
        do {
            _ = try await sut.createBankCollector(
                firstName: "John",
                lastName: "Doe",
                emailAddress: "john@example.com",
                clientSecret: "secret",
                delegate: delegate
            )
            #if canImport(PrimerStripeSDK)
            XCTFail("Expected error to be thrown")
            #endif
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_createBankCollector_emptyPublishableKey_throwsError() async {
        // Given
        sut = makeSUT(stripeOptions: PrimerStripeOptions(publishableKey: ""))
        let delegate = MockAchBankCollectorDelegate()

        // When/Then
        do {
            _ = try await sut.createBankCollector(
                firstName: "John",
                lastName: "Doe",
                emailAddress: "john@example.com",
                clientSecret: "secret",
                delegate: delegate
            )
            #if canImport(PrimerStripeSDK)
            XCTFail("Expected error to be thrown")
            #endif
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - startPaymentAndGetStripeData — No Payment Method

    func test_startPaymentAndGetStripeData_noACHPaymentMethod_throwsError() async {
        // Given
        sut = makeSUT()
        setUpACHSession(paymentMethods: [])

        // When/Then
        do {
            _ = try await sut.startPaymentAndGetStripeData()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - tokenize — No Payment Method

    func test_tokenize_noACHPaymentMethod_throwsError() async {
        // Given
        sut = makeSUT()
        setUpACHSession(paymentMethods: [])

        // When/Then
        do {
            _ = try await sut.tokenize()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }
}

// MARK: - Mock ACH Bank Collector Delegate

@available(iOS 15.0, *)
private final class MockAchBankCollectorDelegate: AchBankCollectorDelegate {

    private(set) var didSucceedPaymentId: String?
    private(set) var didCancelCalled = false
    private(set) var didFailError: PrimerError?

    func achBankCollectorDidSucceed(paymentId: String) {
        didSucceedPaymentId = paymentId
    }

    func achBankCollectorDidCancel() {
        didCancelCalled = true
    }

    func achBankCollectorDidFail(error: PrimerError) {
        didFailError = error
    }
}
