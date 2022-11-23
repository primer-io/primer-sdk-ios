//
//  UserInterfaceModuleSubmitButtonFactory.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 22/11/22.
//

#if canImport(UIKit)

import UIKit

class UserInterfaceModuleSubmitButtonFactory {
    
    static func makeSubmitButtonForUserInterfaceModule(_ userInferfaceModule: UserInterfaceModule,
                                                       titleText: String,
                                                       accessibilityIdentifier: UserInterfaceModuleButtonAccessibilityIdentifierType = .submit,
                                                       action: Selector,
                                                       isEnabled: Bool = false) -> PrimerButton {
        let submitButton = PrimerButton()
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.accessibilityIdentifier = accessibilityIdentifier.rawValue
        submitButton.isEnabled = isEnabled
        submitButton.setTitle(titleText, for: .normal)
        submitButton.backgroundColor = isEnabled ? userInferfaceModule.theme.mainButton.color(for: .enabled) : userInferfaceModule.theme.mainButton.color(for: .disabled)
        submitButton.setTitleColor(userInferfaceModule.theme.mainButton.text.color, for: .normal)
        submitButton.layer.cornerRadius = 4
        submitButton.clipsToBounds = true
        submitButton.addTarget(userInferfaceModule, action: action, for: .touchUpInside)
        return submitButton
    }
    
}

#endif
