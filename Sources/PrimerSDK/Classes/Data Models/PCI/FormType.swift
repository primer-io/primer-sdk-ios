//
//  FormType.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 24/01/2021.
//

#if canImport(UIKit)

import Foundation

public enum PrimerFormType: String, CaseIterable {
    case bankAccount
    case name
    case iban
    case email
    case address
    case cardForm
}

#endif
