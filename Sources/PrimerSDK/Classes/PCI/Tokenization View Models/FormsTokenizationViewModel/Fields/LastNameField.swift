//
//  LastNameField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerUI
import UIKit

final class PrimerLastNameField: PrimerCardFormFieldProtocol {

    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    static func lastNameFieldContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let lastNameFieldContainerView = PrimerCustomFieldView()
        lastNameFieldContainerView.fieldView = primerTextFieldView
        lastNameFieldContainerView.placeholderText = Strings.CardFormView.LastName.label
        lastNameFieldContainerView.setup()
        lastNameFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return lastNameFieldContainerView
    }

    static func lastNameFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerLastNameFieldView {
        let lastNameFieldView = PrimerLastNameFieldView()
        lastNameFieldView.placeholder = Strings.CardFormView.LastName.placeholder
        lastNameFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        lastNameFieldView.textColor = theme.input.text.color
        lastNameFieldView.delegate = delegate
        return lastNameFieldView
    }
}
