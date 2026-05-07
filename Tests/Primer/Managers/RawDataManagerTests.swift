//
//  RawDataManagerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class RawDataManagerTests: XCTestCase {

    var headlessCheckoutDelegate: MockPrimerHeadlessUniversalCheckoutDelegate!

    var rawDataManagerDelegate: MockRawDataManagerDelegate!

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var sut: RawDataManager!

    override func setUpWithError() throws {
        SDKSessionHelper.setUp(withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod])
        headlessCheckoutDelegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        rawDataManagerDelegate = MockRawDataManagerDelegate()
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()

        sut = try RawDataManager(paymentMethodType: "PAYMENT_CARD", delegate: rawDataManagerDelegate)
        sut.tokenizationService = tokenizationService
        sut.createResumePaymentService = createResumePaymentService

        PrimerHeadlessUniversalCheckout.current.delegate = headlessCheckoutDelegate
    }

    override func tearDownWithError() throws {
        sut = nil
        rawDataManagerDelegate = nil

        SDKSessionHelper.tearDown()
    }

    func testFullPaymentFlow() throws {
        let expectDidCompleteCheckout = expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectWillCreatePaymentWithData = expectation(description: "Will create payment with data")
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            expectWillCreatePaymentWithData.fulfill()
            decisionHandler(.continuePaymentCreation())
        }

        let expectOnTokenize = expectation(description: "On tokenization complete")
        tokenizationService.onTokenize = { _ in
            expectOnTokenize.fulfill()
            return Result.success(self.tokenizationResponseBody)
        }

        let expectCreatePayment = expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBody
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.rawData = PrimerCardData(
            cardNumber: "4111 1111 1111 1111",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Appleseed"
        )

        sut.submit()

        waitForExpectations(timeout: 5.0)
    }

    func testFullPaymentFlowWithRequiredActionResume() throws {
        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        PollingModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)
        apiClient.pollingResults = [
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .pending, id: "0", source: "src"), nil),
            (PollingResponse(status: .complete, id: "4321", source: "src"), nil)
        ]

        let expectDidCompleteCheckout = expectation(description: "Headless checkout completed")
        headlessCheckoutDelegate.onDidCompleteCheckoutWithData = { _ in
            expectDidCompleteCheckout.fulfill()
        }

        let expectWillCreatePaymentWithData = expectation(description: "Will create payment with data")
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            expectWillCreatePaymentWithData.fulfill()
            decisionHandler(.continuePaymentCreation())
        }

        let expectOnTokenize = expectation(description: "On tokenization complete")
        tokenizationService.onTokenize = { _ in
            expectOnTokenize.fulfill()
            return Result.success(self.tokenizationResponseBody)
        }

        let expectCreatePayment = expectation(description: "On create payment")
        createResumePaymentService.onCreatePayment = { _ in
            expectCreatePayment.fulfill()
            return self.paymentResponseBodyWithRedirectAction
        }

        let expectResumePayment = expectation(description: "On resume payment")
        createResumePaymentService.onResumePayment = { paymentId, request in
            XCTAssertEqual(paymentId, "id")
            XCTAssertEqual(request.resumeToken, "4321")
            expectResumePayment.fulfill()
            return self.paymentResponseAfterResume
        }

        headlessCheckoutDelegate.onDidFail = { error in
            XCTFail("Failed with error: \(error.localizedDescription)")
        }

        sut.rawData = PrimerCardData(
            cardNumber: "4111 1111 1111 1111",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Appleseed"
        )

        sut.submit()

        waitForExpectations(timeout: 45.0)
    }

    func testAbortPaymentFlow() throws {
        let expectWillCreatePaymentWithData = expectation(description: "Will create payment with data")
        headlessCheckoutDelegate.onWillCreatePaymentWithData = { _, decisionHandler in
            expectWillCreatePaymentWithData.fulfill()
            decisionHandler(.abortPaymentCreation())
        }

        let expectDidFail = expectation(description: "Did fail with merchant error")
        headlessCheckoutDelegate.onDidFail = { error in
            switch error {
            case PrimerError.merchantError: break
            default: XCTFail("Expected merchant error")
            }
            expectDidFail.fulfill()
        }

        sut.rawData = PrimerCardData(
            cardNumber: "4111 1111 1111 1111",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "John Appleseed"
        )

        sut.submit()

        waitForExpectations(timeout: 5.0)
    }
    
    func testNoRawDataSubmit() {

        let expectDidFail = expectation(description: "Did fail")
        headlessCheckoutDelegate.onDidFail = { error in
            switch error {
            case let PrimerError.invalidValue(key, value, _, _):
                XCTAssertEqual(key, "rawData")
                XCTAssertNil(value)
                XCTAssertFalse(self.sut.isDataValid)
            default:
                XCTFail()
            }
            expectDidFail.fulfill()
        }

        let expectDidValidate = expectation(description: "Did validate")
        rawDataManagerDelegate.onDataIsValid = { _, isValid, errors in
            XCTAssertFalse(isValid)
            XCTAssertTrue(
                errors!.first!.localizedDescription.starts(
                    with: "[invalid-value] Invalid value 'nil' for key 'rawData' "
                )
            )
            expectDidValidate.fulfill()
        }

        sut.submit()

        waitForExpectations(timeout: 5.0)
    }

    func testDelegateNotifiedOnValidation() {
        // Arrange
        let expectDidValidate = expectation(description: "Delegate was notified")
        var didCallDelegate = false

        rawDataManagerDelegate.onDataIsValid = { _, _, _ in
            // Only fulfill the expectation once
            if !didCallDelegate {
                didCallDelegate = true
                expectDidValidate.fulfill()
            }
        }

        // Act
        sut.rawData = PrimerCardData(
            cardNumber: "4111111111111111",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "Test Name"
        )

        // Assert
        waitForExpectations(timeout: 3.0)
        XCTAssertTrue(didCallDelegate, "Delegate should have been notified")
    }
    
    func testDelegateNotifiedOnConsecutiveValidations() {
        // Arrange
        let expectFirstValidation = expectation(description: "First validation notification")
        let expectSecondValidation = expectation(description: "Second validation notification")
        var validationCount = 0
        var fulfilledFirst = false
        var fulfilledSecond = false

        rawDataManagerDelegate.onDataIsValid = { _, _, _ in
            validationCount += 1

            // For the first set of validation callbacks
            if !fulfilledFirst {
                fulfilledFirst = true
                expectFirstValidation.fulfill()
            }
            // Only after setting data the second time and not having fulfilled second expectation yet
            else if validationCount > 1, !fulfilledSecond {
                fulfilledSecond = true
                expectSecondValidation.fulfill()
            }
        }

        // Act - First set valid data
        sut.rawData = PrimerCardData(
            cardNumber: "4111111111111111",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "Test Name"
        )

        // Wait for first validation
        wait(for: [expectFirstValidation], timeout: 3.0)

        // Act - Then set identical data to ensure delegate is still called
        sut.rawData = PrimerCardData(
            cardNumber: "4111111111111111",
            expiryDate: "03/2030",
            cvv: "123",
            cardholderName: "Test Name"
        )

        // Assert
        wait(for: [expectSecondValidation], timeout: 3.0)
        XCTAssertTrue(validationCount > 1, "Delegate should be notified at least twice")
    }

    // MARK: setBillingAddress

    func testSetBillingAddressDispatchesClientSessionAction() async throws {
        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (PrimerAPIConfiguration.current, nil)

        let address = PrimerAddress(
            firstName: "John",
            lastName: "Appleseed",
            addressLine1: "1 Infinite Loop",
            addressLine2: nil,
            postalCode: "95014",
            city: "Cupertino",
            state: "CA",
            countryCode: "US"
        )

        try await sut.setBillingAddress(address)
    }

    func testSetBillingAddressThrowsOnEmptyAddress() async {
        let address = PrimerAddress(
            firstName: nil,
            lastName: nil,
            addressLine1: nil,
            addressLine2: nil,
            postalCode: nil,
            city: nil,
            state: nil,
            countryCode: nil
        )

        do {
            try await sut.setBillingAddress(address)
            XCTFail("Expected setBillingAddress to throw on empty address")
        } catch let error as PrimerValidationError {
            if case .invalidRawData = error {
                // pass
            } else {
                XCTFail("Expected .invalidRawData, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerValidationError, got \(error)")
        }
    }

    func testSetBillingAddressThrowsOnInvalidCountryCode() async {
        let address = PrimerAddress(
            firstName: nil,
            lastName: nil,
            addressLine1: nil,
            addressLine2: nil,
            postalCode: "95014",
            city: nil,
            state: nil,
            countryCode: "USA" // invalid — expected "US"
        )

        do {
            try await sut.setBillingAddress(address)
            XCTFail("Expected setBillingAddress to throw on invalid countryCode")
        } catch let error as PrimerValidationError {
            if case .invalidRawData = error {
                // pass
            } else {
                XCTFail("Expected .invalidRawData, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerValidationError, got \(error)")
        }
    }

    func testClientSessionAddressInitFromPrimerAddressMapsFields() {
        let primerAddress = PrimerAddress(
            firstName: "John",
            lastName: "Appleseed",
            addressLine1: "1 Infinite Loop",
            addressLine2: "Building 2",
            postalCode: "95014",
            city: "Cupertino",
            state: "CA",
            countryCode: "US"
        )

        let address = ClientSession.Address(from: primerAddress)

        XCTAssertEqual(address.firstName, "John")
        XCTAssertEqual(address.lastName, "Appleseed")
        XCTAssertEqual(address.addressLine1, "1 Infinite Loop")
        XCTAssertEqual(address.addressLine2, "Building 2")
        XCTAssertEqual(address.city, "Cupertino")
        XCTAssertEqual(address.postalCode, "95014")
        XCTAssertEqual(address.state, "CA")
        XCTAssertEqual(address.countryCode, .us)
    }

    // MARK: Helpers

    var tokenizationResponseBody: Response.Body.Tokenization {
        .init(
            analyticsId: "analytics_id",
            id: "id",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .offSession,
            paymentMethodType: Mocks.Static.Strings.webRedirectPaymentMethodType,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: "token",
            tokenType: .singleUse,
            vaultData: nil
        )
    }

    var paymentResponseBody: Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 123,
            currencyCode: "GBP",
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
            status: .success
        )
    }

    var paymentResponseBodyWithRedirectAction: Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 123,
            currencyCode: "GBP",
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
            requiredAction: .init(
                clientToken: MockAppState.mockClientTokenWithRedirect,
                name: .checkout,
                description: "description"
            ),
            status: .success
        )
    }

    var paymentResponseAfterResume: Response.Body.Payment {
        .init(
            id: "id",
            paymentId: "payment_id",
            amount: 1234,
            currencyCode: "GBP",
            customerId: "customer_id",
            orderId: "order_id",
            status: .success
        )
    }
}
