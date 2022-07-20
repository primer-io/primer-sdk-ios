//
//  CardholderNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerFirstNameField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func firstNameFieldContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let firstNameFieldContainerView = PrimerCustomFieldView()
        firstNameFieldContainerView.fieldView = primerTextFieldView
        firstNameFieldContainerView.placeholderText = Strings.CardFormView.FirstName.label
        firstNameFieldContainerView.setup()
        firstNameFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return firstNameFieldContainerView
    }
    
    static func firstNameFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerFirstNameFieldView {
        let firstNameFieldView = PrimerFirstNameFieldView()
        firstNameFieldView.placeholder = Strings.CardFormView.FirstName.placeholder
        firstNameFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        firstNameFieldView.textColor = theme.input.text.color
        firstNameFieldView.delegate = delegate
        return firstNameFieldView
    }
}

#endif
