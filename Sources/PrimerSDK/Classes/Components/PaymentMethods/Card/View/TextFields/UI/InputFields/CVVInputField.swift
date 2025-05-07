//
//  CVVInputField.swift
//
//
//  Created by Boris on 29. 4. 2025..
//

import SwiftUI
import UIKit

@available(iOS 15.0, *)
public struct CVVInputField: UIViewRepresentable {
    public var placeholder: String
    private let cardNetwork: CardNetwork
    private let coordinator: BaseTextFieldCoordinator

    public init(
        placeholder: String = "123",
        cardNetwork: CardNetwork = .unknown,
        validatorService: ValidationService = DefaultValidationService(),
        onFormattedChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorChange: ((String?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.cardNetwork = cardNetwork
        self.coordinator = BaseTextFieldCoordinator(
            formatter: CVVFormatter(cardNetwork: cardNetwork),
            cursorManager: DefaultCursorManager(),
            validator: CVVFieldValidator(validationService: validatorService, cardNetwork: cardNetwork),
            onValidationChange: { isValid in onValidationChange?(isValid) },
            onErrorMessageChange: { msg in onErrorChange?(msg) },
            onTextChange: { formattedText in onFormattedChange?(formattedText) }
        )
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        // When the external `cardNetwork` state changes:
        coordinator.update(cardNetwork: cardNetwork)
    }

    public func makeCoordinator() -> BaseTextFieldCoordinator { coordinator }
}
