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
        cardNumberContainerView.placeholderText = NSLocalizedString("primer-form-text-field-title-card-number",
                                                                    tableName: nil,
                                                                    bundle: Bundle.primerResources,
                                                                    value: "Card number",
                                                                    comment: "Card number - Form Text Field Title (Card number)")
        cardNumberContainerView.setup()
        cardNumberContainerView.tintColor = theme.input.border.color(for: .selected)
        return cardNumberContainerView
    }
    
    static func cardNumberFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCardNumberFieldView {
        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.placeholder = "4242 4242 4242 4242"
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.input.text.color
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = delegate
        return cardNumberField
    }
}

#endif
