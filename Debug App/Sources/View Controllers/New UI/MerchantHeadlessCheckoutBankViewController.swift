//
//  MerchantHeadlessCheckoutBankViewController.swift
//  Debug App
//
//  Created by Alexandra Lovin on 06.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
import UIKit
import SwiftUI
import PrimerSDK

final class MerchantHeadlessCheckoutBankViewController: UIHostingController<BanksListView> {
    private lazy var idealManager: PrimerHeadlessUniversalCheckout.PrimerHeadlessFormWithRedirectManager = PrimerHeadlessUniversalCheckout.PrimerHeadlessFormWithRedirectManager()
    private let paymentMethodType: String = "ADYEN_IDEAL"

    private(set) var activityIndicator: UIActivityIndicatorView?
    private(set) var bankComponent: BanksComponent?


    override func viewDidLoad() {
        super.viewDidLoad()
        guard let bankComponent = idealManager.provideBanksComponent(paymentMethodType: paymentMethodType) else {
            return
        }
        bankComponent.stepDelegate = self
        bankComponent.validationDelegate = self
        bankComponent.errorDelegate = self
        bankComponent.start()
    }
}

// MARK: - PrimerHeadlessErrorableDelegate, PrimerHeadlessValidatableDelegate, PrimerHeadlessStepableDelegate
extension MerchantHeadlessCheckoutBankViewController:   PrimerHeadlessErrorableDelegate,
                                                        PrimerHeadlessValidatableDelegate,
                                                        PrimerHeadlessSteppableDelegate {

    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        switch validationStatus {

        case .validating:
            print("Forms with redirect validation in progress")
        case .valid:
            if data is BanksCollectableData {
                bankComponent?.submit()
            }
        case .invalid(errors: let errors):
            var message = ""
            for error in errors {
                message += (error.errorDescription ?? error.localizedDescription) + "\n"
            }
            self.showAlert(title: "Validation Error", message: "\(message)")
        case .error(error: let error):
            self.showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
        }
    }

    func didReceiveError(error: PrimerError) {
        self.showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
    }

    func didReceiveStep(step: PrimerHeadlessStep) {
        guard let step = step as? BanksStep else {
            self.showAlert(title: "Error", message: "Received wrong step of \(step)")
            return
        }
        switch step {
        case .loading: showLoadingOverlay()
        case .banksRetrieved(banks: let banks): renderBanks(banks)
        case .webRedirect(component: let redirectComponent): handleRedirectComponent(redirectComponent)
        }
    }
}


private extension MerchantHeadlessCheckoutBankViewController {
    private func showLoadingOverlay() {
        DispatchQueue.main.async {
            if self.activityIndicator != nil { return }
            self.activityIndicator = UIActivityIndicatorView(frame: self.view.bounds)
            self.view.addSubview(self.activityIndicator!)
            self.activityIndicator?.backgroundColor = .black.withAlphaComponent(0.2)
            self.activityIndicator?.color = .black
            self.activityIndicator?.startAnimating()
        }
    }

    private func hideLoadingOverlay() {
        DispatchQueue.main.async {
            self.activityIndicator?.stopAnimating()
            self.activityIndicator?.removeFromSuperview()
            self.activityIndicator = nil
        }
    }

    private func renderBanks(_ banks: [BanksComponent.IssuingBank]) {
        hideLoadingOverlay()
        rootView.banks.updateBanks(banks)
    }

    private func handleRedirectComponent(_ redirectComponent: WebRedirectComponent) {
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
