//
//  CardNumberInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// Helper function to convert SwiftUI Font to UIFont
@available(iOS 15.0, *)
private func convertSwiftUIFontToUIFont(_ font: Font) -> UIFont {
    // Handle iOS 14.0+ specific font cases first
    if #available(iOS 14.0, *) {
        switch font {
        case .title2:
            return UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            return UIFont.preferredFont(forTextStyle: .title3)
        case .caption2:
            return UIFont.preferredFont(forTextStyle: .caption2)
        default:
            break
        }
    }

    // Handle all iOS 13.1+ compatible cases
    switch font {
    case .largeTitle:
        return UIFont.preferredFont(forTextStyle: .largeTitle)
    case .title:
        return UIFont.preferredFont(forTextStyle: .title1)
    case .headline:
        return UIFont.preferredFont(forTextStyle: .headline)
    case .subheadline:
        return UIFont.preferredFont(forTextStyle: .subheadline)
    case .body:
        return UIFont.preferredFont(forTextStyle: .body)
    case .callout:
        return UIFont.preferredFont(forTextStyle: .callout)
    case .footnote:
        return UIFont.preferredFont(forTextStyle: .footnote)
    case .caption:
        return UIFont.preferredFont(forTextStyle: .caption1)
    default:
        return UIFont.systemFont(ofSize: 16, weight: .regular)
    }
}

/// A SwiftUI component for credit card number input with automatic formatting,
/// validation, and card network detection.
@available(iOS 15.0, *)
internal struct CardNumberInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String

    /// Placeholder text for the input field
    let placeholder: String

    /// Callback when the card number changes
    let onCardNumberChange: ((String) -> Void)?

    /// Callback when the card network changes
    let onCardNetworkChange: ((CardNetwork) -> Void)?

    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?

    /// Callback when available networks are detected for co-badged cards
    let onNetworksDetected: (([CardNetwork]) -> Void)?

    /// The currently selected network (takes precedence over auto-detected network)
    let selectedNetwork: CardNetwork?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?

    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The card number entered by the user (without formatting)
    @State private var cardNumber: String = ""

    /// The validation state of the card number
    @State private var isValid: Bool?

    /// The detected card network based on the card number
    @State private var cardNetwork: CardNetwork = .unknown

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Surcharge amount for the detected network
    @State private var surchargeAmount: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Modifier Value Extraction
    // MARK: - Initialization

    /// Creates a new CardNumberInputField with comprehensive customization support
    internal init(
        label: String,
        placeholder: String,
        selectedNetwork: CardNetwork? = nil,
        styling: PrimerFieldStyling? = nil,
        onCardNumberChange: ((String) -> Void)? = nil,
        onCardNetworkChange: ((CardNetwork) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil,
        onNetworksDetected: (([CardNetwork]) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.selectedNetwork = selectedNetwork
        self.styling = styling
        self.onCardNumberChange = onCardNumberChange
        self.onCardNetworkChange = onCardNetworkChange
        self.onValidationChange = onValidationChange
        self.onNetworksDetected = onNetworksDetected
    }

    // MARK: - Computed Properties

    /// The network to display - prioritizes selected network over auto-detected network
    private var displayNetwork: CardNetwork {
        return selectedNetwork ?? cardNetwork
    }

    /// Dynamic border color based on field state
    private var borderColor: Color {
        let color: Color
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            color = styling?.errorBorderColor ?? tokens?.primerColorBorderOutlinedError ?? .red
            logger.debug(message: "🎨 [CardNumber] Border color: ERROR - \(color)")
        } else if isFocused {
            color = styling?.focusedBorderColor ?? tokens?.primerColorBorderOutlinedFocus ?? .blue
            logger.debug(message: "🎨 [CardNumber] Border color: FOCUSED - \(color) (tokens available: \(tokens != nil))")
        } else {
            color = styling?.borderColor ?? tokens?.primerColorBorderOutlinedDefault ?? Color(FigmaDesignConstants.inputFieldBorderColor)
            logger.debug(message: "🎨 [CardNumber] Border color: DEFAULT - \(color)")
        }
        return color
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            // Label with custom styling support
            Text(label)
                .font(styling?.labelFont ?? (tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium)))
                .foregroundColor(styling?.labelColor ?? tokens?.primerColorTextSecondary ?? .secondary)

            // Card input field with integrated network icon
            ZStack {
                // Background and border styling with custom styling support
                RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                    .fill(styling?.backgroundColor ?? tokens?.primerColorBackground ?? .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                            .stroke(borderColor, lineWidth: styling?.borderWidth ?? 1)
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                    )

                // Input field content
                HStack {
                    if let validationService = validationService {
                        CardNumberTextField(
                            cardNumber: $cardNumber,
                            isValid: $isValid,
                            cardNetwork: $cardNetwork,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            styling: styling,
                            validationService: validationService,
                            onCardNumberChange: onCardNumberChange,
                            onCardNetworkChange: { network in
                                onCardNetworkChange?(network)
                                updateSurchargeAmount(for: network)
                            },
                            onValidationChange: onValidationChange,
                            onNetworksDetected: onNetworksDetected
                        )
                        .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, displayNetwork != .unknown ? (tokens?.primerSizeXxlarge ?? 60) : (styling?.padding?.trailing ?? tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: .constant(""))
                            .disabled(true)
                            .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                            .padding(.trailing, styling?.padding?.trailing ?? tokens?.primerSpaceLarge ?? 16)
                            .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
                    }

                    Spacer()
                }

                // Right side overlay (error icon, card network icon, or surcharge)
                HStack {
                    Spacer()

                    if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        // Error icon when validation fails
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: tokens?.primerSizeMedium ?? 20, height: tokens?.primerSizeMedium ?? 20)
                            .foregroundColor(tokens?.primerColorIconNegative ?? Color(red: 1.0, green: 0.45, blue: 0.47))
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    } else if displayNetwork != .unknown {
                        // Card network icon and surcharge when no error
                        VStack(spacing: 2) {
                            // Card network icon
                            if let icon = displayNetwork.icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: tokens?.primerSizeLarge ?? 28, height: tokens?.primerSizeMedium ?? 20)
                            }

                            // Surcharge amount display
                            if let surchargeAmount = surchargeAmount {
                                Text(surchargeAmount)
                                    .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .caption2)
                                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(tokens?.primerColorGray200 ?? Color(.systemGray5))
                                    .cornerRadius(3)
                            }
                        }
                        .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    }
                }
            }
            .frame(height: styling?.fieldHeight ?? FigmaDesignConstants.inputFieldHeight)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .font(tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 11, weight: .regular))
                .foregroundColor(tokens?.primerColorTextNegative ?? .red)
                .padding(.top, tokens?.primerSpaceXsmall ?? 4)
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.2), value: errorMessage != nil)
        }
        .onAppear {
            setupValidationService()
        }
        .onChange(of: isFocused) { focused in
            logger.debug(message: "🎨 [CardNumber] Focus state changed to: \(focused)")
            // Force border color re-evaluation by accessing the computed property
            _ = borderColor
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for CardNumberInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }

    private func updateSurchargeAmount(for network: CardNetwork) {
        // Check if surcharge should be displayed (similar to Drop-in logic)
        guard let surcharge = network.surcharge,
              PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
              let currency = AppState.current.currency else {
            surchargeAmount = nil
            return
        }

        // Format surcharge amount similar to Drop-in implementation
        surchargeAmount = "+ \(surcharge.toCurrencyString(currency: currency))"
    }
}

/// UIViewRepresentable wrapper for card number text field
@available(iOS 15.0, *)
private struct CardNumberTextField: UIViewRepresentable, LogReporter {
    @Binding var cardNumber: String
    @Binding var isValid: Bool?
    @Binding var cardNetwork: CardNetwork
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let onCardNumberChange: ((String) -> Void)?
    let onCardNetworkChange: ((CardNetwork) -> Void)?
    let onValidationChange: ((Bool) -> Void)?
    let onNetworksDetected: (([CardNetwork]) -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.borderStyle = .none
        // Apply custom font or use system default
        if let customFont = styling?.font {
            textField.font = convertSwiftUIFontToUIFont(customFont)
        } else {
            textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

        textField.backgroundColor = .clear

        // Apply custom text color if provided
        if let textColor = styling?.textColor {
            textField.textColor = UIColor(textColor)
        }

        // Apply custom placeholder styling or use defaults
        let placeholderFont: UIFont = {
            if let customFont = styling?.font {
                return convertSwiftUIFontToUIFont(customFont)
            } else if let interFont = UIFont(name: "InterVariable", size: 16) {
                return interFont
            }
            return UIFont.systemFont(ofSize: 16, weight: .regular)
        }()

        let placeholderColor = styling?.placeholderColor != nil ? UIColor(styling!.placeholderColor!) : UIColor.systemGray

        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: placeholderColor,
                .font: placeholderFont
            ]
        )

        // Add a "Done" button to the keyboard using a custom view to avoid UIToolbar constraints
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44))
        accessoryView.backgroundColor = UIColor.systemGray6

        let doneButton = UIButton(type: .system)
        doneButton.setTitle("Done", for: .normal)
        doneButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        doneButton.addTarget(context.coordinator, action: #selector(Coordinator.doneButtonTapped), for: .touchUpInside)

        accessoryView.addSubview(doneButton)
        doneButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            doneButton.trailingAnchor.constraint(equalTo: accessoryView.trailingAnchor, constant: -16),
            doneButton.centerYAnchor.constraint(equalTo: accessoryView.centerYAnchor)
        ])

        textField.inputAccessoryView = accessoryView

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Update text field if needed
        if textField.text != formatCardNumber(cardNumber, for: cardNetwork) {
            textField.text = formatCardNumber(cardNumber, for: cardNetwork)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            cardNumber: $cardNumber,
            cardNetwork: $cardNetwork,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            onCardNumberChange: onCardNumberChange,
            onCardNetworkChange: onCardNetworkChange,
            onValidationChange: onValidationChange,
            onNetworksDetected: onNetworksDetected
        )
    }

    private func formatCardNumber(_ number: String, for network: CardNetwork) -> String {
        let gaps = network.validation?.gaps ?? [4, 8, 12]
        var formatted = ""

        for (index, char) in number.enumerated() {
            formatted.append(char)
            if gaps.contains(index + 1) && index + 1 < number.count {
                formatted.append(" ")
            }
        }

        return formatted
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var cardNumber: String
        @Binding private var cardNetwork: CardNetwork
        @Binding private var isValid: Bool?
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let onCardNumberChange: ((String) -> Void)?
        private let onCardNetworkChange: ((CardNetwork) -> Void)?
        private let onValidationChange: ((Bool) -> Void)?
        private let onNetworksDetected: (([CardNetwork]) -> Void)?

        // Track cursor position for restoration after formatting
        private var savedCursorPosition: Int = 0

        // Timer for debounced network detection
        private var networkDetectionTimer: Timer?

        init(
            validationService: ValidationService,
            cardNumber: Binding<String>,
            cardNetwork: Binding<CardNetwork>,
            isValid: Binding<Bool?>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            onCardNumberChange: ((String) -> Void)?,
            onCardNetworkChange: ((CardNetwork) -> Void)?,
            onValidationChange: ((Bool) -> Void)?,
            onNetworksDetected: (([CardNetwork]) -> Void)?
        ) {
            self.validationService = validationService
            self._cardNumber = cardNumber
            self._cardNetwork = cardNetwork
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.onCardNumberChange = onCardNumberChange
            self.onCardNetworkChange = onCardNetworkChange
            self.onValidationChange = onValidationChange
            self.onNetworksDetected = onNetworksDetected
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.debug(message: "🎨 [CardNumber] Text field began editing - setting isFocused = true")
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.logger.debug(message: "🎨 [CardNumber] Focus state updated on main thread: true")
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            logger.debug(message: "🎨 [CardNumber] Text field ended editing - setting isFocused = false")
            DispatchQueue.main.async {
                self.isFocused = false
                self.logger.debug(message: "🎨 [CardNumber] Focus state updated on main thread: false")
                // Use full validation when field loses focus
                self.validateCardNumberFully(self.cardNumber)
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Save cursor position before making changes
            saveCursorPosition(textField)

            // Get current text without formatting
            let currentText = cardNumber

            // Determine if this is a deletion operation
            let isDeletion = string.isEmpty

            var newCardNumber: String

            if isDeletion {
                // Handle deletion operation
                if range.length > 0 {
                    // Convert formatted range to unformatted range for selection deletion
                    let unformattedRange = getUnformattedRange(
                        formattedRange: range,
                        formattedText: textField.text ?? "",
                        unformattedText: currentText
                    )
                    newCardNumber = handleDeletion(currentText: currentText, unformattedRange: unformattedRange)
                } else if range.location > 0 {
                    // Simple backspace - remove the character before the cursor in unformatted text
                    // Count numeric characters up to cursor position
                    var unformattedPos = 0
                    for i in 0..<range.location where i < (textField.text?.count ?? 0) {
                        let textString = textField.text!
                        let charIndex = textString.index(textString.startIndex, offsetBy: i)
                        if textString[charIndex].isNumber {
                            unformattedPos += 1
                        }
                    }

                    if unformattedPos > 0 && unformattedPos <= currentText.count {
                        let index = currentText.index(currentText.startIndex, offsetBy: unformattedPos - 1)
                        newCardNumber = currentText.removing(at: index)
                    } else {
                        newCardNumber = currentText
                    }
                } else {
                    newCardNumber = currentText
                }
            } else {
                // Handle addition operation for typing or pasting
                // Only allow numeric characters
                let filteredText = string.filter { $0.isNumber }
                if filteredText.isEmpty {
                    return false
                }

                // Count numeric characters up to cursor position to get insertion point
                var unformattedPos = 0
                for i in 0..<range.location where i < (textField.text?.count ?? 0) {
                    let textString = textField.text!
                    let charIndex = textString.index(textString.startIndex, offsetBy: i)
                    if textString[charIndex].isNumber {
                        unformattedPos += 1
                    }
                }

                // Insert at the correct position in unformatted text
                if unformattedPos <= currentText.count {
                    let index = currentText.index(currentText.startIndex, offsetBy: unformattedPos)
                    newCardNumber = currentText.inserting(contentsOf: filteredText, at: index)
                } else {
                    newCardNumber = currentText + filteredText
                }
            }

            // Limit to 19 digits
            if newCardNumber.count > 19 {
                newCardNumber = String(newCardNumber.prefix(19))
            }

            // Update the card number
            cardNumber = newCardNumber

            // Update card network
            let newNetwork = CardNetwork(cardNumber: newCardNumber)
            if newNetwork != cardNetwork {
                cardNetwork = newNetwork
                onCardNetworkChange?(newNetwork)
            }

            // Update formatted text and restore cursor position
            let formattedText = formatCardNumber(newCardNumber, for: cardNetwork)
            textField.text = formattedText

            // Calculate and restore appropriate cursor position
            restoreCursorPosition(textField: textField,
                                  formattedText: formattedText,
                                  originalCursorPos: savedCursorPosition,
                                  isDeletion: isDeletion,
                                  insertedLength: isDeletion ? 0 : string.count)

            // Notify changes
            onCardNumberChange?(newCardNumber)

            // Trigger network detection for co-badged cards (minimum 6 digits for BIN detection)
            if newCardNumber.count >= 6 {
                debouncedNetworkDetection(newCardNumber)
            }

            // Validate if we have enough digits (use debounced validation during typing)
            if newCardNumber.count >= 13 {
                debouncedValidation(newCardNumber)
            } else if newCardNumber.isEmpty {
                // Clear validation state when empty
                isValid = nil
                errorMessage = nil
                onValidationChange?(false)
            }

            return false
        }

        // MARK: - Helper Methods

        private func saveCursorPosition(_ textField: UITextField) {
            if let selectedRange = textField.selectedTextRange {
                savedCursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
            }
        }

        private func restoreCursorPosition(textField: UITextField, formattedText: String, originalCursorPos: Int, isDeletion: Bool, insertedLength: Int) {
            var newCursorPosition: Int

            if isDeletion {
                // For deletion, try to maintain cursor at deletion point
                newCursorPosition = min(originalCursorPos, formattedText.count)
            } else {
                // For insertion, move cursor after inserted content
                newCursorPosition = min(originalCursorPos + insertedLength, formattedText.count)

                // Account for formatting spaces that might have been added
                if originalCursorPos < formattedText.count {
                    // Count how many spaces were added up to cursor position
                    let spacesAdded = formattedText.prefix(newCursorPosition).filter { $0 == " " }.count
                    newCursorPosition = min(originalCursorPos + insertedLength + spacesAdded, formattedText.count)
                }
            }

            // Set cursor position asynchronously to avoid conflicts
            DispatchQueue.main.async {
                if let newPosition = textField.position(from: textField.beginningOfDocument, offset: newCursorPosition) {
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            }
        }

        // Convert a range in formatted text to a range in unformatted text
        private func getUnformattedRange(formattedRange: NSRange, formattedText: String, unformattedText: String) -> NSRange {
            // Count how many non-digit characters are before the selection range
            var digitCount = 0

            for (index, char) in formattedText.enumerated() {
                if index >= formattedRange.location {
                    break
                }

                if char.isNumber {
                    digitCount += 1
                }
            }

            // Adjust the location based on position in unformatted text
            let unformattedLocation = digitCount

            // For length, we need to account for potential spaces in the selection
            var unformattedLength = 0
            if formattedRange.length > 0 {
                let rangeEnd = min(formattedRange.location + formattedRange.length, formattedText.count)

                // Count digits in the selection
                for index in formattedRange.location..<rangeEnd where index < formattedText.count {
                    let charIndex = formattedText.index(formattedText.startIndex, offsetBy: index)
                    if formattedText[charIndex].isNumber {
                        unformattedLength += 1
                    }
                }
            }

            return NSRange(location: unformattedLocation, length: unformattedLength)
        }

        private func handleDeletion(currentText: String, unformattedRange: NSRange) -> String {
            // If deleting a range of characters
            if unformattedRange.length > 0 {
                if unformattedRange.location >= currentText.count {
                    return currentText
                }

                let startIndex = currentText.index(currentText.startIndex, offsetBy: unformattedRange.location)
                let endIndex = currentText.index(startIndex, offsetBy: min(unformattedRange.length, currentText.count - unformattedRange.location))
                return currentText.replacingCharacters(in: startIndex..<endIndex, with: "")
            }

            // If backspace at the end of the text
            if unformattedRange.location >= currentText.count && currentText.count > 0 {
                return String(currentText.dropLast())
            }

            // If backspace in the middle of the text
            if unformattedRange.location > 0 && unformattedRange.location <= currentText.count {
                let index = currentText.index(currentText.startIndex, offsetBy: unformattedRange.location - 1)
                return currentText.removing(at: index)
            }

            return currentText
        }

        private func formatCardNumber(_ number: String, for network: CardNetwork) -> String {
            let gaps = network.validation?.gaps ?? [4, 8, 12]
            var formatted = ""

            for (index, char) in number.enumerated() {
                formatted.append(char)
                if gaps.contains(index + 1) && index + 1 < number.count {
                    formatted.append(" ")
                }
            }

            return formatted
        }

        // Timer for debounced validation
        private var validationTimer: Timer?

        private func debouncedValidation(_ number: String) {
            // Cancel any existing validation timer
            validationTimer?.invalidate()

            // Schedule validation after a longer delay to reduce flickering during typing
            validationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.validateCardNumberWhileTyping(number)
            }
        }

        private func debouncedNetworkDetection(_ number: String) {
            // Cancel any existing network detection timer
            networkDetectionTimer?.invalidate()

            // Schedule network detection after a short delay to avoid excessive API calls
            networkDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.detectNetworksForCardNumber(number)
            }
        }

        private func detectNetworksForCardNumber(_ cardNumber: String) {
            logger.debug(message: "🌐 [CardNumber] Detecting networks for: ***\(String(cardNumber.suffix(4)))")

            // This would be connected to HeadlessRepository in the scope
            // For now, we'll trigger the callback to let the parent handle it
            onNetworksDetected?([])
        }

        // Validation while typing - minimal error display to prevent flickering
        private func validateCardNumberWhileTyping(_ number: String) {
            logger.debug(message: "🔍 [CardNumber] Validating while typing: '\(number)' (length: \(number.count))")

            // For short numbers, don't show errors - user is still typing
            if number.count < 13 {
                logger.debug(message: "🔍 [CardNumber] Too short for validation, maintaining neutral state")
                isValid = nil
                errorMessage = nil
                onValidationChange?(false)
                return
            }

            let network = CardNetwork(cardNumber: number)
            logger.debug(message: "🔍 [CardNumber] Detected network: \(network.displayName)")

            // For known networks, only validate if we have a complete length
            if network != .unknown, let validation = network.validation, validation.lengths.contains(number.count) {
                logger.debug(message: "🔍 [CardNumber] Running validation for complete known network card (expected lengths: \(validation.lengths))")
                let validationResult = validationService.validateCardNumber(number)
                logger.debug(message: "🔍 [CardNumber] Validation result: valid=\(validationResult.isValid), error='\(validationResult.errorMessage ?? "none")'")

                // Only show positive validation during typing, defer errors to focus loss
                if validationResult.isValid {
                    isValid = true
                    errorMessage = nil
                    onValidationChange?(true)
                } else {
                    // Don't show error during typing - defer to focus loss
                    isValid = nil
                    errorMessage = nil
                    onValidationChange?(false)
                }
            } else if number.count >= 16 {
                // For unknown networks, only validate longer numbers and be optimistic
                logger.debug(message: "🔍 [CardNumber] Running validation for unknown network with sufficient length (length: \(number.count))")
                let validationResult = validationService.validateCardNumber(number)
                logger.debug(message: "🔍 [CardNumber] Validation result: valid=\(validationResult.isValid), error='\(validationResult.errorMessage ?? "none")'")

                // Only show positive validation during typing, defer errors to focus loss
                if validationResult.isValid {
                    isValid = true
                    errorMessage = nil
                    onValidationChange?(true)
                } else {
                    // Don't show error during typing - defer to focus loss
                    isValid = nil
                    errorMessage = nil
                    onValidationChange?(false)
                }
            } else {
                logger.debug(message: "🔍 [CardNumber] Number not ready for validation yet (length: \(number.count))")
                // Not ready for validation yet - maintain neutral state
                isValid = nil
                errorMessage = nil
                onValidationChange?(false)
            }
        }

        // Full validation when field loses focus - shows all errors
        private func validateCardNumberFully(_ number: String) {
            logger.debug(message: "🔍 [CardNumber] Full validation for: '\(number)' (length: \(number.count))")

            // Clear any pending validation timer to avoid conflicts
            validationTimer?.invalidate()

            // Empty field handling - don't show errors for empty fields
            let trimmedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedNumber.isEmpty {
                isValid = false // Card number is required
                errorMessage = nil // Never show error message for empty fields
                onValidationChange?(false)
                return
            }

            // Always run full validation on focus loss for non-empty fields
            let validationResult = validationService.validateCardNumber(number)
            logger.debug(message: "🔍 [CardNumber] Full validation result: valid=\(validationResult.isValid), error='\(validationResult.errorMessage ?? "none")'")

            // Show validation result including errors on focus loss
            isValid = validationResult.isValid
            errorMessage = validationResult.isValid ? nil : validationResult.errorMessage
            onValidationChange?(validationResult.isValid)
        }

        deinit {
            validationTimer?.invalidate()
            networkDetectionTimer?.invalidate()
        }
    }
}

// String extensions
private extension String {
    func removing(at index: Index) -> String {
        var result = self
        result.remove(at: index)
        return result
    }

    func inserting(contentsOf newElements: String, at index: Index) -> String {
        var result = self
        result.insert(contentsOf: newElements, at: index)
        return result
    }
}
