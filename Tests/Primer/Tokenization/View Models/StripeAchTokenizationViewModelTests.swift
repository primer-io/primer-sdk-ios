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
        
        sut = StripeAchTokenizationViewModel(config: stripeACHPaymentMethod, uiManager: uiManager, tokenizationService: tokenizationService, createResumePaymentService: createResumePaymentService)
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
            XCTAssertEqual(data.paymentMethodType.type, self.stripeACHPaymentMethodType)
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
            XCTAssertEqual(data.paymentMethodType.type, self.stripeACHPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }
        
        let expectDidStartTokenization = self.expectation(description: "didStartTokenization is called")
        delegate.onDidStartTokenization = { paymentType in
            XCTAssertEqual(paymentType, self.stripeACHPaymentMethodType)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.sut.stripeBankAccountCollectorCompletion?(true, nil)
            expectStripeCollectorCompletion.fulfill()
        }
        
        let expectDidReceiveMandateAdditionalInfo = self.expectation(description: "didReceiveMandateAdditionalInfo is called")
        delegate.onDidReceiveAdditionalInfo = { _ in
            expectDidReceiveMandateAdditionalInfo.fulfill()
        }
        
        let expectMandateCompletion = self.expectation(description: "mandateCompletion called")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
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
            expectDidReceiveMandateAdditionalInfo,
            expectMandateCompletion,
            expectDidResumePayment,
            expectCheckoutDidCompleteWithData
        ], timeout: 20.0, enforceOrder: true)
    }
    
    // MARK: Helpers
    
    var stripeACHPaymentMethodType = "STRIPE_ACH"
    
    let stripeACHPaymentMethod = PrimerPaymentMethod(
        id: "STRIPE_ACH",
        implementationType: .nativeSdk,
        type: "STRIPE_ACH",
        name: "Mock StripeACH Payment Method",
        processorConfigId: "mock_processor_config_id",
        surcharge: 299,
        options: nil,
        displayMetadata: nil)
    
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
                     requiredAction: .init(clientToken: stripeACHToken,
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
              paymentMethodType: stripeACHPaymentMethodType,
              paymentInstrumentData: nil,
              threeDSecureAuthentication: nil,
              token: "token",
              tokenType: .singleUse,
              vaultData: nil)
    }
    
    var stripeACHToken: String {
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjE2NjQ5NTM1OTkwLCJhY2Nlc3NUb2tlbiI6ImIwY2E0NTFhLTBmYmItNGZlYS1hY2UwLTgxMDYwNGQ4OTBkYSIsImFuYWx5dGljc1VybCI6Imh0dHBzOi8vYW5hbHl0aWNzLmFwaS5zYW5kYm94LmNvcmUucHJpbWVyLmlvL21peHBhbmVsIiwiYW5hbHl0aWNzVXJsVjIiOiJodHRwczovL2FuYWx5dGljcy5zYW5kYm94LmRhdGEucHJpbWVyLmlvL2NoZWNrb3V0L3RyYWNrIiwiaW50ZW50IjoiU1RSSVBFX0FDSCIsInN0cmlwZUNsaWVudFNlY3JldCI6ImNsaWVudC1zZWNyZXQtdGVzdCIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwic3RhdHVzVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vcmVzdW1lLXRva2Vucy9lOTM3ZDQyMS0zYzE2LTRjMmUtYTBjOC01OGQxY2RhNWM0NmUiLCJyZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdC5hZHllbi5jb20vaHBwL2NoZWNrb3V0LnNodG1sP3U9c2tpcERldGFpbHMmcD1lSnlOVTl0eW16QVEtUnJ6QmdQaVluamd3UVdTdUUwY2g5aE9waThlV2F4dDFTQXhrbkROMzJjaGwyblR6clF6ekk3WWN5U2RQYnVpYlZ0elJnMlhZaTcyMG9HTEFTVm92YXlwMlV2VnpJV0JnNkpHcW5TcGVBUEtvdi1Zc2FBTi1DOTNBMG9qbGhKcnA2aW9NbGxCZXVCS3RyUzNXS2NVQ05hUHlXSmRXbmdnTzFKaFpvekpUcGkzTzc3dVZxQk5rZDNmZlJEZU5lUEpqdWxiU0xPYkl2dDJ2MTV0cjR0RlVjNnp2ekxQYjFxaTZRZGN3aDRHRFpCeXFiZFNWYUMydk5xRzljLTc5bGJ0ZnVHWlRvbWNHcHBtRCpGeUdUd0gqVk5PbmhZeCplQTg4a042TFNET29KSDVobmpWNWZRZ3dwc3YtV0puaXRYc0txZzhsWWlZcTRmbkpTSHJpWjliNkVJRFdHOHpsdXZGcnFWZ2NJV0xReWFGVVpTWnRDeXlkVm5PRjllSXRVQ05MWVZ0MEJmWm1YUlBhdzJZMSp2eU5qMGEwKnFKUDV1UUstellFZGdKT2ZvbzJ4YVViZEJEaDFZOUNJZko1azhDWmpTb00yZWdjYmw4RlRZWHlFVXhKVlFjbFJsRXpoNkdXakpzOFN2bkRzeFJWaFAtNmxQM3NMN1AtWnVRU0kxR29seUVYd1dUY0pBY0RxSXgwSlk3R2dkbEp5OU9PMjUzdUJ3UnJMSnJ3RGJ5QkVLUEdVajhhUlVRei1hWkY5a0JJMkJUbDhWMkdGY2VxMmpJZ2doR0loYlIxbUNHSDMqNFlYdUNmbGpueVg0S1BtR0pIZTg4WmdmVXhWVTFCWnZSTVBKZFZzVlRCcFlHUFl6Tmh0YTg0cVpQaVV1STdibTJHNnpjR1AxMkl3eCo4dDE2YzNJWXVhRnp3NmdWZVBYZ0M3eUR2dzJjelRwdEpPSzJtblcxS2ZYUjBpY3V4dmZRZGp2blRKeVllSkVmVENNdkNYMHZJYjZUZTlxZkMqa2EqWGh3Tnp5QTQ5YmRlLVVxbi1QTE9lSWJNZTEtblBmSldwcmlCY3BiWlBRIn0.wBc6G5-y-Ji5hFjdMkqhOq2nlsQsm5-DgdVptWwKdl4"
    }
}
