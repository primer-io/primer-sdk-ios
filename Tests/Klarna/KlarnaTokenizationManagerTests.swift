//
//  KlarnaTokenizationManagerTests.swift
//  Debug App Tests
//
//  Created by Stefan Vrancianu on 05.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
@testable import PrimerSDK
import XCTest

final class KlarnaTokenizationManagerTests: XCTestCase {
    var sut: KlarnaTokenizationManager!
    var tokenizationService: MockTokenizationService!
    var createResumePaymentService: MockCreateResumePaymentService!

    override func setUp() {
        super.setUp()
        SDKSessionHelper.setUp(order: KlarnaTestsMocks.klarnaOrder)
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        sut = KlarnaTokenizationManager(
            tokenizationService: tokenizationService,
            createResumePaymentService: createResumePaymentService
        )
    }

    override func tearDown() {
        sut = nil
        createResumePaymentService = nil
        tokenizationService = nil

        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    func test_tokenizeHeadless_success() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.success(KlarnaTestsMocks.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return KlarnaTestsMocks.paymentResponseBody
        }

        firstly {
            sut.tokenizeHeadless(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectDidCreatePayment,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_tokenizeHeadless_failure() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.failure(PrimerError.unknown())
        }

        firstly {
            sut.tokenizeHeadless(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        .catch { error in
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_tokenizeDropIn_success() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.success(KlarnaTestsMocks.tokenizationResponseBody)
        }

        firstly {
            sut.tokenizeDropIn(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { tokenData in
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        }
        .catch { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

    func test_tokenizeDropIn_failure() {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return Result.failure(PrimerError.unknown())
        }

        firstly {
            sut.tokenizeDropIn(customerToken: finalizePaymentData, offSessionAuthorizationId: finalizePaymentData.customerTokenId)
        }
        .done { _ in
            XCTFail("Result should be nil")
            expectation.fulfill()
        }
        .catch { error in
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }

        wait(for: [
            expectDidTokenize,
            expectation
        ], timeout: 10.0, enforceOrder: true)
    }

    func testFullPaymentFlow_headless() throws {
        PrimerInternal.shared.intent = .checkout

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in
            XCTAssertTrue(body.paymentInstrument is KlarnaAuthorizationPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaAuthorizationPaymentInstrument
            XCTAssertEqual(instrument.klarnaAuthorizationToken, "osa_id")
            expectDidTokenize.fulfill()
            return Result.success(Mocks.primerPaymentMethodTokenData)
        }

        let expectCreatePayment = expectation(description: "Did create payment")
        createResumePaymentService.onCreatePayment = { body in
            XCTAssertEqual(body.paymentMethodToken, "mock_payment_method_token")
            expectCreatePayment.fulfill()
            return Mocks.payment
        }

        let expectDidCompleteCheckout = expectation(description: "did complete checkout")
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

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in
            XCTAssertTrue(body.paymentInstrument is KlarnaAuthorizationPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaAuthorizationPaymentInstrument
            XCTAssertEqual(instrument.klarnaAuthorizationToken, "osa_id")
            expectDidTokenize.fulfill()
            return Result.success(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCompleteCheckout = expectation(description: "did complete checkout")
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

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in
            XCTAssertTrue(body.paymentInstrument is KlarnaCustomerTokenPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaCustomerTokenPaymentInstrument
            XCTAssertEqual(instrument.klarnaCustomerToken, "customer_token_id")
            expectDidTokenize.fulfill()
            return Result.success(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCompleteCheckout = expectation(description: "did complete checkout")
        sut.tokenizeDropIn(customerToken: customerToken, offSessionAuthorizationId: "osa_id")
            .done { _ in
                expectDidCompleteCheckout.fulfill()
            }
            .catch { error in
                XCTFail("Checkout did not succeed. Received error: \(error.localizedDescription)")
            }

        waitForExpectations(timeout: 5.0)
    }
}

extension KlarnaTokenizationManagerTests {
    private var address: Response.Body.Klarna.BillingAddress {
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

    private var customerToken: Response.Body.Klarna.CustomerToken {
        .init(customerTokenId: "customer_token_id",
              sessionData: .init(recurringDescription: "recurring_description",
                                 purchaseCountry: "gb",
                                 purchaseCurrency: "GBP",
                                 locale: "gb",
                                 orderAmount: 1234,
                                 orderTaxAmount: nil,
                                 orderLines: [],
                                 billingAddress: address,
                                 shippingAddress: address,
                                 tokenDetails: .init(brand: "brand",
                                                     maskedNumber: nil,
                                                     type: "td_type",
                                                     expiryDate: nil)))
    }
}

#endif
