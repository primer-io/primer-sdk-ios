//
//  AddressField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import UIKit

class PrimerAddressField: PrimerCardFormFieldProtocol {

    static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
}

final class PrimerAddressLine1Field: PrimerAddressField {

    static func addressLine1ContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let addressLine1FieldContainerView = PrimerCustomFieldView()
        addressLine1FieldContainerView.fieldView = primerTextFieldView
        addressLine1FieldContainerView.placeholderText = Strings.CardFormView.AddressLine1.label
        addressLine1FieldContainerView.setup()
        addressLine1FieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return addressLine1FieldContainerView
    }

    static func addressLine1FieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerAddressLine1FieldView {
        let addressLine1FieldView = PrimerAddressLine1FieldView()
        addressLine1FieldView.placeholder = Strings.CardFormView.AddressLine1.placeholder
        addressLine1FieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addressLine1FieldView.textColor = theme.input.text.color
        addressLine1FieldView.delegate = delegate
        return addressLine1FieldView
    }
}

final class PrimerAddressLine2Field: PrimerAddressField {

    static func addressLine2ContainerViewFieldView(_ primerTextFieldView: PrimerTextFieldView) -> PrimerCustomFieldView {
        let addressLine2FieldContainerView = PrimerCustomFieldView()
        addressLine2FieldContainerView.fieldView = primerTextFieldView
        addressLine2FieldContainerView.placeholderText = Strings.CardFormView.AddressLine2.label
        addressLine2FieldContainerView.setup()
        addressLine2FieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return addressLine2FieldContainerView
    }

    static func addressLine2FieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerAddressLine2FieldView {
        let addressLine2FieldView = PrimerAddressLine2FieldView()
        addressLine2FieldView.placeholder = Strings.CardFormView.AddressLine2.placeholder
        addressLine2FieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addressLine2FieldView.textColor = theme.input.text.color
        addressLine2FieldView.delegate = delegate
        return addressLine2FieldView
    }
}
