//
//  ExpiryDateInputField.swift
//  
//
//  Created by Boris on 29. 4. 2025..
//


import SwiftUI
import UIKit

@available(iOS 15.0, *)
public struct ExpiryDateInputField: UIViewRepresentable {
    public var placeholder: String
    private let coordinator: ExpiryDateCoordinator
    public init(
        placeholder: String = "MM/YY",
        validatorService: ValidationService = DefaultValidationService(),
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorChange: ((String?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.coordinator = ExpiryDateCoordinator(
            formatter: ExpiryDateFormatter(),
            cursorManager: ExpiryDateCursorManager(),
            validator: ExpiryDateFieldValidator(validationService: validatorService),
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
    public func makeCoordinator() -> ExpiryDateCoordinator { coordinator }
}
