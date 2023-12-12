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

final class MerchantHeadlessCheckoutBankViewController: UIViewController {
    private lazy var manager: PrimerHeadlessUniversalCheckout.ComponentWithRedirectManager = PrimerHeadlessUniversalCheckout.ComponentWithRedirectManager()
    let paymentMethodType: String = "ADYEN_IDEAL"

    private(set) var activityIndicator: UIActivityIndicatorView?
    private(set) var bankComponent: (any BanksComponent)?
    private let banksModel: BanksListModel = BanksListModel()

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let bankComponent: any BanksComponent = try? manager.provide(paymentMethodType: paymentMethodType) else {
            return
        }
        addBanksListViewController()
        bankComponent.stepDelegate = self
        bankComponent.validationDelegate = self
        bankComponent.errorDelegate = self
        bankComponent.start()
        self.bankComponent = bankComponent
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hideLoadingOverlay()
    }

    private func addBanksListViewController() {
        let headerView = BanksListView(paymentMethodModel: PaymentMethodModel(name: paymentMethodType, logo: nil), banksModel: banksModel, didSelectBank: { [weak self] bankId in
            guard let self = self else { return }
            self.showLoadingOverlay()
            self.bankComponent?.updateCollectedData(collectableData: BanksCollectableData.bankId(bankId: bankId))
        }, didFilterByText: { [weak self] filterText in
            guard let self = self else { return }
            self.showLoadingOverlay()
            self.bankComponent?.updateCollectedData(collectableData: BanksCollectableData.bankFilterText(text: filterText))
        })
        let listViewController = UIHostingController(rootView: headerView)
        listViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(listViewController)
        view.addSubview(listViewController.view)
        listViewController.didMove(toParent: self)
        NSLayoutConstraint.activate([
            listViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            listViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            listViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            listViewController.view.heightAnchor.constraint(
                equalTo: view.heightAnchor,
                multiplier: 1
            )
        ])
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
            if let data = data as? BanksCollectableData {
                switch data {
                case .bankId(bankId: _):
                    bankComponent?.submit()
                default:
                    break
                }
            }
        case .invalid(errors: let errors):
            var message = ""
            for error in errors {
                message += (error.errorDescription ?? error.localizedDescription) + "\n"
            }
            hideLoadingOverlay()
            self.showAlert(title: "Validation Error", message: "\(message)")
        case .error(error: let error):
            self.showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
            hideLoadingOverlay()
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

    private func renderBanks(_ banks: [IssuingBank]) {
        hideLoadingOverlay()
        banksModel.updateBanks(banks)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}
