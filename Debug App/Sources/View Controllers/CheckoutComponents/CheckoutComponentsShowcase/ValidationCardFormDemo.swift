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
    
    var body: some View {
        VStack {
            Text("Validation Showcase Demo")
                .font(.headline)
                .padding()
            
            Text("Error states and validation feedback")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Validation Showcase Checkout") {
                presentCheckout(title: "ValidationCardFormDemo")
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 200)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
    
    private func presentCheckout(title: String) {
        // Find the current view controller to present from
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let rootViewController = findTopViewController(from: window.rootViewController) else {
            print("❌ [\(title)] Could not find view controller to present from")
            return
        }
        
        print("🔍 [\(title)] Button tapped - presenting CheckoutComponents")
        print("🔍 [\(title)] About to present CheckoutComponents for validation demo")
        print("🔍 [\(title)] Expected behavior: Should skip payment method selection and show custom validation form directly")
        
        // Present using CheckoutComponentsPrimer with custom validation showcase content
        CheckoutComponentsPrimer.presentCheckout(
            with: clientToken,
            from: rootViewController,
            customContent: { checkoutScope in
                print("📱 [\(title)] CustomContent closure called - creating PrimerCheckout")
                return AnyView(
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            print("🔧 [\(title)] PrimerCheckout scope closure called - setting custom payment method screen")
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                print("🎨 [\(title)] Custom validation form screen builder called - this should be the custom UI")
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
                                    VStack(spacing: 20) {
                                        // Validation showcase header
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("Validation Showcase")
                                                    .font(.title2.weight(.semibold))
                                                Spacer()
                                                Image(systemName: "checkmark.shield")
                                                    .foregroundColor(.green)
                                                    .font(.title3)
                                            }
                                            Text("Try entering invalid data to see error states")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Validation info banner
                                        HStack {
                                            Image(systemName: "info.circle.fill")
                                                .foregroundColor(.blue)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Validation Examples")
                                                    .font(.caption.weight(.semibold))
                                                Text("Try: 1234 (invalid), 4242424242424242 (valid)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(.blue.opacity(0.1))
                                        .cornerRadius(8)
                                        
                                        // Form with validation emphasis
                                        VStack(spacing: 16) {
                                            // Card number with validation styling
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text("Card Number")
                                                            .font(.subheadline.weight(.medium))
                                                        Spacer()
                                                        Text("Required")
                                                            .font(.caption)
                                                            .foregroundColor(.red)
                                                    }
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                        .background(.white)
                                                        .cornerRadius(8)
                                                        .border(.red.opacity(0.3), width: 2)
                                                    )
                                                    Text("16-digit card number")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            
                                            // Expiry and CVV with validation states
                                            HStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text("Expiry")
                                                                .font(.subheadline.weight(.medium))
                                                            Spacer()
                                                            Text("MM/YY")
                                                                .font(.caption)
                                                                .foregroundColor(.orange)
                                                        }
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                            .background(.white)
                                                            .cornerRadius(8)
                                                            .border(.orange.opacity(0.3), width: 2)
                                                        )
                                                        Text("Must be future date")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text("CVV")
                                                                .font(.subheadline.weight(.medium))
                                                            Spacer()
                                                            Text("3-4 digits")
                                                                .font(.caption)
                                                                .foregroundColor(.purple)
                                                        }
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                            .background(.white)
                                                            .cornerRadius(8)
                                                            .border(.purple.opacity(0.3), width: 2)
                                                        )
                                                        Text("Security code")
                                                            .font(.caption)
                                                            .foregroundColor(.secondary)
                                                    }
                                                }
                                            }
                                            
                                            // Cardholder name with validation
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text("Cardholder Name")
                                                            .font(.subheadline.weight(.medium))
                                                        Spacer()
                                                        Text("Full name")
                                                            .font(.caption)
                                                            .foregroundColor(.green)
                                                    }
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                        .background(.white)
                                                        .cornerRadius(8)
                                                        .border(.green.opacity(0.3), width: 2)
                                                    )
                                                    Text("As shown on your card")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                        
                                        // Validation rules footer
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Validation Rules:")
                                                .font(.caption.weight(.semibold))
                                            Text("• Card numbers must pass Luhn algorithm")
                                            Text("• Expiry dates must be in the future")
                                            Text("• CVV must be 3-4 digits depending on card type")
                                            Text("• All fields are required for completion")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    }
                                    .padding(20)
                                    .background(.gray.opacity(0.02))
                                )
                            }
                        }
                    )
                )
            },
            completion: {
                print("✅ [\(title)] CheckoutComponents presentation completed")
            }
        )
        
        print("✅ [\(title)] CheckoutComponents presentation initiated")
    }

    private func findTopViewController(from rootViewController: UIViewController?) -> UIViewController? {
        if let presented = rootViewController?.presentedViewController {
            return findTopViewController(from: presented)
        }
        
        if let navigationController = rootViewController as? UINavigationController {
            return findTopViewController(from: navigationController.visibleViewController)
        }
        
        if let tabBarController = rootViewController as? UITabBarController {
            return findTopViewController(from: tabBarController.selectedViewController)
        }
        
        return rootViewController
    }
}
