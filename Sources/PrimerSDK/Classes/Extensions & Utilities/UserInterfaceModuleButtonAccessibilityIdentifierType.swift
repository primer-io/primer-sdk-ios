//
//  UserInterfaceModuleButtonAccessibilityIdentifierType.swift
//  PrimerSDK
//
//  Created by Evangelos on 21/10/22.
//

#if canImport(UIKit)

import UIKit

enum UserInterfaceModuleButtonAccessibilityIdentifierType {
    case submit
    case other(String)
}

extension UserInterfaceModuleButtonAccessibilityIdentifierType: RawRepresentable {
    
    init?(rawValue: String) {
        switch rawValue {
        case "submit_btn": self = .submit
        case let otherAccessibilityId: self = .other(otherAccessibilityId)
        }
    }

    var rawValue: String {
        switch self {
        case .submit: return "submit_btn"
        case let .other(otherAccessibilityId): return otherAccessibilityId
        }
    }
}

#endif

