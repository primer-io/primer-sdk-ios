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
    private let coordinator: CVVCoordinator
    public init(
        placeholder: String = "123",
        cardNetwork: CardNetwork = .unknown,
        validatorService: ValidationService = DefaultValidationService(),
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorChange: ((String?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.coordinator = CVVCoordinator(
            formatter: CVVFormatter(),
            cursorManager: DefaultCursorManager(),
            validator: CVVFieldValidator(validationService: validatorService, cardNetwork: cardNetwork),
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
    public func makeCoordinator() -> CVVCoordinator { coordinator }
}
