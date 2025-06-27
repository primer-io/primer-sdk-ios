//
//  CorporateThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Corporate theme demo with professional blue and gray styling
@available(iOS 15.0, *)
struct CorporateThemedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        VStack {
            Text("Corporate Theme Demo")
                .font(.headline)
                .padding()
            
            Text("Professional blue and gray styling")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Corporate Theme Checkout") {
                presentCheckout(title: "CorporateThemedCardFormDemo")
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
        
        // Present using CheckoutComponentsPrimer with custom corporate-themed content
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
                            // Corporate header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Payment Details")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.7))
                                
                                Text("Enter your corporate card information")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Corporate styled card form
                            VStack(spacing: 12) {
                                // Card number with corporate styling
                                if let cardNumberInput = cardScope.cardNumberInput {
                                    cardNumberInput(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(50)
                                        .padding(.horizontal, 16)
                                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                        .cornerRadius(8)
                                        .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                        .font(.system(.body, design: .monospaced))
                                    )
                                }
                                
                                // Expiry and CVV row
                                HStack(spacing: 12) {
                                    if let expiryDateInput = cardScope.expiryDateInput {
                                        expiryDateInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(50)
                                            .padding(.horizontal, 16)
                                            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                            .cornerRadius(8)
                                            .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                            .font(.system(.body, design: .monospaced))
                                        )
                                    }
                                    
                                    if let cvvInput = cardScope.cvvInput {
                                        cvvInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(50)
                                            .padding(.horizontal, 16)
                                            .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                            .cornerRadius(8)
                                            .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                            .font(.system(.body, design: .monospaced))
                                        )
                                    }
                                }
                                
                                // Cardholder name
                                if let cardholderNameInput = cardScope.cardholderNameInput {
                                    cardholderNameInput(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(50)
                                        .padding(.horizontal, 16)
                                        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
                                        .cornerRadius(8)
                                        .border(Color(red: 0.2, green: 0.4, blue: 0.7), width: 1)
                                        .font(.system(.body, design: .monospaced))
                                    )
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(red: 0.95, green: 0.96, blue: 0.98))
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
