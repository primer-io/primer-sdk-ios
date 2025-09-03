//
//  StripeAchTokenizationViewModelTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class StripeAchTokenizationViewModelTests: XCTestCase {
    // MARK: - Test Dependencies

    private var sut: StripeAchTokenizationViewModel!
    private var apiClient: MockPrimerAPIClient!
    private var tokenizationService: MockTokenizationService!
    private var createResumePaymentService: MockCreateResumePaymentService!
    private var uiManager: MockPrimerUIManager!
    private var appState: MockAppState!
    private var mandateDelegate: ACHMandateDelegate?

    // MARK: - Test Helper Data

    private let stripeACHPaymentMethodType = "STRIPE_ACH"

    private let stripeACHPaymentMethod = PrimerPaymentMethod(
        id: "STRIPE_ACH",
        implementationType: .nativeSdk,
        type: "STRIPE_ACH",
        name: "Mock StripeACH Payment Method",
        processorConfigId: "mock_processor_config_id",
        surcharge: 299,
        options: nil,
        displayMetadata: nil
    )

    private let order = ClientSession.Order(
        id: "order_id",
        merchantAmount: 1234,
        totalOrderAmount: 1234,
        totalTaxAmount: nil,
        countryCode: .us,
        currencyCode: Currency(code: "USD", decimalDigits: 2),
        fees: nil,
        lineItems: [
            .init(itemId: "item_id",
                  quantity: 1,
                  amount: 1234,
                  discountAmount: nil,
                  name: "my_item",
                  description: "item_description",
                  taxAmount: nil,
                  taxCode: nil,
                  productType: nil)
        ]
    )

    private let paymentResponseBody = Response.Body.Payment(
        id: "id",
        paymentId: "payment_id",
        amount: 123,
        currencyCode: "USD",
        customer: .init(
            firstName: "first_name",
            lastName: "last_name",
            emailAddress: "email_address",
            mobileNumber: "+44(0)7891234567",
            billingAddress: .init(
                firstName: "billing_first_name",
                lastName: "billing_last_name",
                addressLine1: "billing_line_1",
                addressLine2: "billing_line_2",
                city: "billing_city",
                state: "billing_state",
                countryCode: "billing_country_code",
                postalCode: "billing_postal_code"
            ),
            shippingAddress: .init(
                firstName: "shipping_first_name",
                lastName: "shipping_last_name",
                addressLine1: "shipping_line_1",
                addressLine2: "shipping_line_2",
                city: "shipping_city",
                state: "shipping_state",
                countryCode: "shipping_country_code",
                postalCode: "shipping_postal_code"
            )
        ),
        customerId: "customer_id",
        orderId: "order_id",
        requiredAction: .init(clientToken: MockAppState.stripeACHToken, name: .checkout, description: "description"),
        status: .success
    )

    private let tokenizationResponseBody = Response.Body.Tokenization(
        analyticsId: "analytics_id",
        id: "id",
        isVaulted: false,
        isAlreadyVaulted: false,
        paymentInstrumentType: .stripeAch,
        paymentMethodType: "STRIPE_ACH",
        paymentInstrumentData: nil,
        threeDSecureAuthentication: nil,
        token: "token",
        tokenType: .singleUse,
        vaultData: nil
    )

    // MARK: - Setup & Teardown

    override func setUpWithError() throws {
        apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient

        SDKSessionHelper.setUp(order: order)
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()

        sut = StripeAchTokenizationViewModel(
            config: stripeACHPaymentMethod,
            uiManager: uiManager,
            tokenizationService: tokenizationService,
            createResumePaymentService: createResumePaymentService
        )
        mandateDelegate = sut

        let settings = PrimerSettings(paymentMethodOptions:
            PrimerPaymentMethodOptions(urlScheme: "test://primer.io",
                                       stripeOptions: PrimerStripeOptions(publishableKey: "test-pk-1234")))

        DependencyContainer.register(settings as PrimerSettingsProtocol)

        appState = MockAppState()
        appState.amount = 1234
        appState.currency = Currency(code: "USD", decimalDigits: 2)
        DependencyContainer.register(appState as AppStateProtocol)
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        mandateDelegate = nil
        SDKSessionHelper.tearDown()
    }

    // MARK: - Validation Tests

    func test_validation_requiresValidConfiguration() throws {
        XCTAssertNoThrow(try sut.validate())
    }

    // MARK: - Async Flow Tests

    func test_startFlow_whenAborted_shouldCallOnDidFail() throws {
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentWithData = self.expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, self.stripeACHPaymentMethodType)
            decision(.abortPaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidFail = self.expectation(description: "flow fails with error")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError:
                break
            default:
                XCTFail()
            }
            expectDidFail.fulfill()
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentWithData,
            expectDidFail
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_startFlow_fullCheckout_shouldCompleteSuccessfully() throws {
        SDKSessionHelper.setUp(order: order)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.sdkCompleteUrlResult = (Response.Body.Complete(), nil)

        let expectWillCreatePaymentWithData = self.expectation(description: "payment data creation requested")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, self.stripeACHPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentWithData.fulfill()
        }

        let expectDidStartTokenization = self.expectation(description: "tokenization begins")
        delegate.onDidStartTokenization = { paymentType in
            XCTAssertEqual(paymentType, self.stripeACHPaymentMethodType)
            expectDidStartTokenization.fulfill()
        }

        let expectDidTokenize = self.expectation(description: "payment method tokenized")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return .success(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "payment created")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        let expectDidReceiveStripeCollectorAdditionalInfo = self.expectation(description: "Stripe bank account collector info received")
        let expectDidReceiveMandateAdditionalInfo = self.expectation(description: "mandate additional info received")
        delegate.onDidReceiveAdditionalInfo = { additionalInfo in
            if additionalInfo is ACHBankAccountCollectorAdditionalInfo {
                expectDidReceiveStripeCollectorAdditionalInfo.fulfill()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.sut.stripeBankAccountCollectorCompletion?(.success(()))
                }
            } else {
                expectDidReceiveMandateAdditionalInfo.fulfill()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.mandateDelegate?.acceptMandate()
                }
            }
        }

        let expectDidCompleteCheckoutWithData = self.expectation(description: "checkout completes successfully")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectDidCompleteCheckoutWithData.fulfill()
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentWithData,
            expectDidStartTokenization,
            expectDidTokenize,
            expectDidCreatePayment,
            expectDidReceiveStripeCollectorAdditionalInfo,
            expectDidReceiveMandateAdditionalInfo,
            expectDidCompleteCheckoutWithData
        ], timeout: 10.0, enforceOrder: true)
    }
}
