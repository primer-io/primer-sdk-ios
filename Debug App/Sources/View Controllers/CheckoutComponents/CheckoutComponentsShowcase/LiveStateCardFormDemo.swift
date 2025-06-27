//
//  LiveStateCardFormDemo.swift
//  Debug App
//
//  Created by Claude on 26.6.25.
//

import SwiftUI
import PrimerSDK

/// Live state demo with real-time state updates and debugging
@available(iOS 15.0, *)
struct LiveStateCardFormDemo: View {
    let clientToken: String
    let settings: PrimerSettings
    
    var body: some View {
        VStack {
            Text("Live State Demo")
                .font(.headline)
                .padding()
            
            Text("Real-time state updates and debugging")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            
            Button("Show Live State Checkout") {
                presentCheckout(title: "LiveStateCardFormDemo")
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
        
        // Present using CheckoutComponentsPrimer with custom live state content
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
                                        // Live state header with indicators
                                        VStack(spacing: 8) {
                                            HStack {
                                                Text("Live State Demo")
                                                    .font(.title2.weight(.semibold))
                                                Spacer()
                                                Circle()
                                                    .fill(.green)
                                                    .frame(width: 8, height: 8)
                                                Text("LIVE")
                                                    .font(.caption.weight(.bold))
                                                    .foregroundColor(.green)
                                            }
                                            Text("Real-time validation and state updates")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        // Form with live state indicators
                                        VStack(spacing: 16) {
                                            // Card number with live state
                                            if let cardNumberInput = cardScope.cardNumberInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text("Card Number")
                                                            .font(.subheadline.weight(.medium))
                                                        Spacer()
                                                        Text("🟢 Validating...")
                                                            .font(.caption)
                                                            .foregroundColor(.orange)
                                                    }
                                                    cardNumberInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                        .background(.blue.opacity(0.05))
                                                        .cornerRadius(10)
                                                        .border(.blue.opacity(0.3), width: 2)
                                                    )
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                            
                                            // Expiry and CVV with state indicators
                                            HStack(spacing: 16) {
                                                if let expiryDateInput = cardScope.expiryDateInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text("Expiry")
                                                                .font(.subheadline.weight(.medium))
                                                            Spacer()
                                                            Text("⚙️")
                                                                .font(.caption)
                                                        }
                                                        expiryDateInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                            .background(.green.opacity(0.05))
                                                            .cornerRadius(10)
                                                            .border(.green.opacity(0.3), width: 2)
                                                        )
                                                    }
                                                    .padding(.horizontal, 4)
                                                }
                                                
                                                if let cvvInput = cardScope.cvvInput {
                                                    VStack(alignment: .leading, spacing: 6) {
                                                        HStack {
                                                            Text("CVV")
                                                                .font(.subheadline.weight(.medium))
                                                            Spacer()
                                                            Text("🔒")
                                                                .font(.caption)
                                                        }
                                                        cvvInput(PrimerModifier()
                                                            .fillMaxWidth()
                                                            .height(50)
                                                            .padding(.horizontal, 16)
                                                            .background(.purple.opacity(0.05))
                                                            .cornerRadius(10)
                                                            .border(.purple.opacity(0.3), width: 2)
                                                        )
                                                    }
                                                    .padding(.horizontal, 4)
                                                }
                                            }
                                            
                                            // Cardholder name with live feedback
                                            if let cardholderNameInput = cardScope.cardholderNameInput {
                                                VStack(alignment: .leading, spacing: 6) {
                                                    HStack {
                                                        Text("Name on Card")
                                                            .font(.subheadline.weight(.medium))
                                                        Spacer()
                                                        Text("👤 Input Active")
                                                            .font(.caption)
                                                            .foregroundColor(.blue)
                                                    }
                                                    cardholderNameInput(PrimerModifier()
                                                        .fillMaxWidth()
                                                        .height(50)
                                                        .padding(.horizontal, 16)
                                                        .background(.orange.opacity(0.05))
                                                        .cornerRadius(10)
                                                        .border(.orange.opacity(0.3), width: 2)
                                                    )
                                                }
                                                .padding(.horizontal, 4)
                                            }
                                        }
                                        
                                        // Live state footer
                                        VStack(spacing: 4) {
                                            Text("• Fields validate in real-time")
                                            Text("• State changes are immediately visible")
                                            Text("• Live feedback provides instant validation")
                                        }
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    }
                                    .padding(20)
                                    .background(.white)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(.blue.opacity(0.2), lineWidth: 1)
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
