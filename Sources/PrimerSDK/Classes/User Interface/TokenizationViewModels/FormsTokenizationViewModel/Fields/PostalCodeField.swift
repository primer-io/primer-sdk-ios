//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
//

#if canImport(UIKit)

import UIKit

class PrimerPostalCodeField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func postalCodeContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let postalCodeContainerView = PrimerCustomFieldView()
        postalCodeContainerView.fieldView = primerTextFieldView
        postalCodeContainerView.placeholderText = Strings.CardFormView.PostalCode.label
        postalCodeContainerView.setup()
        postalCodeContainerView.tintColor = theme.input.border.color(for: .selected)
        return postalCodeContainerView
    }
    
    static func postalCodeViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerPostalCodeFieldView {
        let postalCodeFieldView = PrimerPostalCodeFieldView()
        postalCodeFieldView.placeholder = Strings.CardFormView.PostalCode.placeholder
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
}

#endif
