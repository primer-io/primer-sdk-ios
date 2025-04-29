//
//  CardNumberInputField.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import SwiftUI
import UIKit

@available(iOS 15.0, *)
public struct CardNumberInputField: UIViewRepresentable {
    public var placeholder: String
    public var onFormattedChange: ((String) -> Void)?
    public var onValidationChange: ((Bool) -> Void)?
    public var onErrorChange: ((String?) -> Void)?

    private let coordinator: CardNumberCoordinator

    public init(
        placeholder: String = "1234 5678 9012 3456",
        validatorService: ValidationService = DefaultValidationService(),
        onFormattedChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorChange: ((String?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.onFormattedChange = onFormattedChange
        self.onValidationChange = onValidationChange
        self.onErrorChange = onErrorChange
        self.coordinator = CardNumberCoordinator(
            formatter: CardNumberFormatter(),
            cursorManager: CardNumberCursorManager(),
            validator: CardNumberFieldValidator(validationService: validatorService),
            onValidationChange: { isValid in onValidationChange?(isValid) },
            onErrorMessageChange: { msg in onErrorChange?(msg) }
        )
    }

    public func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = coordinator
        tf.keyboardType = .numberPad
        tf.placeholder = placeholder
        return tf
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {}

    public func makeCoordinator() -> CardNumberCoordinator { coordinator }
}
