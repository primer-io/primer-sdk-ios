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
    
    static func cityFieldContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let cityFieldContainerView = PrimerCustomFieldView()
        cityFieldContainerView.fieldView = primerTextFieldView
        cityFieldContainerView.placeholderText = Strings.CardFormView.City.label
        cityFieldContainerView.setup()
        cityFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return cityFieldContainerView
    }
    
    static func cityFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCityFieldView {
        let cityFieldView = PrimerCityFieldView()
        cityFieldView.placeholder = Strings.CardFormView.City.placeholder
        cityFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cityFieldView.textColor = theme.input.text.color
        cityFieldView.delegate = delegate
        return cityFieldView
    }
}

#endif
