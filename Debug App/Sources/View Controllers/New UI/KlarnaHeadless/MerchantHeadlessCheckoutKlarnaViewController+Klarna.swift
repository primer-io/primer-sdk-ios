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
        case .klarnaWrapperError:
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
                presentResultsVC(checkoutData: checkoutData, error: nil)
                
            case .paymentSessionFinalizationRequired:
                klarnaInitializationViewModel.updatSnackBar(with: "Finalizing in 2 seconds")
                finalizeSession()
                
            case .paymentSessionFinalized( _, let checkoutData):
                presentResultsVC(checkoutData: checkoutData, error: nil)
                
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
    
    private func presentResultsVC(checkoutData: PrimerCheckoutData?, error: Error?) {
        let rvc = MerchantResultViewController.instantiate(checkoutData: checkoutData, error: error, logs: logs)
        navigationController?.popToRootViewController(animated: true)
        navigationController?.pushViewController(rvc, animated: true)
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
