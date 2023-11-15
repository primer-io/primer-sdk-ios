//
//  MerchantHeadlessCheckoutBankViewController.swift
//  Debug App
//
//  Created by Alexandra Lovin on 06.11.2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import Foundation
import UIKit
import PrimerSDK

final class MerchantHeadlessCheckoutBankViewController: UIViewController {
    private lazy var idealManager: PrimerHeadlessUniversalCheckout.PrimerHeadlessFormWithRedirectManager = PrimerHeadlessUniversalCheckout.PrimerHeadlessFormWithRedirectManager()
    private let paymentMethodType: String = "ADYEN_IDEAL"

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
//        guard let banksComponent = idealManager.provideBanksComponent(methodType: paymentMethodType) else { return }
//        banksComponent.errorDelegate = self
//        banksComponent.validationDelegate = self
//        banksComponent.stepDelegate = self
//        banksComponent.start()
    }

    private func setupUI() {

    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: - PrimerHeadlessErrorableDelegate, PrimerHeadlessValidatableDelegate, PrimerHeadlessStepableDelegate
extension MerchantHeadlessCheckoutBankViewController:   PrimerHeadlessErrorableDelegate,
                                                        PrimerHeadlessValidatableDelegate,
                                                        PrimerHeadlessSteppableDelegate {

    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
//        switch validationStatus {
//
//        case .validating:
//            print("NOL data validation in progress")
//        case .valid:
//            switch data {
//            case is BanksCollectableData:
//                banksComponent.submit()
//            case is EmptyCollectableData:
//                webRedirectComponent?.submit()
//            default: break
//            }
//        case .invalid(errors: let errors):
//            var message = ""
//            for error in errors {
//                message += (error.errorDescription ?? error.localizedDescription) + "\n"
//            }
//            self.showAlert(title: "Validation Error", message: "\(message)")
//        case .error(error: let error):
//            self.showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
//        }
    }

    func didReceiveError(error: PrimerError) {
        self.showAlert(title: "Error", message: error.errorDescription ?? error.localizedDescription)
    }

    func didReceiveStep(step: PrimerHeadlessStep) {
        // TODO: implement step processing
        print("Did receive step using \(step)")
        if let step = step as? BanksStep {
            processBankStep(step: step)
        }
    }

    private func processBankStep(step: BanksStep) {

    }
}
