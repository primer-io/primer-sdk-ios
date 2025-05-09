//
//  KlarnaTokenizationManagerTests.swift
//
//
//  Created by Jack Newcombe on 11/06/2024.
//

import XCTest
@testable import PrimerSDK

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK

final class KlarnaTokenizationManagerTests: XCTestCase {

    var sut: KlarnaTokenizationManager!

    var createResumePaymentService: MockCreateResumePaymentService!

    var tokenizationService: MockTokenizationService!

    override func setUpWithError() throws {
        createResumePaymentService = MockCreateResumePaymentService()
        tokenizationService = MockTokenizationService()
        sut = KlarnaTokenizationManager(
            tokenizationService: tokenizationService,
            createResumePaymentService: createResumePaymentService
        )
    }

    override func tearDownWithError() throws {
        sut = nil
        tokenizationService = nil
        createResumePaymentService = nil

        PrimerInternal.shared.intent = .checkout
    }

    func testFullPaymentFlow_headless() throws {
        PrimerInternal.shared.intent = .checkout

        let expectDidTokenize = self.expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in

            XCTAssertTrue(body.paymentInstrument is KlarnaAuthorizationPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaAuthorizationPaymentInstrument
            XCTAssertEqual(instrument.klarnaAuthorizationToken, "osa_id")
            expectDidTokenize.fulfill()
            return .fulfilled(Mocks.primerPaymentMethodTokenData)
        }

        let expectCreatePayment = self.expectation(description: "Did create payment")
        createResumePaymentService.onCreatePayment = { body in
            XCTAssertEqual(body.paymentMethodToken, "mock_payment_method_token")
            expectCreatePayment.fulfill()
            return Mocks.payment
        }

        let expectDidCompleteCheckout = self.expectation(description: "did complete checkout")
        sut.tokenizeHeadless(customerToken: customerToken, offSessionAuthorizationId: "osa_id")
            .done { _ in
                expectDidCompleteCheckout.fulfill()
            }
            .catch { error in
                XCTFail("Checkout did not succeed. Received error: \(error.localizedDescription)")
            }

        waitForExpectations(timeout: 5.0)
    }

    func testFullPaymentFlow_dropIn() throws {
        PrimerInternal.shared.intent = .checkout

        let expectDidTokenize = self.expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in

            XCTAssertTrue(body.paymentInstrument is KlarnaAuthorizationPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaAuthorizationPaymentInstrument
            XCTAssertEqual(instrument.klarnaAuthorizationToken, "osa_id")
            expectDidTokenize.fulfill()
            return .fulfilled(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCompleteCheckout = self.expectation(description: "did complete checkout")
        sut.tokenizeDropIn(customerToken: customerToken, offSessionAuthorizationId: "osa_id")
            .done { _ in
                expectDidCompleteCheckout.fulfill()
            }
            .catch { error in
                XCTFail("Checkout did not succeed. Received error: \(error.localizedDescription)")
            }

        waitForExpectations(timeout: 5.0)
    }

    func testFullPaymentFlow_dropIn_vault() throws {
        PrimerInternal.shared.intent = .vault

        let expectDidTokenize = self.expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in

            XCTAssertTrue(body.paymentInstrument is KlarnaCustomerTokenPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaCustomerTokenPaymentInstrument
            XCTAssertEqual(instrument.klarnaCustomerToken, "customer_token_id")
            expectDidTokenize.fulfill()
            return .fulfilled(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCompleteCheckout = self.expectation(description: "did complete checkout")
        sut.tokenizeDropIn(customerToken: customerToken, offSessionAuthorizationId: "osa_id")
            .done { _ in
                expectDidCompleteCheckout.fulfill()
            }
            .catch { error in
                XCTFail("Checkout did not succeed. Received error: \(error.localizedDescription)")
            }

        waitForExpectations(timeout: 5.0)
    }

    // MARK: Helpers

    var address: Response.Body.Klarna.BillingAddress {
        .init(addressLine1: "address_line_1",
              addressLine2: "address_line_2",
              addressLine3: "address_line_3",
              city: "city",
              countryCode: "gb",
              email: "john@appleseed.com",
              firstName: "John",
              lastName: "Appleseed",
              phoneNumber: "01515551234",
              postalCode: "EC4M 7RF",
              state: "state",
              title: "Mr")
    }

    var customerToken: Response.Body.Klarna.CustomerToken {

        .init(customerTokenId: "customer_token_id",
              sessionData: .init(recurringDescription: "recurring_description",
                                 purchaseCountry: "gb",
                                 purchaseCurrency: "GBP",
                                 locale: "gb",
                                 orderAmount: 1234,
                                 orderTaxAmount: nil,
                                 orderLines: [

                                 ],
                                 billingAddress: address,
                                 shippingAddress: address,
                                 tokenDetails: .init(brand: "brand",
                                                     maskedNumber: nil,
                                                     type: "td_type",
                                                     expiryDate: nil)))
    }
}
#endif
