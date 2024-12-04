//
//  ApplePayTokenizationViewModelTests.swift
//  
//
//  Created by Jack Newcombe on 23/05/2024.
//

import XCTest
import PassKit
@testable import PrimerSDK

final class ApplePayTokenizationViewModelTests: XCTestCase {

    var tokenizationService: MockTokenizationService!

    var createResumePaymentService: MockCreateResumePaymentService!

    var uiManager: MockPrimerUIManager!

    var appState: MockAppState!

    var sut: ApplePayTokenizationViewModel!

    override func setUpWithError() throws {
        tokenizationService = MockTokenizationService()
        createResumePaymentService = MockCreateResumePaymentService()
        uiManager = MockPrimerUIManager()
        sut = ApplePayTokenizationViewModel(config: Mocks.PaymentMethods.webRedirectPaymentMethod,
                                            uiManager: uiManager,
                                            tokenizationService: tokenizationService,
                                            createResumePaymentService: createResumePaymentService)

        let settings = PrimerSettings(paymentMethodOptions:
            PrimerPaymentMethodOptions(applePayOptions:
                PrimerApplePayOptions(merchantIdentifier: "merchant_id", merchantName: "merchant_name")
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        appState = MockAppState()
        appState.amount = 1234
        appState.currency = Currency(code: "GBP", decimalDigits: 2)
        DependencyContainer.register(appState as AppStateProtocol)
    }

    override func tearDownWithError() throws {
        sut = nil
        uiManager = nil
        createResumePaymentService = nil
        tokenizationService = nil
        SDKSessionHelper.tearDown()
    }

    func testClientTokenValidation() throws {
        // without token
        SDKSessionHelper.tearDown()
        XCTAssertThrowsError(try sut.validate())

        // without order
        try SDKSessionHelper.test {
            XCTAssertThrowsError(try sut.validate())
        }

        // without currency
        try SDKSessionHelper.test(order: order) {
            let appState: AppStateProtocol = DependencyContainer.resolve()
            (appState as! MockAppState).currency = nil
            XCTAssertThrowsError(try sut.validate())
            (appState as! MockAppState).currency = Currency(code: "GBP", decimalDigits: 2)
        }

        // without apple pay options
        try SDKSessionHelper.test(order: order) {
            let settings = PrimerSettings(paymentMethodOptions: PrimerPaymentMethodOptions())
            DependencyContainer.register(settings as PrimerSettingsProtocol)
            XCTAssertThrowsError(try sut.validate())
            let resetSettings = PrimerSettings(paymentMethodOptions:
                PrimerPaymentMethodOptions(applePayOptions:
                    PrimerApplePayOptions(merchantIdentifier: "merchant_id", merchantName: "merchant_name")
                )
            )
            DependencyContainer.register(resetSettings as PrimerSettingsProtocol)
        }

        // with order
        try SDKSessionHelper.test(order: order) {
            XCTAssertNoThrow(try sut.validate())
        }
    }

    func testStartWithPreTokenizationAndAbort() throws {
        SDKSessionHelper.setUp(order: order)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
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

    func testWithShippingModules() throws {
        guard var config = PrimerAPIConfiguration.current else {
            XCTFail("Unable to generate configuration")
            return
        }
        config.checkoutModules = checkoutModules
        testStartWithFullCheckoutFlow(config: config)
    }

    func testFullCheckoutFlow() throws {
        guard let config = PrimerAPIConfiguration.current else {
            XCTFail("Unable to generate configuration")
            return
        }
        testStartWithFullCheckoutFlow(config: config)
    }

    private func testStartWithFullCheckoutFlow(config: PrimerAPIConfiguration) {
        SDKSessionHelper.setUp(order: order)
        let delegate = MockPrimerHeadlessUniversalCheckoutDelegate()
        PrimerHeadlessUniversalCheckout.current.delegate = delegate

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient
        apiClient.fetchConfigurationWithActionsResult = (config, nil)

        let applePayPresentationManager = MockApplePayPresentationManager()
        sut.applePayPresentationManager = applePayPresentationManager

        let expectWillCreatePaymentData = self.expectation(description: "onWillCreatePaymentData is called")
        delegate.onWillCreatePaymentWithData = { data, decision in
            XCTAssertEqual(data.paymentMethodType.type, Mocks.Static.Strings.webRedirectPaymentMethodType)
            decision(.continuePaymentCreation())
            expectWillCreatePaymentData.fulfill()
        }

        let expectCheckoutDidCompletewithData = self.expectation(description: "")
        delegate.onDidCompleteCheckoutWithData = { data in
            XCTAssertEqual(data.payment?.id, "id")
            XCTAssertEqual(data.payment?.orderId, "order_id")
            expectCheckoutDidCompletewithData.fulfill()
        }

        let expectDidPresent = self.expectation(description: "Did present ApplePay")
        applePayPresentationManager.onPresent = { request, delegate in
            Promise { seal in
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    let dummyController = PKPaymentAuthorizationController()
                    delegate.paymentAuthorizationController?(dummyController,
                                                             didAuthorizePayment: MockPKPayment(),
                                                             handler: { _ in })
                    delegate.paymentAuthorizationControllerDidFinish(dummyController)
                }
                expectDidPresent.fulfill()
                seal.fulfill()
            }
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

        delegate.onDidFail = { error in
            print(error)
        }

        sut.start()

        wait(for: [
            expectWillCreatePaymentData,
            expectDidPresent,
            expectDidTokenize,
            expectDidCreatePayment,
            expectCheckoutDidCompletewithData
        ], timeout: 10.0, enforceOrder: true)
    }

    private typealias ShippingMethodOptions = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions
    private typealias ShippingMethod = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions.ShippingMethod

    func testGetShippingMethodsInfo() throws {
        PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules = checkoutModules

        let sut = ApplePayTokenizationViewModel(config: PrimerPaymentMethod(id: "APPLE_PAY",
                                                                            implementationType: .nativeSdk,
                                                                            type: "APPLE_PAY",
                                                                            name: "Apple Pay",
                                                                            processorConfigId: nil,
                                                                            surcharge: nil,
                                                                            options: nil,
                                                                            displayMetadata: nil))

        let methods = sut.getShippingMethodsInfo()

        XCTAssert(methods.shippingMethods?.count == 2)
        XCTAssert(methods.selectedShippingMethodOrderItem?.name == "Shipping")
    }


    func testCreateOrderItemsWithFees() throws {

        let itemName = "Fancy Shoes"
        let itemDescription = "Some nice shoes"
        let itemAmount = 1000

        let surchargeAmount = 10
        let fees = [ClientSession.Order.Fee(type: .surcharge, amount: surchargeAmount)]

        let merchantName = "Merchant Name"
        let applePayOptions = ApplePayOptions(merchantName: merchantName)

        let apiResponse = ClientSession.APIResponse(
            clientSessionId: nil,
            paymentMethod: nil,
            order: .init(id: "OrderId",
                         merchantAmount: nil,
                         totalOrderAmount: itemAmount + surchargeAmount,
                         totalTaxAmount: nil,
                         countryCode: .init(rawValue: "GB"),
                         currencyCode: .init(code: "GBP", decimalDigits: 2),
                         fees: fees,
                         lineItems: [
                            .init(itemId: "123",
                                  quantity: 1,
                                  amount: itemAmount,
                                  discountAmount: nil,
                                  name: itemName,
                                  description: itemDescription,
                                  taxAmount: nil,
                                  taxCode: nil,
                                  productType: nil)
                         ],
                         shippingMethod: nil
                         ),
            customer: nil,
            testId: nil)

        do {
            let orderItems = try sut.createOrderItemsFromClientSession(apiResponse,
                                                                       applePayOptions: applePayOptions)

            let expectedOrderItems = [
                try! ApplePayOrderItem(name: itemDescription,
                                  unitAmount: itemAmount,
                                  quantity: 1,
                                  discountAmount: nil,
                                  taxAmount: nil),
                try! ApplePayOrderItem(name: "Additional fees",
                                  unitAmount: surchargeAmount,
                                  quantity: 1,
                                  discountAmount: nil,
                                  taxAmount: nil),
                try! ApplePayOrderItem(name: merchantName,
                                  unitAmount: itemAmount + surchargeAmount,
                                  quantity: 1,
                                  discountAmount: nil,
                                  taxAmount: nil)
            ]

            XCTAssert(orderItems.count == 3)

            XCTAssert(orderItems == expectedOrderItems)


        } catch {
            XCTFail("Failed with error: \(error.localizedDescription)")
        }
    }

    func testCreateOrderItemsWithMerchantAmount() throws {
        let itemName = "Fancy Shoes"
        let itemDescription = "Some nice shoes"
        let itemAmount = 1000

        let surchargeAmount = 10
        let fees = [ClientSession.Order.Fee(type: .surcharge, amount: surchargeAmount)]

        let merchantName = "Merchant Name"
        let applePayOptions = ApplePayOptions(merchantName: merchantName)

        let apiResponse = ClientSession.APIResponse(
            clientSessionId: nil,
            paymentMethod: nil,
            order: .init(id: "OrderId",
                         merchantAmount: nil,
                         totalOrderAmount: itemAmount + surchargeAmount,
                         totalTaxAmount: nil,
                         countryCode: .init(rawValue: "GB"),
                         currencyCode: .init(code: "GBP", decimalDigits: 2),
                         fees: fees,
                         lineItems: [
                            .init(itemId: "123",
                                  quantity: 1,
                                  amount: itemAmount,
                                  discountAmount: nil,
                                  name: itemName,
                                  description: itemDescription,
                                  taxAmount: nil,
                                  taxCode: nil,
                                  productType: nil)
                         ],
                         shippingMethod: nil
                         ),
            customer: nil,
            testId: nil)
    }

    func testCreateOrderItemsWithShipping() throws {

        let itemName = "Fancy Shoes"
        let itemDescription = "Some nice shoes"
        let itemAmount = 1000

        let shippingMethodId = "ShippingMethodId"
        let shippingMethodName = "Shipping Method"
        let shippingMethodDescription = "Shipping Method Description"
        let shippingAmount = 100

        let merchantName = "Merchant Name"
        let applePayOptions = ApplePayOptions(merchantName: merchantName)

        let selectedShippingMethod = PKShippingMethod(label: shippingMethodName, amount: 100)
        selectedShippingMethod.identifier = shippingMethodId

        let selectedShippingMethodItem = try? ApplePayOrderItem(name: shippingMethodName,
                                                           unitAmount: shippingAmount,
                                                           quantity: 1,
                                                           discountAmount: nil,
                                                           taxAmount: nil)

        let apiResponse = ClientSession.APIResponse(
            clientSessionId: nil,
            paymentMethod: nil,
            order: .init(id: "OrderId",
                         merchantAmount: nil,
                         totalOrderAmount: itemAmount + shippingAmount,
                         totalTaxAmount: nil,
                         countryCode: .init(rawValue: "GB"),
                         currencyCode: .init(code: "GBP", decimalDigits: 2),
                         fees: nil,
                         lineItems: [
                            .init(itemId: "123",
                                  quantity: 1,
                                  amount: itemAmount,
                                  discountAmount: nil,
                                  name: itemName,
                                  description: itemDescription,
                                  taxAmount: nil,
                                  taxCode: nil,
                                  productType: nil)
                         ],
                         shippingMethod:
                            ClientSession.Order.ShippingMethod(amount: 100,
                                                               methodId: shippingMethodId,
                                                               methodName: shippingMethodName,
                                                               methodDescription: shippingMethodDescription)
                         ),
            customer: nil,
            testId: nil)

        do {
            let orderItems = try sut.createOrderItemsFromClientSession(apiResponse,
                                                                       applePayOptions: applePayOptions,
                                                                       selectedShippingItem: selectedShippingMethodItem)

            let expectedOrderItems = [
                try! ApplePayOrderItem(name: itemDescription,
                                  unitAmount: itemAmount,
                                  quantity: 1,
                                  discountAmount: nil, 
                                  taxAmount: nil),
                try! ApplePayOrderItem(name: "\(shippingMethodName)",
                                  unitAmount: shippingAmount,
                                  quantity: 1,
                                  discountAmount: nil,
                                  taxAmount: nil),
                try! ApplePayOrderItem(name: merchantName,
                                  unitAmount: itemAmount + shippingAmount,
                                  quantity: 1,
                                  discountAmount: nil,
                                  taxAmount: nil)
            ]

            XCTAssert(orderItems.count == 3)

            XCTAssert(orderItems == expectedOrderItems)


        } catch {
            XCTFail("Failed with error: \(error.localizedDescription)")
        }
    }

    func testProcessShippingContactChange() async throws {
        let contact = PKContact()
        var nameParts = PersonNameComponents()
        nameParts.givenName = "John"
        nameParts.familyName = "Doe"
        contact.name = nameParts

        contact.phoneNumber = CNPhoneNumber(stringValue: "1234567890")

        contact.emailAddress = "john.doe@example.com"

        let address = CNMutablePostalAddress()
        address.street = "123 Apple Street"
        address.city = "Cupertino"
        address.state = "CA"
        address.postalCode = "95014"
        address.country = "United States"
        contact.postalAddress = address

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient


        guard var config = PrimerAPIConfiguration.current else {
            XCTFail("Unable to generate configuration")
            return
        }
        config.checkoutModules = checkoutModules

        config.clientSession = ClientSession.APIResponse(
            clientSessionId: nil,
            paymentMethod: nil,
            order: .init(id: "OrderId",
                         merchantAmount: nil,
                         totalOrderAmount: 1200,
                         totalTaxAmount: nil,
                         countryCode: .init(rawValue: "GB"),
                         currencyCode: .init(code: "GBP", decimalDigits: 2),
                         fees: nil,
                         lineItems: [
                            .init(itemId: "123",
                                  quantity: 1,
                                  amount: 1000,
                                  discountAmount: nil,
                                  name: "Fancy Shoes",
                                  description: "Some nice shoes",
                                  taxAmount: nil,
                                  taxCode: nil,
                                  productType: nil)
                         ],
                         shippingMethod:
                            ClientSession.Order.ShippingMethod(amount: 200,
                                                               methodId: "Shipping",
                                                               methodName: "Shipping",
                                                               methodDescription: "Description")
                         ),
            customer: nil,
            testId: nil)


        let sut = ApplePayTokenizationViewModel(config: PrimerPaymentMethod(id: "APPLE_PAY",
                                                                            implementationType: .nativeSdk,
                                                                            type: "APPLE_PAY",
                                                                            name: "Apple Pay",
                                                                            processorConfigId: nil,
                                                                            surcharge: nil,
                                                                            options: nil,
                                                                            displayMetadata: nil))

        apiClient.fetchConfigurationWithActionsResult = (config, nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        // Test happy path
        let update = await sut.processShippingContactChange(contact)

        XCTAssertNotNil(update.paymentSummaryItems)
        XCTAssertNotNil(update.shippingMethods)

        //Test error when no Address
        contact.postalAddress = nil
        let update2 = await sut.processShippingContactChange(contact)
        XCTAssertNotNil(update2.errors)

        //Test Error when no shipping methods and Settings requireShippingMethod
        let settings = PrimerSettings(paymentMethodOptions:
            PrimerPaymentMethodOptions(applePayOptions:
                                        PrimerApplePayOptions(merchantIdentifier: "merchant_id",
                                                              merchantName: "merchant_name",
                                                              shippingOptions: .init(requireShippingMethod: true))
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        contact.postalAddress = address
        config.checkoutModules = nil
        apiClient.fetchConfigurationWithActionsResult = (config, nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        let update3 = await sut.processShippingContactChange(contact)
        XCTAssertNotNil(update3.errors)

        //Test error when no ClientSession
        config.clientSession = nil
        apiClient.fetchConfigurationWithActionsResult = (config, nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        let update4 = await sut.processShippingContactChange(contact)
        XCTAssertNotNil(update4.errors)
    }

    func testProcessShippingMethodChange() async throws {
        let sut = ApplePayTokenizationViewModel(config: PrimerPaymentMethod(id: "APPLE_PAY",
                                                                            implementationType: .nativeSdk,
                                                                            type: "APPLE_PAY",
                                                                            name: "Apple Pay",
                                                                            processorConfigId: nil,
                                                                            surcharge: nil,
                                                                            options: nil,
                                                                            displayMetadata: nil))

        //Test shipping method with no ID results in empty update
        let shippingMethod = PKShippingMethod()
        let update = await sut.processShippingMethodChange(shippingMethod)
        XCTAssert(update.paymentSummaryItems.isEmpty)

        //Test no clientSession results in empty update
        shippingMethod.identifier = "123"
        let update2 = await sut.processShippingMethodChange(shippingMethod)
        XCTAssert(update2.paymentSummaryItems.isEmpty)

        guard var config = PrimerAPIConfiguration.current else {
            XCTFail("Unable to generate configuration")
            return
        }
        config.checkoutModules = checkoutModules

        config.clientSession = ClientSession.APIResponse(
            clientSessionId: nil,
            paymentMethod: nil,
            order: .init(id: "OrderId",
                         merchantAmount: nil,
                         totalOrderAmount: 1200,
                         totalTaxAmount: nil,
                         countryCode: .init(rawValue: "GB"),
                         currencyCode: .init(code: "GBP", decimalDigits: 2),
                         fees: nil,
                         lineItems: [
                            .init(itemId: "123",
                                  quantity: 1,
                                  amount: 1000,
                                  discountAmount: nil,
                                  name: "Fancy Shoes",
                                  description: "Some nice shoes",
                                  taxAmount: nil,
                                  taxCode: nil,
                                  productType: nil)
                         ],
                         shippingMethod:
                            ClientSession.Order.ShippingMethod(amount: 200,
                                                               methodId: "Shipping",
                                                               methodName: "Shipping",
                                                               methodDescription: "Description")
                         ),
            customer: nil,
            testId: nil)

        let apiClient = MockPrimerAPIClient()
        PrimerAPIConfigurationModule.apiClient = apiClient

        config.checkoutModules = [Response.Body.Configuration.CheckoutModule(type: "SHIPPING",
                                                                            requestUrlStr: nil,
                                                                            options: ShippingMethodOptions(shippingMethods: [
                                                                             ShippingMethod(name: "Default",
                                                                                            description: "The default method",
                                                                                            amount: 100,
                                                                                            id: "default"),
                                                                             ShippingMethod(name: "Next Day",
                                                                                            description: "Get your stuff next day",
                                                                                            amount: 200,
                                                                                            id: "nextDay")],
                                                                                                          selectedShippingMethod: "nextDay")
                                                                           )]
        apiClient.fetchConfigurationWithActionsResult = (config, nil)
        PrimerAPIConfigurationModule.apiConfiguration = config

        let shippingMethod2 = PKShippingMethod(label: "Next Day", amount: 200)
        shippingMethod2.identifier = "nextDay"

        let update3 = await sut.processShippingMethodChange(shippingMethod2)
        XCTAssert(update3.paymentSummaryItems.count == 3)
        let shippingItem = update3.paymentSummaryItems[1]
        XCTAssertEqual(shippingItem.amount, 2)
        XCTAssertEqual(shippingItem.label, "Shipping")
    }

    // MARK: Helpers

    var order: ClientSession.Order {
        .init(id: "order_id",
              merchantAmount: 1234,
              totalOrderAmount: 1234,
              totalTaxAmount: nil,
              countryCode: .gb,
              currencyCode: Currency(code: "GBP", decimalDigits: 2),
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

    var checkoutModules = [
        Response.Body.Configuration.CheckoutModule(type: "SHIPPING",
                                                   requestUrlStr: nil,
                                                   options: ShippingMethodOptions(shippingMethods: [
                                                    ShippingMethod(name: "Default",
                                                                   description: "The default method",
                                                                   amount: 100,
                                                                   id: "default"),
                                                    ShippingMethod(name: "Next Day",
                                                                   description: "Get your stuff next day",
                                                                   amount: 200,
                                                                   id: "nextDay")],
                                                                                 selectedShippingMethod: "default")
                                                  )
    ]

}

fileprivate class MockApplePayPresentationManager: ApplePayPresenting {
    var isPresentable: Bool = true

    var errorForDisplay: Error = PrimerError.unableToPresentPaymentMethod(paymentMethodType: "APPLE_PAY",
                                                                          userInfo: .errorUserInfoDictionary(),
                                                                          diagnosticsId: UUID().uuidString)

    var onPresent: ((ApplePayRequest, PKPaymentAuthorizationControllerDelegate) -> Promise<Void>)?

    func present(withRequest applePayRequest: ApplePayRequest, delegate: PKPaymentAuthorizationControllerDelegate) -> Promise<Void> {
        return onPresent?(applePayRequest, delegate) ?? Promise.rejected(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
    }
    

}

fileprivate class MockPKPayment: PKPayment {
    override var token: PKPaymentToken {
        return MockPKPaymentToken()
    }

    override var billingContact: PKContact? {
        return MockPKContact()
    }
}

fileprivate class MockPKPaymentToken: PKPaymentToken {
    override var paymentMethod: PKPaymentMethod {
        return MockPKPaymentMethod()
    }

    override var paymentData: Data {
        let response = ApplePayPaymentResponseTokenPaymentData(data: "data", 
                                                               signature: "sig",
                                                               version: "version",
                                                               header: .init(ephemeralPublicKey: "key", publicKeyHash: "hash", transactionId: "t_id"))
        return try! JSONEncoder().encode(response)
    }
}

fileprivate class MockPKPaymentMethod: PKPaymentMethod {
    override var network: PKPaymentNetwork? {
        .visa
    }

    override var displayName: String? {
        "display_name"
    }

    override var type: PKPaymentMethodType {
        .credit
    }
}

fileprivate class MockPKContact: PKContact {
    override var postalAddress: CNPostalAddress? {
        get {
            let address = CNMutablePostalAddress()
            address.street = "pk_contact_street"
            address.postalCode = "pk_contact_postal_code"
            address.city = "pk_contact_city"
            address.state = "pk_contact_state"
            return address as CNPostalAddress
        }
        set {}
    }
}
