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
        cardholderNameContainerView.placeholderText = Strings.CardFormView.Cardholder.label
        cardholderNameContainerView.setup()
        cardholderNameContainerView.tintColor = theme.input.border.color(for: .selected)
        return cardholderNameContainerView
    }
    
    static func cardholderNameFieldViewWithDelegate(_ delegate: PrimerTextFieldViewDelegate?) -> PrimerCardholderNameFieldView {
        let cardholderNameField = PrimerCardholderNameFieldView()
        cardholderNameField.placeholder = Strings.CardFormView.Cardholder.placeholder
        cardholderNameField.heightAnchor.constraint(equalToConstant: 36).isActive = true
        cardholderNameField.textColor = theme.input.text.color
        cardholderNameField.delegate = delegate
        return cardholderNameField
    }
}

extension PrimerCardholderNameField {
    
    internal static var isCardholderNameFieldEnabled: Bool {
        let cardInfoOptions = PrimerAPIConfigurationModule.apiConfiguration?.checkoutModules?.filter({ $0.type == "CARD_INFORMATION" }).first?.options as? PrimerAPIConfiguration.CheckoutModule.CardInformationOptions
        if let isCardHolderNameCheckoutModuleOptionEnabled = cardInfoOptions?.cardHolderName {
            return isCardHolderNameCheckoutModuleOptionEnabled
        }
        return true
    }
}

#endif
