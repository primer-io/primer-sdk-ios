//
//  MerchantHeadlessCheckoutKlarnaViewController+Klarna.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerSDK
import UIKit

extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessErrorableDelegate,
                                                        PrimerHeadlessValidatableDelegate,
                                                        PrimerHeadlessSteppableDelegate {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerError) {
        print("Klarna finished with error: \(error)")
    }

    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {
        case .validating:
            showLoader()
        case .valid:
            hideLoader()
        case let .invalid(errors: errors):
            hideLoader()
            var message = ""
            for error in errors {
                message += (error.errorDescription ?? error.localizedDescription) + "\n"
            }
            showAlert(title: "Validation Error", message: "\(message)")
        case let .error(error: error):
            hideLoader()
            showAlert(title: error.errorId, message: error.recoverySuggestion ?? error.localizedDescription)
        }
    }

    // MARK: - PrimerHeadlessSteppableDelegate
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaStep {
            switch step {
            case let .paymentSessionCreated(clientToken, paymentCategories):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hideLoader()
                    self.clientToken = clientToken
                    self.klarnaInitializationViewModel.updatePaymentCategories(paymentCategories)
                }

            case let .paymentSessionAuthorized( _, checkoutData):
                print("Payment session authorization successful with data: \(checkoutData)")

            case .paymentSessionFinalizationRequired:
                klarnaInitializationViewModel.updatSnackBar(with: "Finalizing in 2 seconds")
                finalizeSession()

            case let .paymentSessionFinalized( _, checkoutData):
                print("Payment session finalization successful with data: \(checkoutData)")

            case let .viewLoaded(view):
                hideLoader()
                if let view {
                    passRenderedKlarnaView(view)
                }

            default:
                break
            }
        }
    }
}

// MARK: - Payment
extension MerchantHeadlessCheckoutKlarnaViewController {
    func startPaymentSession() {
        showLoader()
        klarnaComponent?.start()
    }

    func authorizeSession() {
        klarnaComponent?.submit()
    }

    func finalizeSession() {
        showLoader()
        klarnaComponent?.updateCollectedData(collectableData: KlarnaCollectableData.finalizePayment)
    }
}
