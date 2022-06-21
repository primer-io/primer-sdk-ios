//
//  CardholderNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerPostalCodeField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func postalCodeContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let postalCodeContainerView = PrimerCustomFieldView()
        postalCodeContainerView.fieldView = view
        postalCodeContainerView.placeholderText = localPostalCodeTitle
        postalCodeContainerView.setup()
        postalCodeContainerView.tintColor = theme.input.border.color(for: .selected)
        return postalCodeContainerView
    }
    
    static func postalCodeViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerPostalCodeFieldView {
        let postalCodeFieldView = PrimerPostalCodeFieldView()
        postalCodeFieldView.placeholder = localSamplePostalCode
        postalCodeFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        postalCodeFieldView.textColor = theme.input.text.color
        postalCodeFieldView.delegate = delegate
        return postalCodeFieldView
    }
}

extension PrimerPostalCodeField {
    
    private static var localSamplePostalCode: String {
        let countryCode = AppState.current.apiConfiguration?.clientSession?.order?.countryCode
        return PostalCode.sample(for: countryCode)
    }

    static var localPostalCodeTitle: String {
        let countryCode = AppState.current.apiConfiguration?.clientSession?.order?.countryCode
        return PostalCode.name(for: countryCode)
    }
}

#endif
