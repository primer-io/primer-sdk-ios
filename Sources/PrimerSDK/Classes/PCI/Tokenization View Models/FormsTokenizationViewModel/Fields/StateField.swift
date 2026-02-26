//
//  StateField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

final class PrimerStateField: PrimerCardFormFieldProtocol {

    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    static func stateFieldContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let stateFieldContainerView = PrimerCustomFieldView()
        stateFieldContainerView.fieldView = primerTextFieldView
        stateFieldContainerView.placeholderText = Strings.CardFormView.State.label
        stateFieldContainerView.setup()
        stateFieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return stateFieldContainerView
    }

    static func stateFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerStateFieldView {
        let stateFieldView = PrimerStateFieldView()
        stateFieldView.placeholder = Strings.CardFormView.State.placeholder
        stateFieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        stateFieldView.textColor = theme.input.text.color
        stateFieldView.delegate = delegate
        return stateFieldView
    }
}
