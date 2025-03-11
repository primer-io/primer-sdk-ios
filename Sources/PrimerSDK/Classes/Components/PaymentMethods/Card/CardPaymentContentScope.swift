//
//  CardPaymentContentScope.swift
//
//
//  Created by Boris on 5.3.25..
//

import SwiftUI

/// PaymentMethodContentScope implementation for card payments.
/// This class uses SwiftUI’s ObservableObject so that changes are reflected in the UI.
class CardPaymentContentScope: PaymentMethodContentScope, ObservableObject {
    let method: PaymentMethod

    // Card details input fields.
    @Published var cardNumber: String = "" {
        didSet { validateFields() }
    }
    @Published var expiryMonth: String = "" {
        didSet { validateFields() }
    }
    @Published var expiryYear: String = "" {
        didSet { validateFields() }
    }
    @Published var cvv: String = "" {
        didSet { validateFields() }
    }
    @Published var cardholderName: String = "" {
        didSet { validateFields() }
    }

    // State properties.
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var validationState: PaymentValidationState = PaymentValidationState(isValid: false)

    init(method: PaymentMethod) {
        self.method = method
        // Perform initial validation.
        validateFields()
    }

    /// Validate all input fields and update the validation state.
    private func validateFields() {
        let number = cardNumber.filter { $0.isNumber }
        var valid = true

        // Validate card number using the Luhn algorithm.
        if !luhnCheck(number) {
            valid = false
        }
        // Validate expiry date.
        if let month = Int(expiryMonth), let yearVal = Int(expiryYear) {
            let currentDate = Date()
            let currentYear = Calendar.current.component(.year, from: currentDate) % 100
            let currentMonth = Calendar.current.component(.month, from: currentDate)
            let expYear = yearVal < 100 ? yearVal : yearVal % 100
            if expYear < currentYear || (expYear == currentYear && month < currentMonth) {
                valid = false  // card expired
            }
            if month < 1 || month > 12 {
                valid = false  // invalid month
            }
        } else {
            valid = false  // expiry not fully provided or not numeric
        }
        // Validate CVV (3 or 4 digits).
        let cvvDigits = cvv.filter { $0.isNumber }
        if cvvDigits.count < 3 || cvvDigits.count > 4 || cvvDigits.count != cvv.count {
            valid = false
        }
        // Validate cardholder name.
        if cardholderName.trimmingCharacters(in: .whitespaces).isEmpty {
            valid = false
        }
        // Update validation state.
        validationState = PaymentValidationState(isValid: valid)
    }

    /// Luhn algorithm check for the card number.
    private func luhnCheck(_ number: String) -> Bool {
        var sum = 0
        let reversedDigits = number.reversed().compactMap { Int(String($0)) }
        for (idx, digit) in reversedDigits.enumerated() {
            if idx % 2 == 1 {
                var doubled = digit * 2
                if doubled > 9 { doubled -= 9 }
                sum += doubled
            } else {
                sum += digit
            }
        }
        return !number.isEmpty && sum % 10 == 0
    }

    /// Returns a snapshot of the current payment method state.
    func getState() async -> PaymentMethodState {
        PaymentMethodState(isLoading: isLoading, validationState: validationState)
    }

    /// Simulate submission of the payment.
    func submit() async -> Result<PaymentResult, Error> {
        guard validationState.isValid else {
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid card details"])
            return .failure(error)
        }
        isLoading = true
        defer { isLoading = false }
        // Simulate network delay (2 seconds)
        try? await Task.sleep(nanoseconds: 2 * 1_000_000_000)
        return .success(PaymentResult(success: true, message: "Card payment processed successfully"))
    }

    /// Instead of reading the design tokens via @Environment here (which only works in a View),
    /// we delegate default UI rendering to a dedicated SwiftUI view that properly uses the environment.
    func defaultContent() -> AnyView {
        AnyView(CardPaymentDefaultContentView(scope: self))
    }
}

/// A dedicated SwiftUI view to render default content for card payments.
/// This view reads the design tokens from the environment.
struct CardPaymentDefaultContentView: View {
    @Environment(\.designTokens) var tokens: DesignTokens?
    @ObservedObject var scope: CardPaymentContentScope

    var body: some View {
        if let tokens = tokens {
            VStack(alignment: .leading, spacing: 12) {
                Text("Enter card details:")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tokens.primerColorBrand)
                Group {
                    TextField("Card Number", text: $scope.cardNumber)
                        .keyboardType(.numberPad)
                    HStack {
                        TextField("MM", text: $scope.expiryMonth)
                            .keyboardType(.numberPad)
                        TextField("YY", text: $scope.expiryYear)
                            .keyboardType(.numberPad)
                    }
                    TextField("CVV", text: $scope.cvv)
                        .keyboardType(.numberPad)
                    TextField("Cardholder Name", text: $scope.cardholderName)
                }
                .padding(8)
                .background(tokens.primerColorGray100)
                .cornerRadius(8)
            }
            .padding(16)
        } else {
            Text("Loading design tokens...")
        }
    }
}
