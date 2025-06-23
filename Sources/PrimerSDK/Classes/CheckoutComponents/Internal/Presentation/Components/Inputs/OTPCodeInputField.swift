//
//  OTPCodeInputField.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for OTP code input with validation
@available(iOS 15.0, *)
internal struct OTPCodeInputField: View, LogReporter {
    // MARK: - Public Properties
    
    /// The label text shown above the field
    let label: String
    
    /// Placeholder text for the input field
    let placeholder: String
    
    /// Expected length of the OTP code
    let expectedLength: Int
    
    /// Callback when the OTP code changes
    let onOTPCodeChange: ((String) -> Void)?
    
    /// Callback when the validation state changes
    let onValidationChange: ((Bool) -> Void)?
    
    // MARK: - Private Properties
    
    /// The validation service resolved from DI environment
    @Environment(\.diContainer) private var container
    @State private var validationService: ValidationService?
    
    /// The OTP code entered by the user
    @State private var otpCode: String = ""
    
    /// The validation state of the OTP code
    @State private var isValid: Bool = false
    
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
            
            // OTP input field
            TextField(placeholder, text: $otpCode)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .padding()
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: otpCode) { newValue in
                    // Limit to expected length
                    if newValue.count > expectedLength {
                        otpCode = String(newValue.prefix(expectedLength))
                    } else {
                        onOTPCodeChange?(newValue)
                        validateOTPCode()
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
        .onAppear {
            setupValidationService()
        }
    }
    
    private func setupValidationService() {
        guard let container = container else {
            logger.error(message: "DIContainer not available for OTPCodeInputField")
            return
        }
        
        do {
            validationService = try container.resolveSync(ValidationService.self)
        } catch {
            logger.error(message: "Failed to resolve ValidationService: \(error)")
        }
    }
    
    private func validateOTPCode() {
        guard let validationService = validationService else { return }
        
        // Use OTPCodeRule with expected length
        let otpRule = OTPCodeRule(expectedLength: expectedLength)
        let result = otpRule.validate(otpCode)
        
        isValid = result.isValid
        errorMessage = result.errors.first?.message
        onValidationChange?(result.isValid)
    }
}