//
//  ModifierChainsCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// PrimerModifier chains demo with complex styling combinations
@available(iOS 15.0, *)
struct ModifierChainsCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        VStack {
            Text("Modifier Chains Demo")
                .font(.headline)
                .padding()
            
            Text("Complex styling combinations")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Modifier Chains Checkout") {
                presentCheckout(title: "ModifierChainsCardFormDemo")
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
        
        // Present using CheckoutComponentsPrimer with custom modifier chains content
        CheckoutComponentsPrimer.presentCheckout(
            with: clientToken,
            from: rootViewController,
            customContent: { checkoutScope in
                return AnyView(
                    PrimerCheckout(
                        clientToken: clientToken,
                        settings: settings,
                        scope: { checkoutScope in
                            checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
                                    VStack(spacing: 20) {
                                        // Modifier chains header
                                        VStack(spacing: 8) {
                                            Text("🔗 Modifier Chains")
                                                .font(.title2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.purple)
                                            
                                            Text("Complex PrimerModifier styling combinations")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        // Advanced modifier chain examples
                                        VStack(spacing: 16) {
                                            // Card number with complex modifier chain
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                cardNumberInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(55)
                                                    .padding(.horizontal, 18)
                                                    .background(.white)
                                                    .cornerRadius(14)
                                                    .border(.purple.opacity(0.6), width: 2)
                                                    .shadow(color: .purple.opacity(0.2), radius: 6, x: 0, y: 3)
                                                )
                                            }
                                            
                                            // Expiry and CVV with different chain styles
                                            HStack(spacing: 14) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(55)
                                                        .padding(.horizontal, 16)
                                                        .background(.white)
                                                        .cornerRadius(12)
                                                        .border(.orange.opacity(0.7), width: 2)
                                                        .shadow(color: .orange.opacity(0.3), radius: 4, x: 2, y: 2)
                                                    )
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(55)
                                                        .padding(.horizontal, 16)
                                                        .background(.white)
                                                        .cornerRadius(12)
                                                        .border(.blue.opacity(0.7), width: 2)
                                                        .shadow(color: .blue.opacity(0.3), radius: 4, x: -2, y: 2)
                                                    )
                                                }
                                            }
                                            
                                            // Cardholder name with most complex chain
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                cardholderNameInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(55)
                                                    .padding(.horizontal, 18)
                                                    .background(.white)
                                                    .cornerRadius(16)
                                                    .border(.green.opacity(0.6), width: 2)
                                                    .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
                                                )
                                            }
                                        }
                                    }
                                    .padding(20)
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                .purple.opacity(0.05),
                                                .orange.opacity(0.05),
                                                .blue.opacity(0.05),
                                                .green.opacity(0.05)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
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
