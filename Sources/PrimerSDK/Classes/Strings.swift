//
//  Strings.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 10/02/22.
//  Copyright © 2022 Primer API ltd, Inc. All rights reserved.
//

import Foundation

struct Strings {
    
    enum PrimerButton {
        
        static let title = NSLocalizedString(
            "primer-button-title-default",
            bundle: Bundle.primerResources,
            comment: "The title of the primer deafult button")
        
        static let payInInstallments = NSLocalizedString(
            "primer-button-title-pay-in-installments",
            bundle: Bundle.primerResources,
            value: "Pay in installments",
            comment: "The title of the primer 'pay in installments' button")
        
        static let pay = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                      bundle: Bundle.primerResources,
                                      value: "Pay",
                                      comment: "Pay - Card Form View (Sumbit button text)")
    }
    
    enum Generic {
        static let somethingWentWrong = NSLocalizedString(
            "primer-error-screen",
            bundle: Bundle.primerResources,
            value: "Something went wrong, please try again.",
            comment: "A generic error message that is displayed on the error view")
    }
    
    enum PrimerTestFlowDecision {
        
        static let successTitle = NSLocalizedString(
            "primer-test-payment-method-success-flow-title",
            bundle: Bundle.primerResources,
            value: "Authorized",
            comment: "The title of the mocked successful flow for a Test Payment Method")

        static let declineTitle = NSLocalizedString(
            "primer-test-payment-method-decline-flow-title",
            bundle: Bundle.primerResources,
            value: "Declined",
            comment: "The title of the mocked declined flow for a Test Payment Method")

        static let failTitle = NSLocalizedString(
            "primer-test-payment-method-fail-flow-title",
            bundle: Bundle.primerResources,
            value: "Failed",
            comment: "The title of the mocked failed flow for a Test Payment Method")
    }
}
