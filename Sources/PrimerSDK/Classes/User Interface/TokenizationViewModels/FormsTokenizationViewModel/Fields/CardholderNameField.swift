//
//  CardholderNameField.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 08/06/22.
//

#if canImport(UIKit)

import UIKit

class PrimerCardholderNameField: PrimerCardFormFieldProtocol {
    
    private static let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    static func cardholderNameContainerViewFieldView(_ view: PrimerTextFieldView?) -> PrimerCustomFieldView? {
        guard let view = view else {
            return nil
        }
        let cardholderNameContainerView = PrimerCustomFieldView()
        cardholderNameContainerView.fieldView = view
        cardholderNameContainerView.placeholderText = NSLocalizedString("primer-card-form-name",
                                                                        tableName: nil,
                                                                        bundle: Bundle.primerResources,
                                                                        value: "Name",
                                                                        comment: "Cardholder name")
        cardholderNameContainerView.setup()
        cardholderNameContainerView.tintColor = theme.input.border.color(for: .selected)
        return cardholderNameContainerView
    }
    
    static func cardholderNameFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCardholderNameFieldView {
        let cardholderNameField = PrimerCardholderNameFieldView()
        cardholderNameField.placeholder = NSLocalizedString("primer-form-text-field-placeholder-cardholder",
                                                            tableName: nil,
                                                            bundle: Bundle.primerResources,
                                                            value: "e.g. John Doe",
                                                            comment: "e.g. John Doe - Form Text Field Placeholder (Cardholder name)")
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.textColor = theme.input.text.color
        cardholderNameField.delegate = delegate
        return cardholderNameField
    }
}

extension PrimerCardholderNameField {
    
    internal static var isCardholderNameFieldEnabled: Bool {
        let cardInfoOptions = AppState.current.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions
        return cardInfoOptions?.cardHolderName == true
    }
}

#endif
