//
//  PrimerTestPaymentMethodValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 5/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerVoucherValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
        try super.throwErrors()
    }
}

#endif
