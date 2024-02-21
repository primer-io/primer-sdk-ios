//
//  MerchantHeadlessCheckoutKlarnaViewController+Klarna.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 29.01.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

extension MerchantHeadlessCheckoutKlarnaViewController: PrimerHeadlessKlarnaDelegates {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerSDK.PrimerError) {
        showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
    }
    
    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        
        // Aici logica de la creation step
        
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
                
            case .paymentSessionAuthorizationFailed(let error):
                presentResultsVC(checkoutData: nil, error: error)
                
            case .paymentSessionFinalizationRequired:
                klarnaInitializationViewModel.updatSnackBar(with: "Finalizing in 2 seconds")
                finalizeSession()
                
            case .paymentSessionFinalized( _, let checkoutData):
                presentResultsVC(checkoutData: checkoutData, error: nil)
                
            case .paymentSessionFinalizationFailed(let error):
                presentResultsVC(checkoutData: nil, error: error)
                
            case .viewInitialized:
                klarnaComponent?.loadPaymentView()
                
            case .viewResized:
                view.layoutIfNeeded()
                
            case .viewLoaded:
                hideLoader()
                
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
    
    func createPaymentView(category: KlarnaPaymentCategory) -> UIView? {
        logs.append(#function)
        guard let clientToken = clientToken else {
            showAlert(title: "Client token", message: "Client token not available")
            return nil
        }
        
        klarnaComponent?.setProvider(with: clientToken, paymentCategory: category.id)
        klarnaComponent?.setPaymentSessionDelegates()
        
        guard let paymentView = klarnaComponent?.createPaymentView() else {
            showAlert(title: "Payment view", message: "Unable to create payment view")
            return nil
        }
        
        klarnaComponent?.initPaymentView()
        
        return paymentView
    }
    
    func authorizeSession() {
        logs.append(#function)
        klarnaComponent?.submit()
    }
    
    func finalizeSession() {
        logs.append(#function)
        showLoader()
        klarnaComponent?.finalise()
    }
}
