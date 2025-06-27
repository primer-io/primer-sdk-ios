//
//  CompactCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Compact layout demo with horizontal card fields
@available(iOS 15.0, *)
struct CompactCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings

    @State private var showingCheckout = false
    var body: some View {
        VStack {
            Text("Compact Layout Demo")
                .font(.headline)
                .padding()

            Text("Horizontal fields with tight spacing")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            Button("Show Compact Layout Checkout") {
                presentCheckout(title: "CompactCardFormDemo")
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
        
        // Present using CheckoutComponentsPrimer with custom compact layout content
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
                                    VStack(spacing: 12) {
                                        // Compact header
                                        Text("Compact Form")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        // Compact layout - horizontal fields with tight spacing
                                        VStack(spacing: 8) {
                                            // Card number (full width but smaller)
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                cardNumberInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(40)
                                                    .padding(.horizontal, 12)
                                                    .background(.white)
                                                    .cornerRadius(6)
                                                    .border(.gray.opacity(0.3), width: 1)
                                                )
                                            }
                                            
                                            // Compact row: Expiry, CVV, and first part of name
                                            HStack(spacing: 6) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(40)
                                                        .padding(.horizontal, 10)
                                                        .background(.white)
                                                        .cornerRadius(6)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(40)
                                                        .padding(.horizontal, 10)
                                                        .background(.white)
                                                        .cornerRadius(6)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                                
                                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(40)
                                                        .padding(.horizontal, 10)
                                                        .background(.white)
                                                        .cornerRadius(6)
                                                        .border(.gray.opacity(0.3), width: 1)
                                                    )
                                                }
                                            }
                                        }
                                    }
                                    .padding(16)
                                    .background(.gray.opacity(0.05))
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
