//
//  CardNumberInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

@available(iOS 15.0, *)
private func convertSwiftUIFontToUIFont(_ font: Font) -> UIFont {
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

@available(iOS 15.0, *)
internal struct CardNumberInputField: View, LogReporter {
    let label: String?
    let placeholder: String
    let scope: any PrimerCardFormScope
    let selectedNetwork: CardNetwork?
    let styling: PrimerFieldStyling?

    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    @State private var cardNumber: String = ""
    @State private var isValid: Bool?
    @State private var cardNetwork: CardNetwork = .unknown
    @State private var errorMessage: String?
    @State private var surchargeAmount: String?
    @State private var isFocused: Bool = false
    @Environment(\.designTokens) private var tokens

    internal init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        selectedNetwork: CardNetwork? = nil,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.selectedNetwork = selectedNetwork
        self.styling = styling
    }

    private var displayNetwork: CardNetwork {
        return selectedNetwork ?? cardNetwork
    }

    private var borderColor: Color {
        let color: Color
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            color = styling?.errorBorderColor ?? tokens?.primerColorBorderOutlinedError ?? .red
        } else if isFocused {
            color = styling?.focusedBorderColor ?? tokens?.primerColorBorderOutlinedFocus ?? .blue
        } else {
            color = styling?.borderColor ?? tokens?.primerColorBorderOutlinedDefault ?? Color(FigmaDesignConstants.inputFieldBorderColor)
        }
        return color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            if let label = label {
                Text(label)
                    .font(styling?.labelFont ?? (tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium)))
                    .foregroundColor(styling?.labelColor ?? tokens?.primerColorTextSecondary ?? .secondary)
            }

            ZStack {
                RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                    .fill(styling?.backgroundColor ?? tokens?.primerColorBackground ?? .white)
                    .overlay(
                        RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                            .stroke(borderColor, lineWidth: styling?.borderWidth ?? 1)
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                    )

                HStack {
                    if let validationService = validationService {
                        CardNumberTextField(
                            scope: scope,
                            cardNumber: $cardNumber,
                            isValid: $isValid,
                            cardNetwork: $cardNetwork,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            styling: styling,
                            validationService: validationService
                        )
                        .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                        .padding(.trailing, displayNetwork != .unknown ?
                                    (tokens?.primerSizeXxlarge ?? 60) :
                                    (styling?.padding?.trailing ?? tokens?.primerSpaceLarge ?? 16))
                        .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
                    } else {
                        TextField(placeholder, text: .constant(""))
                            .disabled(true)
                            .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                            .padding(.trailing, styling?.padding?.trailing ?? tokens?.primerSpaceLarge ?? 16)
                            .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
                    }

                    Spacer()
                }

                HStack {
                    Spacer()

                    if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: tokens?.primerSizeMedium ?? 20, height: tokens?.primerSizeMedium ?? 20)
                            .foregroundColor(tokens?.primerColorIconNegative ?? Color(red: 1.0, green: 0.45, blue: 0.47))
                            .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    } else if displayNetwork != .unknown {
                        VStack(spacing: 2) {
                            if let icon = displayNetwork.icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: tokens?.primerSizeLarge ?? 28, height: tokens?.primerSizeMedium ?? 20)
                            }

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
        .onChange(of: isFocused) { _ in
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
        guard let surcharge = network.surcharge,
              PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.merchantAmount == nil,
              let currency = AppState.current.currency else {
            surchargeAmount = nil
            return
        }

        surchargeAmount = "+ \(surcharge.toCurrencyString(currency: currency))"
    }
}

@available(iOS 15.0, *)
private struct CardNumberTextField: UIViewRepresentable, LogReporter {
    let scope: any PrimerCardFormScope
    @Binding var cardNumber: String
    @Binding var isValid: Bool?
    @Binding var cardNetwork: CardNetwork
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let styling: PrimerFieldStyling?
    let validationService: ValidationService

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.keyboardType = .numberPad
        textField.borderStyle = .none

        if let customFont = styling?.font {
            textField.font = convertSwiftUIFontToUIFont(customFont)
        } else {
            textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

        textField.backgroundColor = .clear

        if let textColor = styling?.textColor {
            textField.textColor = UIColor(textColor)
        }

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
        if textField.text != formatCardNumber(cardNumber, for: cardNetwork) {
            textField.text = formatCardNumber(cardNumber, for: cardNetwork)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            scope: scope,
            validationService: validationService,
            cardNumber: $cardNumber,
            cardNetwork: $cardNetwork,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused
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
        private let scope: any PrimerCardFormScope
        private let validationService: ValidationService
        @Binding private var cardNumber: String
        @Binding private var cardNetwork: CardNetwork
        @Binding private var isValid: Bool?
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private var savedCursorPosition: Int = 0
        private var networkDetectionTimer: Timer?
        private var validationTimer: Timer?

        init(
            scope: any PrimerCardFormScope,
            validationService: ValidationService,
            cardNumber: Binding<String>,
            cardNetwork: Binding<CardNetwork>,
            isValid: Binding<Bool?>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>
        ) {
            self.scope = scope
            self.validationService = validationService
            self._cardNumber = cardNumber
            self._cardNetwork = cardNetwork
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.scope.clearFieldError(.cardNumber)
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
                self.validateCardNumberFully(self.cardNumber)
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            saveCursorPosition(textField)

            let currentText = cardNumber
            let isDeletion = string.isEmpty

            // Process the text change
            let newCardNumber = processTextFieldChange(
                currentText: currentText,
                range: range,
                replacementString: string,
                formattedText: textField.text ?? "",
                isDeletion: isDeletion
            )

            // Early return if no change needed
            guard newCardNumber != currentText || isDeletion else {
                return false
            }

            // Update model
            cardNumber = newCardNumber
            scope.updateCardNumber(newCardNumber)

            // Update network if needed
            updateCardNetworkIfNeeded(newCardNumber)

            // Format and update text field
            let formattedText = formatCardNumber(newCardNumber, for: cardNetwork)
            textField.text = formattedText

            restoreCursorPosition(
                textField: textField,
                formattedText: formattedText,
                originalCursorPos: savedCursorPosition,
                isDeletion: isDeletion,
                insertedLength: isDeletion ? 0 : string.count
            )

            // Update validation state
            updateValidationState(newCardNumber)

            return false
        }

        private func processTextFieldChange(
            currentText: String,
            range: NSRange,
            replacementString string: String,
            formattedText: String,
            isDeletion: Bool
        ) -> String {
            var newCardNumber: String

            if isDeletion {
                newCardNumber = processDeletion(
                    currentText: currentText,
                    range: range,
                    formattedText: formattedText
                )
            } else {
                let filteredText = string.filter { $0.isNumber }
                if filteredText.isEmpty {
                    return currentText
                }

                newCardNumber = processInsertion(
                    currentText: currentText,
                    range: range,
                    formattedText: formattedText,
                    insertText: filteredText
                )
            }

            // Limit to 19 digits
            if newCardNumber.count > 19 {
                newCardNumber = String(newCardNumber.prefix(19))
            }

            return newCardNumber
        }

        private func processDeletion(
            currentText: String,
            range: NSRange,
            formattedText: String
        ) -> String {
            if range.length > 0 {
                let unformattedRange = getUnformattedRange(
                    formattedRange: range,
                    formattedText: formattedText,
                    unformattedText: currentText
                )
                return handleDeletion(currentText: currentText, unformattedRange: unformattedRange)
            } else if range.location > 0 {
                let unformattedPos = calculateUnformattedPosition(
                    upToIndex: range.location,
                    in: formattedText
                )

                if unformattedPos > 0 && unformattedPos <= currentText.count {
                    let index = currentText.index(currentText.startIndex, offsetBy: unformattedPos - 1)
                    return currentText.removing(at: index)
                }
            }

            return currentText
        }

        private func processInsertion(
            currentText: String,
            range: NSRange,
            formattedText: String,
            insertText: String
        ) -> String {
            let unformattedPos = calculateUnformattedPosition(
                upToIndex: range.location,
                in: formattedText
            )

            if unformattedPos <= currentText.count {
                let index = currentText.index(currentText.startIndex, offsetBy: unformattedPos)
                return currentText.inserting(contentsOf: insertText, at: index)
            } else {
                return currentText + insertText
            }
        }

        private func calculateUnformattedPosition(upToIndex index: Int, in formattedText: String) -> Int {
            var unformattedPos = 0
            for i in 0..<index where i < formattedText.count {
                let charIndex = formattedText.index(formattedText.startIndex, offsetBy: i)
                if formattedText[charIndex].isNumber {
                    unformattedPos += 1
                }
            }
            return unformattedPos
        }

        private func updateCardNetworkIfNeeded(_ newCardNumber: String) {
            let newNetwork = CardNetwork(cardNumber: newCardNumber)
            if newNetwork != cardNetwork {
                cardNetwork = newNetwork
                if newNetwork != .unknown {
                    scope.updateSelectedCardNetwork(newNetwork.rawValue)
                }
            }
        }

        private func updateValidationState(_ newCardNumber: String) {
            if newCardNumber.count >= 6 {
                debouncedNetworkDetection(newCardNumber)
            }

            if newCardNumber.count >= 13 {
                debouncedValidation(newCardNumber)
            } else if newCardNumber.isEmpty {
                isValid = nil
                errorMessage = nil
                scope.clearFieldError(.cardNumber)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardNumberValidationState(false)
                }
            }
        }

        private func saveCursorPosition(_ textField: UITextField) {
            if let selectedRange = textField.selectedTextRange {
                savedCursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
            }
        }

        private func restoreCursorPosition(textField: UITextField, formattedText: String, originalCursorPos: Int, isDeletion: Bool, insertedLength: Int) {
            var newCursorPosition: Int

            if isDeletion {
                newCursorPosition = min(originalCursorPos, formattedText.count)
            } else {
                newCursorPosition = min(originalCursorPos + insertedLength, formattedText.count)

                if originalCursorPos < formattedText.count {
                    let spacesAdded = formattedText.prefix(newCursorPosition).filter { $0 == " " }.count
                    newCursorPosition = min(originalCursorPos + insertedLength + spacesAdded, formattedText.count)
                }
            }

            DispatchQueue.main.async {
                if let newPosition = textField.position(from: textField.beginningOfDocument, offset: newCursorPosition) {
                    textField.selectedTextRange = textField.textRange(from: newPosition, to: newPosition)
                }
            }
        }

        private func getUnformattedRange(formattedRange: NSRange, formattedText: String, unformattedText: String) -> NSRange {
            var digitCount = 0

            for (index, char) in formattedText.enumerated() {
                if index >= formattedRange.location {
                    break
                }

                if char.isNumber {
                    digitCount += 1
                }
            }

            let unformattedLocation = digitCount

            var unformattedLength = 0
            if formattedRange.length > 0 {
                let rangeEnd = min(formattedRange.location + formattedRange.length, formattedText.count)

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
            if unformattedRange.length > 0 {
                if unformattedRange.location >= currentText.count {
                    return currentText
                }

                let startIndex = currentText.index(currentText.startIndex, offsetBy: unformattedRange.location)
                let endIndex = currentText.index(startIndex, offsetBy: min(unformattedRange.length, currentText.count - unformattedRange.location))
                return currentText.replacingCharacters(in: startIndex..<endIndex, with: "")
            }

            if unformattedRange.location >= currentText.count && currentText.count > 0 {
                return String(currentText.dropLast())
            }

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

        private func debouncedValidation(_ number: String) {
            validationTimer?.invalidate()
            validationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.validateCardNumberWhileTyping(number)
            }
        }

        private func debouncedNetworkDetection(_ number: String) {
            networkDetectionTimer?.invalidate()
            networkDetectionTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.detectNetworksForCardNumber(number)
            }
        }

        private func detectNetworksForCardNumber(_ cardNumber: String) {
            logger.debug(message: "Detecting card networks")
        }

        private func validateCardNumberWhileTyping(_ number: String) {
            if number.count < 13 {
                isValid = nil
                errorMessage = nil
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardNumberValidationState(false)
                }
                return
            }

            let network = CardNetwork(cardNumber: number)

            if network != .unknown, let validation = network.validation, validation.lengths.contains(number.count) {
                let validationResult = validationService.validateCardNumber(number)

                if validationResult.isValid {
                    isValid = true
                    errorMessage = nil
                    // Update scope validation state
                    if let scope = scope as? DefaultCardFormScope {
                        scope.updateCardNumberValidationState(true)
                    }
                } else {
                    isValid = nil
                    errorMessage = nil
                    // Update scope validation state
                    if let scope = scope as? DefaultCardFormScope {
                        scope.updateCardNumberValidationState(false)
                    }
                }
            } else if number.count >= 16 {
                let validationResult = validationService.validateCardNumber(number)

                if validationResult.isValid {
                    isValid = true
                    errorMessage = nil
                    // Update scope validation state
                    if let scope = scope as? DefaultCardFormScope {
                        scope.updateCardNumberValidationState(true)
                    }
                } else {
                    isValid = nil
                    errorMessage = nil
                    // Update scope validation state
                    if let scope = scope as? DefaultCardFormScope {
                        scope.updateCardNumberValidationState(false)
                    }
                }
            } else {
                isValid = nil
                errorMessage = nil
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardNumberValidationState(false)
                }
            }
        }

        private func validateCardNumberFully(_ number: String) {
            validationTimer?.invalidate()

            let trimmedNumber = number.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmedNumber.isEmpty {
                isValid = false
                errorMessage = nil
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardNumberValidationState(false)
                }
                return
            }

            let validationResult = validationService.validateCardNumber(number)
            isValid = validationResult.isValid

            if validationResult.isValid {
                errorMessage = nil
                scope.clearFieldError(.cardNumber)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardNumberValidationState(true)
                }
            } else {
                errorMessage = validationResult.errorMessage
                if let errorMessage = validationResult.errorMessage {
                    scope.setFieldError(.cardNumber, message: errorMessage, errorCode: validationResult.errorCode)
                }
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateCardNumberValidationState(false)
                }
            }
        }

        deinit {
            validationTimer?.invalidate()
            networkDetectionTimer?.invalidate()
        }
    }
}

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
