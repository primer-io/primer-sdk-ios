//
//  ApplePayPresentationManagerTests.swift
//
//
//  Created by Jack Newcombe on 23/05/2024.
//

import XCTest
@testable import PrimerSDK

final class ApplePayPresentationManagerTests: XCTestCase {

    var sut: ApplePayPresentationManager!

    override func setUpWithError() throws {
        sut = ApplePayPresentationManager()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    func testCreateRequest() throws {
        let applePayRequest = ApplePayRequest(currency: Currency(code: "GBP", decimalDigits: 2),
                                              merchantIdentifier: "merchant_id",
                                              countryCode: .gb,
                                              items: [
                                                try .init(name: "line_item_name",
                                                          unitAmount: 123,
                                                          quantity: 1,
                                                          discountAmount: nil,
                                                          taxAmount: nil)
                                              ],
                                              shippingMethods: [.init(label: "Shipping", amount: 100)])
        let request = sut.createRequest(for: applePayRequest)

        XCTAssertEqual(request.countryCode, "GB")
        XCTAssertEqual(request.currencyCode, "GBP")
        XCTAssertEqual(request.merchantIdentifier, "merchant_id")

        XCTAssertNotNil(request.paymentSummaryItems.first)
        XCTAssertEqual(request.paymentSummaryItems.first!.amount.doubleValue, 1.23, accuracy: 0.01)
        XCTAssertEqual(request.paymentSummaryItems.first!.label, "line_item_name")
        XCTAssertEqual(request.paymentSummaryItems.first!.type, .final)

        XCTAssertNotNil(request.shippingMethods)
    }

    func testIsPresentable() {
        XCTAssertTrue(sut.isPresentable)

        registerApplePayOptions()
        XCTAssertTrue(sut.isPresentable)

        registerAllowedCardNetworks()
        XCTAssertTrue(sut.isPresentable)
    }

    func testShippingContactFields() throws {
        let additionalFields: [PrimerApplePayOptions.RequiredContactField] = [.name, .emailAddress, .phoneNumber, .postalAddress,]

        var applePayOptions = PrimerApplePayOptions(merchantIdentifier: "merchant_id",
                                                    merchantName: "merchant_name",
                                                    checkProvidedNetworks: true,
                                                    shippingOptions: .init(shippingContactFields: additionalFields,
                                                                           requireShippingMethod: true))
        var shippingFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions).mappedShippingContactFields

        XCTAssertEqual(shippingFields, [.name, .emailAddress, .phoneNumber, .postalAddress])

        applePayOptions = PrimerApplePayOptions(merchantIdentifier: "merchant_id",
                                                merchantName: "merchant_name",
                                                checkProvidedNetworks: true,
                                                shippingOptions: .init(shippingContactFields: nil,
                                                                       requireShippingMethod: true))

        shippingFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions).mappedShippingContactFields

        XCTAssertEqual(shippingFields, [])
    }

    func testBillingContactFields() throws {
        let additionalFields: [PrimerApplePayOptions.RequiredContactField] = [.name, .emailAddress, .phoneNumber, .postalAddress,]

        var applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            checkProvidedNetworks: true,
            shippingOptions: .init(shippingContactFields: [], requireShippingMethod: true),
            billingOptions: .init(requiredBillingContactFields: additionalFields)
        )

        let contactFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields = contactFields.mappedBillingContactFields
        let shippingFields = contactFields.mappedShippingContactFields

        XCTAssertEqual(billingFields, [.name, .postalAddress])
        XCTAssertEqual(shippingFields, [.emailAddress, .phoneNumber])

        // Test with nil billing contact fields
        applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            checkProvidedNetworks: true,
            shippingOptions: .init(shippingContactFields: [], requireShippingMethod: true),
            billingOptions: .init(requiredBillingContactFields: nil)
        )

        let contactFields2 = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields2 = contactFields2.mappedBillingContactFields
        let shippingFields2 = contactFields2.mappedShippingContactFields

        XCTAssertEqual(billingFields2, [])
        XCTAssertEqual(shippingFields2, [])

        // Test with deprecated `isCaptureBillingAddressEnabled`
        applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            isCaptureBillingAddressEnabled: true,
            checkProvidedNetworks: true,
            shippingOptions: .init(shippingContactFields: [], requireShippingMethod: true)
        )

        let contactFields3 = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields3 = contactFields3.mappedBillingContactFields
        let shippingFields3 = contactFields3.mappedShippingContactFields

        XCTAssertEqual(billingFields3, [.postalAddress])
        XCTAssertEqual(shippingFields3, [])
    }

    func testErrorForDisplay() {
        let error = sut.errorForDisplay
        XCTAssertTrue(error.localizedDescription.hasPrefix("[unable-to-present-payment-method] Unable to present payment method APPLE_PAY"))

        registerApplePayOptions()
        let error2 = sut.errorForDisplay
        XCTAssertTrue(error2.localizedDescription.hasPrefix("[unable-to-make-payments-on-provided-networks] Unable to make payments on provided networks"))
    }

    // MARK: Helpers

    func registerApplePayOptions() {
        let settings = PrimerSettings(paymentMethodOptions:
                .init(applePayOptions:
                        .init(merchantIdentifier: "merchant_id", merchantName: "merchant_name", checkProvidedNetworks: true)
                )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    func registerAllowedCardNetworks() {
        PrimerAPIConfigurationModule.apiConfiguration?.clientSession = .init(clientSessionId: "client_session_id",
                                                                             paymentMethod: .init(vaultOnSuccess: false,
                                                                                                  options: nil,
                                                                                                  orderedAllowedCardNetworks: [
                                                                                                    "CARTES_BANCAIRES"
                                                                                                  ]),
                                                                             order: nil,
                                                                             customer: nil,
                                                                             testId: nil)

    }

    func testDefaultContactFields() throws {
        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            checkProvidedNetworks: true,
            shippingOptions: nil,
            billingOptions: nil
        )

        let contactFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields = contactFields.mappedBillingContactFields
        let shippingFields = contactFields.mappedShippingContactFields

        XCTAssertEqual(billingFields, [])
        XCTAssertEqual(shippingFields, [])
    }

    func testMovingPhoneAndEmailToShipping() throws {
        let additionalFields: [PrimerApplePayOptions.RequiredContactField] = [.name, .emailAddress, .phoneNumber]

        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            checkProvidedNetworks: true,
            shippingOptions: .init(shippingContactFields: [], requireShippingMethod: true),
            billingOptions: .init(requiredBillingContactFields: additionalFields)
        )

        let contactFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields = contactFields.mappedBillingContactFields
        let shippingFields = contactFields.mappedShippingContactFields

        XCTAssertEqual(billingFields, [.name])
        XCTAssertEqual(shippingFields, [.emailAddress, .phoneNumber])
    }

    func testDeprecatedCaptureBillingAddressEnabled() throws {
        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            isCaptureBillingAddressEnabled: true,
            checkProvidedNetworks: true,
            shippingOptions: .init(shippingContactFields: [], requireShippingMethod: true),
            billingOptions: nil
        )

        let contactFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields = contactFields.mappedBillingContactFields
        let shippingFields = contactFields.mappedShippingContactFields

        XCTAssertEqual(billingFields, [.postalAddress])
        XCTAssertEqual(shippingFields, [])
    }

    func testAllShippingFields() throws {
        let additionalFields: [PrimerApplePayOptions.RequiredContactField] = [.name, .emailAddress, .phoneNumber, .postalAddress]

        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            checkProvidedNetworks: true,
            shippingOptions: .init(shippingContactFields: additionalFields, requireShippingMethod: true),
            billingOptions: nil
        )

        let contactFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields = contactFields.mappedBillingContactFields
        let shippingFields = contactFields.mappedShippingContactFields

        XCTAssertEqual(billingFields, [])
        XCTAssertEqual(shippingFields, [.name, .emailAddress, .phoneNumber, .postalAddress])
    }

    func testNoShippingOrBillingFields() throws {
        let applePayOptions = PrimerApplePayOptions(
            merchantIdentifier: "merchant_id",
            merchantName: "merchant_name",
            checkProvidedNetworks: true,
            shippingOptions: nil,
            billingOptions: nil
        )
        
        let contactFields = sut.mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        let billingFields = contactFields.mappedBillingContactFields
        let shippingFields = contactFields.mappedShippingContactFields

        XCTAssertEqual(billingFields, [])
        XCTAssertEqual(shippingFields, [])
    }
}
