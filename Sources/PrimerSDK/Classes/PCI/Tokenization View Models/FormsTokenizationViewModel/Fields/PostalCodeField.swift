//
//  PostalCodeField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerUI
import UIKit

final class PrimerPostalCodeField: PrimerCardFormFieldProtocol {

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
