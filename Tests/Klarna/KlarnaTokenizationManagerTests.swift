//
//  KlarnaTokenizationManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

    func test_tokenizeHeadless_success() async {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return .success(KlarnaTestsMocks.tokenizationResponseBody)
        }

        let expectDidCreatePayment = self.expectation(description: "didCreatePayment called")
        createResumePaymentService.onCreatePayment = { _ in
            expectDidCreatePayment.fulfill()
            return KlarnaTestsMocks.paymentResponseBody
        }

        do {
            let tokenData = try await sut.tokenizeHeadless(
                customerToken: finalizePaymentData,
                offSessionAuthorizationId: finalizePaymentData.customerTokenId
            )
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        } catch {
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        await fulfillment(of: [expectDidTokenize, expectDidCreatePayment, expectation], timeout: 10.0, enforceOrder: false)
    }

    func test_tokenizeHeadless_failure() async {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return .failure(PrimerError.unknown())
        }

        do {
            _ = try await sut.tokenizeHeadless(
                customerToken: finalizePaymentData,
                offSessionAuthorizationId: finalizePaymentData.customerTokenId
            )
            XCTFail("Result should be nil")
            expectation.fulfill()
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }

        await fulfillment(of: [expectDidTokenize, expectation], timeout: 10.0, enforceOrder: false)
    }

    func test_tokenizeDropIn_success() async {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: true)
        let expectation = XCTestExpectation(description: "Successful Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return .success(KlarnaTestsMocks.tokenizationResponseBody)
        }

        do {
            let tokenData = try await sut.tokenizeDropIn(
                customerToken: finalizePaymentData,
                offSessionAuthorizationId: finalizePaymentData.customerTokenId
            )
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectation.fulfill()
        } catch {
            XCTFail("Result should be nil")
            expectation.fulfill()
        }

        await fulfillment(of: [expectDidTokenize, expectation], timeout: 10.0, enforceOrder: false)
    }

    func test_tokenizeDropIn_failure() async {
        let finalizePaymentData = KlarnaTestsMocks.getMockFinalizeKlarnaPaymentSession(isValid: false)
        let expectation = XCTestExpectation(description: "Failure Tokenize Klarna Payment Session")

        let expectDidTokenize = self.expectation(description: "TokenizationService: onTokenize is called")
        tokenizationService.onTokenize = { _ in
            expectDidTokenize.fulfill()
            return .failure(PrimerError.unknown())
        }

        do {
            _ = try await sut.tokenizeDropIn(
                customerToken: finalizePaymentData,
                offSessionAuthorizationId: finalizePaymentData.customerTokenId
            )
            XCTFail("Result should be nil")
            expectation.fulfill()
        } catch {
            XCTAssertNotNil(error, "Error should not be nil")
            expectation.fulfill()
        }

        await fulfillment(of: [expectDidTokenize, expectation], timeout: 10.0, enforceOrder: false)
    }

    func testFullPaymentFlow_headless() async throws {
        PrimerInternal.shared.intent = .checkout

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in
            XCTAssertTrue(body.paymentInstrument is KlarnaAuthorizationPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaAuthorizationPaymentInstrument
            XCTAssertEqual(instrument.klarnaAuthorizationToken, "osa_id")
            expectDidTokenize.fulfill()
            return .success(Mocks.primerPaymentMethodTokenData)
        }

        let expectCreatePayment = expectation(description: "Did create payment")
        createResumePaymentService.onCreatePayment = { body in
            XCTAssertEqual(body.paymentMethodToken, "mock_payment_method_token")
            expectCreatePayment.fulfill()
            return Mocks.payment
        }

        let expectDidCompleteCheckout = expectation(description: "did complete checkout")
        do {
            let tokenData = try await sut.tokenizeHeadless(customerToken: customerToken, offSessionAuthorizationId: "osa_id")
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectDidCompleteCheckout.fulfill()
        } catch {
            XCTFail("Checkout did not succeed. Received error: \(error.localizedDescription)")
        }

        await fulfillment(of: [expectDidTokenize, expectCreatePayment, expectDidCompleteCheckout], timeout: 10.0, enforceOrder: false)
    }

    func testFullPaymentFlow_dropIn() async throws {
        PrimerInternal.shared.intent = .checkout

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in
            XCTAssertTrue(body.paymentInstrument is KlarnaAuthorizationPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaAuthorizationPaymentInstrument
            XCTAssertEqual(instrument.klarnaAuthorizationToken, "osa_id")
            expectDidTokenize.fulfill()
            return .success(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCompleteCheckout = expectation(description: "did complete checkout")
        do {
            let tokenData = try await sut.tokenizeDropIn(customerToken: customerToken, offSessionAuthorizationId: "osa_id")
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectDidCompleteCheckout.fulfill()
        } catch {
            XCTFail("Checkout did not succeed. Received error: \(error.localizedDescription)")
        }

        await fulfillment(of: [expectDidTokenize, expectDidCompleteCheckout], timeout: 10.0, enforceOrder: false)
    }

    func testFullPaymentFlow_dropIn_vault() async throws {
        PrimerInternal.shared.intent = .vault

        let expectDidTokenize = expectation(description: "Did tokenize")
        tokenizationService.onTokenize = { body in
            XCTAssertTrue(body.paymentInstrument is KlarnaCustomerTokenPaymentInstrument)
            let instrument = body.paymentInstrument as! KlarnaCustomerTokenPaymentInstrument
            XCTAssertEqual(instrument.klarnaCustomerToken, "customer_token_id")
            expectDidTokenize.fulfill()
            return .success(Mocks.primerPaymentMethodTokenData)
        }

        let expectDidCompleteCheckout = expectation(description: "did complete checkout")
        do {
            let tokenData = try await sut.tokenizeDropIn(customerToken: customerToken, offSessionAuthorizationId: "osa_id")
            XCTAssertNotNil(tokenData, "Result should not be nil")
            expectDidCompleteCheckout.fulfill()
        } catch {
            XCTFail("Checkout did not succeed. Received error: \(error.localizedDescription)")
        }

        await fulfillment(of: [expectDidTokenize, expectDidCompleteCheckout], timeout: 10.0, enforceOrder: false)
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
        .init(
            customerTokenId: "customer_token_id",
            sessionData: .init(
                recurringDescription: "recurring_description",
                purchaseCountry: "gb",
                purchaseCurrency: "GBP",
                locale: "gb",
                orderAmount: 1234,
                orderTaxAmount: nil,
                orderLines: [],
                billingAddress: address,
                shippingAddress: address,
                tokenDetails: .init(
                    brand: "brand",
                    maskedNumber: nil,
                    type: "td_type",
                    expiryDate: nil
                )
            )
        )
    }
}

#endif
