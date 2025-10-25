//
//  StateInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI
import UIKit

/// A SwiftUI component for state/province input with validation and consistent styling
/// matching the card form field validation timing patterns.
@available(iOS 15.0, *)
struct StateInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The state entered by the user
    @State private var state: String = ""

    /// The validation state of the state
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    @Environment(\.designTokens) private var tokens
    // MARK: - Computed Properties

    /// Dynamic border color based on field state
    private var borderColor: Color {
        return primerInputBorderColor(
            errorMessage: errorMessage,
            isFocused: isFocused,
            styling: styling,
            tokens: tokens
        )
    }

    // MARK: - Initialization

    /// Creates a new StateInputField with comprehensive customization support
    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.xsmall(tokens: tokens)) {
            // Label with custom styling support
            if let label = label {
                Text(label)
                    .primerLabelStyle(styling: styling, tokens: tokens)
                    
            }

            // State input field with ZStack architecture
            ZStack {
                // Background and border styling with custom styling support
                Color.clear
                    .primerInputFieldBorder(
                        cornerRadius: PrimerRadius.small(tokens: tokens),
                        backgroundColor: styling?.backgroundColor ?? PrimerCheckoutColors.background(tokens: tokens),
                        borderColor: borderColor,
                        borderWidth: styling?.borderWidth ?? PrimerBorderWidth.standard,
                        animationValue: isFocused
                    )

                // Input field content
                HStack {
                    if let validationService = validationService {
                        StateTextField(
                            state: $state,
                            isValid: $isValid,
                            errorMessage: $errorMessage,
                            isFocused: $isFocused,
                            placeholder: placeholder,
                            styling: styling,
                            validationService: validationService,
                            scope: scope
                        )
                        .primerInputPadding(styling: styling, tokens: tokens, errorPresent: errorMessage != nil)
                    } else {
                        // Fallback view while loading validation service
                        TextField(placeholder, text: $state)
                            .autocapitalization(.words)
                            .disabled(true)
                            .padding(.leading, styling?.padding?.leading ?? PrimerSpacing.large(tokens: tokens))
                            .padding(.trailing, styling?.padding?.trailing ?? PrimerSpacing.large(tokens: tokens))
                            .padding(.vertical, styling?.padding?.top ?? PrimerSpacing.medium(tokens: tokens))
                    }

                    Spacer()
                }

                // Right side overlay (error icon)
                HStack {
                    Spacer()

                    if let errorMessage = errorMessage, !errorMessage.isEmpty {
                        // Error icon when validation fails
                        Image(systemName: "exclamationmark.triangle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .primerErrorIconStyle(tokens: tokens)
                    }
                }
            }
            .primerInputFieldHeight(styling: styling, tokens: tokens)

            // Error message (always reserve space to prevent height changes)
            Text(errorMessage ?? " ")
                .primerErrorMessageStyle(tokens: tokens)
                
                .opacity(errorMessage != nil ? 1.0 : 0.0)
                .animation(AnimationConstants.errorAnimation, value: errorMessage != nil)
        }
        .onAppear {
            setupValidationService()
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for StateInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
}

/// UIViewRepresentable wrapper for state input with focus-based validation
@available(iOS 15.0, *)
private struct StateTextField: UIViewRepresentable, LogReporter {
    @Binding var state: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?
    @Binding var isFocused: Bool
    let placeholder: String
    let styling: PrimerFieldStyling?
    let validationService: ValidationService
    let scope: any PrimerCardFormScope

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.borderStyle = .none
        // Apply custom font or use system default
        if let customFont = styling?.font {
            textField.font = UIFont(customFont)
        } else {
            textField.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        }

        textField.backgroundColor = .clear

        // Apply custom text color if provided
        if let textColor = styling?.textColor {
            textField.textColor = UIColor(textColor)
        }
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done

        // Apply custom placeholder styling or use defaults
        let placeholderFont: UIFont = {
            if let customFont = styling?.font {
                return UIFont(customFont)
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
        let accessoryView = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: PrimerComponentHeight.keyboardAccessory))
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
        if textField.text != state {
            textField.text = state
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            validationService: validationService,
            state: $state,
            isValid: $isValid,
            errorMessage: $errorMessage,
            isFocused: $isFocused,
            scope: scope
        )
    }

    class Coordinator: NSObject, UITextFieldDelegate, LogReporter {
        private let validationService: ValidationService
        @Binding private var state: String
        @Binding private var isValid: Bool
        @Binding private var errorMessage: String?
        @Binding private var isFocused: Bool
        private let scope: any PrimerCardFormScope

        init(
            validationService: ValidationService,
            state: Binding<String>,
            isValid: Binding<Bool>,
            errorMessage: Binding<String?>,
            isFocused: Binding<Bool>,
            scope: any PrimerCardFormScope
        ) {
            self.validationService = validationService
            self._state = state
            self._isValid = isValid
            self._errorMessage = errorMessage
            self._isFocused = isFocused
            self.scope = scope
        }

        @objc func doneButtonTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = true
                self.errorMessage = nil
                self.scope.clearFieldError(.state)
                // Don't set isValid = false immediately - let validation happen on text change or focus loss
            }
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            DispatchQueue.main.async {
                self.isFocused = false
            }
            validateState()
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Get current text
            let currentText = state

            // Create new text
            guard let textRange = Range(range, in: currentText) else { return false }
            let newText = currentText.replacingCharacters(in: textRange, with: string)

            // Update state
            state = newText
            scope.updateState(newText)

            // Simple validation while typing (don't show errors until focus loss)
            isValid = !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            // Update scope validation state while typing
            if let scope = scope as? DefaultCardFormScope {
                scope.updateStateValidationState(isValid)
            }

            return false
        }

        private func validateState() {
            let trimmedState = state.trimmingCharacters(in: .whitespacesAndNewlines)

            // Empty field handling - don't show errors for empty fields
            if trimmedState.isEmpty {
                isValid = false // State is required
                errorMessage = nil // Never show error message for empty fields
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateStateValidationState(false)
                }
                return
            }

            let result = validationService.validate(
                input: state,
                with: StateRule()
            )

            isValid = result.isValid
            errorMessage = result.errorMessage

            // Update scope state based on validation
            if result.isValid {
                scope.clearFieldError(.state)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateStateValidationState(true)
                }
            } else if let message = result.errorMessage {
                scope.setFieldError(.state, message: message, errorCode: result.errorCode)
                // Update scope validation state
                if let scope = scope as? DefaultCardFormScope {
                    scope.updateStateValidationState(false)
                }
            }
        }
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
struct StateInputField_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 32) {
                // MARK: - Basic States
                Group {
                    StateInputField(label: "State", placeholder: "Enter state", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: nil, placeholder: "State", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - State/Province Examples
                Group {
                    Text("State/Province Examples").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    StateInputField(label: "US State (Full)", placeholder: "California", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "US State (Abbr)", placeholder: "CA", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "Canadian Province", placeholder: "Ontario", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "Canadian Province (Abbr)", placeholder: "ON", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "Australian State", placeholder: "New South Wales", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "Province/Region", placeholder: "State or Province", scope: MockCardFormScope())
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - Validation States
                Group {
                    Text("Validation States").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    StateInputField(label: "Valid State", placeholder: "New York", scope: MockCardFormScope(isValid: true))
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "Invalid State", placeholder: "Enter valid state", scope: MockCardFormScope(isValid: false))
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - Styling Variations
                Group {
                    Text("Styling Variations").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    StateInputField(label: "State (Custom Light)", placeholder: "Texas", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .body, textColor: .primary, backgroundColor: .gray.opacity(0.05), placeholderColor: .gray, borderWidth: 1))
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "State (Dark Theme)", placeholder: "Florida", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .body, textColor: .white, backgroundColor: .black.opacity(0.8), placeholderColor: .gray, borderWidth: 2))
                        .background(Color.gray.opacity(0.1))
                        .preferredColorScheme(.dark)
                    StateInputField(label: "State (Bold Style)", placeholder: "Enter your state", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .title3, textColor: .primary, backgroundColor: .blue.opacity(0.1), borderWidth: 3))
                        .background(Color.gray.opacity(0.1))
                }
                Divider()
                // MARK: - Size Variations
                Group {
                    Text("Size Variations").font(.headline).frame(maxWidth: .infinity, alignment: .leading)
                    StateInputField(label: "Compact State", placeholder: "State", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .caption, textColor: .primary, backgroundColor: .clear, borderWidth: 1))
                        .background(Color.gray.opacity(0.1))
                    StateInputField(label: "Large State", placeholder: "Enter your state or province", scope: MockCardFormScope(), styling: PrimerFieldStyling(font: .title2, textColor: .primary, backgroundColor: .clear, borderWidth: 2))
                        .background(Color.gray.opacity(0.1))
                }
            }.padding()
        }
        .environment(\.designTokens, nil)
        .environment(\.diContainer, nil)
        .previewDisplayName("State Input Field")
    }
}
#endif
