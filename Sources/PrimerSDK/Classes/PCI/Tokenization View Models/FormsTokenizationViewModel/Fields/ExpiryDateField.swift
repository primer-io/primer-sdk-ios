//
//  PrimerEpiryDateField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//



import UIKit

class PrimerEpiryDateField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func expiryDateContainerViewWithFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let expiryDateContainerView = PrimerCustomFieldView()
        expiryDateContainerView.fieldView = primerTextFieldView
        expiryDateContainerView.placeholderText = Strings.CardFormView.ExpiryDate.label
        expiryDateContainerView.setup()
        expiryDateContainerView.tintColor = theme.input.border.color(for: .selected)
        return expiryDateContainerView
    }

    static func expiryDateFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerExpiryDateFieldView {
        let expiryDateField = PrimerExpiryDateFieldView()
        expiryDateField.placeholder = Strings.CardFormView.ExpiryDate.placeholder
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.input.text.color
        expiryDateField.delegate = delegate
        return expiryDateField
    }
}


