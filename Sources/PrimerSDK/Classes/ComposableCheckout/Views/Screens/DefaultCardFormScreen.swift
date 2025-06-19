//
//  DefaultCardFormScreen.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Default card form screen with scope integration
@available(iOS 15.0, *)
internal struct DefaultCardFormScreen: View, LogReporter {

    // MARK: - Properties

    let scope: any CardFormScope

    // MARK: - State

    @State private var isLoading = false
    @State private var isSubmitEnabled = false
    @State private var fieldErrors: [ComposableInputValidationError] = []
    @State private var hasBillingFields = false
    @State private var stateTask: Task<Void, Never>?
    @Environment(\.designTokens) private var tokens
    @Environment(\.presentationMode) private var presentationMode

    // MARK: - Body

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    headerView

                    // Use composite methods from scope
                    AnyView(scope.PrimerCardDetails())

                    // Show billing address if required
                    billingAddressSection

                    // Error Display
                    if !fieldErrors.isEmpty {
                        errorSection
                    }

                    // Security Notice
                    securityNoticeView

                    submitButtonSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(tokens?.primerColorBackground ?? Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(tokens?.primerColorBrand ?? .blue)
                }
            }
        }
        .onAppear {
            setupStateBinding()
        }
        .onDisappear {
            stateTask?.cancel()
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 16) {
            Text("Enter Card Details")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

            Text("Your payment information is encrypted and secure")
                .font(.subheadline)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 16)
    }

    @ViewBuilder
    private var billingAddressSection: some View {
        // Only show if billing fields are required
        if hasBillingFields {
            AnyView(scope.PrimerBillingAddress())
        }
    }

    private var cardFormBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(tokens?.primerColorGray100 ?? Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(tokens?.primerColorBorderOutlinedDefault ?? Color(.separator), lineWidth: 1)
            )
    }

    @ViewBuilder
    private var errorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                Text("Please fix the following errors:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
            }

            ForEach(fieldErrors, id: \.elementType) { error in
                Text("• \(error.errorMessage)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.red, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var securityNoticeView: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield")
                .font(.system(size: 20))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text("Secure Payment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(tokens?.primerColorTextPrimary ?? .primary)

                Text("Your card details are encrypted and protected")
                    .font(.caption)
                    .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green, lineWidth: 1)
                )
        )
    }

    @ViewBuilder
    private var submitButtonSection: some View {
        VStack(spacing: 16) {
            AnyView(scope.PrimerSubmitButton(text: "Pay Now"))

            Text("By continuing, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Private Methods

    private func setupStateBinding() {
        logger.debug(message: "🔗 [DefaultCardFormScreen] Setting up state binding")

        stateTask = Task { @MainActor in
            for await state in scope.state() {
                handleStateChange(state)
            }
        }
    }

    private func handleStateChange(_ state: CardFormState) {
        logger.debug(message: "🔄 [DefaultCardFormScreen] State changed - loading: \(state.isLoading), enabled: \(state.isSubmitEnabled)")

        isLoading = state.isLoading
        isSubmitEnabled = state.isSubmitEnabled
        fieldErrors = state.fieldErrors
        hasBillingFields = !state.billingFields.isEmpty

        if !fieldErrors.isEmpty {
            logger.warn(message: "⚠️ [DefaultCardFormScreen] Form has \(fieldErrors.count) validation errors")
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct DefaultCardFormScreen_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCardFormScreen(scope: MockCardFormScope())
    }
}

// MARK: - Mock Scope for Preview

@available(iOS 15.0, *)
private class MockCardFormScope: CardFormScope, ObservableObject {
    @Published private var _state = CardFormState.initial

    func state() -> AsyncStream<CardFormState> {
        asyncStream(for: \._state)
    }

    func updateCardNumber(_ cardNumber: String) {}
    func updateCvv(_ cvv: String) {}
    func updateExpiryDate(_ expiryDate: String) {}
    func updateCardholderName(_ cardholderName: String) {}
    func updatePostalCode(_ postalCode: String) {}
    func updateCountryCode(_ countryCode: String) {}
    func updateCity(_ city: String) {}
    func updateState(_ state: String) {}
    func updateAddressLine1(_ addressLine1: String) {}
    func updateAddressLine2(_ addressLine2: String) {}
    func updatePhoneNumber(_ phoneNumber: String) {}
    func updateFirstName(_ firstName: String) {}
    func updateLastName(_ lastName: String) {}
    func updateRetailOutlet(_ retailOutlet: String) {}
    func updateOtpCode(_ otpCode: String) {}
    func submit() {}
}
