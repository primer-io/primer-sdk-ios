//
//  FirstNameField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerUI
import UIKit

final class PrimerFirstNameField: PrimerCardFormFieldProtocol {

    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    static func firstNameFieldContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let firstNameFieldContainerView = PrimerCustomFieldView()
        firstNameFieldContainerView.fieldView = primerTextFieldView
        firstNameFieldContainerView.placeholderText = Strings.CardFormView.FirstName.label
        firstNameFieldContainerView.setup()
        firstNameFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return firstNameFieldContainerView
    }

    static func firstNameFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerFirstNameFieldView {
        let firstNameFieldView = PrimerFirstNameFieldView()
        firstNameFieldView.placeholder = Strings.CardFormView.FirstName.placeholder
        firstNameFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        firstNameFieldView.textColor = theme.input.text.color
        firstNameFieldView.delegate = delegate
        return firstNameFieldView
    }
}
