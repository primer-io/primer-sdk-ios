//
//  MerchantHeadlessCheckoutKlarnaViewController+Klarna.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 29.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessErrorableDelegate,
                                                        PrimerHeadlessValidatableDelegate,
                                                        PrimerHeadlessSteppableDelegate {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerSDK.PrimerError) {
        print("Klarna finished with error: \(error)")
    }

    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {
        case .validating:
            showLoader()
        case .valid:
            hideLoader()
        case .invalid(errors: let errors):
            hideLoader()
            var message = ""
            for error in errors {
                message += (error.errorDescription ?? error.localizedDescription) + "\n"
            }
            showAlert(title: "Validation Error", message: "\(message)")
        case .error(error: let error):
            hideLoader()
            showAlert(title: error.errorId, message: error.recoverySuggestion ?? error.localizedDescription)
        }
    }

    // MARK: - PrimerHeadlessSteppableDelegate
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaStep {
            switch step {
            case .paymentSessionCreated(let clientToken, let paymentCategories):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hideLoader()
                    self.clientToken = clientToken
                    self.klarnaInitializationViewModel.updatePaymentCategories(paymentCategories)
                }

            case .paymentSessionAuthorized( _, let checkoutData):
                print("Payment session authorization successful with data: \(checkoutData)")

            case .paymentSessionFinalizationRequired:
                klarnaInitializationViewModel.updatSnackBar(with: "Finalizing in 2 seconds")
                finalizeSession()

            case .paymentSessionFinalized( _, let checkoutData):
                print("Payment session finalization successful with data: \(checkoutData)")

            case .viewLoaded(let view):
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
