//
//  CardholderNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerCityField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func cityFieldContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let cityFieldContainerView = PrimerCustomFieldView()
        cityFieldContainerView.fieldView = view
        cityFieldContainerView.placeholderText = NSLocalizedString("primer-card-form-city",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "City",
                                                                        comment: "The billing address city")
        cityFieldContainerView.setup()
        cityFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return cityFieldContainerView
    }
    
    static func cityFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCityFieldView {
        let cityFieldView = PrimerCityFieldView()
        cityFieldView.placeholder = NSLocalizedString("primer-form-text-field-placeholder-city",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "City",
                                                            comment: "Form Text Field Placeholder (Address city)")
        cityFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cityFieldView.textColor = theme.input.text.color
        cityFieldView.delegate = delegate
        return cityFieldView
    }
}

#endif
