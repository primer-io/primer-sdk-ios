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

class PrimerEpiryDateField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func expiryDateContainerViewWithFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let expiryDateContainerView = PrimerCustomFieldView()
        expiryDateContainerView.fieldView = primerTextFieldView
        expiryDateContainerView.placeholderText = Strings.CardFormView.ExpiryDate.label
        expiryDateContainerView.setup()
        expiryDateContainerView.tintColor = theme.input.border.color(for: .selected)
        return expiryDateContainerView
    }

    static func expiryDateFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerExpiryDateFieldView {
        let expiryDateField = PrimerExpiryDateFieldView()
        expiryDateField.placeholder = Strings.CardFormView.ExpiryDate.placeholder
        expiryDateField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        expiryDateField.textColor = theme.input.text.color
        expiryDateField.delegate = delegate
        return expiryDateField
    }
}

#endif
