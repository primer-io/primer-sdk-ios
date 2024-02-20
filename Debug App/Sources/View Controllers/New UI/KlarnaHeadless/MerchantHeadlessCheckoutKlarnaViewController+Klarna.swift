//
//  MerchantHeadlessCheckoutKlarnaViewController+Klarna.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 29.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessKlarnaComponent {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerSDK.PrimerError) {
        showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
    }
    
    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {}
    
    // MARK: - PrimerHeadlessSteppableDelegate
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        if let step = step as? KlarnaSessionCreationStep {
            switch step {
            case .paymentSessionCreated(let clientToken, let paymentCategories):
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.hideLoader()
                    self.clientToken = clientToken
                    self.klarnaHeadlessPaymentViewModel.updatePaymentCategories(paymentCategories)
                }
            }
        }
        
        if let step = step as? KlarnaViewHandlingStep {
            switch step {
            case .viewInitialized:
                klarnaManager.loadPaymentView()
                
            case .viewResized:
                view.layoutIfNeeded()
                
            case .viewLoaded:
                hideLoader()
                
            default:
                break
            }
        }
        
        if let step = step as? KlarnaSessionAuthorizationStep {
            hideLoader()
            
            switch step {
            case .paymentSessionAuthorized(let authToken):
                showAlert(title: "Success", message: "Payment session completed with token: \(authToken)") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
                
            case .paymentSessionAuthorizationFailed:
                showAlert(title: "Authorization", message: "Payment authorization failed") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
                
            case .paymentSessionFinalizationRequired:
                klarnaHeadlessPaymentViewModel.updatSnackBar(with: "Finalizing in 2 seconds")
                finalizeSession()
                
            case .paymentSessionReauthorized(let authToken):
                showAlert(title: "Success", message: "Payment session reauthorized with token: \(authToken)") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
            
            case .paymentSessionReauthorizationFailed:
                showAlert(title: "Reauthorization", message: "Payment reauthorization failed") { [unowned self] in
                    navigationController?.popViewController(animated: true)
                }
            }
        }
        
        if let step = step as? KlarnaSessionFinalizationStep {
            hideLoader()
            
            switch step {
            case .paymentSessionFinalized(let authToken):
                showAlert(title: "Success", message: "Payment session finalized with token: \(authToken)") { [unowned self] in
                    navigationController?.popToRootViewController(animated: true)
                }
                
            case .paymentSessionFinalizationFailed:
                showAlert(title: "Finalization", message: "Payment finalization failed") { [unowned self] in
                    navigationController?.popViewController(animated: true)
                }
            }
        }
    }
}

// MARK: - Payment
extension MerchantHeadlessCheckoutKlarnaViewController {
    func startPaymentSession() {
        showLoader()
        klarnaManager.startSession()
    }
    
    func createPaymentView(category: KlarnaPaymentCategory) -> UIView? {
        guard let clientToken = clientToken else {
            showAlert(title: "Client token", message: "Client token not available")
            return nil
        }
        
        klarnaManager.setProvider(with: clientToken, paymentCategory: category.id)
        klarnaManager.setPaymentSessionDelegates()
        
        guard let paymentView = klarnaManager.createPaymentView() else {
            showAlert(title: "Payment view", message: "Unable to create payment view")
            return nil
        }
        
        klarnaManager.initPaymentView()
        
        return paymentView
    }
    
    func authorizeSession() {
        klarnaManager.authorizeSession(autoFinalize: autoFinalize)
    }
    
    func finalizeSession() {
        showLoader()
        klarnaManager.finalizeSession()
    }
}
