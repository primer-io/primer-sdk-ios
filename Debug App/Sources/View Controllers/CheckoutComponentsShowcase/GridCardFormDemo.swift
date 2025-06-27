//
//  GridCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Grid layout demo with card details in organized grid
@available(iOS 15.0, *)
struct GridCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings

    var body: some View {
        VStack {
            Text("Grid Layout Demo")
                .font(.headline)
                .padding()

            Text("Card details in organized grid")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)

            Button("Show Grid Layout Checkout") {
                presentCheckout(title: "GridCardFormDemo")
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

        print("🔍 [\(title)] Button tapped - presenting CheckoutComponents with grid layout")

        // Present using CheckoutComponentsPrimer with custom grid layout content
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
                            // Grid header
                            Text("Grid Payment Layout")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.purple)
                            
                            // Grid layout for card form
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 16) {
                                // Card number spans full width
                                HStack {
                                    if let cardNumberInput = cardScope.cardNumberInput {
                                        cardNumberInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(48)
                                            .padding(.horizontal, 12)
                                            .background(.white)
                                            .cornerRadius(10)
                                            .border(.purple.opacity(0.3), width: 2)
                                        )
                                    }
                                }
                                                                
                                // Expiry date
                                if let expiryDateInput = cardScope.expiryDateInput {
                                    expiryDateInput(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(48)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(10)
                                        .border(.purple.opacity(0.3), width: 2)
                                    )
                                }
                                
                                // CVV
                                if let cvvInput = cardScope.cvvInput {
                                    cvvInput(PrimerModifier()
                                        .fillMaxWidth()
                                        .height(48)
                                        .padding(.horizontal, 12)
                                        .background(.white)
                                        .cornerRadius(10)
                                        .border(.purple.opacity(0.3), width: 2)
                                    )
                                }
                                
                                // Cardholder name spans full width
                                HStack {
                                    if let cardholderNameInput = cardScope.cardholderNameInput {
                                        cardholderNameInput(PrimerModifier()
                                            .fillMaxWidth()
                                            .height(48)
                                            .padding(.horizontal, 12)
                                            .background(.white)
                                            .cornerRadius(10)
                                            .border(.purple.opacity(0.3), width: 2)
                                        )
                                    }
                                }
                                                            }
                        }
                        .padding()
                        .background(.purple.opacity(0.05))
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
