//
//  PrimerEpiryDateField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerEpiryDateField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func expiryDateContainerViewWithFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let expiryDateContainerView = PrimerCustomFieldView()
        expiryDateContainerView.fieldView = view
        expiryDateContainerView.placeholderText = NSLocalizedString("primer-form-text-field-title-expiry-date",
                                                                    tableName: nil,
                                                                    bundle: Bundle.primerResources,
                                                                    value: "Expiry date",
                                                                    comment: "Expiry date - Form Text Field Title (Expiry date)")
        expiryDateContainerView.setup()
        expiryDateContainerView.tintColor = theme.input.border.color(for: .selected)
        return expiryDateContainerView
    }

    static func expiryDateFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerExpiryDateFieldView {
        let expiryDateField = PrimerExpiryDateFieldView()
        expiryDateField.placeholder = "02/25"
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.input.text.color
        expiryDateField.delegate = delegate
        return expiryDateField
    }
}

#endif
