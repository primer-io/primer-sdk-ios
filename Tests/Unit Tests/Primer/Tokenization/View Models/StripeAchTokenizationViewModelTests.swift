//
//  File.swift
//
//
//  Created by Stefan Vrancianu on 29.05.2024.
//

import XCTest
@testable import PrimerSDK

final class StripeAchTokenizationViewModelTests: XCTestCase {
    
    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!
    var uiManager: MockPrimerUIManager!
    var sut: StripeAchTokenizationViewModel!
    var appState: MockAppState!
    var mandateDelegate: ACHMandateDelegate?
    
    override func setUpWithError() throws {
        SDKSessionHelper.setUp(order: order)
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        
        sut = StripeAchTokenizationViewModel(config: ACHMocks.stripeACHPaymentMethod, uiManager: uiManager, tokenizationService: tokenizationService, createResumePaymentService: createResumePaymentService)
        mandateDelegate = sut
        
        let settings = PrimerSettings(paymentMethodOptions:
                                        PrimerPaymentMethodOptions(urlScheme: "test://primer.io",
                                                                   stripeOptions: PrimerStripeACHOptions(publishableKey: "test-pk-1234")))
        
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
    
    func test_tokenization_validation() throws {
        XCTAssertNoThrow(try sut.validate())
    }
    
    func test_start_pre_tokenization_and_abort() throws {
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate
        
        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, ACHMocks.stripeACHPaymentMethodType)
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
        
        waitForExpectations(timeout: 2.0)
    }
    
    func test_full_flow_checkout() throws {
        SDKSessionHelper.setUp(order: order, showTestId: true)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        
        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, ACHMocks.stripeACHPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }
        
        let expectDidStartTokenization = self.expectation(description: "didStartTokenization is called")
        delegate.onDidStartTokenization = { paymentType in
            XCTAssertEqual(paymentType, ACHMocks.stripeACHPaymentMethodType)
            expectDidStartTokenization.fulfill()
        }
        
        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { body in
            expectDidTokenize.fulfill()
            return Promise.fulfilled(self.tokenizationResponseBody)
        }
        
        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { body in
            expectDidCreatePayment.fulfill()
            return self.paymentResponseBody
        }
        
        let expectStripeCollectorCompletion = self.expectation(description: "stripeCollectorCompletion called")
        DispatchQueue.global().async {
            sleep(3)
            self.sut.stripeBankAccountCollectorCompletion?(true, nil)
            expectStripeCollectorCompletion.fulfill()
        }
        
        
        let expectDidReceiveAdditionalInfo = self.expectation(description: "didReceiveAdditionalInfo is called")
        delegate.onDidReceiveAdditionalInfo = { _ in
            expectDidReceiveAdditionalInfo.fulfill()
        }
        
        let expectMandateCompletion = self.expectation(description: "mandateCompletion called")
        DispatchQueue.global().async {
            sleep(5)
            self.mandateDelegate?.mandateAccepted()
            expectMandateCompletion.fulfill()
        }
        
        let expectDidResumePayment = self.expectation(description: "didResumePayment called")
        createResumePaymentService.onResumePayment = { paymentId, body in
            expectDidResumePayment.fulfill()
            return self.paymentResponseBody
        }
        
        let expectCheckoutDidCompleteWithData = self.expectation(description: "didCompleteCheckout is called")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectCheckoutDidCompleteWithData.fulfill()
        }

        sut.start()
        
        wait(for: [
            expectWillCreatePaymentData,
            expectDidStartTokenization,
            expectDidTokenize,
            expectDidCreatePayment,
            expectStripeCollectorCompletion,
            expectDidReceiveAdditionalInfo,
            expectMandateCompletion,
            expectDidResumePayment,
            expectCheckoutDidCompleteWithData
        ], timeout: 20.0, enforceOrder: true)
    }
    
    // MARK: Helpers
    var order: ClientSession.Order {
        .init(id: "order_id",
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
              ],
              shippingAmount: nil)
    }
    
    var paymentResponseBody: Response.Body.Payment {
        return .init(id: "id",
                     paymentId: "payment_id",
                     amount: 123,
                     currencyCode: "USD",
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
                     requiredAction: .init(clientToken: ACHMocks.stripeACHToken,
                                           name: .checkout,
                                           description: "description"),
                     status: .success,
                     paymentFailureReason: nil)
    }
    
    var tokenizationResponseBody: Response.Body.Tokenization {
        .init(analyticsId: "analytics_id",
              id: "id",
              isVaulted: false,
              isAlreadyVaulted: false,
              paymentInstrumentType: .stripeAch,
              paymentMethodType: ACHMocks.stripeACHPaymentMethodType,
              paymentInstrumentData: nil,
              threeDSecureAuthentication: nil,
              token: "token",
              tokenType: .singleUse,
              vaultData: nil)
    }
}
