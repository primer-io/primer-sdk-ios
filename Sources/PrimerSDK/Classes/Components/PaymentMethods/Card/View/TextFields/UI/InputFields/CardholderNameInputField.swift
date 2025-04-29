//
//  CardholderNameInputField.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import SwiftUI
import UIKit

@available(iOS 15.0, *)
public struct CardholderNameInputField: UIViewRepresentable {
    public var placeholder: String
    private let coordinator: CardholderNameCoordinator
    public init(
        placeholder: String = "John Doe",
        validatorService: ValidationService = DefaultValidationService(),
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorChange: ((String?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.coordinator = CardholderNameCoordinator(
            formatter: CardholderNameFormatter(),
            cursorManager: DefaultCursorManager(),
            validator: CardholderNameFieldValidator(validationService: validatorService),
            onValidationChange: { isValid in onValidationChange?(isValid) },
            onErrorMessageChange: { msg in onErrorChange?(msg) }
        )
    }
    public func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.delegate = coordinator
        tf.keyboardType = .default
        tf.placeholder = placeholder
        return tf
    }
    public func updateUIView(_ uiView: UITextField, context: Context) {}
    public func makeCoordinator() -> CardholderNameCoordinator { coordinator }
}
