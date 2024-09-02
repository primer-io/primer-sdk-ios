//
//  MerchantHeadlessCheckoutStripeAchViewController+StripeAch.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 03.05.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit
import PrimerSDK

extension MerchantHeadlessCheckoutStripeAchViewController: PrimerHeadlessErrorableDelegate,
                                                        PrimerHeadlessValidatableDelegate,
                                                        PrimerHeadlessSteppableDelegate {
    // MARK: - PrimerHeadlessErrorableDelegate
    func didReceiveError(error: PrimerSDK.PrimerError) {
        presentResultsVC(checkoutData: nil, error: error)
    }

    // MARK: - PrimerHeadlessValidatableDelegate
    func didUpdate(validationStatus: PrimerSDK.PrimerValidationStatus, for data: PrimerSDK.PrimerCollectableData?) {
        guard let data = data as? ACHUserDetailsCollectableData else { return }
        switch validationStatus {
        case .valid:
            updateFieldStatus(data)
        case .invalid(errors: let errors):
            guard let error = errors.first else { return }
            updateFieldStatus(data, error: error)
        default:
            break
        }
    }

    // MARK: - PrimerHeadlessSteppableDelegate
    func didReceiveStep(step: PrimerSDK.PrimerHeadlessStep) {
        guard let step = step as? ACHUserDetailsStep else { return }
        switch step {
        case .retrievedUserDetails(let userDetails):
            stripeFormViewModel.firstName = userDetails.firstName
            stripeFormViewModel.lastName = userDetails.lastName
            stripeFormViewModel.emailAddress = userDetails.emailAddress
            setupObservables()
        default:
            break
        }
    }
}

// MARK: - Method helpers
extension MerchantHeadlessCheckoutStripeAchViewController {
    private func updateFieldStatus(_ data: ACHUserDetailsCollectableData, error: PrimerValidationError? = nil) {
        let isFieldValid = data.isValid
        switch data {
        case .firstName:
            stripeFormViewModel.isFirstNameValid = isFieldValid
            stripeFormViewModel.firstNameErrorDescription = error?.errorDescription ?? ""
        case .lastName:
            stripeFormViewModel.isLastNameValid = isFieldValid
            stripeFormViewModel.lastNameErrorDescription = error?.errorDescription ?? ""
        case .emailAddress:
            stripeFormViewModel.isEmailAddressValid = isFieldValid
            stripeFormViewModel.emailErrorDescription = error?.errorDescription ?? ""
        }
    }
    
    private func presentResultsVC(checkoutData: PrimerCheckoutData?, error: Error?) {
        DispatchQueue.main.async {
            let rvc = MerchantResultViewController.instantiate(checkoutData: checkoutData, error: error, logs: self.logs)
            self.navigationController?.popToRootViewController(animated: true)
            self.navigationController?.pushViewController(rvc, animated: true)
        }
    }
}

// MARK: - PrimerHeadlessUniversalCheckoutDelegate
extension MerchantHeadlessCheckoutStripeAchViewController: PrimerHeadlessUniversalCheckoutDelegate {
    func primerHeadlessUniversalCheckoutDidStartTokenization(for paymentMethodType: String) {
        print("\n\nMERCHANT APP\n\(#function)\npaymentMethodType: \(paymentMethodType)")
        self.logs.append(#function)
    }
    
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {
        print("\n\nMERCHANT APP\n\(#function)\ndata: \(data)")
        logs.append(#function)
        presentResultsVC(checkoutData: data, error: nil)
    }
    
    func primerHeadlessUniversalCheckoutDidFail(withError err: any Error, checkoutData: PrimerCheckoutData?) {
        print("\n\nMERCHANT APP\n\(#function)\nerror: \(err)\ncheckoutData: \(String(describing: checkoutData))")
        logs.append(#function)
        presentResultsVC(checkoutData: nil, error: err)
    }
    
    func primerHeadlessUniversalCheckoutDidReceiveAdditionalInfo(_ additionalInfo: PrimerCheckoutAdditionalInfo?) {
        print("\n\nMERCHANT APP\n\(#function)\nadditionalInfo: \(String(describing: additionalInfo))")
        if let stripeCollector = additionalInfo as? ACHBankAccountCollectorAdditionalInfo {
            showStripeCollector(stripeCollector.collectorViewController)
        } else {
            showMandate()
        }
    }
}
