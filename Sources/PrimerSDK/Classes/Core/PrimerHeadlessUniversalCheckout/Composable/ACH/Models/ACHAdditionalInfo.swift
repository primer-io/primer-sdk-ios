//
//  ACHAdditionalInfo.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 31.05.2024.
//

import UIKit

@objc public class PrimerStripeAchAdditionalInfo: PrimerCheckoutAdditionalInfo {}

// MARK: Stripe bank account collector view controller
@objc public class StripeBankAccountCollectorAdditionalInfo: PrimerStripeAchAdditionalInfo {

    public var collectorViewController: UIViewController

    public init(collectorViewController: UIViewController) {
        self.collectorViewController = collectorViewController
        super.init()
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

// MARK: Stripe bank account collector view controller
@objc public class ACHMandateAdditionalInfo: PrimerStripeAchAdditionalInfo {}
