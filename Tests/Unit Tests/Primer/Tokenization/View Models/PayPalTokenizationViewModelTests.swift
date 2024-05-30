//
//  PayPalTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 28/05/2024.
//

import XCTest
import AuthenticationServices
@testable import PrimerSDK

final class PayPalTokenizationViewModelTests: XCTestCase {

    var uiManager: MockPrimerUIManager!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var sut: PayPalTokenizationViewModel!

    override func setUpWithError() throws {

        uiManager = MockPrimerUIManager()
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()

        sut = PayPalTokenizationViewModel(config: Mocks.PaymentMethods.adyenIDealPaymentMethod,
                                          uiManager: uiManager,
                                          tokenizationService: tokenizationService,
                                          createResumePaymentService: createResumePaymentService)
    }

    override func tearDownWithError() throws {
        sut = nil
        createResumePaymentService = nil
        tokenizationService = nil
        uiManager = nil
    }

    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        let mockViewController = MockPrimerRootViewController()
        uiManager.onPrepareViewController = {
            self.uiManager.primerRootViewController = mockViewController
            return Promise.fulfilled(())
        }

        _ = uiManager.prepareRootViewController()

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
            decision(.abortPaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectWillAbort = self.expectation(description: "onDidAbort is called")
        delegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError:
                break
            default:
                XCTFail()
            }
            expectWillAbort.fulfill()
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectWillAbort
        ], timeout: 10.0, enforceOrder: true)
    }

    func testStartWithFullCheckoutFlow() throws {
        SDKSessionHelper.setUp()
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        let uiDelegate = MockPrimerHeadlessUniversalCheckoutUIDelegate()
        PrimerHeadlessUniversalCheckout.current.uiDelegate = uiDelegate

        PrimerInternal.shared.intent = .checkout

        let settings = PrimerSettings(paymentMethodOptions: .init(urlScheme: "urlscheme://app"))
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let payPalService = MockPayPalService()
        sut.payPalService = payPalService
        payPalService.onStartOrderSession = {
            return .init(orderId: "order_id", approvalUrl: "https://approval.url/")
        }
        payPalService.onFetchPayPalExternalPayerInfo = { _ in
            return .init(orderId: "order_id", externalPayerInfo: .init(externalPayerId: "external_payer_id",
                                                                       email: "john@appleseed.com",
                                                                       firstName: "John",
                                                                       lastName: "Appleseed"))
        }

        let webAuthenticationService = MockWebAuthenticationService()
        sut.webAuthenticationService = webAuthenticationService
        webAuthenticationService.onConnect = { _, _ in
            return URL(string: "https://webauthsvc.app/")!
        }

        let mockViewController = MockPrimerRootViewController()
        uiManager.onPrepareViewController = {
            self.uiManager.primerRootViewController = mockViewController
            return Promise.fulfilled(())
        }

        let expectShowPaymentMethod = self.expectation(description: "Showed view controller")
        uiDelegate.onUIDidShowPaymentMethod = { _ in
            expectShowPaymentMethod.fulfill()
        }

        _ = uiManager.prepareRootViewController()

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, "ADYEN_IDEAL")
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectCheckoutDidCompletewithData = self.expectation(description: "Did complete checkout with data")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectCheckoutDidCompletewithData.fulfill()
        }

        let expectOnTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { body in
            expectOnTokenize.fulfill()
            return Promise.fulfilled(self.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { body in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectShowPaymentMethod,
            expectOnTokenize,
            expectDidCreatePayment,
            expectCheckoutDidCompletewithData
        ], timeout: 40.0, enforceOrder: true)
    }
    
    // MARK: Helpers

    var tokenizationResponseBody: Response.Body.Tokenization {
        .init(analyticsId: "analytics_id",
              id: "id",
              isVaulted: false,
              isAlreadyVaulted: false,
              paymentInstrumentType: .offSession,
              paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
              paymentInstrumentData: nil,
              threeDSecureAuthentication: nil,
              token: "token",
              tokenType: .singleUse,
              vaultData: nil)
    }

    var paymentResponseBody: Response.Body.Payment {
        return .init(id: "id",
                     paymentId: "payment_id",
                     amount: 123,
                     currencyCode: "GBP",
                     customer: .init(firstName: "first_name",
                                     lastName: "last_name",
                                     emailAddress: "email_address",
                                     mobileNumber: "+44(0)7891234567",
                                     billingAddress: .init(firstName: "billing_first_name",
                                                           lastName: "billing_last_name",
                                                           addressLine1: "billing_line_1",
                                                           addressLine2: "billing_line_2",
                                                           city: "billing_city",
                                                           state: "billing_state",
                                                           countryCode: "billing_country_code",
                                                           postalCode: "billing_postal_code"),
                                     shippingAddress: .init(firstName: "shipping_first_name",
                                                            lastName: "shipping_last_name",
                                                            addressLine1: "shipping_line_1",
                                                            addressLine2: "shipping_line_2",
                                                            city: "shipping_city",
                                                            state: "shipping_state",
                                                            countryCode: "shipping_country_code",
                                                            postalCode: "shipping_postal_code")),
                     customerId: "customer_id",
                     dateStr: nil,
                     order: nil,
                     orderId: "order_id",
                     requiredAction: nil,
                     status: .success,
                     paymentFailureReason: nil)
    }
}

class MockPayPalService: PayPalServiceProtocol {

    // MARK: startOrderSession

    var onStartOrderSession: (() -> Response.Body.PayPal.CreateOrder)?

    func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, any Error>) -> Void) {
        if let onStartOrderSession = onStartOrderSession {
            completion(.success(onStartOrderSession()))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    // MARK: startBillingAgreementSession

    var onStartBillingAgreementSession: (() -> String)?

    func startBillingAgreementSession(_ completion: @escaping (Result<String, any Error>) -> Void) {
        if let onStartBillingAgreementSession {
            completion(.success(onStartBillingAgreementSession()))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
    
    // MARK: confirmBillingAgreement

    var onConfirmBillingAgreement: (() -> Response.Body.PayPal.ConfirmBillingAgreement)?

    func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, any Error>) -> Void) {
        if let onConfirmBillingAgreement {
            completion(.success(onConfirmBillingAgreement()))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }

    // MARK: fetchPayPalExternalPayerInfo

    var onFetchPayPalExternalPayerInfo: ((String) -> Response.Body.PayPal.PayerInfo)?

    func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, any Error>) -> Void) {
        if let onFetchPayPalExternalPayerInfo {
            completion(.success(onFetchPayPalExternalPayerInfo(orderId)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
}

class MockWebAuthenticationService: WebAuthenticationService {
    var session: ASWebAuthenticationSession?

    var onConnect: ((URL, String) -> URL)?

    func connect(url: URL, scheme: String, _ completion: @escaping (Result<URL, any Error>) -> Void) {
        if let onConnect = onConnect {
            completion(.success(onConnect(url, scheme)))
        } else {
            completion(.failure(PrimerError.unknown(userInfo: nil, diagnosticsId: "")))
        }
    }
}
