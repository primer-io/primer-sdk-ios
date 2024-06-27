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
    func present(withRequest applePayRequest: ApplePayRequest,
                 delegate: PKPaymentAuthorizationControllerDelegate) -> Promise<Void>
}

class ApplePayPresentationManager: ApplePayPresenting, LogReporter {

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
            guard isPresentable else {
                let error = errorForDisplay
                ErrorHandler.handle(error: error)
                seal.reject(error)
                return
            }

            let request = createRequest(for: applePayRequest)

            let paymentController = PKPaymentAuthorizationController(paymentRequest: request)
            paymentController.delegate = delegate

            paymentController.present { success in
                if success == false {
                    let err = PrimerError.unableToPresentApplePay(userInfo: .errorUserInfoDictionary(),
                                                                  diagnosticsId: UUID().uuidString)
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
        let isBillingContactFieldsRequired = applePayOptions?.isCaptureBillingAddressEnabled == true
        request.requiredBillingContactFields = isBillingContactFieldsRequired ? [.postalAddress] : []
        request.currencyCode = applePayRequest.currency.code
        request.countryCode = applePayRequest.countryCode.rawValue
        request.merchantIdentifier = applePayRequest.merchantIdentifier
        request.merchantCapabilities = [.capability3DS]
        request.supportedNetworks = supportedNetworks
        request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })

        return request
    }

    var errorForDisplay: Error {
        let errorMessage = "Cannot run ApplePay on this device"

        if PrimerSettings.current.paymentMethodOptions.applePayOptions?.checkProvidedNetworks == true {
            self.logger.error(message: "APPLE PAY")
            self.logger.error(message: errorMessage)
            let err = PrimerError.unableToMakePaymentsOnProvidedNetworks(userInfo: .errorUserInfoDictionary(),
                                                                         diagnosticsId: UUID().uuidString)
            return err
        } else {
            self.logger.error(message: "APPLE PAY")
            self.logger.error(message: errorMessage)
            let info = ["message": errorMessage]
            let err = PrimerError.unableToPresentPaymentMethod(paymentMethodType: "APPLE_PAY",
                                                               userInfo: .errorUserInfoDictionary(additionalInfo: info),
                                                               diagnosticsId: UUID().uuidString)
            return err
        }
    }
}
