//
//  ACHUserDetailsViewControllerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class ACHUserDetailsViewControllerTests: XCTestCase {

    var sut: ACHUserDetailsViewController!

    // ACHUserDetailsDelegate variables
    var sessionRestarted = false
    var userSubmitedForm = false
    var didReceiveError = false

    override func setUp() {
        super.setUp()

        SDKSessionHelper.setUp(order: order, customer: customer)
        let tokenizationService = MockTokenizationService()
        let createResumePaymentService = MockCreateResumePaymentService()
        let uiManager = MockPrimerUIManager()

        let tokenizationViewModel = StripeAchTokenizationViewModel(config: stripeACHPaymentMethod, uiManager: uiManager, tokenizationService: tokenizationService, createResumePaymentService: createResumePaymentService)

        sut = ACHUserDetailsViewController(tokenizationViewModel: tokenizationViewModel, delegate: self)
    }

    override func tearDown() {
        sut = nil
        sessionRestarted = false
        userSubmitedForm = false
        didReceiveError = false
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    func test_achUserDetails_viewWillAppear() {
        sut.viewWillAppear(false)

        if let parentVC = sut.parent as? PrimerContainerViewController {
            XCTAssertTrue(parentVC.mockedNavigationBar.hidesBackButton)
        }
    }

    func test_achUserDetails_viewDidAppear() {
        sut.achUserDetailsViewModel.shouldDisableViews = true
        sut.viewDidAppear(false)

        XCTAssertTrue(sessionRestarted)
    }

    func test_achUserDetails_viewWillDisappear() {
        sut.viewWillDisappear(false)

        if let parentVC = sut.parent as? PrimerContainerViewController {
            XCTAssertFalse(parentVC.mockedNavigationBar.hidesBackButton)
        }
    }

    func test_achUserDetails_view_not_nil() {
        sut.loadViewIfNeeded()
        XCTAssertNotNil(sut.achUserDetailsView)
    }

    func test_achUserDetails_component_not_nil() {
        XCTAssertNotNil(sut.stripeAchComponent)
    }

    func test_achUserDetails_firstName_valid() {
        var didReceiveStepCalled = false

        let expectDidReceiveStep = self.expectation(description: "expectDidReceiveStep called")
        sut.didReceiveStepCompletion = { step in
            switch step {
            case .retrievedUserDetails:
                didReceiveStepCalled = true
                self.sut.achUserDetailsViewModel.firstName = "John"
                expectDidReceiveStep.fulfill()
            default:
                break
            }
        }

        let expectUpdateFirstName = self.expectation(description: "expectUpdateFirstName called")
        sut.didUpdateCompletion = {
            if didReceiveStepCalled {
                XCTAssertTrue(self.sut.achUserDetailsViewModel.isFirstNameValid)
                XCTAssertTrue(self.sut.achUserDetailsViewModel.firstNameErrorDescription.isEmpty)
                expectUpdateFirstName.fulfill()
            }
        }
        
        sut.loadViewIfNeeded()

        wait(for: [
            expectDidReceiveStep,
            expectUpdateFirstName
        ], timeout: 3.0, enforceOrder: true)
    }

    func test_achUserDetails_lastName_valid() {
        var didReceiveStepCalled = false

        let expectDidReceiveStep = self.expectation(description: "expectDidReceiveStep called")
        sut.didReceiveStepCompletion = { step in
            switch step {
            case .retrievedUserDetails:
                didReceiveStepCalled = true
                self.sut.achUserDetailsViewModel.lastName = "Doe"
                expectDidReceiveStep.fulfill()
            default:
                break
            }
        }

        let expectUpdateFirstName = self.expectation(description: "expectUpdateFirstName called")
        sut.didUpdateCompletion = {
            if didReceiveStepCalled {
                XCTAssertTrue(self.sut.achUserDetailsViewModel.isLastNameValid)
                XCTAssertTrue(self.sut.achUserDetailsViewModel.lastNameErrorDescription.isEmpty)
                expectUpdateFirstName.fulfill()
            }
        }
        
        sut.loadViewIfNeeded()

        wait(for: [
            expectDidReceiveStep,
            expectUpdateFirstName
        ], timeout: 3.0, enforceOrder: true)
    }

    func test_achUserDetails_emailAddress_valid() {
        var didReceiveStepCalled = false

        let expectDidReceiveStep = self.expectation(description: "expectDidReceiveStep called")
        sut.didReceiveStepCompletion = { step in
            switch step {
            case .retrievedUserDetails:
                didReceiveStepCalled = true
                self.sut.achUserDetailsViewModel.emailAddress = "john.doe@primer.io"
                expectDidReceiveStep.fulfill()
            default:
                break
            }
        }

        let expectUpdateFirstName = self.expectation(description: "expectUpdateFirstName called")
        sut.didUpdateCompletion = {
            if didReceiveStepCalled {
                XCTAssertTrue(self.sut.achUserDetailsViewModel.isEmailAddressValid)
                XCTAssertTrue(self.sut.achUserDetailsViewModel.emailErrorDescription.isEmpty)
                expectUpdateFirstName.fulfill()
            }
        }
        
        sut.loadViewIfNeeded()

        wait(for: [
            expectDidReceiveStep,
            expectUpdateFirstName
        ], timeout: 3.0, enforceOrder: true)
    }

    func test_achUserDetails_firstName_invalid() {
        var didReceiveStepCalled = false

        let expectDidReceiveStep = self.expectation(description: "expectDidReceiveStep called")
        sut.didReceiveStepCompletion = { step in
            switch step {
            case .retrievedUserDetails:
                didReceiveStepCalled = true
                self.sut.achUserDetailsViewModel.firstName = "John_"
                expectDidReceiveStep.fulfill()
            default:
                break
            }
        }

        let expectUpdateFirstName = self.expectation(description: "expectUpdateFirstName called")
        sut.didUpdateCompletion = {
            if didReceiveStepCalled {
                XCTAssertFalse(self.sut.achUserDetailsViewModel.isFirstNameValid)
                XCTAssertFalse(self.sut.achUserDetailsViewModel.firstNameErrorDescription.isEmpty)
                expectUpdateFirstName.fulfill()
            }
        }
        
        sut.loadViewIfNeeded()

        wait(for: [
            expectDidReceiveStep,
            expectUpdateFirstName
        ], timeout: 3.0, enforceOrder: true)
    }

    func test_achUserDetails_lastName_invalid() {
        var didReceiveStepCalled = false

        let expectDidReceiveStep = self.expectation(description: "expectDidReceiveStep called")
        sut.didReceiveStepCompletion = { step in
            switch step {
            case .retrievedUserDetails:
                didReceiveStepCalled = true
                self.sut.achUserDetailsViewModel.lastName = "Doe_"
                expectDidReceiveStep.fulfill()
            default:
                break
            }
        }

        let expectUpdateFirstName = self.expectation(description: "expectUpdateFirstName called")
        sut.didUpdateCompletion = {
            if didReceiveStepCalled {
                XCTAssertFalse(self.sut.achUserDetailsViewModel.isLastNameValid)
                XCTAssertFalse(self.sut.achUserDetailsViewModel.lastNameErrorDescription.isEmpty)
                expectUpdateFirstName.fulfill()
            }
        }
        
        sut.loadViewIfNeeded()

        wait(for: [
            expectDidReceiveStep,
            expectUpdateFirstName
        ], timeout: 3.0, enforceOrder: true)
    }

    func test_achUserDetails_emailAddress_invalid() {
        var didReceiveStepCalled = false

        let expectDidReceiveStep = self.expectation(description: "expectDidReceiveStep called")
        sut.didReceiveStepCompletion = { step in
            switch step {
            case .retrievedUserDetails:
                didReceiveStepCalled = true
                self.sut.achUserDetailsViewModel.emailAddress = "john.doe@primer.i"
                expectDidReceiveStep.fulfill()
            default:
                break
            }
        }

        let expectUpdateFirstName = self.expectation(description: "expectUpdateFirstName called")
        sut.didUpdateCompletion = {
            if didReceiveStepCalled {
                XCTAssertFalse(self.sut.achUserDetailsViewModel.isEmailAddressValid)
                XCTAssertFalse(self.sut.achUserDetailsViewModel.emailErrorDescription.isEmpty)
                expectUpdateFirstName.fulfill()
            }
        }
        
        sut.loadViewIfNeeded()

        wait(for: [
            expectDidReceiveStep,
            expectUpdateFirstName
        ], timeout: 3.0, enforceOrder: true)
    }

    func test_achUserDetails_isValidForm_true() {
        XCTAssertTrue(sut.achUserDetailsViewModel.isValidForm)
    }

    func test_retrievedUserDetails_values() {
        let expectDidReceiveStep = self.expectation(description: "expectDidReceiveStep called")

        sut.didReceiveStepCompletion = { step in
            switch step {
            case .retrievedUserDetails:
                XCTAssertFalse(self.sut.achUserDetailsViewModel.firstName.isEmpty)
                XCTAssertFalse(self.sut.achUserDetailsViewModel.firstName.isEmpty)
                XCTAssertFalse(self.sut.achUserDetailsViewModel.firstName.isEmpty)
                expectDidReceiveStep.fulfill()
            default:
                break
            }
        }
        
        sut.loadViewIfNeeded()

        waitForExpectations(timeout: 2.0)
    }

    func test_achUserDetails_submit() {
        sut.stripeAchComponent?.submit()

        XCTAssertTrue(userSubmitedForm)
    }

    func test_achUserDetails_restartSession() {
        sut.delegate?.restartSession()

        XCTAssertTrue(sessionRestarted)
    }

    func test_achUserDetails_didReceiveError() {
        let error = ACHHelpers.getInvalidTokenError()
        sut.stripeAchComponent?.errorDelegate?.didReceiveError(error: error)

        XCTAssertTrue(didReceiveError)
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
              ])
    }

    var customer = ClientSession.Customer(
        id: "mock-customer-id",
        firstName: "mock-first-name",
        lastName: "mock-last-name",
        emailAddress: "mock@email.com",
        mobileNumber: "12345678"
    )

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
                     orderId: "order_id",
                     requiredAction: .init(clientToken: stripeACHToken,
                                           name: .checkout,
                                           description: "description"),
                     status: .success)
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
        "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6ImNsaWVudC10b2tlbi1zaWduaW5nLWtleSJ9.eyJleHAiOjE2NjQ5NTM1OTkwLCJhY2Nlc3NUb2tlbiI6ImIwY2E0NTFhLTBmYmItNGZlYS1hY2UwLTgxMDYwNGQ4OTBkYSIsImFuYWx5dGljc1VybCI6Imh0dHBzOi8vYW5hbHl0aWNzLmFwaS5zYW5kYm94LmNvcmUucHJpbWVyLmlvL21peHBhbmVsIiwiYW5hbHl0aWNzVXJsVjIiOiJodHRwczovL2FuYWx5dGljcy5zYW5kYm94LmRhdGEucHJpbWVyLmlvL2NoZWNrb3V0L3RyYWNrIiwiaW50ZW50IjoiU1RSSVBFX0FDSCIsInN0cmlwZUNsaWVudFNlY3JldCI6ImNsaWVudC1zZWNyZXQtdGVzdCIsInNka0NvbXBsZXRlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vY2xpZW50LXNkay9jb21wbGV0ZSIsImNvbmZpZ3VyYXRpb25VcmwiOiJodHRwczovL2FwaS5zYW5kYm94LnByaW1lci5pby9jbGllbnQtc2RrL2NvbmZpZ3VyYXRpb24iLCJjb3JlVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJwY2lVcmwiOiJodHRwczovL3Nkay5hcGkuc2FuZGJveC5wcmltZXIuaW8iLCJlbnYiOiJTQU5EQk9YIiwic3RhdHVzVXJsIjoiaHR0cHM6Ly9hcGkuc2FuZGJveC5wcmltZXIuaW8vcmVzdW1lLXRva2Vucy9lOTM3ZDQyMS0zYzE2LTRjMmUtYTBjOC01OGQxY2RhNWM0NmUiLCJyZWRpcmVjdFVybCI6Imh0dHBzOi8vdGVzdC5hZHllbi5jb20vaHBwL2NoZWNrb3V0LnNodG1sP3U9c2tpcERldGFpbHMmcD1lSnlOVTl0eW16QVEtUnJ6QmdQaVluamd3UVdTdUUwY2g5aE9waThlV2F4dDFTQXhrbkROMzJjaGwyblR6clF6ekk3WWN5U2RQYnVpYlZ0elJnMlhZaTcyMG9HTEFTVm92YXlwMlV2VnpJV0JnNkpHcW5TcGVBUEtvdi1Zc2FBTi1DOTNBMG9qbGhKcnA2aW9NbGxCZXVCS3RyUzNXS2NVQ05hUHlXSmRXbmdnTzFKaFpvekpUcGkzTzc3dVZxQk5rZDNmZlJEZU5lUEpqdWxiU0xPYkl2dDJ2MTV0cjR0RlVjNnp2ekxQYjFxaTZRZGN3aDRHRFpCeXFiZFNWYUMydk5xRzljLTc5bGJ0ZnVHWlRvbWNHcHBtRCpGeUdUd0gqVk5PbmhZeCplQTg4a042TFNET29KSDVobmpWNWZRZ3dwc3YtV0puaXRYc0txZzhsWWlZcTRmbkpTSHJpWjliNkVJRFdHOHpsdXZGcnFWZ2NJV0xReWFGVVpTWnRDeXlkVm5PRjllSXRVQ05MWVZ0MEJmWm1YUlBhdzJZMSp2eU5qMGEwKnFKUDV1UUstellFZGdKT2ZvbzJ4YVViZEJEaDFZOUNJZko1azhDWmpTb00yZWdjYmw4RlRZWHlFVXhKVlFjbFJsRXpoNkdXakpzOFN2bkRzeFJWaFAtNmxQM3NMN1AtWnVRU0kxR29seUVYd1dUY0pBY0RxSXgwSlk3R2dkbEp5OU9PMjUzdUJ3UnJMSnJ3RGJ5QkVLUEdVajhhUlVRei1hWkY5a0JJMkJUbDhWMkdGY2VxMmpJZ2doR0loYlIxbUNHSDMqNFlYdUNmbGpueVg0S1BtR0pIZTg4WmdmVXhWVTFCWnZSTVBKZFZzVlRCcFlHUFl6Tmh0YTg0cVpQaVV1STdibTJHNnpjR1AxMkl3eCo4dDE2YzNJWXVhRnp3NmdWZVBYZ0M3eUR2dzJjelRwdEpPSzJtblcxS2ZYUjBpY3V4dmZRZGp2blRKeVllSkVmVENNdkNYMHZJYjZUZTlxZkMqa2EqWGh3Tnp5QTQ5YmRlLVVxbi1QTE9lSWJNZTEtblBmSldwcmlCY3BiWlBRIn0.p7BV8U5chJSGUvdY9nyrrWeXUjCMWRF_bPCgSwU0h9U"
    }
}

extension ACHUserDetailsViewControllerTests: ACHUserDetailsDelegate {
    func restartSession() {
        sessionRestarted = true
    }

    func didSubmit() {
        userSubmitedForm = true
    }

    func didReceivedError(error: PrimerSDK.PrimerError) {
        didReceiveError = true
    }

}
