//
//  ValidationCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Validation showcase with error states and feedback
@available(iOS 15.0, *)
struct ValidationCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    @State private var showValidationErrors = false
    @State private var errorMessages: [String] = []
    
    var body: some View {
        VStack(spacing: 16) {
            // Control section
            HStack {
                Button("Trigger Validation") {
                    showValidationErrors.toggle()
                    if showValidationErrors {
                        errorMessages = [
                            "Card number is required",
                            "Expiry date is invalid",
                            "CVV must be 3-4 digits"
                        ]
                    } else {
                        errorMessages = []
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Spacer()
                
                Text("Errors: \(errorMessages.count)")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            // Card form with validation styling
            PrimerCheckout(
                clientToken: clientToken,
                settings: settings,
                scope: { checkoutScope in
                    if let cardFormScope = checkoutScope.cardForm {
                        cardFormScope.screen = { scope in
                            AnyView(
                                VStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        scope.cardNumberInput?(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(44)
                                            .padding(.horizontal, 12)
                                            .background(.white)
                                            .cornerRadius(8)
                                            .border(showValidationErrors ? .red : .gray.opacity(0.3), width: showValidationErrors ? 2 : 1)
                                        )
                                        
                                        if showValidationErrors && errorMessages.count > 0 {
                                            Text(errorMessages[0])
                                                .font(.caption)
                                                .foregroundColor(.red)
                                        }
                                    }
                                    
                                    HStack(spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            scope.expiryDateInput?(PrimerModifier()
                                                .fillMaxWidth()
                                                .height(44)
                                                .padding(.horizontal, 12)
                                                .background(.white)
                                                .cornerRadius(8)
                                                .border(showValidationErrors ? .red : .gray.opacity(0.3), width: showValidationErrors ? 2 : 1)
                                            )
                                            
                                            if showValidationErrors && errorMessages.count > 1 {
                                                Text(errorMessages[1])
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            scope.cvvInput?(PrimerModifier()
                                                .fillMaxWidth()
                                                .height(44)
                                                .padding(.horizontal, 12)
                                                .background(.white)
                                                .cornerRadius(8)
                                                .border(showValidationErrors ? .red : .gray.opacity(0.3), width: showValidationErrors ? 2 : 1)
                                            )
                                            
                                            if showValidationErrors && errorMessages.count > 2 {
                                                Text(errorMessages[2])
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            )
            .frame(height: showValidationErrors ? 140 : 120)
            .animation(.easeInOut(duration: 0.3), value: showValidationErrors)
        }
    }
}