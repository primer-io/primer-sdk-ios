//
//  ApplePayPresentationManagerTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import PassKit
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
        let request = try sut.createRequest(for: applePayRequest)

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
        let additionalFields: [PrimerApplePayOptions.RequiredContactField] = [.name, .emailAddress, .phoneNumber, .postalAddress ]

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
        let additionalFields: [PrimerApplePayOptions.RequiredContactField] = [.name, .emailAddress, .phoneNumber, .postalAddress ]

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
        XCTAssertTrue(error.localizedDescription.hasPrefix("[unable-to-present-apple-pay] Unable to present Apple Pay"))

        registerApplePayOptions()
        let error2 = sut.errorForDisplay
        XCTAssertTrue(error2.localizedDescription.hasPrefix("[apple-pay-no-cards-in-wallet] Apple Pay has no cards in wallet"))
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
                                                                                                  ], descriptor: nil),
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
    
    // MARK: - Additional coverage tests
    
    func testCreateRequestWithNilShippingMethods() throws {
        let applePayRequest = ApplePayRequest(
            currency: Currency(code: "USD", decimalDigits: 2),
            merchantIdentifier: "merchant_id",
            countryCode: .us,
            items: [],
            shippingMethods: nil
        )
        
        let request = try sut.createRequest(for: applePayRequest)
        
        XCTAssertNil(request.shippingMethods)
        XCTAssertEqual(request.merchantIdentifier, "merchant_id")
        XCTAssertEqual(request.countryCode, "US")
    }
    
    // MARK: - Error for display tests
    
    func testErrorForDisplayWithCheckProvidedNetworksFalse() {
        // First ensure settings without checkProvidedNetworks
        let settings = PrimerSettings(paymentMethodOptions:
                                        .init(applePayOptions:
                                                .init(merchantIdentifier: "merchant_id", 
                                                      merchantName: "merchant_name", 
                                                      checkProvidedNetworks: false)
                                        )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        
        let error = sut.errorForDisplay
        
        guard let primerError = error as? PrimerError else {
            XCTFail("Expected PrimerError")
            return
        }
        
        // When checkProvidedNetworks is false and device supports Apple Pay, 
        // it should return the generic unableToPresentApplePay error
        switch primerError {
        case .unableToPresentApplePay:
            XCTAssertEqual(primerError.errorId, "unable-to-present-apple-pay")
        default:
            XCTFail("Expected unableToPresentApplePay error")
        }
    }

    // MARK: - PKContactField extension tests
    
    func testPKContactFieldExtension() {
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.name.toPKContact(), .name)
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.emailAddress.toPKContact(), .emailAddress)
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.phoneNumber.toPKContact(), .phoneNumber)
        XCTAssertEqual(PrimerApplePayOptions.RequiredContactField.postalAddress.toPKContact(), .postalAddress)
    }
}
