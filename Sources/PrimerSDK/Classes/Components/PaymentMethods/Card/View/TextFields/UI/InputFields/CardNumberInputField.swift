import SwiftUI
import UIKit

@available(iOS 15.0, *)
public struct CardNumberInputField: UIViewRepresentable {
    public var placeholder: String
    public var cardNetwork: CardNetwork
    private let validationService: ValidationService

    private let onCardNetworkChange: ((CardNetwork) -> Void)?
    private let onFormattedChange: ((String) -> Void)?
    private let onValidationChange: ((Bool) -> Void)?
    private let onErrorChange: ((String?) -> Void)?

    private let coordinator: CardNumberCoordinator

    public init(
        placeholder: String = "1234 5678 9012 3456",
        cardNetwork: CardNetwork = .unknown,
        validationService: ValidationService = DefaultValidationService(),
        onCardNetworkChange: ((CardNetwork) -> Void)? = nil,
        onFormattedChange: ((String) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil,
        onErrorChange: ((String?) -> Void)? = nil
    ) {
        self.placeholder = placeholder
        self.cardNetwork = cardNetwork
        self.validationService = validationService
        self.onCardNetworkChange = onCardNetworkChange
        self.onFormattedChange = onFormattedChange
        self.onValidationChange = onValidationChange
        self.onErrorChange = onErrorChange

        // Build all dependencies first
        let initialFormatter = CardNumberFormatter(cardNetwork: cardNetwork)
        let cursorMgr = CardNumberCursorManager()
        let validator = CardNumberFieldValidator(validationService: validationService)

        // Wrap your callbacks so they don’t capture `self`
        let liveValidation: (Bool) -> Void = { valid in
            onValidationChange?(valid)
        }
        let liveError: (String?) -> Void = { msg in
            onErrorChange?(msg)
        }

        // Build your coordinator—capture it in a local var so closures can refer to it
        var coord: CardNumberCoordinator! = nil
        let liveText: (String) -> Void = { formattedText in
            onFormattedChange?(formattedText)
            let raw = formattedText.filter { $0.isNumber }
            let network = CardNetwork(cardNumber: raw)
            coord.update(cardNetwork: network)
            onCardNetworkChange?(network)
        }

        coord = CardNumberCoordinator(
            formatter: initialFormatter,
            cursorManager: cursorMgr,
            validator: validator,
            onValidationChange: liveValidation,
            onErrorMessageChange: liveError,
            onTextChange: liveText
        )

        self.coordinator = coord
    }

    public func makeCoordinator() -> CardNumberCoordinator {
        coordinator
    }

    public func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.text = coordinator.formatter.format("")
        return textField
    }

    public func updateUIView(_ uiView: UITextField, context: Context) {
        // When your external `cardNetwork` state changes:
        coordinator.update(cardNetwork: cardNetwork)

        // Re-format whatever is currently in the field
        let raw = uiView.text?.filter { $0.isNumber } ?? ""
        uiView.text = coordinator.formatter.format(raw)
    }
}
