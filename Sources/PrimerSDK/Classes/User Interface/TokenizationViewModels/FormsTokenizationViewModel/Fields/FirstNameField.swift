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
    
    static func firstNameFieldContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let firstNameFieldContainerView = PrimerCustomFieldView()
        firstNameFieldContainerView.fieldView = view
        firstNameFieldContainerView.placeholderText = NSLocalizedString("primer-card-form-first-name",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "First Name",
                                                                        comment: "The billing address first name")
        firstNameFieldContainerView.setup()
        firstNameFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return firstNameFieldContainerView
    }
    
    static func firstNameFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerFirstNameFieldView {
        let firstNameField = PrimerFirstNameFieldView()
        firstNameField.placeholder = NSLocalizedString("primer-form-text-field-placeholder-first-name",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "e.g. John",
                                                            comment: "e.g. John - Form Text Field Placeholder (Address first name)")
        firstNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        firstNameField.textColor = theme.input.text.color
        firstNameField.delegate = delegate
        return firstNameField
    }
}

#endif
