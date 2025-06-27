//
//  ModernThemedCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Modern theme demo with clean white and subtle shadows
@available(iOS 15.0, *)
struct ModernThemedCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings

    var body: some View {
        VStack {
            Text("Modern Theme Demo")
                .font(.headline)
                .padding()

            Text("Clean white with subtle shadows")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            Button("Show Modern Theme Checkout") {
                presentCheckout(title: "ModernThemedCardFormDemo")
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

        print("🔍 [\(title)] Button tapped - presenting CheckoutComponents with modern theme")
        print("🔍 [\(title)] About to present CheckoutComponents for card form demo")
        print("🔍 [\(title)] Expected behavior: Should skip payment method selection and show custom card form directly")

        // Present using CheckoutComponentsPrimer with custom modern-themed content
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
                                print("🎨 [\(title)] Custom card form screen builder called - this should be the custom UI")
                                guard let cardScope = scope as? any PrimerCardFormScope else {
                                    return AnyView(Text("Error: Invalid scope type").foregroundColor(.red))
                                }
                                return AnyView(
                                    VStack(spacing: 24) {
                                        // Modern header
                                        Text("Payment")
                                            .font(.largeTitle)
                                            .fontWeight(.thin)
                                            .foregroundColor(.primary)
                                        
                                        // Modern styled card form
                                        VStack(spacing: 20) {
                                            // Card number with modern styling
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                cardNumberInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(56)
                                                    .padding(.horizontal, 20)
                                                    .background(.white)
                                                    .cornerRadius(16)
                                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                )
                                            }
                                            
                                            // Expiry and CVV row
                                            HStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    expiryDateInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(56)
                                                        .padding(.horizontal, 20)
                                                        .background(.white)
                                                        .cornerRadius(16)
                                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                    )
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    cvvInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(56)
                                                        .padding(.horizontal, 20)
                                                        .background(.white)
                                                        .cornerRadius(16)
                                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                    )
                                                }
                                            }
                                            
                                            // Cardholder name
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                cardholderNameInput(PrimerModifier()
                                                    .fillMaxWidth()
                                                    .height(56)
                                                    .padding(.horizontal, 20)
                                                    .background(.white)
                                                    .cornerRadius(16)
                                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                                                )
                                            }
                                        }
                                    }
                                    .padding(24)
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
