//
//  ACHAdditionalInfo.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 31.05.2024.
//

import UIKit

@objc public class ACHAdditionalInfo: PrimerCheckoutAdditionalInfo {}

// MARK: ACH bank account collector view controller
@objc public class ACHBankAccountCollectorAdditionalInfo: ACHAdditionalInfo {

    public var collectorViewController: UIViewController

    public init(collectorViewController: UIViewController) {
        self.collectorViewController = collectorViewController
        super.init()
    }
    
    required init(from decoder: any Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }
}

// MARK: ACH mandate info
@objc public class ACHMandateAdditionalInfo: ACHAdditionalInfo {}
