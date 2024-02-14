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
        if let step = step as? KlarnaPaymentSessionCreation {
            switch step {
            case .paymentSessionCreated(let clientToken, let paymentCategories):
                DispatchQueue.main.async { [weak self] in
                    self?.hideLoader()
                    self?.clientToken = clientToken
                    self?.paymentCategories = paymentCategories
                }
            }
        }
        
        if let step = step as? KlarnaPaymentViewHandling {
            switch step {
            case .viewInitialized:
                klarnaManager.loadPaymentView()
                
            case .viewResized(let height):
                paymentViewContainerHeightConstraint.constant = height
                view.layoutIfNeeded()
                
            case .viewLoaded:
                hideLoader()
                paymentContainerView.isHidden = false
                view.bringSubviewToFront(paymentContainerView)
                
            default:
                break
            }
        }
        
        if let step = step as? KlarnaPaymentSessionAuthorization {
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
                finalizePayment = true
                paymentContinueButton.setTitle("Finalize", for: .normal)
                
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
        
        if let step = step as? KlarnaPaymentSessionFinalization {
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
        checkoutTypeContainerView.isHidden = true
        klarnaManager.startSession()
    }
    
    func createPaymentView(category: KlarnaPaymentCategory) {
        guard let clientToken = clientToken else {
            showAlert(title: "Client token", message: "Client token not available")
            return
        }
        
        klarnaManager.setProvider(with: clientToken, paymentCategory: category.id)
        klarnaManager.setViewHandlingDelegate(self)
        
        guard let paymentView = klarnaManager.createPaymentView() else {
            showAlert(title: "Payment view", message: "Unable to create payment view")
            return
        }
        
        paymentView.translatesAutoresizingMaskIntoConstraints = false
        paymentViewContainerView.addSubview(paymentView)
        
        NSLayoutConstraint.activate([
            paymentView.topAnchor.constraint(equalTo: paymentViewContainerView.topAnchor),
            paymentView.leadingAnchor.constraint(equalTo: paymentViewContainerView.leadingAnchor),
            paymentView.trailingAnchor.constraint(equalTo: paymentViewContainerView.trailingAnchor),
            paymentView.bottomAnchor.constraint(equalTo: paymentViewContainerView.bottomAnchor)
        ])
        
        klarnaManager.initPaymentView()
    }
    
    func authorizeSession() {
        klarnaManager.setSessionAuthorizationDelegate(self)
        klarnaManager.authorizeSession(autoFinalize: !finalizeManually)
    }
    
    func finalizeSession() {
        klarnaManager.setSessionFinalizationDelegate(self)
        klarnaManager.finalizeSession()
    }
}
