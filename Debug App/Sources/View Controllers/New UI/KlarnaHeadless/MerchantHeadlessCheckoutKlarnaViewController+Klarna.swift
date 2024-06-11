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
        switch error {
        case .klarnaError:
            showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
        default:
            logs.removeAll()
            logs.append("primerHeadlessUniversalCheckoutDidFail(withError:checkoutData:)")
            presentResultsVC(checkoutData: nil, error: error)
        }
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
                showResultsVC(checkoutData: checkoutData, error: nil)

            case .paymentSessionFinalizationRequired:
                klarnaInitializationViewModel.updatSnackBar(with: "Finalizing in 2 seconds")
                finalizeSession()

            case .paymentSessionFinalized( _, let checkoutData):
                showResultsVC(checkoutData: checkoutData, error: nil)

            case .viewLoaded(let view):
                hideLoader()
                logs.append("Loaded klarna view")
                if let view {
                    passRenderedKlarnaView(view)
                }

            default:
                break
            }
        }
    }

    private func showResultsVC(checkoutData: PrimerCheckoutData?, error: Error?) {
        // If the checkout flow was set for Manual Handling then we want to show the manualHandlingCheckoutData
        if manualHandlingCheckoutData != nil {
            presentResultsVC(checkoutData: manualHandlingCheckoutData, error: nil)
            return
        }
        presentResultsVC(checkoutData: checkoutData, error: nil)
    }
    
    private func presentResultsVC(checkoutData: PrimerCheckoutData?, error: Error?) {
        let rvc = MerchantResultViewController.instantiate(checkoutData: checkoutData, error: error, logs: logs)
        navigationController?.popToRootViewController(animated: true)
        navigationController?.pushViewController(rvc, animated: true)
    }
}

extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessUniversalCheckoutDelegate {
    
    func primerHeadlessUniversalCheckoutWillCreatePaymentWithData(_ data: PrimerCheckoutPaymentMethodData, decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        decisionHandler(.continuePaymentCreation())
    }
    
    func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
    }
    
    func primerHeadlessUniversalCheckoutDidTokenizePaymentMethod(_ paymentMethodTokenData: PrimerPaymentMethodTokenData, decisionHandler: @escaping (PrimerHeadlessUniversalCheckoutResumeDecision) -> Void) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodTokenData: \(paymentMethodTokenData)")

        Networking.createPayment(with: paymentMethodTokenData) { (res, err) in
            if let err = err {
                self.showErrorMessage(err.localizedDescription)
                self.showLoader()

            } else if let res = res {
                //self.paymentId = res.id

                if res.requiredAction?.clientToken != nil {
                    decisionHandler(.continueWithNewClientToken(res.requiredAction!.clientToken))
                } else {
                    DispatchQueue.main.async {
                        self.hideLoader()
                    }
                    self.manualHandlingCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(id: res.id,
                                                                                              orderId: res.orderId,
                                                                                              paymentFailureReason: nil))
                    decisionHandler(.complete())
                }

            } else {
                assert(true)
            }
        }
    }
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
    }
}

// MARK: - Payment
extension MerchantHeadlessCheckoutKlarnaViewController {
    func startPaymentSession() {
        logs.append(#function)
        showLoader()
        klarnaComponent?.start()
    }

    func authorizeSession() {
        logs.append(#function)
        klarnaComponent?.submit()
    }

    func finalizeSession() {
        logs.append(#function)
        showLoader()
        klarnaComponent?.updateCollectedData(collectableData: KlarnaCollectableData.finalizePayment)
    }
}
