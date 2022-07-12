//
//  PrimerEpiryDateField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerCardNumberField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func cardNumberContainerViewWithFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let cardNumberContainerView = PrimerCustomFieldView()
        cardNumberContainerView.fieldView = view
        cardNumberContainerView.placeholderText = Strings.CardFormView.CardNumber.label
        cardNumberContainerView.setup()
        cardNumberContainerView.tintColor = theme.input.border.color(for: .selected)
        return cardNumberContainerView
    }
    
    static func cardNumberFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCardNumberFieldView {
        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.placeholder = Strings.CardFormView.CardNumber.placeholder
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.input.text.color
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = delegate
        return cardNumberField
    }
}

#endif
