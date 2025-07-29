//
//  CardNumberField.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import UIKit

final class PrimerCardNumberField: PrimerCardFormFieldProtocol {

    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()

    static func cardNumberContainerViewWithFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let cardNumberContainerView = PrimerCustomFieldView()
        cardNumberContainerView.fieldView = primerTextFieldView
        cardNumberContainerView.placeholderText = Strings.CardFormView.CardNumber.label
        cardNumberContainerView.setup()
        cardNumberContainerView.tintColor = theme.input.border.color(for: .selected)
        return cardNumberContainerView
    }

    static func cardNumberFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCardNumberFieldView {
        let cardNumberField = PrimerCardNumberFieldView()
        cardNumberField.placeholder = Strings.CardFormView.CardNumber.placeholder
        cardNumberField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardNumberField.textColor = theme.input.text.color
        cardNumberField.borderStyle = .none
        cardNumberField.delegate = delegate
        return cardNumberField
    }
}
