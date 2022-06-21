//
//  LastNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerAddressField: PrimerCardFormFieldProtocol {
    
    internal static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
}

class PrimerAddressLine1Field: PrimerAddressField {
        
    static func addressLine1ContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let addressLine1FieldContainerView = PrimerCustomFieldView()
        addressLine1FieldContainerView.fieldView = view
        addressLine1FieldContainerView.placeholderText = NSLocalizedString("primer-card-form-address-line-1",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "Address line 1",
                                                                        comment: "The billing address line 1")
        addressLine1FieldContainerView.setup()
        addressLine1FieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return addressLine1FieldContainerView
    }
    
    static func addressLine1FieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerAddressLine1FieldView {
        let addressLine1FieldView = PrimerAddressLine1FieldView()
        addressLine1FieldView.placeholder = NSLocalizedString("primer-form-text-field-placeholder-address-line-1",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "Address line 1",
                                                            comment: "e.g. Address line 1 - Form Text Field Placeholder (Address line 1)")
        addressLine1FieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addressLine1FieldView.textColor = theme.input.text.color
        addressLine1FieldView.delegate = delegate
        return addressLine1FieldView
    }
}

class PrimerAddressLine2Field: PrimerAddressField {
        
    static func addressLine2ContainerViewFieldView(_ view: PrimerTextFieldView) -> PrimerCustomFieldView {
        let addressLine2FieldContainerView = PrimerCustomFieldView()
        addressLine2FieldContainerView.fieldView = view
        addressLine2FieldContainerView.placeholderText = NSLocalizedString("primer-card-form-address-line-2",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "Address line 2",
                                                                        comment: "The billing address line 2")
        addressLine2FieldContainerView.setup()
        addressLine2FieldContainerView.tintColor = theme.input.border.color(for: .selected)
        return addressLine2FieldContainerView
    }
    
    static func addressLine2FieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerAddressLine2FieldView {
        let addressLine2FieldView = PrimerAddressLine2FieldView()
        addressLine2FieldView.placeholder = NSLocalizedString("primer-form-text-field-placeholder-address-line-2",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "Address line 2 (optional)",
                                                            comment: "e.g. Address line 2 - Form Text Field Placeholder (Address line 2)")
        addressLine2FieldView.heightAnchor.constraint(equalToConstant: 36).isActive = true
        addressLine2FieldView.textColor = theme.input.text.color
        addressLine2FieldView.delegate = delegate
        return addressLine2FieldView
    }
}


#endif
