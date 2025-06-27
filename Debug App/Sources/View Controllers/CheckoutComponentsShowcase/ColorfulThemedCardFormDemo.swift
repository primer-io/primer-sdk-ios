//
//  ColorfulThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Colorful theme demo with branded colors and gradients
@available(iOS 15.0, *)
struct ColorfulThemedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        VStack {
            Text("Colorful Theme Demo")
                .font(.headline)
                .padding()
            
            Text("Branded colors with gradients")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Colorful Theme Checkout") {
                presentCheckout(title: "ColorfulThemedCardFormDemo")
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
        
        print("🔍 [\(title)] Button tapped - presenting CheckoutComponents with colorful theme")
        
        // Present using CheckoutComponentsPrimer with custom colorful-themed content
        CheckoutComponentsPrimer.presentCheckout(
            with: clientToken,
            from: rootViewController,
            customContent: { checkoutScope in
                checkoutScope.setPaymentMethodScreen(.paymentCard) { (scope: any PrimerPaymentMethodScope) in
                    guard let cardScope = scope as? any PrimerCardFormScope else {
                        return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                    }
                    return AnyView(
                        VStack(spacing: 20) {
                            // Colorful header
                            Text("🌈 Payment")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundStyle(LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.pink, Color.orange]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ))
                            
                            // Colorful styled card form
                            VStack(spacing: 16) {
                                // Card number with rainbow border
                                if let cardNumberInput = cardScope.cardNumberInput {
                                    cardNumberInput(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(52)
                                        .padding(.horizontal, 16)
                                        .background(.white)
                                        .cornerRadius(12)
                                        .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 2)
                                    )
                                }
                                
                                // Expiry and CVV row with different colors
                                HStack(spacing: 12) {
                                    if let expiryDateInput = cardScope.expiryDateInput {
                                        expiryDateInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(52)
                                            .padding(.horizontal, 16)
                                            .background(.white)
                                            .cornerRadius(12)
                                            .border(Color.orange.opacity(0.6), width: 2)
                                            .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                    
                                    if let cvvInput = cardScope.cvvInput {
                                        cvvInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(52)
                                            .padding(.horizontal, 16)
                                            .background(.white)
                                            .cornerRadius(12)
                                            .border(Color.green.opacity(0.6), width: 2)
                                            .shadow(color: Color.green.opacity(0.3), radius: 4, x: 0, y: 2)
                                        )
                                    }
                                }
                                
                                // Cardholder name with blue accent
                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                    cardholderNameInput(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(52)
                                        .padding(.horizontal, 16)
                                        .background(.white)
                                        .cornerRadius(12)
                                        .border(Color.blue.opacity(0.6), width: 2)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(LinearGradient(
                            gradient: Gradient(colors: [
                                Color.purple.opacity(0.1),
                                Color.pink.opacity(0.1),
                                Color.orange.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
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
