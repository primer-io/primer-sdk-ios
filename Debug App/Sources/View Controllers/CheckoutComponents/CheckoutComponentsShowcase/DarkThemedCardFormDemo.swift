//
//  DarkThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Dark theme demo with full dark mode implementation
@available(iOS 15.0, *)
struct DarkThemedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        VStack {
            Text("Dark Theme Demo")
                .font(.headline)
                .padding()
            
            Text("Full dark mode implementation")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Dark Theme Checkout") {
                presentCheckout(title: "DarkThemedCardFormDemo")
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
        
        // Present using CheckoutComponentsPrimer with custom dark theme content
        CheckoutComponentsPrimer.presentCheckout(
            with: clientToken,
            from: rootViewController,
            customContent: { checkoutScope in
                checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                    guard let cardScope = scope as? any PrimerCardFormScope else {
                        return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                    }
                    return AnyView(
                        VStack(spacing: 16) {
                            // Dark theme header
                            VStack(spacing: 8) {
                                Text("Dark Mode Payment")
                                    .font(.title2.weight(.semibold))
                                    .foregroundColor(.white)
                                Text("Complete your secure payment")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .padding(.bottom, 8)
                            
                            // Dark form fields
                            VStack(spacing: 16) {
                                // Card number with dark styling
                                if let cardNumberInput = cardScope.cardNumberInput {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Card Number")
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        cardNumberInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(48)
                                            .padding(.horizontal, 16)
                                            .background(.white.opacity(0.1))
                                            .cornerRadius(12)
                                            .border(.white.opacity(0.3), width: 1)
                                        )
                                    }
                                }
                                
                                // Expiry and CVV row with dark theme
                                HStack(spacing: 16) {
                                    if let expiryDateInput = cardScope.expiryDateInput {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Expiry")
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.white.opacity(0.9))
                                            expiryDateInput(PrimerModifier()
                                                .fillMaxWidth()
                                                .height(48)
                                                .padding(.horizontal, 16)
                                                .background(.white.opacity(0.1))
                                                .cornerRadius(12)
                                                .border(.white.opacity(0.3), width: 1)
                                            )
                                        }
                                    }
                                    
                                    if let cvvInput = cardScope.cvvInput {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("CVV")
                                                .font(.caption.weight(.medium))
                                                .foregroundColor(.white.opacity(0.9))
                                            cvvInput(PrimerModifier()
                                                .fillMaxWidth()
                                                .height(48)
                                                .padding(.horizontal, 16)
                                                .background(.white.opacity(0.1))
                                                .cornerRadius(12)
                                                .border(.white.opacity(0.3), width: 1)
                                            )
                                        }
                                    }
                                }
                                
                                // Cardholder name with dark theme
                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Cardholder Name")
                                            .font(.caption.weight(.medium))
                                            .foregroundColor(.white.opacity(0.9))
                                        cardholderNameInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(48)
                                            .padding(.horizontal, 16)
                                            .background(.white.opacity(0.1))
                                            .cornerRadius(12)
                                            .border(.white.opacity(0.3), width: 1)
                                        )
                                    }
                                }
                            }
                            
                            // Dark theme footer
                            Text("🔒 Secured with 256-bit encryption")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.top, 8)
                        }
                        .padding(24)
                        .background(
                            LinearGradient(
                                colors: [.black, .gray.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    )
                }
                return AnyView(EmptyView())
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
