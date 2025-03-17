//
//  CardPaymentView.swift
//  
//
//  Created by Boris on 17.3.25..
//

import SwiftUI

/// Default UI for card payments.
@available(iOS 14.0, *)
struct CardPaymentView: View {
    let scope: any CardPaymentMethodScope
    
    @State private var cardNumber: String = ""
    @State private var expiryMonth: String = ""
    @State private var expiryYear: String = ""
    @State private var cvv: String = ""
    @State private var cardholderName: String = ""
    @State private var isValid: Bool = false
    @State private var isSubmitting: Bool = false
    
    @Environment(\.designTokens) private var tokens
    
    var body: some View {
        if #available(iOS 15.0, *) {
            VStack(spacing: 16) {
                // Card number field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Card Number")
                        .font(.caption)
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    TextField("1234 5678 9012 3456", text: $cardNumber)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: cardNumber) { newValue in
                            scope.updateCardNumber(newValue)
                        }
                }
                
                // Expiry date and CVV row
                HStack(spacing: 16) {
                    // Expiry month/year fields
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expiry Date")
                            .font(.caption)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        HStack(spacing: 8) {
                            TextField("MM", text: $expiryMonth)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .padding()
                                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: expiryMonth) { newValue in
                                    scope.updateExpiryMonth(newValue)
                                }
                            
                            Text("/")
                                .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                            
                            TextField("YY", text: $expiryYear)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 60)
                                .padding()
                                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                                .cornerRadius(8)
                                .onChange(of: expiryYear) { newValue in
                                    scope.updateExpiryYear(newValue)
                                }
                        }
                    }
                    
                    // CVV field
                    VStack(alignment: .leading, spacing: 4) {
                        Text("CVV")
                            .font(.caption)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                        TextField("123", text: $cvv)
                            .keyboardType(.numberPad)
                            .padding()
                            .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                            .cornerRadius(8)
                            .onChange(of: cvv) { newValue in
                                scope.updateCvv(newValue)
                            }
                    }
                }
                
                // Cardholder name field
                VStack(alignment: .leading, spacing: 4) {
                    Text("Cardholder Name")
                        .font(.caption)
                        .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    TextField("John Doe", text: $cardholderName)
                        .padding()
                        .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                        .cornerRadius(8)
                        .onChange(of: cardholderName) { newValue in
                            scope.updateCardholderName(newValue)
                        }
                }
                
                // Submit button
                Button {
                    isSubmitting = true
                    Task {
                        do {
                            let result = try await scope.submit()
                            print("Payment successful: \(result)")
                            // Handle successful payment
                        } catch {
                            print("Payment failed: \(error)")
                            // Handle payment failure
                        }
                        isSubmitting = false
                    }
                } label: {
                    Text(isSubmitting ? "Processing..." : "Pay")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isValid ? (tokens?.primerColorBrand ?? .blue) : (tokens?.primerColorGray400 ?? .gray))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(!isValid || isSubmitting)
            }
            .padding(16)
            .task {
                for await state in await scope.state() {
                    if let state = state {
                        cardNumber = state.cardNumber
                        expiryMonth = state.expiryMonth
                        expiryYear = state.expiryYear
                        cvv = state.cvv
                        cardholderName = state.cardholderName
                        isValid = state.isValid
                    }
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
