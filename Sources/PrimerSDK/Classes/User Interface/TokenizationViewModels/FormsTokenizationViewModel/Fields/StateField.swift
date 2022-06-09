//
//  CardholderNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerStateField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func stateFieldContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let stateFieldContainerView = PrimerCustomFieldView()
        stateFieldContainerView.fieldView = view
        stateFieldContainerView.placeholderText = NSLocalizedString("primer-card-form-state",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "State",
                                                                        comment: "The billing address state")
        stateFieldContainerView.setup()
        stateFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return stateFieldContainerView
    }
    
    static func stateFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerStateFieldView {
        let stateFieldView = PrimerStateFieldView()
        stateFieldView.placeholder = NSLocalizedString("primer-form-text-field-placeholder-state",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "State",
                                                            comment: "Form Text Field Placeholder (Address state)")
        stateFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        stateFieldView.textColor = theme.input.text.color
        stateFieldView.delegate = delegate
        return stateFieldView
    }
}

#endif
