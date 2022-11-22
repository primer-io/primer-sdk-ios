//
//  UserInterfaceModuleButton.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/11/22.
//

#if canImport(UIKit)

import UIKit

protocol UserInterfaceModuleButtonProtocol {
        
    var accessibilityIdentifier: UserInterfaceModuleButtonAccessibilityIdentifierType { get }
    var buttonTitle: String { get set }
    var backgroundColor: UIColor { get }
    var titleColor: UIColor { get }
    var action: Selector { get }
    
    init(text: String, isEnabled: Bool, action: Selector)

    func enableUserInterfaceModuleButtonIfNeeded()
}

#endif
