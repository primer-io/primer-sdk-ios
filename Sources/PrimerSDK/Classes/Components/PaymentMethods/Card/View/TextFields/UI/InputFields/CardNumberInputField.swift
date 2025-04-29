import SwiftUI
import UIKit

@available(iOS 15.0, *)
public struct CardNumberInputField: UIViewRepresentable {
    public var placeholder: String
    private let validationService: ValidationService
    private let coordinator: CardNumberCoordinator

    public init(
        label: String? = nil,
        placeholder: String = "1234 5678 9012 3456",
        validationService: ValidationService = DefaultValidationService(),
        onCardNetworkChange: ((CardNetwork) -> Void)? = nil,
        onFormattedChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorChange: ((String?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.validationService = validationService

        let formatter = CardNumberFormatter()

        self.coordinator = CardNumberCoordinator(
            formatter: formatter,
            cursorManager: CardNumberCursorManager(),
            validator: CardNumberFieldValidator(validationService: validationService),
            onValidationChange: { isValid in onValidationChange?(isValid) },
            onErrorMessageChange: { msg in onErrorChange?(msg) },
            onTextChange: { formattedText in
                onFormattedChange?(formattedText)

                // Detect card network from number
                let digitsOnly = formattedText.filter { $0.isNumber }
                let network = CardNetwork(cardNumber: digitsOnly)
                onCardNetworkChange?(network)
            }
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
