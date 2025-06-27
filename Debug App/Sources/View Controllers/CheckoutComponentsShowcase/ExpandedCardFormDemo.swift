//
//  ExpandedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Expanded layout demo with vertical fields and generous spacing
@available(iOS 15.0, *)
struct ExpandedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings

    var body: some View {
        VStack {
            Text("Expanded Layout Demo")
                .font(.headline)
                .padding()

            Text("Vertical fields with generous spacing")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            Button("Show Expanded Layout Checkout") {
                presentCheckout(title: "ExpandedCardFormDemo")
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
        
        // Present using CheckoutComponentsPrimer with custom expanded layout content
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
                                    VStack(spacing: 28) {
                                        // Expanded header
                                        VStack(spacing: 8) {
                                            Text("Expanded Payment Form")
                                                .font(.title2)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text("Generous spacing for comfortable input")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Expanded layout - vertical fields with generous spacing
                                        VStack(spacing: 24) {
                                            // Card number with label
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Card Number")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                
                                                if let cardNumberInput = cardScope.cardNumberInput {
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(60)
                                                        .padding(.horizontal, 20)
                                                        .background(.white)
                                                        .cornerRadius(12)
                                                        .border(.blue.opacity(0.2), width: 1)
                                                        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                    )
                                                }
                                            }
                                            
                                            // Expiry and CVV with labels
                                            HStack(spacing: 20) {
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("Expiry Date")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    
                                                    if let expiryDateInput = cardScope.expiryDateInput {
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(60)
                                                            .padding(.horizontal, 20)
                                                            .background(.white)
                                                            .cornerRadius(12)
                                                            .border(.blue.opacity(0.2), width: 1)
                                                            .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                        )
                                                    }
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 8) {
                                                    Text("CVV")
                                                        .font(.subheadline)
                                                        .fontWeight(.semibold)
                                                    
                                                    if let cvvInput = cardScope.cvvInput {
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(60)
                                                            .padding(.horizontal, 20)
                                                            .background(.white)
                                                            .cornerRadius(12)
                                                            .border(.blue.opacity(0.2), width: 1)
                                                            .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                        )
                                                    }
                                                }
                                            }
                                            
                                            // Cardholder name with label
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Cardholder Name")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                
                                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(60)
                                                        .padding(.horizontal, 20)
                                                        .background(.white)
                                                        .cornerRadius(12)
                                                        .border(.blue.opacity(0.2), width: 1)
                                                        .shadow(color: .black.opacity(0.02), radius: 2, x: 0, y: 1)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .padding(24)
                                    .background(.blue.opacity(0.02))
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
