//
//  CountryInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for country selection with validation
@available(iOS 15.0, *)
struct CountryInputField: View, LogReporter {
    // MARK: - Public Properties

    /// The label text shown above the field
    let label: String?

    /// Placeholder text for the input field
    let placeholder: String

    /// The card form scope for state management
    let scope: any PrimerCardFormScope

    /// External country for reactive updates (using proper SDK type)
    let selectedCountry: CountryCode.PhoneNumberCountryCode?

    /// Optional styling configuration for customizing field appearance
    let styling: PrimerFieldStyling?
    // MARK: - Private Properties

    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?

    /// The country name displayed
    @State private var countryName: String = ""

    /// The country code (ISO 2-letter)
    @State private var countryCode: String = ""

    /// The validation state
    @State private var isValid: Bool = false

    /// Error message if validation fails
    @State private var errorMessage: String?

    /// Focus state for input field styling
    @State private var isFocused: Bool = false

    /// Debounce navigation to prevent multiple rapid calls
    @State private var isNavigating: Bool = false

    @Environment(\.designTokens) private var tokens

    // MARK: - Modifier Value Extraction
    // MARK: - Computed Properties

    /// Dynamic border color based on field state
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

    /// Display text font for country field
    private var countryTextFont: Font {
        styling?.font ?? (tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .body)
    }

    /// Text color for country display (placeholder vs selected)
    private var countryTextColor: Color {
        if countryName.isEmpty {
            return styling?.placeholderColor ?? tokens?.primerColorTextSecondary ?? .secondary
        } else {
            return styling?.textColor ?? tokens?.primerColorTextPrimary ?? .primary
        }
    }

    // MARK: - Initialization

    /// Creates a new CountryInputField with comprehensive customization support
    init(
        label: String?,
        placeholder: String,
        scope: any PrimerCardFormScope,
        selectedCountry: CountryCode.PhoneNumberCountryCode? = nil,
        styling: PrimerFieldStyling? = nil
    ) {
        self.label = label
        self.placeholder = placeholder
        self.scope = scope
        self.selectedCountry = selectedCountry
        self.styling = styling
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: FigmaDesignConstants.labelInputSpacing) {
            // Label with custom styling support
            if let label = label {
                Text(label)
                    .font(styling?.labelFont ?? (tokens != nil ? PrimerFont.bodySmall(tokens: tokens!) : .system(size: 12, weight: .medium)))
                    .foregroundColor(styling?.labelColor ?? tokens?.primerColorTextSecondary ?? .secondary)
            }

            // Country field with selector button using Button with HStack layout
            Button(action: {
                guard !isNavigating else {
                    return
                }

                isNavigating = true

                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()

                scope.navigateToCountrySelection()

                // Reset after shorter timeout - 1 second should be enough
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.isNavigating = false
                }
            }, label: {
                ZStack {
                    // Background and border styling
                    RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                        .fill(styling?.backgroundColor ?? tokens?.primerColorBackground ?? .white)
                        .overlay(
                            RoundedRectangle(cornerRadius: styling?.cornerRadius ?? FigmaDesignConstants.inputFieldRadius)
                                .stroke(borderColor, lineWidth: styling?.borderWidth ?? 1)
                                .animation(.easeInOut(duration: 0.2), value: isFocused)
                        )

                    // Content layout
                    HStack {
                        Text(countryName.isEmpty ? placeholder : countryName)
                            .font(countryTextFont)
                            .foregroundColor(countryTextColor)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        Spacer()

                        // Right side icon (error icon or chevron)
                        if let errorMessage = errorMessage, !errorMessage.isEmpty {
                            // Error icon when validation fails
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: tokens?.primerSizeMedium ?? 20, height: tokens?.primerSizeMedium ?? 20)
                                .foregroundColor(tokens?.primerColorIconNegative ?? .defaultIconNegative)
                        } else {
                            // Chevron down icon when no error
                            Image(systemName: "chevron.down")
                                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        }
                    }
                    .padding(.leading, styling?.padding?.leading ?? tokens?.primerSpaceLarge ?? 16)
                    .padding(.trailing, tokens?.primerSpaceMedium ?? 12)
                    .padding(.vertical, styling?.padding?.top ?? tokens?.primerSpaceMedium ?? 12)
                }
            })
            .buttonStyle(PlainButtonStyle())
            .disabled(isNavigating)
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
            isNavigating = false
            setupValidationService()
            updateFromExternalState()
        }
        .onChange(of: selectedCountry) { newCountry in
            updateFromExternalState(with: newCountry)
        }
    }

    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for CountryInputField")
            return
        }

        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }

    /// Updates the field from external state changes using the property
    @MainActor
    private func updateFromExternalState() {
        updateFromExternalState(with: selectedCountry)
    }

    /// Updates the field from external state changes using the provided country
    @MainActor
    private func updateFromExternalState(with country: CountryCode.PhoneNumberCountryCode?) {
        // Update directly from the atomic CountryCode.PhoneNumberCountryCode object
        if let country = country, !country.name.isEmpty, !country.code.isEmpty {
            countryName = country.name
            countryCode = country.code
            validateCountry()
        }
    }

    /// Updates the selected country
    @MainActor
    func updateCountry(name: String, code: String) {
        countryName = name
        countryCode = code
        scope.updateCountryCode(code)
        validateCountry()
    }

    @MainActor
    private func validateCountry() {
        guard let validationService = validationService else { return }

        let result = validationService.validate(
            input: countryCode,
            with: CountryCodeRule()
        )

        isValid = result.isValid
        errorMessage = result.errorMessage

        // Update scope state based on validation
        if result.isValid {
            scope.clearFieldError(.countryCode)
            // Update scope validation state
            if let scope = scope as? DefaultCardFormScope {
                scope.updateCountryCodeValidationState(true)
            }
        } else if let message = result.errorMessage {
            scope.setFieldError(.countryCode, message: message, errorCode: result.errorCode)
            // Update scope validation state
            if let scope = scope as? DefaultCardFormScope {
                scope.updateCountryCodeValidationState(false)
            }
        }
    }
}
