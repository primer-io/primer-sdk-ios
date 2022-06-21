//
//  CardholderNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerCVVField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func cvvContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let cvvContainerView = PrimerCustomFieldView()
        cvvContainerView.fieldView = view
        cvvContainerView.placeholderText = NSLocalizedString("primer-card-form-cvv",
                                                             tableName: nil,
                                                             bundle: Bundle.primerResources,
                                                             value: "CVV",
                                                             comment: "CVV - Card Form (CVV text field placeholder text)")
        cvvContainerView.setup()
        cvvContainerView.tintColor = theme.input.border.color(for: .selected)
        return cvvContainerView
    }
    
    static func cvvFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCVVFieldView {
        let cvvField = PrimerCVVFieldView()
        cvvField.placeholder = "123"
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.input.text.color
        cvvField.delegate = delegate
        return cvvField
    }
}

#endif
