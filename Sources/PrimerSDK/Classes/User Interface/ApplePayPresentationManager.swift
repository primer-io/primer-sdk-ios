//
//  ApplePayPresentationManager.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 23/05/2024.
//

import Foundation
import PassKit

protocol ApplePayPresenting {
    var isPresentable: Bool { get }
    var errorForDisplay: Error { get }
    func present(withRequest applePayRequest: ApplePayRequest,
                 delegate: PKPaymentAuthorizationControllerDelegate) -> Promise<Void>
}

final class ApplePayPresentationManager: ApplePayPresenting, LogReporter {

    private var supportedNetworks: [PKPaymentNetwork] {
        ApplePayUtils.supportedPKPaymentNetworks()
    }

    var isPresentable: Bool {
        var canMakePayment: Bool
        if PrimerSettings.current.paymentMethodOptions.applePayOptions?.checkProvidedNetworks == true {
            canMakePayment = PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
        } else {
            canMakePayment = PKPaymentAuthorizationController.canMakePayments()
        }
        return canMakePayment
    }

    func present(withRequest applePayRequest: ApplePayRequest,
                 delegate: PKPaymentAuthorizationControllerDelegate) -> Promise<Void> {
        Promise { seal in
            let request = createRequest(for: applePayRequest)

            let paymentController = PKPaymentAuthorizationController(paymentRequest: request)
            paymentController.delegate = delegate

            paymentController.present { success in
                if success == false {
                    // Check merchant identifier first
                    if applePayRequest.merchantIdentifier.isEmpty {
                        let err = PrimerError.applePayConfigurationError(
                            merchantIdentifier: nil,
                            userInfo: .errorUserInfoDictionary(),
                            diagnosticsId: UUID().uuidString
                        )
                        ErrorHandler.handle(error: err)
                        self.logger.error(message: "APPLE PAY")
                        self.logger.error(message: err.recoverySuggestion ?? "")
                        seal.reject(err)
                        return
                    }
                    
                    // Generic presentation failure
                    let err = PrimerError.applePayPresentationFailed(
                        reason: "PKPaymentAuthorizationController.present returned false",
                        userInfo: .errorUserInfoDictionary(),
                        diagnosticsId: UUID().uuidString
                    )
                    ErrorHandler.handle(error: err)
                    self.logger.error(message: "APPLE PAY")
                    self.logger.error(message: err.recoverySuggestion ?? "")
                    seal.reject(err)
                    return
                } else {
                    PrimerDelegateProxy.primerHeadlessUniversalCheckoutUIDidShowPaymentMethod(for: PrimerPaymentMethodType.applePay.rawValue)
                    seal.fulfill()
                }
            }
        }
    }

    func createRequest(for applePayRequest: ApplePayRequest) -> PKPaymentRequest {
        let request = PKPaymentRequest()
        let applePayOptions = PrimerSettings.current.paymentMethodOptions.applePayOptions

        // Map contact fields from options
        let contactFields = mapContactFieldsFromOptions(applePayOptions: applePayOptions)
        request.requiredShippingContactFields = contactFields.mappedShippingContactFields
        request.requiredBillingContactFields = contactFields.mappedBillingContactFields

        request.currencyCode = applePayRequest.currency.code
        request.countryCode = applePayRequest.countryCode.rawValue
        request.merchantIdentifier = applePayRequest.merchantIdentifier
        request.merchantCapabilities = [.capability3DS]
        request.supportedNetworks = supportedNetworks
        request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })

        if let shippingMethods = applePayRequest.shippingMethods {
            request.shippingMethods = shippingMethods
        }

        return request
    }

    func mapContactFieldsFromOptions(applePayOptions: PrimerApplePayOptions?) -> (mappedShippingContactFields: Set<PKContactField>, mappedBillingContactFields: Set<PKContactField>) {

        var requiredShippingContactFields = Set<PKContactField>()
        var requiredBillingContactFields = Set<PKContactField>()

        // Map required shipping contact fields
        if let shippingContactFields = applePayOptions?.shippingOptions?.shippingContactFields, !shippingContactFields.isEmpty {
            shippingContactFields.forEach {
                requiredShippingContactFields.insert($0.toPKContact())
            }
        }

        // Map required billing contact fields
        if let billingContactFields = applePayOptions?.billingOptions?.requiredBillingContactFields {
            billingContactFields.forEach {
                requiredBillingContactFields.insert($0.toPKContact())
            }
        }

        // Handle deprecated `isCaptureBillingAddressEnabled`
        if requiredBillingContactFields.isEmpty, applePayOptions?.isCaptureBillingAddressEnabled == true {
            requiredBillingContactFields.insert(.postalAddress)
        }

        // Move phone and email from billing to shipping if existing
        let phoneField = PKContactField.phoneNumber
        let emailField = PKContactField.emailAddress

        if requiredBillingContactFields.contains(phoneField), !requiredShippingContactFields.contains(phoneField) {
            requiredShippingContactFields.insert(phoneField)
        }

        if requiredBillingContactFields.contains(emailField), !requiredShippingContactFields.contains(emailField) {
            requiredShippingContactFields.insert(emailField)
        }

        // Remove phone and email from billing fields
        requiredBillingContactFields.remove(phoneField)
        requiredBillingContactFields.remove(emailField)

        return (requiredShippingContactFields, requiredBillingContactFields)
    }

    var errorForDisplay: Error {
        // Check if device supports Apple Pay at all
        if !PKPaymentAuthorizationController.canMakePayments() {
            self.logger.error(message: "APPLE PAY")
            self.logger.error(message: "Device does not support Apple Pay")
            let err = PrimerError.applePayDeviceNotSupported(userInfo: .errorUserInfoDictionary(),
                                                            diagnosticsId: UUID().uuidString)
            return err
        }
        
        // Check if we're checking specific networks
        if PrimerSettings.current.paymentMethodOptions.applePayOptions?.checkProvidedNetworks == true {
            // Device supports Apple Pay but no cards for our supported networks
            self.logger.error(message: "APPLE PAY")
            self.logger.error(message: "No cards available for supported networks")
            let err = PrimerError.applePayNoCardsInWallet(userInfo: .errorUserInfoDictionary(),
                                                          diagnosticsId: UUID().uuidString)
            return err
        } else {
            // Generic error - shouldn't reach here in normal flow
            self.logger.error(message: "APPLE PAY")
            self.logger.error(message: "Cannot present Apple Pay")
            let err = PrimerError.unableToPresentApplePay(userInfo: .errorUserInfoDictionary(),
                                                          diagnosticsId: UUID().uuidString)
            return err
        }
    }
}

extension PrimerApplePayOptions.RequiredContactField {
    func toPKContact() -> PKContactField {
        switch self {
        case .name:
            return .name
        case .emailAddress:
            return .emailAddress
        case .phoneNumber:
            return .phoneNumber
        case .postalAddress:
            return .postalAddress
        }
    }
}
