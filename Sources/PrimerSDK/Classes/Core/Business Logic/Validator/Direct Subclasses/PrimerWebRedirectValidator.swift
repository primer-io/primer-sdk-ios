//
//  PrimerWebRedirectValidator.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

#if canImport(UIKit)

import Foundation

class PrimerWebRedirectValidator: PrimerValidator {
    
    override func validateSynchronously() throws {
        try super.validateSynchronously()
        try super.throwErrors()
    }
}

#endif
