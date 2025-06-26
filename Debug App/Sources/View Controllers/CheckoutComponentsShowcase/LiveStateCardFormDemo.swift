//
//  LiveStateCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Live state demo with real-time state updates and debugging
@available(iOS 15.0, *)
struct LiveStateCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    @State private var currentState: String = "Initializing..."
    @State private var cardNumber: String = ""
    @State private var isValid: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // State display section
            VStack(alignment: .leading, spacing: 8) {
                Text("Live State Monitor")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Current State: \(currentState)")
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Text("Card Number: \(cardNumber.isEmpty ? "Empty" : cardNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Valid: \(isValid ? "✅" : "❌")")
                        .font(.caption)
                        .foregroundColor(isValid ? .green : .red)
                }
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            
            // Card form
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: { checkoutScope in
                    // Use new generic payment method screen API
                    checkoutScope.setPaymentMethodScreen((any PrimerCardFormScope).self) { (scope: any PrimerCardFormScope) in
                        AnyView(
                            VStack(spacing: 12) {
                                scope.cardNumberInput?(PrimerModifier()
                                    .fillMaxWidth()
                                    .height(44)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .border(isValid ? .green : .gray.opacity(0.3), width: isValid ? 2 : 1)
                                )
                                
                                HStack(spacing: 12) {
                                    scope.expiryDateInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(44)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(8)
                                        .border(.gray.opacity(0.3), width: 1)
                                    )
                                    
                                    scope.cvvInput?(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(44)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(8)
                                        .border(.gray.opacity(0.3), width: 1)
                                    )
                                }
                            }
                            .onChange(of: cardNumber) { _ in
                                updateState()
                            }
                        )
                    }
                }
            )
            .frame(height: 120)
        }
        .onAppear {
            currentState = "Form loaded and ready"
        }
    }
    
    private func updateState() {
        isValid = cardNumber.count >= 16
        currentState = isValid ? "Valid card number detected" : "Waiting for valid input"
    }
}