//
//  LastNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerLastNameField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func lastNameFieldContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let lastNameFieldContainerView = PrimerCustomFieldView()
        lastNameFieldContainerView.fieldView = view
        lastNameFieldContainerView.placeholderText = NSLocalizedString("primer-card-form-last-name",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "Last Name",
                                                                        comment: "The billing address last name")
        lastNameFieldContainerView.setup()
        lastNameFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return lastNameFieldContainerView
    }
    
    static func lastNameFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerLastNameFieldView {
        let lastNameFieldView = PrimerLastNameFieldView()
        lastNameFieldView.placeholder = NSLocalizedString("primer-form-text-field-placeholder-last-name",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "e.g. Doe",
                                                            comment: "e.g. Doe - Form Text Field Placeholder (Address last name)")
        lastNameFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        lastNameFieldView.textColor = theme.input.text.color
        lastNameFieldView.delegate = delegate
        return lastNameFieldView
    }
}

#endif
