//
//  CardNumberTextField.swift
//
//  Created by Boris on 12.3.25..
//

import SwiftUI
import UIKit

/// A SwiftUI component for credit card number input with automatic formatting,
/// validation, and card network detection.
@available(iOS 15.0, *)
struct CardNumberInputField: View {
    // MARK: - Public Properties

    /// The label text shown above the field
    var label: String

    /// Placeholder text for the input field
    var placeholder: String

    /// Callback when the card network changes
    var onCardNetworkChange: ((CardNetwork) -> Void)?

    /// Callback when the validation state changes
    var onValidationChange: ((Bool) -> Void)?

    // MARK: - Private Properties

    /// The validation service used to validate the card number
    private let validationService: ValidationService

    /// The card number entered by the user (without formatting)
    @State private var cardNumber: String = ""

    /// The validation state of the card number
    @State private var isValid: Bool?

    /// The detected card network based on the card number
    @State private var cardNetwork: CardNetwork = .unknown

    /// Error message if validation fails
    @State private var errorMessage: String?

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(
        label: String,
        placeholder: String,
        validationService: ValidationService = DefaultValidationService(),
        onCardNetworkChange: ((CardNetwork) -> Void)? = nil,
        onValidationChange: ((Bool) -> Void)? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.validationService = validationService
        self.onCardNetworkChange = onCardNetworkChange
        self.onValidationChange = onValidationChange
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // Card input field with network icon
            HStack(spacing: 8) {
                CardNumberTextField(
                    cardNumber: $cardNumber,
                    isValid: $isValid,
                    cardNetwork: $cardNetwork,
                    errorMessage: $errorMessage,
                    placeholder: placeholder,
                    validationService: validationService
                )
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)

                // Card network icon if detected
                if cardNetwork != .unknown {
                    if let icon = cardNetwork.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 24)
                    }
                }
            }

            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 2)
            }
        }
        .onChange(of: cardNetwork) { newValue in
            // Use DispatchQueue to avoid state updates during view update
            DispatchQueue.main.async {
                onCardNetworkChange?(newValue)
            }
        }
        .onChange(of: isValid) { newValue in
            if let isValid = newValue {
                // Use DispatchQueue to avoid state updates during view update
                DispatchQueue.main.async {
                    onValidationChange?(isValid)
                }
            }
        }
    }

    /// Retrieves the sanitized card number
    /// - Returns: Current card number without formatting
    func getCardNumber() -> String {
        return cardNumber
    }
}

/// An improved UIViewRepresentable wrapper that avoids state cycles
@available(iOS 15.0, *)
struct CardNumberTextField: UIViewRepresentable, LogReporter {
    @Binding var cardNumber: String
    @Binding var isValid: Bool?
    @Binding var cardNetwork: CardNetwork
    @Binding var errorMessage: String?
    var placeholder: String
    let validationService: ValidationService

    func makeUIView(context: Context) -> UITextField {
        let textField = PrimerCardNumberTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)

        logger.debug(message: "🔤 Creating new card number text field")

        // Add a "Done" button to the keyboard
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: context.coordinator, action: #selector(Coordinator.doneButtonTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar

        // Add observers for cursor position changes
        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.textDidChangeNotification(_:)),
            name: UITextField.textDidChangeNotification,
            object: textField
        )

        // Important: Set initial value
        textField.internalText = cardNumber

        logger.debug(message: "🔤 Initial card number text field setup complete")

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Minimal updates to avoid cycles
        guard let primerTextField = textField as? PrimerCardNumberTextField else { return }

        // Only update if needed
        if primerTextField.internalText != cardNumber {
            logger.debug(message: "🔄 Updating text field: internalText='\(primerTextField.internalText ?? "")' → cardNumber='\(cardNumber)'")

            primerTextField.internalText = cardNumber

            // Format the displayed text without triggering validation
            if !cardNumber.isEmpty {
                let formattedText = formatCardNumber(cardNumber, for: cardNetwork)
                if primerTextField.text != formattedText {
                    logger.debug(message: "🔄 Formatted text update: '\(primerTextField.text ?? "")' → '\(formattedText)'")
                    primerTextField.text = formattedText
                }
            }

            // Log the current cursor position after update
            if let selectedRange = primerTextField.selectedTextRange {
                let cursorPosition = primerTextField.offset(from: primerTextField.beginningOfDocument, to: selectedRange.start)
                logger.debug(message: "🔄 Cursor position after update: \(cursorPosition)")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            updateCardNumber: { newNumber in
                self.cardNumber = newNumber
            },
            updateCardNetwork: { newNetwork in
                self.cardNetwork = newNetwork
            },
            updateValidationState: { isValid, errorMessage in
                self.isValid = isValid
                self.errorMessage = errorMessage
            },
            formatCardNumber: { number, network in
                self.formatCardNumber(number, for: network)
            }
        )
    }

    /// Formats a card number string with spaces according to the card network type
    func formatCardNumber(_ number: String, for network: CardNetwork) -> String {
        // Get gaps based on card network
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
        // MARK: - Properties

        private let validationService: ValidationService
        private let updateCardNumber: (String) -> Void
        private let updateCardNetwork: (CardNetwork) -> Void
        private let updateValidationState: (Bool?, String?) -> Void
        private let formatCardNumber: (String, CardNetwork) -> String

        // Add a flag to prevent update cycles
        private var isUpdating = false

        // Track cursor position to restore it after text formatting
        private var selectedRange: UITextRange?
        private var cursorPosition: Int = 0

        // For tracking changes in cursor position
        private var lastCursorPosition: Int = 0

        // Local state for accessing current card network
        private var currentCardNetwork: CardNetwork = .unknown

        // Timer for debounced validation
        private var validationTimer: Timer?

        // MARK: - Initialization

        init(
            validationService: ValidationService,
            updateCardNumber: @escaping (String) -> Void,
            updateCardNetwork: @escaping (CardNetwork) -> Void,
            updateValidationState: @escaping (Bool?, String?) -> Void,
            formatCardNumber: @escaping (String, CardNetwork) -> String
        ) {
            self.validationService = validationService
            self.updateCardNumber = updateCardNumber
            self.updateCardNetwork = updateCardNetwork
            self.updateValidationState = updateValidationState
            self.formatCardNumber = formatCardNumber
            super.init()
            logger.debug(message: "📝 Card number field coordinator initialized")
        }

        // MARK: - Notification Handlers

        @objc func textDidChangeNotification(_ notification: Notification) {
            guard let textField = notification.object as? UITextField,
                  let selectedRange = textField.selectedTextRange else {
                return
            }

            let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)

            if cursorPosition != lastCursorPosition {
                logger.debug(message: "📍 Cursor position changed: \(lastCursorPosition) → \(cursorPosition)")
                lastCursorPosition = cursorPosition
            }
        }

        @objc func doneButtonTapped() {
            logger.debug(message: "⌨️ Done button tapped")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        // MARK: - UITextFieldDelegate

        func textFieldDidBeginEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Text field began editing")
            // Clear error message when user starts editing
            updateValidationState(nil, nil)

            // Log initial cursor position
            if let selectedRange = textField.selectedTextRange {
                let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
                logger.debug(message: "📍 Initial cursor position: \(cursorPosition)")
                lastCursorPosition = cursorPosition
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            logger.debug(message: "⌨️ Text field ended editing")
            // Validate the card number when the field loses focus
            if let primerTextField = textField as? PrimerCardNumberTextField,
               let cardNumber = primerTextField.internalText {
                validateCardNumberFully(cardNumber)
            }
        }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            if let selectedRange = textField.selectedTextRange {
                let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)

                if cursorPosition != lastCursorPosition {
                    logger.debug(message: "📍 Selection changed: \(lastCursorPosition) → \(cursorPosition)")
                    lastCursorPosition = cursorPosition
                }
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Avoid reentrance
            if isUpdating {
                logger.debug(message: "🔄 Avoiding reentrance in shouldChangeCharactersIn")
                return false
            }

            guard let primerTextField = textField as? PrimerCardNumberTextField else {
                return true
            }

            logger.debug(message: "⌨️ shouldChangeCharactersIn - range: \(range.location),\(range.length), replacement: '\(string)'")

            // Save current cursor position before making changes
            saveCursorPosition(textField)

            // Get the current internal text (unformatted)
            let currentText = primerTextField.internalText ?? ""

            // Determine if this is a deletion operation (backspace)
            let isDeletion = string.isEmpty

            // IMPROVEMENT: Handle paste operation more robustly
            // Check if this is a paste operation by checking string length
            let isPasteOperation = !isDeletion && string.count > 1
            if isPasteOperation {
                logger.debug(message: "📋 Paste operation detected with \(string.count) characters")
            }

            var newCardNumber: String

            if isDeletion {
                // Handle deletion operation
                if range.length > 0 {
                    // Convert formatted range to unformatted range for selection deletion
                    let unformattedRange = getUnformattedRange(formattedRange: range, formattedText: textField.text ?? "", unformattedText: currentText)
                    logger.debug(message: "🗑️ Deletion - formatted range \(range.location),\(range.length) → unformatted range \(unformattedRange.location),\(unformattedRange.length)")
                    newCardNumber = handleDeletion(currentText: currentText, unformattedRange: unformattedRange)
                } else if range.location > 0 {
                    // Simple backspace - remove the character before the cursor in unformatted text
                    // Count numeric characters up to cursor position
                    var unformattedPos = 0
                    for i in 0..<range.location {
                        if i < (textField.text?.count ?? 0) &&
                            (textField.text?[textField.text!.index(textField.text!.startIndex, offsetBy: i)].isNumber ?? false) {
                            unformattedPos += 1
                        }
                    }

                    logger.debug(message: "🗑️ Backspace at position \(range.location) maps to unformatted position \(unformattedPos)")

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
                    logger.debug(message: "⌨️ Ignoring non-numeric input: '\(string)'")
                    return false
                }

                // For paste operations, log the filtered content
                if isPasteOperation && filteredText.count != string.count {
                    logger.debug(message: "📋 Filtered paste content from \(string.count) to \(filteredText.count) digits")
                }

                // Count numeric characters up to cursor position to get insertion point
                var unformattedPos = 0
                for i in 0..<range.location {
                    if i < (textField.text?.count ?? 0) &&
                        (textField.text?[textField.text!.index(textField.text!.startIndex, offsetBy: i)].isNumber ?? false) {
                        unformattedPos += 1
                    }
                }

                if isPasteOperation {
                    logger.debug(message: "📋 Pasting at position \(range.location) maps to unformatted position \(unformattedPos)")
                } else {
                    logger.debug(message: "⌨️ Typing at position \(range.location) maps to unformatted position \(unformattedPos)")
                }

                // Insert at the correct position in unformatted text
                if unformattedPos <= currentText.count {
                    let index = currentText.index(currentText.startIndex, offsetBy: unformattedPos)
                    newCardNumber = currentText.inserting(contentsOf: filteredText, at: index)
                } else {
                    newCardNumber = currentText + filteredText
                }
            }

            // If text is invalid or too long, reject the change
            if newCardNumber.count > 19 {
                logger.debug(message: "⌨️ Rejecting input - would exceed max length (19)")
                return false
            }

            logger.debug(message: "🔄 Text will change: '\(currentText)' → '\(newCardNumber)'")

            // Process the valid text change
            processTextChange(primerTextField: primerTextField, newText: newCardNumber, isDeletion: isDeletion)

            return false // We handle the update manually
        }

        // MARK: - Helper Methods

        private func saveCursorPosition(_ textField: UITextField) {
            if let selectedTextRange = textField.selectedTextRange {
                selectedRange = selectedTextRange
                if let start = textField.position(from: textField.beginningOfDocument, offset: 0),
                   let cursorPos = textField.selectedTextRange?.start {
                    cursorPosition = textField.offset(from: start, to: cursorPos)
                    logger.debug(message: "💾 Saved cursor position: \(cursorPosition)")
                }
            }
        }

        // Convert a range in formatted text to a range in unformatted text
        private func getUnformattedRange(formattedRange: NSRange, formattedText: String, unformattedText: String) -> NSRange {
            // Count how many non-digit characters are before the selection range
            var nonDigitCount = 0
            var digitCount = 0

            for (index, char) in formattedText.enumerated() {
                if index >= formattedRange.location {
                    break
                }

                if char.isNumber {
                    digitCount += 1
                } else {
                    nonDigitCount += 1
                }
            }

            // Adjust the location based on position in unformatted text
            let unformattedLocation = digitCount

            // For length, we need to account for potential spaces in the selection
            var unformattedLength = 0
            if formattedRange.length > 0 {
                let rangeEnd = min(formattedRange.location + formattedRange.length, formattedText.count)

                // Count digits in the selection
                for index in formattedRange.location..<rangeEnd
                    where index < formattedText.count &&
                          formattedText[formattedText.index(formattedText.startIndex, offsetBy: index)].isNumber {

                    // Increment only when the character is a number
                    unformattedLength += 1
                }
            }

            logger.debug(message: "🔍 Range conversion: formatted \(formattedRange.location),\(formattedRange.length) → unformatted \(unformattedLocation),\(unformattedLength)")

            return NSRange(location: unformattedLocation, length: unformattedLength)
        }

        private func handleDeletion(currentText: String, unformattedRange: NSRange) -> String {
            // If deleting a range of characters
            if unformattedRange.length > 0 {
                if unformattedRange.location >= currentText.count {
                    logger.debug(message: "🗑️ Deletion range outside text bounds")
                    return currentText
                }

                let startIndex = currentText.index(currentText.startIndex, offsetBy: unformattedRange.location)
                let endIndex = currentText.index(startIndex, offsetBy: min(unformattedRange.length, currentText.count - unformattedRange.location))
                let newText = currentText.replacingCharacters(in: startIndex..<endIndex, with: "")
                logger.debug(message: "🗑️ Deleted range from text: '\(currentText)' → '\(newText)'")
                return newText
            }

            // If backspace at the end of the text
            if unformattedRange.location >= currentText.count && currentText.count > 0 {
                let newText = String(currentText.dropLast())
                logger.debug(message: "🗑️ Deleted last character: '\(currentText)' → '\(newText)'")
                return newText
            }

            // If backspace in the middle of the text
            if unformattedRange.location > 0 && unformattedRange.location <= currentText.count {
                let index = currentText.index(currentText.startIndex, offsetBy: unformattedRange.location - 1)
                let newText = currentText.removing(at: index)
                logger.debug(message: "🗑️ Deleted character at position \(unformattedRange.location-1): '\(currentText)' → '\(newText)'")
                return newText
            }

            logger.debug(message: "🗑️ No changes made during deletion")
            return currentText
        }

        private func processTextChange(primerTextField: PrimerCardNumberTextField, newText: String, isDeletion: Bool) {
            logger.debug(message: "🔄 Processing text change: current='\(primerTextField.text ?? "")', new unformatted='\(newText)'")

            // Get current text for comparison
            let currentFormattedText = primerTextField.text ?? ""
            let currentUnformattedText = primerTextField.internalText ?? ""

            // Determine card network only if we have enough digits
            let networkChanged = updateCardNetworkIfNeeded(newText: newText)
            if networkChanged {
                logger.debug(message: "🔄 Card network changed to: \(currentCardNetwork.displayName)")
            }

            // Avoid update cycles
            isUpdating = true

            // Limit length based on card type
            let maxLength = currentCardNetwork.validation?.lengths.max() ?? 16
            let truncatedText = String(newText.prefix(maxLength))
            if truncatedText.count < newText.count {
                logger.debug(message: "🔄 Text truncated to max length \(maxLength)")
            }

            // Format for display with spaces
            let formattedText = formatCardNumber(truncatedText, currentCardNetwork)

            // Update the text and internal text properties immediately
            primerTextField.internalText = truncatedText
            primerTextField.text = formattedText

            logger.debug(message: "🔄 Text updated: unformatted='\(truncatedText)', formatted='\(formattedText)'")

            // Calculate new cursor position
            var newCursorPosition: Int = 0

            if isDeletion {
                if truncatedText.isEmpty {
                    // If all text was deleted, position cursor at the beginning
                    newCursorPosition = 0
                    logger.debug(message: "📍 Cursor reset to beginning after complete deletion")
                } else {
                    // For backspace operation, position cursor at the end of the text
                    // This handles the common case of pressing backspace at the end of the text
                    newCursorPosition = formattedText.count

                    // If deletion wasn't at the end, try to position cursor at the deletion point
                    if cursorPosition < currentFormattedText.count {
                        // Count digits up to cursor position in the old text
                        var digitCountBeforeCursor = 0
                        for i in 0..<cursorPosition {
                            if i < currentFormattedText.count &&
                                currentFormattedText[currentFormattedText.index(currentFormattedText.startIndex, offsetBy: i)].isNumber {
                                digitCountBeforeCursor += 1
                            }
                        }

                        // Position cursor after the same number of digits in the new text
                        // If we deleted a digit, we need to adjust by 1
                        var positionCursor = 0
                        var digitsEncountered = 0
                        let targetDigits = max(0, digitCountBeforeCursor - 1) // One less because we deleted a digit

                        for (i, char) in formattedText.enumerated() {
                            if char.isNumber {
                                digitsEncountered += 1
                            }
                            if digitsEncountered >= targetDigits {
                                positionCursor = char.isNumber ? i + 1 : i
                                break
                            }
                            positionCursor = i + 1
                        }

                        newCursorPosition = positionCursor
                        logger.debug(message: "📍 Calculated cursor position after deletion: \(newCursorPosition) (target digits: \(targetDigits))")
                    } else {
                        logger.debug(message: "📍 Cursor positioned at end after deletion: \(newCursorPosition)")
                    }
                }
            } else {
                // For additions, position cursor after the newly inserted text
                var targetDigitPosition = 0

                // Convert cursor position to digit position
                for i in 0..<min(cursorPosition, currentFormattedText.count) {
                    if i < currentFormattedText.count &&
                        currentFormattedText[currentFormattedText.index(currentFormattedText.startIndex, offsetBy: i)].isNumber {
                        targetDigitPosition += 1
                    }
                }

                // Add 1 to account for the newly inserted digit
                targetDigitPosition += 1

                // Find where this position is in the formatted text
                var digitCount = 0
                var cursorPos = 0

                for (i, char) in formattedText.enumerated() {
                    if char.isNumber {
                        digitCount += 1
                        if digitCount == targetDigitPosition {
                            cursorPos = i + 1
                            break
                        }
                    }
                    cursorPos = i + 1
                }

                newCursorPosition = cursorPos
                logger.debug(message: "📍 Calculated cursor position after addition: \(newCursorPosition) (target digits: \(targetDigitPosition))")
            }

            // Ensure cursor position is within valid range
            let safePosition = min(newCursorPosition, formattedText.count)
            if safePosition != newCursorPosition {
                logger.debug(message: "📍 Cursor position adjusted to safe value: \(newCursorPosition) → \(safePosition)")
            }

            // Restore cursor position
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                if let textField = primerTextField as UITextField?,
                   let newPosition = textField.position(from: textField.beginningOfDocument, offset: safePosition) {
                    logger.debug(message: "📍 Setting cursor position to: \(safePosition)")
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    self.lastCursorPosition = safePosition
                } else {
                    logger.debug(message: "⚠️ Failed to set cursor position to: \(safePosition)")
                }
            }

            // Update state with delay to avoid cycles
            updateParentState(truncatedText: truncatedText, networkChanged: networkChanged)
        }

        private func updateCardNetworkIfNeeded(newText: String) -> Bool {
            if newText.count < 4 {
                if currentCardNetwork != .unknown {
                    logger.debug(message: "🔄 Resetting card network to unknown (insufficient digits)")
                    currentCardNetwork = .unknown
                    updateCardNetwork(.unknown)
                    return true
                }
                return false
            }

            let newCardNetwork = CardNetwork(cardNumber: newText)
            let networkChanged = newCardNetwork != currentCardNetwork

            if networkChanged {
                logger.debug(message: "🔄 Card network changed: \(currentCardNetwork.displayName) → \(newCardNetwork.displayName)")
                currentCardNetwork = newCardNetwork
                updateCardNetwork(newCardNetwork)
            }

            return networkChanged
        }

        private func updateParentState(truncatedText: String, networkChanged: Bool) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Always update the card number
                logger.debug(message: "🔄 Updating parent state with: '\(truncatedText)'")
                self.updateCardNumber(truncatedText)

                // Don't show validation errors during typing unless we have a complete number
                if truncatedText.count >= 13 {
                    self.debouncedValidation(truncatedText)
                } else if truncatedText.isEmpty {
                    logger.debug(message: "🔄 Clearing validation state (empty text)")
                    self.updateValidationState(nil, nil)
                }

                // Reset update flag
                self.isUpdating = false
                logger.debug(message: "🔄 Text change processing completed")
            }
        }

        private func debouncedValidation(_ number: String) {
            // Cancel any existing validation timer
            validationTimer?.invalidate()

            // Schedule validation after a short delay to avoid flickering during typing
            validationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                logger.debug(message: "⏱️ Running delayed validation after typing pause")
                self.validateCardNumberWhileTyping(number)
            }
        }

        // Validation while typing - more lenient for better UX
        private func validateCardNumberWhileTyping(_ number: String) {
            // Only validate complete card numbers during typing
            if number.count < 13 {
                updateValidationState(nil, nil)
                return
            }

            // Use the validation service for card number validation
            // For typing feedback, just use a basic check first
            let network = CardNetwork(cardNumber: number)

            // Verify the network is valid
            if network == .unknown && number.count >= 6 {
                logger.debug(message: "⚠️ Validation failed: Unsupported card type")
                updateValidationState(false, "Unsupported card type")
                return
            }

            // Only do full validation if we have a potentially complete number
            if let validation = network.validation, validation.lengths.contains(number.count) {
                // Use validation service for the actual check
                let validationResult = validationService.validateCardNumber(number)
                updateValidationState(validationResult.isValid, validationResult.isValid ? nil : validationResult.errorMessage)

                if validationResult.isValid {
                    logger.debug(message: "✅ Validation passed: Card number is valid")
                } else {
                    logger.debug(message: "⚠️ Validation failed: \(validationResult.errorMessage ?? "Unknown error")")
                }
            } else {
                // Not a complete number yet
                updateValidationState(nil, nil)
            }
        }

        // Full validation when field loses focus
        private func validateCardNumberFully(_ number: String) {
            // Use the validation service for complete validation
            let validationResult = validationService.validateCardNumber(number)

            // Update the state based on validation result
            updateValidationState(validationResult.isValid, validationResult.errorMessage)

            if validationResult.isValid {
                logger.debug(message: "✅ Validation passed: Card number is valid")
            } else {
                logger.debug(message: "⚠️ Validation failed: \(validationResult.errorMessage ?? "Unknown error")")
            }
        }

        deinit {
            validationTimer?.invalidate()
        }
    }
}

// MARK: - Custom TextField

/// A custom UITextField that masks its text property to prevent exposing
/// sensitive card information externally, while maintaining the internal value.
class PrimerCardNumberTextField: UITextField, LogReporter {
    /// The actual card number stored internally
    var internalText: String?

    /// Overridden to return masked text for external access
    override var text: String? {
        get {
            return super.text
        }
        set {
            super.text = newValue
        }
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        logger.debug(message: "⌨️ TextField became first responder: \(result)")
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        logger.debug(message: "⌨️ TextField resigned first responder: \(result)")
        return result
    }
}
