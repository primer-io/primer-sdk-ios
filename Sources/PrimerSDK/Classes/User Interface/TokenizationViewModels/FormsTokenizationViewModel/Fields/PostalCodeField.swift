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
        let postalCodeField = PrimerPostalCodeFieldView()
        postalCodeField.placeholder = localSamplePostalCode
        postalCodeField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        postalCodeField.textColor = theme.input.text.color
        postalCodeField.delegate = delegate
        return postalCodeField
    }
}

extension PrimerPostalCodeField {
    
    private static var localSamplePostalCode: String {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let countryCode = state.primerConfiguration?.clientSession?.order?.countryCode
        return PostalCode.sample(for: countryCode)
    }

    static var localPostalCodeTitle: String {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let countryCode = state.primerConfiguration?.clientSession?.order?.countryCode
        return PostalCode.name(for: countryCode)
    }
}

#endif
