//
//  CVVField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerUI
import UIKit

final class PrimerCVVField: PrimerCardFormFieldProtocol {

    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    static func cvvContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let cvvContainerView = PrimerCustomFieldView()
        cvvContainerView.fieldView = primerTextFieldView
        cvvContainerView.placeholderText = Strings.CardFormView.CVV.label
        cvvContainerView.setup()
        cvvContainerView.tintColor = theme.input.border.color(for: .selected)
        return cvvContainerView
    }

    static func cvvFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCVVFieldView {
        let cvvField = PrimerCVVFieldView()
        cvvField.placeholder = Strings.CardFormView.CVV.placeholder
        cvvField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cvvField.textColor = theme.input.text.color
        cvvField.delegate = delegate
        return cvvField
    }
}
