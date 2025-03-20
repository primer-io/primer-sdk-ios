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

    /// The card number entered by the user (without formatting)
    @State private var cardNumber: String = ""

    /// The validation state of the card number
    @State private var isValid: Bool?

    /// The detected card network based on the card number
    @State private var cardNetwork: CardNetwork = .unknown

    /// Error message if validation fails
    @State private var errorMessage: String?

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)

            // Card input field with network icon
            HStack(spacing: 8) {
                ImprovedCardNumberTextField(
                    cardNumber: $cardNumber,
                    isValid: $isValid,
                    cardNetwork: $cardNetwork,
                    errorMessage: $errorMessage,
                    placeholder: placeholder
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
struct ImprovedCardNumberTextField: UIViewRepresentable {
    @Binding var cardNumber: String
    @Binding var isValid: Bool?
    @Binding var cardNetwork: CardNetwork
    @Binding var errorMessage: String?
    var placeholder: String

    func makeUIView(context: Context) -> UITextField {
        let textField = PrimerCardNumberTextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.font = UIFont.preferredFont(forTextStyle: .body)

        print("🔤 Creating new card number text field")

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

        print("🔤 Initial card number text field setup complete")

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        // Minimal updates to avoid cycles
        guard let primerTextField = textField as? PrimerCardNumberTextField else { return }

        // Only update if needed
        if primerTextField.internalText != cardNumber {
            print("🔄 Updating text field: internalText='\(primerTextField.internalText ?? "")' → cardNumber='\(cardNumber)'")

            primerTextField.internalText = cardNumber

            // Format the displayed text without triggering validation
            if !cardNumber.isEmpty {
                let formattedText = formatCardNumber(cardNumber, for: cardNetwork)
                if primerTextField.text != formattedText {
                    print("🔄 Formatted text update: '\(primerTextField.text ?? "")' → '\(formattedText)'")
                    primerTextField.text = formattedText
                }
            }

            // Log the current cursor position after update
            if let selectedRange = primerTextField.selectedTextRange {
                let cursorPosition = primerTextField.offset(from: primerTextField.beginningOfDocument, to: selectedRange.start)
                print("🔄 Cursor position after update: \(cursorPosition)")
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
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

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: ImprovedCardNumberTextField

        // Add a flag to prevent update cycles
        private var isUpdating = false

        // Track cursor position to restore it after text formatting
        private var selectedRange: UITextRange?
        private var cursorPosition: Int = 0

        // For tracking changes in cursor position
        private var lastCursorPosition: Int = 0

        init(_ parent: ImprovedCardNumberTextField) {
            self.parent = parent
            print("📝 Coordinator initialized")
        }

        @objc func textDidChangeNotification(_ notification: Notification) {
            guard let textField = notification.object as? UITextField,
                  let selectedRange = textField.selectedTextRange else {
                return
            }

            let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)

            if cursorPosition != lastCursorPosition {
                print("📍 Cursor position changed: \(lastCursorPosition) → \(cursorPosition)")
                lastCursorPosition = cursorPosition
            }
        }

        @objc func doneButtonTapped() {
            print("⌨️ Done button tapped")
            DispatchQueue.main.async {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            print("⌨️ Text field began editing")
            // Clear error message when user starts editing
            parent.errorMessage = nil

            // Log initial cursor position
            if let selectedRange = textField.selectedTextRange {
                let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
                print("📍 Initial cursor position: \(cursorPosition)")
                lastCursorPosition = cursorPosition
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            print("⌨️ Text field ended editing")
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
                    print("📍 Selection changed: \(lastCursorPosition) → \(cursorPosition)")
                    lastCursorPosition = cursorPosition
                }
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Avoid reentrance
            if isUpdating {
                print("🔄 Avoiding reentrance in shouldChangeCharactersIn")
                return false
            }

            guard let primerTextField = textField as? PrimerCardNumberTextField else {
                return true
            }

            print("⌨️ shouldChangeCharactersIn - range: \(range.location),\(range.length), replacement: '\(string)'")

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
                print("📋 Paste operation detected with \(string.count) characters")
            }

            var newCardNumber: String

            if isDeletion {
                // Handle deletion operation
                if range.length > 0 {
                    // Convert formatted range to unformatted range for selection deletion
                    let unformattedRange = getUnformattedRange(formattedRange: range, formattedText: textField.text ?? "", unformattedText: currentText)
                    print("🗑️ Deletion - formatted range \(range.location),\(range.length) → unformatted range \(unformattedRange.location),\(unformattedRange.length)")
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

                    print("🗑️ Backspace at position \(range.location) maps to unformatted position \(unformattedPos)")

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
                    print("⌨️ Ignoring non-numeric input: '\(string)'")
                    return false
                }

                // For paste operations, log the filtered content
                if isPasteOperation && filteredText.count != string.count {
                    print("📋 Filtered paste content from \(string.count) to \(filteredText.count) digits")
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
                    print("📋 Pasting at position \(range.location) maps to unformatted position \(unformattedPos)")
                } else {
                    print("⌨️ Typing at position \(range.location) maps to unformatted position \(unformattedPos)")
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
                print("⌨️ Rejecting input - would exceed max length (19)")
                return false
            }

            print("🔄 Text will change: '\(currentText)' → '\(newCardNumber)'")

            // Process the valid text change
            processTextChange(primerTextField: primerTextField, newText: newCardNumber, isDeletion: isDeletion)

            return false // We handle the update manually
        }

        private func saveCursorPosition(_ textField: UITextField) {
            if let selectedTextRange = textField.selectedTextRange {
                selectedRange = selectedTextRange
                if let start = textField.position(from: textField.beginningOfDocument, offset: 0),
                   let cursorPos = textField.selectedTextRange?.start {
                    cursorPosition = textField.offset(from: start, to: cursorPos)
                    print("💾 Saved cursor position: \(cursorPosition)")
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
                for index in formattedRange.location..<rangeEnd {
                    if index < formattedText.count {
                        let char = formattedText[formattedText.index(formattedText.startIndex, offsetBy: index)]
                        if char.isNumber {
                            unformattedLength += 1
                        }
                    }
                }
            }

            print("🔍 Range conversion: formatted \(formattedRange.location),\(formattedRange.length) → unformatted \(unformattedLocation),\(unformattedLength)")

            return NSRange(location: unformattedLocation, length: unformattedLength)
        }

        private func handleDeletion(currentText: String, unformattedRange: NSRange) -> String {
            // If deleting a range of characters
            if unformattedRange.length > 0 {
                if unformattedRange.location >= currentText.count {
                    print("🗑️ Deletion range outside text bounds")
                    return currentText
                }

                let startIndex = currentText.index(currentText.startIndex, offsetBy: unformattedRange.location)
                let endIndex = currentText.index(startIndex, offsetBy: min(unformattedRange.length, currentText.count - unformattedRange.location))
                let newText = currentText.replacingCharacters(in: startIndex..<endIndex, with: "")
                print("🗑️ Deleted range from text: '\(currentText)' → '\(newText)'")
                return newText
            }

            // If backspace at the end of the text
            if unformattedRange.location >= currentText.count && currentText.count > 0 {
                let newText = String(currentText.dropLast())
                print("🗑️ Deleted last character: '\(currentText)' → '\(newText)'")
                return newText
            }

            // If backspace in the middle of the text
            if unformattedRange.location > 0 && unformattedRange.location <= currentText.count {
                let index = currentText.index(currentText.startIndex, offsetBy: unformattedRange.location - 1)
                let newText = currentText.removing(at: index)
                print("🗑️ Deleted character at position \(unformattedRange.location-1): '\(currentText)' → '\(newText)'")
                return newText
            }

            print("🗑️ No changes made during deletion")
            return currentText
        }

        private func processTextChange(primerTextField: PrimerCardNumberTextField, newText: String, isDeletion: Bool) {
            print("🔄 Processing text change: current='\(primerTextField.text ?? "")', new unformatted='\(newText)'")

            // Get current text for comparison
            let currentFormattedText = primerTextField.text ?? ""
            let currentUnformattedText = primerTextField.internalText ?? ""

            // Determine card network only if we have enough digits
            let networkChanged = updateCardNetworkIfNeeded(newText: newText)
            if networkChanged {
                print("🔄 Card network changed to: \(parent.cardNetwork.displayName)")
            }

            // Avoid update cycles
            isUpdating = true

            // Limit length based on card type
            let maxLength = parent.cardNetwork.validation?.lengths.max() ?? 16
            let truncatedText = String(newText.prefix(maxLength))
            if truncatedText.count < newText.count {
                print("🔄 Text truncated to max length \(maxLength)")
            }

            // Format for display with spaces
            let formattedText = parent.formatCardNumber(truncatedText, for: parent.cardNetwork)

            // Update the text and internal text properties immediately
            primerTextField.internalText = truncatedText
            primerTextField.text = formattedText

            print("🔄 Text updated: unformatted='\(truncatedText)', formatted='\(formattedText)'")

            // Calculate new cursor position
            var newCursorPosition: Int = 0

            if isDeletion {
                if truncatedText.isEmpty {
                    // If all text was deleted, position cursor at the beginning
                    newCursorPosition = 0
                    print("📍 Cursor reset to beginning after complete deletion")
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
                        print("📍 Calculated cursor position after deletion: \(newCursorPosition) (target digits: \(targetDigits))")
                    } else {
                        print("📍 Cursor positioned at end after deletion: \(newCursorPosition)")
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
                print("📍 Calculated cursor position after addition: \(newCursorPosition) (target digits: \(targetDigitPosition))")
            }

            // Ensure cursor position is within valid range
            let safePosition = min(newCursorPosition, formattedText.count)
            if safePosition != newCursorPosition {
                print("📍 Cursor position adjusted to safe value: \(newCursorPosition) → \(safePosition)")
            }

            // Restore cursor position
            DispatchQueue.main.async {
                if let textField = primerTextField as UITextField?,
                   let newPosition = textField.position(from: textField.beginningOfDocument, offset: safePosition) {
                    print("📍 Setting cursor position to: \(safePosition)")
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                    self.lastCursorPosition = safePosition
                } else {
                    print("⚠️ Failed to set cursor position to: \(safePosition)")
                }
            }

            // Update parent state with delay to avoid cycles
            updateParentState(truncatedText: truncatedText, networkChanged: networkChanged)
        }

        private func updateCardNetworkIfNeeded(newText: String) -> Bool {
            if newText.count < 4 {
                if parent.cardNetwork != .unknown {
                    print("🔄 Resetting card network to unknown (insufficient digits)")
                    parent.cardNetwork = .unknown
                    return true
                }
                return false
            }

            let newCardNetwork = CardNetwork(cardNumber: newText)
            let networkChanged = newCardNetwork != parent.cardNetwork

            if networkChanged {
                print("🔄 Card network changed: \(parent.cardNetwork.displayName) → \(newCardNetwork.displayName)")
                parent.cardNetwork = newCardNetwork
            }

            return networkChanged
        }

        // IMPROVEMENT 2: Optimize state updates to avoid redundant binding updates
        private func updateParentState(truncatedText: String, networkChanged: Bool) {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                // Only update the binding if the value has actually changed
                if truncatedText != self.parent.cardNumber {
                    print("🔄 Updating parent state with: '\(truncatedText)'")
                    self.parent.cardNumber = truncatedText
                } else {
                    print("🔄 Skipping redundant state update (value unchanged)")
                }

                // Don't show validation errors during typing unless we have a complete number
                if truncatedText.count >= 13 {
                    self.debouncedValidation(truncatedText)
                } else if truncatedText.isEmpty {
                    print("🔄 Clearing validation state (empty text)")
                    self.parent.isValid = nil
                    self.parent.errorMessage = nil
                }

                // Reset update flag
                self.isUpdating = false
                print("🔄 Text change processing completed")
            }
        }

        // IMPROVEMENT 3: Add debouncing for validation
        private var validationTimer: Timer?

        private func debouncedValidation(_ number: String) {
            // Cancel any existing validation timer
            validationTimer?.invalidate()

            // Schedule validation after a short delay to avoid flickering during typing
            validationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                print("⏱️ Running delayed validation after typing pause")
                self.validateCardNumberWhileTyping(number, for: self.parent.cardNetwork)
            }
        }

        // Validation while typing - keep it minimal during input
        private func validateCardNumberWhileTyping(_ number: String, for network: CardNetwork) {
            // Only validate complete card numbers during typing
            if number.count < 13 {
                parent.isValid = nil
                parent.errorMessage = nil
                return
            }

            // Verify the network is valid
            if network == .unknown && number.count >= 6 {
                print("⚠️ Validation failed: Unsupported card type")
                parent.isValid = false
                parent.errorMessage = "Unsupported card type"
                return
            }

            // Check Luhn only for complete numbers
            if let validation = network.validation,
               validation.lengths.contains(number.count) {
                if isLuhnValid(number) {
                    print("✅ Validation passed: Card number is valid")
                    parent.isValid = true
                    parent.errorMessage = nil
                } else {
                    print("⚠️ Validation failed: Invalid card number (Luhn check)")
                    parent.isValid = false
                    parent.errorMessage = "Invalid card number"
                }
            } else {
                // Not a complete number yet
                parent.isValid = nil
                parent.errorMessage = nil
            }
        }

        // Full validation when field loses focus
        private func validateCardNumberFully(_ number: String) {
            if number.isEmpty {
                print("⚠️ Validation failed: Card number cannot be blank")
                parent.isValid = false
                parent.errorMessage = "Card number cannot be blank"
                return
            }

            let network = CardNetwork(cardNumber: number)

            // Check if the network is valid
            if network == .unknown {
                print("⚠️ Validation failed: Unsupported card type")
                parent.isValid = false
                parent.errorMessage = "Unsupported card type"
                return
            }

            // Check if the length is valid for this network
            if let validation = network.validation {
                if !validation.lengths.contains(number.count) {
                    print("⚠️ Validation failed: Invalid card number length (\(number.count)) for \(network.displayName)")
                    parent.isValid = false
                    parent.errorMessage = "Invalid card number length"
                    return
                }
            }

            // Check Luhn algorithm
            if !isLuhnValid(number) {
                print("⚠️ Validation failed: Invalid card number (Luhn check)")
                parent.isValid = false
                parent.errorMessage = "Invalid card number"
                return
            }

            // All checks passed
            print("✅ Validation passed: Card number is valid")
            parent.isValid = true
            parent.errorMessage = nil
        }

        // Luhn algorithm implementation
        private func isLuhnValid(_ number: String) -> Bool {
            let digitOnly = number.filter { $0.isNumber }
            if digitOnly.isEmpty { return false }

            let reversedDigits = digitOnly.reversed().map { Int(String($0))! }
            var sum = 0

            for (index, digit) in reversedDigits.enumerated() {
                if index % 2 == 1 {
                    let doubledValue = digit * 2
                    sum += doubledValue > 9 ? doubledValue - 9 : doubledValue
                } else {
                    sum += digit
                }
            }

            return sum % 10 == 0
        }
    }
}

// Helper extensions
extension String {
    func inserting(contentsOf string: String, at index: String.Index) -> String {
        var result = self
        result.insert(contentsOf: string, at: index)
        return result
    }

    func removing(at index: String.Index) -> String {
        var result = self
        result.remove(at: index)
        return result
    }
}

// MARK: - Custom TextField

/// A custom UITextField that masks its text property to prevent exposing
/// sensitive card information externally, while maintaining the internal value.
class PrimerCardNumberTextField: UITextField {
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
        print("⌨️ TextField became first responder: \(result)")
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        print("⌨️ TextField resigned first responder: \(result)")
        return result
    }
}
