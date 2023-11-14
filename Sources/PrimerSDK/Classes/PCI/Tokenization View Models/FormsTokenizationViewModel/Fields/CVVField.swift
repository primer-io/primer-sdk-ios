//
//  CardholderNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

import UIKit

class PrimerCVVField: PrimerCardFormFieldProtocol {

    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    static func cvvContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let cvvContainerView = PrimerCustomFieldView()
        cvvContainerView.fieldView = primerTextFieldView
        cvvContainerView.placeholderText = Strings.CardFormView.CVV.label
        cvvContainerView.setup()
        cvvContainerView.tintColor = theme.input.border.color(for: .selected)
        return cvvContainerView
    }

    static func cvvFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCVVFieldView {
        let cvvField = PrimerCVVFieldView()
        cvvField.placeholder = Strings.CardFormView.CVV.placeholder
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.input.text.color
        cvvField.delegate = delegate
        return cvvField
    }
}
