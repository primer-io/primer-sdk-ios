//
//  PrimerQRCodeValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 3/7/23.
//

#if canImport(UIKit)

import Foundation

class PrimerQRCodeValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
        try super.throwErrors()
    }
}

#endif
