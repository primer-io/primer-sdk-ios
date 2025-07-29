//
//  ACHAdditionalInfo.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

@objc public class ACHAdditionalInfo: PrimerCheckoutAdditionalInfo {}

// MARK: ACH bank account collector view controller
@objc public final class ACHBankAccountCollectorAdditionalInfo: ACHAdditionalInfo {

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
@objc public final class ACHMandateAdditionalInfo: ACHAdditionalInfo {}
